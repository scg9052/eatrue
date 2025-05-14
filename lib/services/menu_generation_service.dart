// services/menu_generation_service.dart
import 'dart:convert';
import 'dart:async'; // 타임아웃 설정용
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/recipe.dart'; // Recipe 모델 import
import '../models/user_data.dart'; // UserData 모델 import
import 'package:shared_preferences/shared_preferences.dart'; // 캐싱용
import '../models/simple_menu.dart';

class MenuGenerationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';
  
  // 메뉴 응답 캐싱용 변수
  Map<String, dynamic>? _cachedMenuResponse;
  DateTime? _lastMenuGenerationTime;
  String? _lastMenuGenerationKey;

  // 타임아웃 설정
  final Duration _defaultTimeout = Duration(seconds: 30);

  MenuGenerationService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  GenerationConfig _getBaseGenerationConfig({String? responseMimeType}) {
    return GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1,
      topP: 0.95,
      responseMimeType: responseMimeType,
    );
  }

  List<SafetySetting> _getSafetySettings() {
    // TODO: firebase_vertexai 패키지 버전에 맞는 정확한 HarmBlockThreshold 및 HarmBlockMethod 값으로 수정하세요.
    // 예: SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.block)
    return [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity),
    ];
  }

  // 메뉴 생성을 위한 캐시 키 생성
  String _generateMenuCacheKey(Map<String, dynamic> nutrients, String dislikes, String preferences) {
    // 간단한 해시 생성 (실제로는 더 강력한 해싱 알고리즘 사용 권장)
    final hash = '${nutrients.hashCode}_${dislikes.hashCode}_${preferences.hashCode}';
    return 'menu_cache_$hash';
  }

  // 캐시에서 메뉴 로드
  Future<Map<String, dynamic>?> _loadMenuFromCache(String cacheKey) async {
    try {
      // 메모리 캐시 확인
      if (_cachedMenuResponse != null && 
          _lastMenuGenerationKey == cacheKey &&
          _lastMenuGenerationTime != null) {
        // 캐시가 1시간 이내인 경우에만 사용
        final cacheDuration = DateTime.now().difference(_lastMenuGenerationTime!);
        if (cacheDuration.inHours < 1) {
          print("✅ 메모리 캐시에서 메뉴 로드됨 (캐시 생성 후 ${cacheDuration.inMinutes}분 경과)");
          return _cachedMenuResponse;
        }
      }
      
      // 로컬 스토리지 캐시 확인
      final prefs = await SharedPreferences.getInstance();
      final menuCacheJson = prefs.getString(cacheKey);
      
      if (menuCacheJson != null) {
        final cacheTimestamp = prefs.getInt('${cacheKey}_timestamp') ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        final cacheDuration = DateTime.now().difference(cacheTime);
        
        // 캐시가 12시간 이내인 경우에만 사용
        if (cacheDuration.inHours < 12) {
          final cachedMenu = json.decode(menuCacheJson) as Map<String, dynamic>;
          print("✅ 로컬 캐시에서 메뉴 로드됨 (캐시 생성 후 ${cacheDuration.inHours}시간 경과)");
          
          // 메모리 캐시도 업데이트
          _cachedMenuResponse = cachedMenu;
          _lastMenuGenerationTime = cacheTime;
          _lastMenuGenerationKey = cacheKey;
          
          return cachedMenu;
        } else {
          print("⚠️ 로컬 캐시가 만료됨 (${cacheDuration.inHours}시간 경과)");
          // 만료된 캐시 삭제
          prefs.remove(cacheKey);
          prefs.remove('${cacheKey}_timestamp');
        }
      }
      
      return null;
    } catch (e) {
      print("⚠️ 캐시 로드 중 오류: $e");
      return null;
    }
  }

  // 캐시에 메뉴 저장
  Future<void> _saveMenuToCache(String cacheKey, Map<String, dynamic> menuResponse) async {
    try {
      // 메모리 캐시 업데이트
      _cachedMenuResponse = menuResponse;
      _lastMenuGenerationTime = DateTime.now();
      _lastMenuGenerationKey = cacheKey;
      
      // 로컬 스토리지 캐시 업데이트
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, json.encode(menuResponse));
      await prefs.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      print("✅ 메뉴가 캐시에 저장됨");
    } catch (e) {
      print("⚠️ 캐시 저장 중 오류: $e");
    }
  }

  // 타임아웃 적용된 API 호출
  Future<dynamic> _callGenerativeModelWithTimeout(
      String systemInstructionText, String userPrompt, {
      String? modelNameOverride,
      Duration? timeout}) async {
    
    final effectiveTimeout = timeout ?? _defaultTimeout;
    
    try {
      return await _callGenerativeModelForJson(
        systemInstructionText, 
        userPrompt,
        modelNameOverride: modelNameOverride,
      ).timeout(effectiveTimeout, onTimeout: () {
        print("⚠️ API 호출 타임아웃 (${effectiveTimeout.inSeconds}초)");
        return null;
      });
    } catch (e) {
      print("❌ API 호출 중 오류 (타임아웃 처리): $e");
      return null;
    }
  }

  Future<dynamic> _callGenerativeModelForJson(
      String systemInstructionText, String userPrompt, {String? modelNameOverride}) async {
    try {
      final systemInstruction = Content.system(systemInstructionText);
      final model = _vertexAI.generativeModel(
        model: modelNameOverride ?? _modelName,
        generationConfig: _getBaseGenerationConfig(responseMimeType: 'application/json'),
        safetySettings: _getSafetySettings(),
        systemInstruction: systemInstruction,
      );
      final chat = model.startChat();
      final startTime = DateTime.now();
      final response = await chat.sendMessage(Content.text(userPrompt));
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print("Vertex AI 응답 소요시간: ${duration.inMilliseconds}ms");
      
      if (response.text == null || response.text!.isEmpty) {
        print("오류: Vertex AI가 빈 응답을 반환했습니다.");
        return null;
      }

      print("응답 텍스트 길이: ${response.text!.length}자");
      String previewText = response.text!.length > 100 
          ? response.text!.substring(0, 100) 
          : response.text!;
      print("응답 미리보기: $previewText...");
      
      // 응답 정제 및 파싱
      try {
        // 백틱과 JSON 표시 제거
        String jsonString = response.text!.trim();
        
        // 백틱으로 감싸진 코드 블록 제거
        if (jsonString.contains("```")) {
          final regex = RegExp(r'```(?:json)?([\s\S]*?)```');
          final matches = regex.allMatches(jsonString);
          
          if (matches.isNotEmpty) {
            // 첫 번째 매치된 코드 블록 내용만 사용
            jsonString = matches.first.group(1)?.trim() ?? jsonString;
          } else {
            // 정규식 매치가 실패한 경우 수동으로 처리
            jsonString = jsonString
                .replaceAll("```json", "")
                .replaceAll("```", "")
                .trim();
          }
          print("백틱 제거 후 JSON 문자열 정제");
        }
        
        // JSON 시작/끝 위치 정확하게 찾기
        final int jsonStart = jsonString.indexOf('{');
        final int jsonEnd = jsonString.lastIndexOf('}');
        
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          // 정확한 JSON 부분만 추출
          jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
        }
        
        // 일반적인 JSON 오류 수정
        jsonString = jsonString
            .replaceAll("'", "\"")           // 작은따옴표를 큰따옴표로 변경
            .replaceAll(",\n}", "\n}")       // 마지막 쉼표 제거
            .replaceAll(",\n]", "\n]")       // 배열 마지막 쉼표 제거
            .replaceAll("},\n  ]", "}\n  ]") // 배열 마지막 쉼표 제거
            .replaceAll(",,", ",")           // 중복 쉼표 제거
            .replaceAll(",}", "}")           // 객체 끝 쉼표 제거
            .replaceAll(",]", "]");          // 배열 끝 쉼표 제거
        
        // 속성명에 따옴표 추가 (안전한 방식)
        jsonString = _addQuotesToPropertyNames(jsonString);
        
        try {
          // JSON 파싱 시도
          final decoded = json.decode(jsonString);
          print("✅ JSON 파싱 성공");
          
          // 결과 처리 로직
          if (decoded is List) {
            return decoded;
          } else if (decoded is Map) {
            // 실패한 경우 명시적 오류 확인
            if (decoded.containsKey('error')) {
              print("API 오류 응답: ${decoded['error']}");
            }
            
            // candidates나 results 키가 있는지 확인
            final candidates = decoded['candidates'];
            final results = decoded['results'];
            if (candidates is List && candidates.isNotEmpty) return candidates;
            if (results is List && results.isNotEmpty) return results;
            
            // breakfast, lunch 등의 식사 키가 있는지 확인 (메뉴 생성 응답)
            if (decoded.containsKey('breakfast') || decoded.containsKey('lunch') || 
                decoded.containsKey('dinner') || decoded.containsKey('snacks')) {
              print("메뉴 응답 구조 확인됨");
              return decoded;
            }
            
            return decoded;
          }
          return decoded;
        } catch (jsonError) {
          print("⚠️ JSON 파싱 실패: $jsonError");
          
          // 주요 식단 정보가 있는지 확인하고 부분적으로 복구 시도
          final result = _attemptJsonRecovery(jsonString);
          if (result != null) {
            print("✅ 메뉴 JSON 복구 성공");
            return result;
          }
          
          print("❌ 모든 JSON 복구 시도 실패");
          return _createFallbackMenuResponse();
        }
      } catch (e) {
        print("❌ Vertex AI 응답 처리 중 오류: $e");
        return _createFallbackMenuResponse();
      }
    } catch (e) {
      print("❌ Vertex AI 모델 호출 중 오류: $e");
      return _createFallbackMenuResponse();
    }
  }
  
  // 속성명에 따옴표 추가 (안전한 방식)
  String _addQuotesToPropertyNames(String jsonText) {
    // 속성명:값 패턴을 찾아 속성명에 따옴표 추가
    final propertyRegex = RegExp(r'([a-zA-Z0-9_]+)(\s*:\s*)');
    return jsonText.replaceAllMapped(propertyRegex, (match) {
      final propertyName = match.group(1)!;
      final separator = match.group(2)!;
      
      // 안전하게 이전 문자 확인
      bool isAlreadyQuoted = false;
      if (match.start > 0) {
        final prevChar = jsonText[match.start - 1];
        isAlreadyQuoted = (prevChar == '"' || prevChar == "'");
      }
      
      // 속성명이 이미 따옴표로 감싸져 있지 않은 경우에만 추가
      if (!isAlreadyQuoted) {
        return '"$propertyName"$separator';
      }
      return match.group(0)!;
    });
  }
  
  // JSON 복구 시도 메서드
  Map<String, dynamic>? _attemptJsonRecovery(String jsonText) {
    try {
      print("JSON 복구 시도 시작");
      
      // 1. 기본 메뉴 구조 생성
      final result = {
        'breakfast': <Map<String, dynamic>>[],
        'lunch': <Map<String, dynamic>>[],
        'dinner': <Map<String, dynamic>>[],
        'snacks': <Map<String, dynamic>>[],
      };
      
      // 2. 카테고리별 추출 시도
      bool anySuccess = false;
      final categories = ['breakfast', 'lunch', 'dinner', 'snacks'];
      
      for (final category in categories) {
        // 카테고리 시작점 찾기
        final categoryPattern = '"$category"\\s*:\\s*\\[';
        final categoryMatch = RegExp(categoryPattern).firstMatch(jsonText);
        
        if (categoryMatch != null) {
          int pos = categoryMatch.end;
          int depth = 1; // 대괄호 깊이 추적
          int start = pos;
          
          // 배열 끝 찾기
          while (pos < jsonText.length && depth > 0) {
            if (jsonText[pos] == '[') depth++;
            else if (jsonText[pos] == ']') depth--;
            pos++;
          }
          
          if (depth == 0) {
            // 배열 추출 성공
            final arrayText = jsonText.substring(start, pos - 1);
            print("$category 배열 추출: ${arrayText.length}자");
            
            try {
              // 임시 JSON 구조로 파싱 시도
              final tempJson = '[$arrayText]';
              final items = json.decode(tempJson) as List;
              
              result[category] = List<Map<String, dynamic>>.from(
                items.map((item) => Map<String, dynamic>.from(item))
              );
              
              print("✅ $category 파싱 성공: ${result[category]!.length}개 항목");
              anySuccess = true;
            } catch (e) {
              print("⚠️ $category 배열 파싱 실패: $e");
              // 실패한 경우 기본 메뉴 생성
              result[category] = _createFallbackMenuItems(category);
            }
          } else {
            print("⚠️ $category 배열 종료 태그를 찾지 못함");
            result[category] = _createFallbackMenuItems(category);
          }
        } else {
          print("⚠️ $category 카테고리를 찾지 못함");
          result[category] = _createFallbackMenuItems(category);
        }
      }
      
      if (anySuccess) {
        print("✅ 부분적 JSON 복구 성공");
        return result;
      } else {
        print("❌ JSON 복구 실패, 기본 메뉴 반환");
        return _createFallbackMenuResponse();
      }
    } catch (e) {
      print("❌ JSON 복구 시도 중 오류: $e");
      return _createFallbackMenuResponse();
    }
  }

  // 모델 응답 실패 시 기본 메뉴 구조 생성
  Map<String, dynamic>? _createFallbackMenuResponse() {
    try {
      return {
        "breakfast": [
          {
            "dish_name": "영양 오트밀 죽 세트",
            "category": "breakfast",
            "description": "간단하고 영양가 높은 아침 식사로, 부드러운 오트밀에 견과류와 계절 과일을 곁들임",
            "ingredients": ["오트밀", "우유", "꿀", "아몬드", "블루베리", "바나나"],
            "approximate_nutrients": {"칼로리": "350 kcal", "단백질": "12 g", "탄수화물": "45 g", "지방": "13 g"},
            "cooking_time": "15분",
            "difficulty": "하"
          },
          {
            "dish_name": "채소 계란 토스트 플레이트",
            "category": "breakfast",
            "description": "통밀빵에 계란 프라이와 아보카도, 신선한 채소를 곁들인 단백질이 풍부한 아침 메뉴",
            "ingredients": ["통밀빵", "계란", "아보카도", "시금치", "방울토마토", "올리브 오일"],
            "approximate_nutrients": {"칼로리": "420 kcal", "단백질": "18 g", "탄수화물": "35 g", "지방": "25 g"},
            "cooking_time": "20분",
            "difficulty": "중"
          },
          {
            "dish_name": "그릭요거트 과일 그래놀라 볼",
            "category": "breakfast",
            "description": "단백질이 풍부한 그릭요거트에 다양한 베리류와 홈메이드 그래놀라를 곁들인 건강식",
            "ingredients": ["그릭요거트", "그래놀라", "블루베리", "딸기", "꿀", "치아씨드"],
            "approximate_nutrients": {"칼로리": "380 kcal", "단백질": "15 g", "탄수화물": "40 g", "지방": "18 g"},
            "cooking_time": "10분",
            "difficulty": "하"
          }
        ],
        "lunch": [
          {
            "dish_name": "계절 야채 비빔밥 세트",
            "category": "lunch",
            "description": "오곡밥 위에 다양한 계절 야채와 소고기, 계란 프라이를 올려 고추장과 함께 비벼 먹는 한식 정식",
            "ingredients": ["오곡밥", "소고기", "당근", "시금치", "버섯", "계란", "고추장", "참기름"],
            "approximate_nutrients": {"칼로리": "550 kcal", "단백질": "25 g", "탄수화물": "65 g", "지방": "20 g"},
            "cooking_time": "35분",
            "difficulty": "중"
          },
          {
            "dish_name": "그린 샐러드와 통밀 치아바타 세트",
            "category": "lunch",
            "description": "다양한 신선한 채소와 견과류, 치즈가 들어간 샐러드에 통밀 치아바타 빵을 곁들인 가벼운 점심",
            "ingredients": ["양상추", "베이비 시금치", "토마토", "오이", "아보카도", "호두", "페타 치즈", "통밀 치아바타", "발사믹 드레싱"],
            "approximate_nutrients": {"칼로리": "450 kcal", "단백질": "15 g", "탄수화물": "40 g", "지방": "25 g"},
            "cooking_time": "20분",
            "difficulty": "하"
          },
          {
            "dish_name": "고단백 참치 김밥 도시락",
            "category": "lunch",
            "description": "참치와 채소, 계란을 듬뿍 넣은 든든한 김밥과 미니 과일 세트로 구성된 균형 잡힌 한 끼",
            "ingredients": ["밥", "김", "참치", "당근", "오이", "시금치", "계란", "사과", "귤"],
            "approximate_nutrients": {"칼로리": "520 kcal", "단백질": "22 g", "탄수화물": "70 g", "지방": "15 g"},
            "cooking_time": "30분",
            "difficulty": "중"
          }
        ],
        "dinner": [
          {
            "dish_name": "저지방 닭가슴살 구이 정식",
            "category": "dinner",
            "description": "허브 마리네이드한 닭가슴살 구이에 현미밥과 구운 야채를 곁들인 고단백 저녁 세트",
            "ingredients": ["닭가슴살", "현미밥", "로즈마리", "버섯", "애호박", "브로콜리", "올리브 오일", "마늘"],
            "approximate_nutrients": {"칼로리": "480 kcal", "단백질": "35 g", "탄수화물": "45 g", "지방": "16 g"},
            "cooking_time": "35분",
            "difficulty": "중"
          },
          {
            "dish_name": "두부 야채 스테이크 정식",
            "category": "dinner",
            "description": "두부 스테이크와 구운 야채, 귀리밥을 함께 제공하는 식물성 단백질이 풍부한 건강식",
            "ingredients": ["두부", "귀리밥", "파프리카", "양파", "버섯", "아스파라거스", "간장 소스", "견과류 토핑"],
            "approximate_nutrients": {"칼로리": "430 kcal", "단백질": "25 g", "탄수화물": "40 g", "지방": "20 g"},
            "cooking_time": "40분",
            "difficulty": "중"
          },
          {
            "dish_name": "콩나물 국밥 한상 차림",
            "category": "dinner",
            "description": "소화가 잘되는 콩나물국밥과 계절 나물, 김치를 함께 제공하는 가벼운 저녁 한식 세트",
            "ingredients": ["쌀밥", "콩나물", "파", "마늘", "멸치 육수", "계절 나물", "김치", "참기름"],
            "approximate_nutrients": {"칼로리": "380 kcal", "단백질": "15 g", "탄수화물": "60 g", "지방": "8 g"},
            "cooking_time": "25분",
            "difficulty": "하"
          }
        ],
        "snacks": [
          {
            "dish_name": "계절 과일 믹스",
            "category": "snack", 
            "description": "다양한 비타민과 섬유질을 제공하는 신선한 계절 과일 모둠",
            "ingredients": ["사과", "바나나", "오렌지", "키위", "딸기"],
            "approximate_nutrients": {"칼로리": "150 kcal", "단백질": "2 g", "탄수화물": "35 g", "지방": "1 g"},
            "cooking_time": "5분",
            "difficulty": "하"
          },
          {
            "dish_name": "고단백 견과류 믹스",
            "category": "snack",
            "description": "건강한 지방과 단백질이 풍부한 다양한 견과류와 건과일 조합",
            "ingredients": ["아몬드", "호두", "해바라기씨", "건포도", "건블루베리"],
            "approximate_nutrients": {"칼로리": "200 kcal", "단백질": "8 g", "탄수화물": "15 g", "지방": "15 g"},
            "cooking_time": "0분",
            "difficulty": "하"
          },
          {
            "dish_name": "베리 그릭 요거트 파르페",
            "category": "snack",
            "description": "단백질이 풍부한 그릭 요거트에 다양한 베리와 견과류를 층층이 쌓은 영양 간식",
            "ingredients": ["그릭 요거트", "블루베리", "라즈베리", "꿀", "호두", "아몬드"],
            "approximate_nutrients": {"칼로리": "220 kcal", "단백질": "15 g", "탄수화물": "20 g", "지방": "10 g"},
            "cooking_time": "10분",
            "difficulty": "하"
          }
        ]
      };
    } catch (e) {
      print("기본 메뉴 생성 중 오류: $e");
      return null;
    }
  }

  // 특정 카테고리의 기본 메뉴 항목 생성
  List<Map<String, dynamic>> _createFallbackMenuItems(String category) {
    final fallbackData = _createFallbackMenuResponse()!;
    return List<Map<String, dynamic>>.from(fallbackData[category]);
  }

  // 메뉴 생성 메서드 - 캐싱 및 최적화 적용
  Future<Map<String, dynamic>?> generateMenu({
    required Map<String, dynamic> userRecommendedNutrients,
    required String summarizedDislikes,
    required String summarizedPreferences,
    bool useCache = true, // 캐시 사용 여부
    Duration? timeout, // 타임아웃 설정
    Map<String, dynamic>? previousMenu, // 이전 메뉴 (재생성용)
    Map<String, String>? verificationFeedback, // 검증 피드백 (재생성용)
    UserData? userData, // 사용자 데이터 추가
  }) async {
    // 재생성 모드일 경우 캐시를 사용하지 않음
    if (previousMenu != null && verificationFeedback != null) {
      useCache = false;
    }
    
    // 캐시 키 생성
    final cacheKey = _generateMenuCacheKey(
      userRecommendedNutrients, 
      summarizedDislikes, 
      summarizedPreferences
    );
    
    // 캐시 사용 설정이면서 캐시에 데이터가 있는 경우 캐시 데이터 반환
    if (useCache) {
      final cachedMenu = await _loadMenuFromCache(cacheKey);
      if (cachedMenu != null) {
        return cachedMenu;
      }
    }
    
    print("🔄 Vertex AI에 메뉴 생성 요청 시작...");
    final startTime = DateTime.now();
    
    // 기본 시스템 지시문 개선 - JSON 형식 유효성에 대한 강조
    const baseSystemInstruction = '''
    당신은 사용자에게 개인 맞춤형 음식과 식단을 추천하는 영양학 및 식이 전문가입니다.
    반드시 유효한 JSON 형식으로만 응답하세요.
    JSON 구문 오류가 발생하지 않도록 각별히 주의하세요.
    모든 문자열은 큰따옴표(")로 감싸야 하며, 작은따옴표(')는 사용하지 마세요.
    객체와 배열의 마지막 항목 뒤에는 쉼표(,)를 넣지 마세요.
    모든 JSON 속성명은 영어 snake_case로 작성하세요(예: dish_name, cooking_time).
    코드 블록(```) 또는 설명 없이 순수한 JSON만 반환하세요.
    JSON 외에 어떤 텍스트도 포함하지 마세요.
    ''';
    
    // 재생성 모드일 경우 추가 지시문
    final systemInstruction = previousMenu != null && verificationFeedback != null
        ? baseSystemInstruction + '''
    주의: 이 요청은 이전에 생성된 메뉴를 수정하는 요청입니다.
    검증에서 통과한 항목(verificationFeedback에 포함되지 않은 항목)은 그대로 유지하고, 
    검증에 실패한 항목(verificationFeedback에 포함된 항목)만 새로운 메뉴로 대체하세요.
    '''
        : baseSystemInstruction;

    // 기본 프롬프트
    String prompt = '''
    다음 정보를 바탕으로 하루 식단(아침, 점심, 저녁, 간식)을 생성해주세요.
    
    1) 사용자 권장 영양소: 
    ${json.encode(userRecommendedNutrients)}
    
    2) 사용자 기피 정보: 
    $summarizedDislikes
    
    3) 사용자 선호 정보: 
    $summarizedPreferences
    ''';
    
    // 사용자 정보가 있는 경우 추가
    if (userData != null) {
      prompt += '''
      
    4) 사용자 상세 정보:
      - 나이: ${userData.age ?? '정보 없음'}
      - 성별: ${userData.gender ?? '정보 없음'}
      - 키: ${userData.height != null ? '${userData.height}cm' : '정보 없음'}
      - 체중: ${userData.weight != null ? '${userData.weight}kg' : '정보 없음'}
      - 활동량: ${userData.activityLevel ?? '보통'}
      - 선호 음식: ${userData.favoriteFoods.isNotEmpty ? userData.favoriteFoods.join(', ') : '특별한 선호 없음'}
      - 기피 음식: ${userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : '특별한 기피 없음'}
      - 선호 조리법: ${userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : '특별한 선호 없음'}
      - 가능한 조리도구: ${userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : '기본 조리도구'}
      - 알레르기: ${userData.allergies.isNotEmpty ? userData.allergies.join(', ') : '없음'}
      - 비건 여부: ${userData.isVegan ? '예' : '아니오'}
      - 종교적 제한: ${userData.isReligious ? (userData.religionDetails ?? '있음') : '없음'}
      - 식사 목적: ${userData.mealPurpose.isNotEmpty ? userData.mealPurpose.join(', ') : '일반적인 식사'}
      - 예산: ${userData.mealBudget != null ? '${userData.mealBudget}원' : '정보 없음'}
      - 선호하는 조리 시간: ${userData.preferredCookingTime != null ? '${userData.preferredCookingTime}분 이내' : '제한 없음'}
      - 선호 식재료: ${userData.preferredIngredients.isNotEmpty ? userData.preferredIngredients.join(', ') : '특별한 선호 없음'}
      - 선호 양념: ${userData.preferredSeasonings.isNotEmpty ? userData.preferredSeasonings.join(', ') : '특별한 선호 없음'}
      - 선호 조리 스타일: ${userData.preferredCookingStyles.isNotEmpty ? userData.preferredCookingStyles.join(', ') : '특별한 선호 없음'}
      - 기피 식재료: ${userData.dislikedIngredients.isNotEmpty ? userData.dislikedIngredients.join(', ') : '특별한 기피 없음'}
      - 기피 양념: ${userData.dislikedSeasonings.isNotEmpty ? userData.dislikedSeasonings.join(', ') : '특별한 기피 없음'}
      - 기피 조리 스타일: ${userData.dislikedCookingStyles.isNotEmpty ? userData.dislikedCookingStyles.join(', ') : '특별한 기피 없음'}
      
    사용자의 상세 정보를 적극 활용하여 맞춤형 식단을 생성해주세요. 특히 선호/기피 재료와 조리법, 예산, 조리 시간 등을 고려하는 것이 중요합니다.
    ''';
    }
    
    // 재생성 모드일 경우 추가 정보
    if (previousMenu != null && verificationFeedback != null) {
      prompt += '''
      
    ${userData != null ? '5' : '4'}) 이전에 생성된 메뉴:
    ${json.encode(previousMenu)}
    
    ${userData != null ? '6' : '5'}) 검증 피드백 (재생성이 필요한 항목):
    ${json.encode(verificationFeedback)}
      
    이전 메뉴에서 검증 피드백에 포함된 항목만 새로운 메뉴로 대체하고, 나머지는 그대로 유지하세요.
    ''';
    }
    
    // 공통 출력 형식 지시 - 더 명확하고 구체적인 JSON 형식 명시
    prompt += '''
    
    식단은 다음과 같은 방식으로 생성해주세요:
    - 각 식사 카테고리(아침, 점심, 저녁, 간식)별로 정확히 2개의 메뉴만 생성하세요.
    - 각 메뉴는 완전한 한 끼 식사를 의미합니다 (주요리와 필요한 반찬이 포함된 형태).
    - 건강에 좋고 균형 잡힌 식단을 구성하세요.
    - 한국 음식 문화와 계절 식재료를 고려하세요.
    - 가능한 한 한국어 메뉴명을 사용하세요.
    
    중요 JSON 작성 지침:
    1. 모든 문자열은 큰따옴표(")로 감싸야 합니다. 작은따옴표(')는 사용하지 마세요.
    2. 객체와 배열의 마지막 항목 뒤에는 쉼표(,)를 넣지 마세요.
    3. 각 필드에 적절한 데이터 타입을 사용하세요:
       - dish_name: 문자열 (예: "비빔밥")
       - category: 문자열 (예: "breakfast", "lunch", "dinner", "snack")
       - description: 문자열 (예: "신선한 야채와 함께...")
       - ingredients: 문자열 배열 (예: ["쌀", "야채", "고추장"])
       - approximate_nutrients: 객체 (예: {"칼로리": "500 kcal", "단백질": "20g"})
       - cooking_time: 문자열 (예: "30분")
       - difficulty: 문자열 (예: "중")
    4. JSON 내 모든 값에 유효한 문자열만 사용하세요. 따옴표, 백슬래시 등 특수문자는 이스케이프 처리하세요.
    5. 긴 문자열은 중간에 줄바꿈 없이 한 줄로 작성하세요.
    
    다음 JSON 형식을 정확히 따라 응답해주세요:
    {
      "breakfast": [
        {
          "dish_name": "메뉴명1",
          "category": "breakfast",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        },
        {
          "dish_name": "메뉴명2",
          "category": "breakfast",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        }
      ],
      "lunch": [
        {
          "dish_name": "메뉴명1",
          "category": "lunch",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        },
        {
          "dish_name": "메뉴명2",
          "category": "lunch",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        }
      ],
      "dinner": [
        {
          "dish_name": "메뉴명1",
          "category": "dinner",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        },
        {
          "dish_name": "메뉴명2",
          "category": "dinner",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        }
      ],
      "snacks": [
        {
          "dish_name": "메뉴명1",
          "category": "snack",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        },
        {
          "dish_name": "메뉴명2",
          "category": "snack",
          "description": "간단한 설명",
          "ingredients": ["재료1", "재료2", "재료3"],
          "approximate_nutrients": {"칼로리": "XXX kcal", "단백질": "XX g", "탄수화물": "XX g", "지방": "XX g"},
          "cooking_time": "XX분",
          "difficulty": "중"
        }
      ]
    }
    
    주의사항:
    1. 각 카테고리별로 정확히 2개의 메뉴만 생성하세요. 3개 이상 생성하지 마세요.
    2. 모든 필수 필드를 빠짐없이 포함하세요.
    3. 위에 주어진 정확한 JSON 구조를 따르세요.
    4. 설명이나 추가 텍스트 없이 JSON 객체만 응답하세요.
    5. 특수문자, 줄바꿈, 따옴표 등으로 인한 JSON 파싱 오류가 발생하지 않도록 주의하세요.
    ''';
    
    try {
      // 타임아웃 적용된 API 호출 (최대 3회 재시도)
      Map<String, dynamic>? result;
      final effectiveTimeout = timeout ?? _defaultTimeout;
      int attempts = 0;
      final maxAttempts = 3;
      
      while (attempts < maxAttempts && result == null) {
        attempts++;
        print("🔄 메뉴 생성 시도 #$attempts");
        
        try {
          result = await _callGenerativeModelWithTimeout(
            systemInstruction, 
            prompt,
            timeout: Duration(seconds: effectiveTimeout.inSeconds + (attempts * 5)), // 재시도마다 타임아웃 증가
            modelNameOverride: _modelName, // 모델명 그대로 사용
          );
          
          // JSON 유효성 검증 (필수 키 확인)
          if (result != null) {
            final requiredKeys = ['breakfast', 'lunch', 'dinner', 'snacks'];
            bool isValidStructure = requiredKeys.every((key) => 
              result!.containsKey(key) && 
              result![key] is List && 
              (result![key] as List).isNotEmpty
            );
            
            if (!isValidStructure) {
              print("⚠️ 생성된 메뉴가 필수 구조를 갖추지 않음, 재시도");
              result = null; // 결과 무효화하여 재시도
            }
          }
        } catch (e) {
          print("⚠️ API 호출 중 오류: $e, 재시도");
          result = null;
        }
        
        // 결과가 없으면 짧은 대기 후 재시도
        if (result == null && attempts < maxAttempts) {
          print("⏱️ ${attempts}번째 시도 실패, ${1000 * attempts}ms 후 재시도...");
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
        }
      }
      
      if (result != null) {
        // 성공적으로 생성된 메뉴 캐싱 (재생성 모드가 아닌 경우만)
        if (previousMenu == null && verificationFeedback == null) {
          await _saveMenuToCache(cacheKey, result);
        }
        
        final endTime = DateTime.now();
        final elapsedTime = endTime.difference(startTime);
        print("✅ 메뉴 생성 완료 (소요시간: ${elapsedTime.inSeconds}초, 시도 횟수: $attempts)");
        
        return result;
      } else {
        print("❌ 메뉴 생성 실패 (최대 시도 횟수 초과: $maxAttempts)");
        return _createFallbackMenuResponse();
      }
    } catch (e) {
      print("❌ 메뉴 생성 중 오류: $e");
      return _createFallbackMenuResponse();
    }
  }

  // *** 새로운 메소드: 단일 음식명에 대한 상세 레시피 생성 ***
  Future<Recipe?> getSingleRecipeDetails({
    required String mealName,
    required UserData userData, // 사용자 정보를 받아 개인화된 레시피 생성
  }) async {
    const systemInstructionText =
        'You are a culinary expert. Your task is to provide a detailed recipe for a given dish name, considering user preferences and restrictions. The recipe should include a dish name, cost information, nutritional information, ingredients with quantities, seasonings with quantities, and step-by-step cooking instructions.';

    // 사용자 정보를 프롬프트에 활용
    final userPrompt = '''
Generate a detailed recipe for the following dish: "$mealName".

Please consider these user details for personalization:
* Allergies: ${userData.allergies.isNotEmpty ? userData.allergies.join(', ') : '없음'}
* Disliked Ingredients: ${userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : '없음'}
* Preferred Cooking Methods: ${userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : '제한 없음'}
* Available Cooking Tools: ${userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : '제한 없음'}
* Is Vegan: ${userData.isVegan ? '예' : '아니오'}
* Religious Dietary Restrictions: ${userData.isReligious ? (userData.religionDetails ?? '있음 (상세 정보 없음)') : '없음'}

The recipe should include the following details in JSON format:
* **dish_name:** The name of the dish (should be "$mealName").
* **cost_information:** An estimated cost to prepare the dish.
* **nutritional_information:** A breakdown of the dish's nutritional content (calories, protein, carbohydrates, fats as strings, and optionally vitamins, minerals as lists of strings).
* **ingredients:** A list of objects, each with "name" (string) and "quantity" (string).
* **seasonings:** A list of objects, each with "name" (string) and "quantity" (string).
* **cooking_instructions:** A list of strings, where each string is a step.
* **cookingTimeMinutes:** (Optional) Estimated cooking time in minutes (integer).
* **difficulty:** (Optional) Difficulty level (e.g., "쉬움", "보통", "어려움").

Example JSON output for a single recipe:
{
  "dish_name": "$mealName",
  "cost_information": "Approximately 5 dollar",
  "nutritional_information": {
    "calories": "350",
    "protein": "30g",
    "carbohydrates": "15g",
    "fats": "18g"
  },
  "ingredients": [
    {"name": "Main Ingredient for $mealName", "quantity": "1 serving"}
  ],
  "seasonings": [
    {"name": "Basic Seasoning", "quantity": "to taste"}
  ],
  "cooking_instructions": [
    "Step 1 for $mealName.",
    "Step 2 for $mealName."
  ],
  "cookingTimeMinutes": 25,
  "difficulty": "보통"
}

Ensure the output is a single JSON object representing this one recipe.
''';
    final Map<String, dynamic>? jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse != null) {
      try {
        // Recipe.fromJson이 이 JSON 구조를 파싱할 수 있도록 Recipe 모델 확인/수정 필요
        return Recipe.fromJson(jsonResponse);
      } catch (e) {
        print("단일 레시피 JSON 파싱 오류: $e. 원본 JSON: $jsonResponse");
        return null;
      }
    }
    return null;
  }

  Future<List<SimpleMenu>> generateMealCandidates({required String mealType, int count = 3}) async {
    const systemInstructionText =
        'You are a nutrition expert and menu planner. Your task is to generate meal candidates for a specific meal type. Each candidate should include dish_name, category, description, calories, and ingredients (as a list of strings).';

    final userPrompt = '''
Generate $count candidate dishes for "$mealType".
Each candidate should include:
- dish_name (string)
- category (string, e.g., breakfast, lunch, dinner, snack)
- description (string, 1-2 sentences)
- calories (string)
- ingredients (list of strings)
- meal_type (string, must be: "$mealType")

IMPORTANT: Make sure the response is valid JSON in an array format.

Output format (JSON array):
[
  {
    "dish_name": "Example Dish Name",
    "category": "$mealType",
    "description": "Brief description here",
    "calories": "Approximate calories",
    "ingredients": ["Ingredient 1", "Ingredient 2"],
    "meal_type": "$mealType"
  }
]
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse == null) {
      print("메뉴 후보 생성 실패, 기본 메뉴 반환");
      return _getDefaultCandidates(mealType, count);
    }

    try {
      List<dynamic> menuList;
      
      // JSON 응답이 List인 경우 직접 사용
      if (jsonResponse is List) {
        menuList = jsonResponse;
      } 
      // JSON 응답이 Map인 경우 candidates 또는 results 키에서 List 추출
      else if (jsonResponse is Map) {
        final candidates = jsonResponse['candidates'];
        final results = jsonResponse['results'];
        
        if (candidates is List) {
          menuList = candidates;
        } else if (results is List) {
          menuList = results;
        } else {
          // Map의 값들을 List로 변환
          print("예상치 못한 응답 구조, 기본 메뉴 반환");
          return _getDefaultCandidates(mealType, count);
        }
      } else {
        print("예상치 못한 JSON 응답 형식: $jsonResponse");
        return _getDefaultCandidates(mealType, count);
      }

      // List를 SimpleMenu 객체 리스트로 변환
      final List<SimpleMenu> results = [];
      
      for (var item in menuList) {
        try {
          if (item is Map<String, dynamic>) {
            // 필수 필드 확인 및 보완
            if (!item.containsKey('meal_type') && !item.containsKey('mealType')) {
              item['meal_type'] = mealType;
            }
            
            if (!item.containsKey('category') || item['category'] == null || 
                item['category'].toString().isEmpty) {
              item['category'] = mealType;
            }
            
            if (!item.containsKey('dish_name') || item['dish_name'] == null || 
                item['dish_name'].toString().isEmpty) {
              item['dish_name'] = "메뉴 ${results.length + 1}";
            }
            
            if (!item.containsKey('description') || item['description'] == null || 
                item['description'].toString().isEmpty) {
              item['description'] = "${item['dish_name']} 메뉴입니다.";
            }
            
            final menu = SimpleMenu.fromJson(item);
            results.add(menu);
          } else {
            print("잘못된 메뉴 항목 형식: $item");
          }
        } catch (e) {
          print("메뉴 항목 파싱 오류: $e");
        }
      }
      
      if (results.isEmpty) {
        print("메뉴 후보 생성 결과가 없어 기본 메뉴 반환");
        return _getDefaultCandidates(mealType, count);
      }
      
      return results;
    } catch (e) {
      print("메뉴 후보 JSON 파싱 오류: $e. 원본 JSON: $jsonResponse");
      return _getDefaultCandidates(mealType, count);
    }
  }
  
  List<SimpleMenu> _getDefaultCandidates(String mealType, int count) {
    List<SimpleMenu> defaults = [];
    
    switch (mealType) {
      case 'breakfast':
        defaults = [
          SimpleMenu(
            dishName: "영양 오트밀 죽 세트",
            category: "breakfast",
            description: "간단하고 영양가 높은 아침 식사로, 부드러운 오트밀에 견과류와 계절 과일을 곁들임",
            mealType: "breakfast",
            calories: "약 350kcal",
            ingredients: ["오트밀", "우유", "꿀", "아몬드", "블루베리", "바나나"]
          ),
          SimpleMenu(
            dishName: "채소 계란 토스트 플레이트",
            category: "breakfast",
            description: "통밀빵에 계란 프라이와 아보카도, 신선한 채소를 곁들인 단백질이 풍부한 아침 메뉴",
            mealType: "breakfast",
            calories: "약 420kcal",
            ingredients: ["통밀빵", "계란", "아보카도", "시금치", "방울토마토", "올리브 오일"]
          ),
          SimpleMenu(
            dishName: "그릭요거트 과일 그래놀라 볼",
            category: "breakfast",
            description: "단백질이 풍부한 그릭요거트에 다양한 베리류와 홈메이드 그래놀라를 곁들인 건강식",
            mealType: "breakfast",
            calories: "약 380kcal",
            ingredients: ["그릭요거트", "그래놀라", "블루베리", "딸기", "꿀", "치아씨드"]
          ),
        ];
        break;
      case 'lunch':
        defaults = [
          SimpleMenu(
            dishName: "계절 야채 비빔밥 세트",
            category: "lunch",
            description: "오곡밥 위에 다양한 계절 야채와 소고기, 계란 프라이를 올려 고추장과 함께 비벼 먹는 한식 정식",
            mealType: "lunch",
            calories: "약 550kcal",
            ingredients: ["오곡밥", "소고기", "당근", "시금치", "버섯", "계란", "고추장", "참기름"]
          ),
          SimpleMenu(
            dishName: "그린 샐러드와 통밀 치아바타 세트",
            category: "lunch",
            description: "다양한 신선한 채소와 견과류, 치즈가 들어간 샐러드에 통밀 치아바타 빵을 곁들인 가벼운 점심",
            mealType: "lunch",
            calories: "약 450kcal",
            ingredients: ["양상추", "베이비 시금치", "토마토", "오이", "아보카도", "호두", "페타 치즈", "통밀 치아바타", "발사믹 드레싱"]
          ),
          SimpleMenu(
            dishName: "고단백 참치 김밥 도시락",
            category: "lunch",
            description: "참치와 채소, 계란을 듬뿍 넣은 든든한 김밥과 미니 과일 세트로 구성된 균형 잡힌 한 끼",
            mealType: "lunch",
            calories: "약 520kcal",
            ingredients: ["밥", "김", "참치", "당근", "오이", "시금치", "계란", "사과", "귤"]
          ),
        ];
        break;
      case 'dinner':
        defaults = [
          SimpleMenu(
            dishName: "저지방 닭가슴살 구이 정식",
            category: "dinner",
            description: "허브 마리네이드한 닭가슴살 구이에 현미밥과 구운 야채를 곁들인 고단백 저녁 세트",
            mealType: "dinner",
            calories: "약 480kcal",
            ingredients: ["닭가슴살", "현미밥", "로즈마리", "버섯", "애호박", "브로콜리", "올리브 오일", "마늘"]
          ),
          SimpleMenu(
            dishName: "두부 야채 스테이크 정식",
            category: "dinner",
            description: "두부 스테이크와 구운 야채, 귀리밥을 함께 제공하는 식물성 단백질이 풍부한 건강식",
            mealType: "dinner",
            calories: "약 430kcal",
            ingredients: ["두부", "귀리밥", "파프리카", "양파", "버섯", "아스파라거스", "간장 소스", "견과류 토핑"]
          ),
          SimpleMenu(
            dishName: "콩나물 국밥 한상 차림",
            category: "dinner",
            description: "소화가 잘되는 콩나물국밥과 계절 나물, 김치를 함께 제공하는 가벼운 저녁 한식 세트",
            mealType: "dinner",
            calories: "약 380kcal",
            ingredients: ["쌀밥", "콩나물", "파", "마늘", "멸치 육수", "계절 나물", "김치", "참기름"]
          ),
        ];
        break;
      case 'snack':
        defaults = [
          SimpleMenu(
            dishName: "계절 과일 믹스",
            category: "snack",
            description: "다양한 비타민과 섬유질을 제공하는 신선한 계절 과일 모둠",
            mealType: "snack",
            calories: "약 150kcal",
            ingredients: ["사과", "바나나", "오렌지", "키위", "딸기"]
          ),
          SimpleMenu(
            dishName: "고단백 견과류 믹스",
            category: "snack",
            description: "건강한 지방과 단백질이 풍부한 다양한 견과류와 건과일 조합",
            mealType: "snack",
            calories: "약 200kcal",
            ingredients: ["아몬드", "호두", "해바라기씨", "건포도", "건블루베리"]
          ),
          SimpleMenu(
            dishName: "베리 그릭 요거트 파르페",
            category: "snack",
            description: "단백질이 풍부한 그릭 요거트에 다양한 베리와 견과류를 층층이 쌓은 영양 간식",
            mealType: "snack",
            calories: "약 220kcal",
            ingredients: ["그릭 요거트", "블루베리", "라즈베리", "꿀", "호두", "아몬드"]
          ),
        ];
        break;
      default:
        defaults = [
          SimpleMenu(
            dishName: "계절 과일 믹스",
            category: "snack",
            description: "다양한 비타민과 섬유질을 제공하는 신선한 계절 과일 모둠",
            mealType: "snack",
            calories: "약 150kcal",
            ingredients: ["사과", "바나나", "오렌지", "키위", "딸기"]
          ),
          SimpleMenu(
            dishName: "고단백 견과류 믹스",
            category: "snack",
            description: "건강한 지방과 단백질이 풍부한 다양한 견과류와 건과일 조합",
            mealType: "snack",
            calories: "약 200kcal",
            ingredients: ["아몬드", "호두", "해바라기씨", "건포도", "건블루베리"]
          ),
          SimpleMenu(
            dishName: "베리 그릭 요거트 파르페",
            category: "snack",
            description: "단백질이 풍부한 그릭 요거트에 다양한 베리와 견과류를 층층이 쌓은 영양 간식",
            mealType: "snack",
            calories: "약 220kcal",
            ingredients: ["그릭 요거트", "블루베리", "라즈베리", "꿀", "호두", "아몬드"]
          ),
        ];
    }
    
    // 요청된 수만큼 반환
    return defaults.take(count).toList();
  }
}

