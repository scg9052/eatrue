// services/menu_generation_service.dart
import 'dart:convert';
import 'dart:async'; // 타임아웃 설정용
import 'dart:math'; // min 함수 사용을 위해 추가
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/recipe.dart'; // Recipe 모델 import
import '../models/user_data.dart'; // UserData 모델 import
import 'package:shared_preferences/shared_preferences.dart'; // 캐싱용
import '../models/simple_menu.dart';
import '../providers/language_provider.dart'; // 언어 설정 provider 추가
import '../services/template_service.dart'; // 템플릿 서비스 추가

class MenuGenerationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17'; // 기존 모델로 복구
  final LanguageProvider? languageProvider; // 언어 Provider 추가
  final TemplateService _templateService = TemplateService(); // 템플릿 서비스 인스턴스
  
  // 메뉴 응답 캐싱용 변수
  Map<String, dynamic>? _cachedMenuResponse;
  DateTime? _lastMenuGenerationTime;
  String? _lastMenuGenerationKey;

  // 타임아웃 설정
  final Duration _defaultTimeout = Duration(seconds: 30);

  MenuGenerationService({
    FirebaseVertexAI? vertexAI,
    this.languageProvider, // 생성자에서 LanguageProvider 받기
  }) : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1') {
    // 언어 제공자가 있는 경우, 템플릿 서비스에 현재 언어 코드 설정
    if (languageProvider != null) {
      _templateService.setLanguageCode(languageProvider!.getLanguageCode());
    }
  }

  // 언어 변경시 호출되는 메서드
  void clearCacheOnLanguageChange() {
    print("언어 변경에 따른 메뉴 캐시 초기화");
    _cachedMenuResponse = null;
    _lastMenuGenerationTime = null;
    _lastMenuGenerationKey = null;
    
    // 템플릿 서비스에 현재 언어 코드 업데이트
    if (languageProvider != null) {
      _templateService.setLanguageCode(languageProvider!.getLanguageCode());
    }
  }

  GenerationConfig _getBaseGenerationConfig({String? responseMimeType}) {
    return GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1,
      topP: 0.95,
      responseMimeType: responseMimeType,
    );
  }

  List<SafetySetting> _getSafetySettings() {
    return [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity),
    ];
  }

  // 메뉴 생성을 위한 캐시 키 생성
  String _generateMenuCacheKey(Map<String, dynamic> nutrients, String dislikes, String preferences) {
    // 현재 언어 코드를 캐시 키에 포함
    final langKey = languageProvider?.getLanguageCode() ?? 'ko';
    
    print("메뉴 캐시 키 생성 - 사용 언어: $langKey");
    
    // 간단한 해시 생성
    final hash = '${nutrients.hashCode}_${dislikes.hashCode}_${preferences.hashCode}_$langKey';
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

      // 응답 디버깅 정보 로깅 (개선된 부분)
      final int textLength = response.text!.length;
      print("응답 텍스트 길이: ${textLength}자");
      final previewLength = min(100, textLength);
      final String previewText = response.text!.substring(0, previewLength);
      print("응답 미리보기: $previewText...");
      
      // 비동기 작업으로 JSON 파싱 처리
      return await _processJsonResponse(response.text!);
    } catch (e) {
      print("❌ API 호출 중 오류: $e");
      return null;
    }
  }

  // JSON 응답 처리를 별도 함수로 분리 (비동기 처리)
  Future<dynamic> _processJsonResponse(String responseText) async {
    try {
      // 백틱과 JSON 표시 제거
      String jsonString = responseText.trim();
      
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
          .replaceAll("'", "\"")
          .replaceAll(",\n}", "\n}")
          .replaceAll(",\n]", "\n]")
          .replaceAll("},\n  ]", "}\n  ]")
          .replaceAll(",,", ",")
          .replaceAll(",}", "}")
          .replaceAll(",]", "]")
          .replaceAll("\\\"", "\"")
          .replaceAll("\\n", " ");
          
      // 속성명에 따옴표 추가
      jsonString = _addQuotesToPropertyNames(jsonString);
      
      // 짧은 미리보기만 로깅
      final previewLength = min(100, jsonString.length);
      print("JSON 파싱 시도 전 처리된 문자열: ${jsonString.substring(0, previewLength)}...");
      
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
        
        // 추가 처리 없이 원본 Map 반환
        return decoded;
      }
      
      return null;
    } catch (e) {
      print("❌ JSON 파싱 실패: $e");
      return null;
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
      // 언어 설정 확인 - 기본값은 한국어로 설정
      final bool isKorean = languageProvider?.isKorean() ?? true;
      
      if (isKorean) {
        // 한국어 기본 메뉴
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
      } else {
        // 영어 기본 메뉴
        return {
          "breakfast": [
            {
              "dish_name": "Nutritious Oatmeal Porridge Set",
              "category": "breakfast",
              "description": "A simple, nutritious breakfast with creamy oatmeal topped with nuts and seasonal fruits",
              "ingredients": ["Oatmeal", "Milk", "Honey", "Almonds", "Blueberries", "Banana"],
              "approximate_nutrients": {"calories": "350 kcal", "protein": "12 g", "carbohydrates": "45 g", "fats": "13 g"},
              "cooking_time": "15 minutes",
              "difficulty": "easy"
            },
            {
              "dish_name": "Vegetable Egg Toast Plate",
              "category": "breakfast",
              "description": "Whole wheat bread with fried eggs, avocado, and fresh vegetables for a protein-rich breakfast",
              "ingredients": ["Whole wheat bread", "Eggs", "Avocado", "Spinach", "Cherry tomatoes", "Olive oil"],
              "approximate_nutrients": {"calories": "420 kcal", "protein": "18 g", "carbohydrates": "35 g", "fats": "25 g"},
              "cooking_time": "20 minutes",
              "difficulty": "medium"
            },
            {
              "dish_name": "Greek Yogurt Fruit Granola Bowl",
              "category": "breakfast",
              "description": "Protein-rich Greek yogurt with various berries and homemade granola for a healthy breakfast",
              "ingredients": ["Greek yogurt", "Granola", "Blueberries", "Strawberries", "Honey", "Chia seeds"],
              "approximate_nutrients": {"calories": "380 kcal", "protein": "15 g", "carbohydrates": "40 g", "fats": "18 g"},
              "cooking_time": "10 minutes",
              "difficulty": "easy"
            }
          ],
          "lunch": [
            {
              "dish_name": "Seasonal Vegetable Bibimbap Set",
              "category": "lunch",
              "description": "A Korean dish with multigrain rice topped with various seasonal vegetables, beef, fried egg, and mixed with gochujang",
              "ingredients": ["Multigrain rice", "Beef", "Carrots", "Spinach", "Mushrooms", "Egg", "Gochujang", "Sesame oil"],
              "approximate_nutrients": {"calories": "550 kcal", "protein": "25 g", "carbohydrates": "65 g", "fats": "20 g"},
              "cooking_time": "35 minutes",
              "difficulty": "medium"
            },
            {
              "dish_name": "Green Salad with Whole Wheat Ciabatta Set",
              "category": "lunch",
              "description": "Fresh vegetables with nuts and cheese in a salad, served with whole wheat ciabatta bread for a light lunch",
              "ingredients": ["Lettuce", "Baby spinach", "Tomatoes", "Cucumber", "Avocado", "Walnuts", "Feta cheese", "Whole wheat ciabatta", "Balsamic dressing"],
              "approximate_nutrients": {"calories": "450 kcal", "protein": "15 g", "carbohydrates": "40 g", "fats": "25 g"},
              "cooking_time": "20 minutes",
              "difficulty": "easy"
            },
            {
              "dish_name": "High-Protein Tuna Kimbap Lunchbox",
              "category": "lunch",
              "description": "A balanced meal with tuna, vegetables, and eggs in seaweed-wrapped rice rolls, served with mini fruit assortment",
              "ingredients": ["Rice", "Seaweed", "Tuna", "Carrots", "Cucumber", "Spinach", "Eggs", "Apple", "Tangerine"],
              "approximate_nutrients": {"calories": "520 kcal", "protein": "22 g", "carbohydrates": "70 g", "fats": "15 g"},
              "cooking_time": "30 minutes",
              "difficulty": "medium"
            }
          ],
          "dinner": [
            {
              "dish_name": "Low-Fat Chicken Breast Grill Set",
              "category": "dinner",
              "description": "Herb-marinated grilled chicken breast with brown rice and roasted vegetables for a high-protein dinner",
              "ingredients": ["Chicken breast", "Brown rice", "Rosemary", "Mushrooms", "Zucchini", "Broccoli", "Olive oil", "Garlic"],
              "approximate_nutrients": {"calories": "480 kcal", "protein": "35 g", "carbohydrates": "45 g", "fats": "16 g"},
              "cooking_time": "35 minutes",
              "difficulty": "medium"
            },
            {
              "dish_name": "Tofu Vegetable Steak Set",
              "category": "dinner",
              "description": "Tofu steak with roasted vegetables and oat rice, rich in plant-based protein",
              "ingredients": ["Tofu", "Oat rice", "Bell peppers", "Onions", "Mushrooms", "Asparagus", "Soy sauce", "Nut topping"],
              "approximate_nutrients": {"calories": "430 kcal", "protein": "25 g", "carbohydrates": "40 g", "fats": "20 g"},
              "cooking_time": "40 minutes",
              "difficulty": "medium"
            },
            {
              "dish_name": "Bean Sprout Soup Rice Bowl Set",
              "category": "dinner",
              "description": "Easy-to-digest bean sprout soup with rice, seasonal greens and kimchi for a light Korean dinner set",
              "ingredients": ["Rice", "Bean sprouts", "Green onions", "Garlic", "Anchovy broth", "Seasonal greens", "Kimchi", "Sesame oil"],
              "approximate_nutrients": {"calories": "380 kcal", "protein": "15 g", "carbohydrates": "60 g", "fats": "8 g"},
              "cooking_time": "25 minutes",
              "difficulty": "easy"
            }
          ],
          "snacks": [
            {
              "dish_name": "Seasonal Fruit Mix",
              "category": "snack", 
              "description": "Fresh seasonal fruit assortment providing various vitamins and fiber",
              "ingredients": ["Apple", "Banana", "Orange", "Kiwi", "Strawberries"],
              "approximate_nutrients": {"calories": "150 kcal", "protein": "2 g", "carbohydrates": "35 g", "fats": "1 g"},
              "cooking_time": "5 minutes",
              "difficulty": "easy"
            },
            {
              "dish_name": "High-Protein Nut Mix",
              "category": "snack",
              "description": "Assortment of nuts and dried fruits rich in healthy fats and protein",
              "ingredients": ["Almonds", "Walnuts", "Sunflower seeds", "Raisins", "Dried blueberries"],
              "approximate_nutrients": {"calories": "200 kcal", "protein": "8 g", "carbohydrates": "15 g", "fats": "15 g"},
              "cooking_time": "0 minutes",
              "difficulty": "easy"
            },
            {
              "dish_name": "Berry Greek Yogurt Parfait",
              "category": "snack",
              "description": "Protein-rich Greek yogurt layered with various berries and nuts for a nutritious snack",
              "ingredients": ["Greek yogurt", "Blueberries", "Raspberries", "Honey", "Walnuts", "Almonds"],
              "approximate_nutrients": {"calories": "220 kcal", "protein": "15 g", "carbohydrates": "20 g", "fats": "10 g"},
              "cooking_time": "10 minutes",
              "difficulty": "easy"
            }
          ]
        };
      }
    } catch (e) {
      print("기본 메뉴 생성 중 오류: $e");
      return null;
    }
  }

  // 특정 카테고리의 기본 메뉴 항목 생성
  List<Map<String, dynamic>> _createFallbackMenuItems(String category) {
    // 언어 설정에 맞게 기본 메뉴 응답 생성
    final fallbackData = _createFallbackMenuResponse()!;
    
    // 카테고리가 존재하는지 확인
    if (fallbackData.containsKey(category)) {
      return List<Map<String, dynamic>>.from(fallbackData[category]);
    } else {
      // 다른 이름의 카테고리인 경우 (snack <-> snacks 등) 비슷한 카테고리 찾기
      if (category == 'snack' && fallbackData.containsKey('snacks')) {
        return List<Map<String, dynamic>>.from(fallbackData['snacks']);
      } else if (category == 'snacks' && fallbackData.containsKey('snack')) {
        return List<Map<String, dynamic>>.from(fallbackData['snack']);
      }
      
      // 기본 간식 메뉴 반환 (모든 예외 상황에 대응)
      final bool isKorean = languageProvider?.isKorean() ?? true;
      
      if (isKorean) {
        return [
          {
            "dish_name": "계절 과일 믹스",
            "category": category,
            "description": "다양한 비타민과 섬유질을 제공하는 신선한 계절 과일 모둠",
            "ingredients": ["사과", "바나나", "오렌지", "키위", "딸기"],
            "approximate_nutrients": {"칼로리": "150 kcal", "단백질": "2 g", "탄수화물": "35 g", "지방": "1 g"},
            "cooking_time": "5분",
            "difficulty": "하"
          }
        ];
      } else {
        return [
          {
            "dish_name": "Seasonal Fruit Mix",
            "category": category,
            "description": "Fresh seasonal fruit assortment providing various vitamins and fiber",
            "ingredients": ["Apple", "Banana", "Orange", "Kiwi", "Strawberries"],
            "approximate_nutrients": {"calories": "150 kcal", "protein": "2 g", "carbohydrates": "35 g", "fats": "1 g"},
            "cooking_time": "5 minutes",
            "difficulty": "easy"
          }
        ];
      }
    }
  }

  // 메뉴 생성 메서드
  Future<Map<String, dynamic>?> generateMenu({
    required Map<String, dynamic> nutrients,
    required String dislikes,
    required String preferences,
    UserData? userData,
    Duration? timeout,
  }) async {
    // 캐시 키 생성
    final cacheKey = _generateMenuCacheKey(nutrients, dislikes, preferences);
    
    // 캐시에서 기존 메뉴 확인
    final cachedMenu = await _loadMenuFromCache(cacheKey);
    if (cachedMenu != null) {
      return cachedMenu;
    }
    
    try {
      // 현재 언어 정보 로깅
      final langCode = languageProvider?.getLanguageCode() ?? 'ko';
      print('메뉴 생성 시작 - 사용 언어: $langCode');
      
      // 템플릿 서비스에서 시스템 지시문 가져오기
      final systemInstruction = _templateService.getMenuSystemInstruction();
      
      // 템플릿 서비스에서 프롬프트 생성
      final prompt = _templateService.generateMenuPrompt(
        nutrients: nutrients,
        dislikes: dislikes,
        preferences: preferences,
        userData: userData,
      );
      
      // 로깅
      print("메뉴 생성 프롬프트 길이: ${prompt.length}자");
      
      // Vertex AI 호출
      final menuResponse = await _callGenerativeModelWithTimeout(
        systemInstruction, 
        prompt,
        timeout: timeout,
      );
      
      if (menuResponse == null) {
        print("❌ 메뉴 생성 실패 - AI 응답이 null입니다");
        return null;
      }
      
      // 캐시에 저장
      await _saveMenuToCache(cacheKey, menuResponse);
      return menuResponse;
    } catch (e) {
      print("❌ 메뉴 생성 중 오류 발생: $e");
      return null;
    }
  }

  // 메뉴 재생성 메서드
  Future<Map<String, dynamic>?> regenerateMenu({
    required Map<String, dynamic> nutrients,
    required String dislikes,
    required String preferences,
    required Map<String, dynamic> previousMenu,
    required Map<String, String> verificationFeedback,
    UserData? userData,
    Duration? timeout,
  }) async {
    try {
      // 현재 언어 정보 로깅
      final langCode = languageProvider?.getLanguageCode() ?? 'ko';
      print('메뉴 재생성 시작 - 사용 언어: $langCode');
      
      // 템플릿 서비스에서 시스템 지시문 가져오기 (재생성 모드)
      final systemInstruction = _templateService.getMenuSystemInstruction(isRegeneration: true);
      
      // 템플릿 서비스에서 프롬프트 생성 (재생성 모드)
      final prompt = _templateService.generateMenuPrompt(
        nutrients: nutrients,
        dislikes: dislikes,
        preferences: preferences,
        userData: userData,
        previousMenu: previousMenu,
        verificationFeedback: verificationFeedback,
      );
      
      // 로깅
      print("메뉴 재생성 프롬프트 길이: ${prompt.length}자");
      
      // Vertex AI 호출
      final menuResponse = await _callGenerativeModelWithTimeout(
        systemInstruction,
        prompt,
        timeout: timeout,
      );
      
      if (menuResponse == null) {
        print("❌ 메뉴 재생성 실패 - AI 응답이 null입니다");
        return null;
      }
      
      // 재생성 결과는 캐시에 저장하지 않음
      return menuResponse;
    } catch (e) {
      print("❌ 메뉴 재생성 중 오류 발생: $e");
      return null;
    }
  }

  // 레시피 생성 메서드
  Future<Recipe?> generateRecipe({
    required String mealName,
    required UserData userData,
    Duration? timeout,
  }) async {
    try {
      // 현재 언어 정보 로깅
      final langCode = languageProvider?.getLanguageCode() ?? 'ko';
      print('레시피 생성 시작 - 사용 언어: $langCode');
      
      // 템플릿 서비스에서 시스템 지시문 가져오기
      final systemInstruction = _templateService.getRecipeSystemInstruction();
      
      // 템플릿 서비스에서 프롬프트 생성
      final prompt = _templateService.generateRecipePrompt(
        mealName: mealName,
        userData: userData,
      );
      
      // 로깅
      print("레시피 생성 프롬프트 길이: ${prompt.length}자");
      
      // Vertex AI 호출
      final recipeResponse = await _callGenerativeModelWithTimeout(
        systemInstruction,
        prompt,
        timeout: timeout,
      );
      
      if (recipeResponse == null) {
        print("❌ 레시피 생성 실패 - AI 응답이 null입니다");
        return null;
      }
      
      // Recipe 객체로 변환
      return Recipe.fromJson(recipeResponse);
    } catch (e) {
      print("❌ 레시피 생성 중 오류 발생: $e");
      return null;
    }
  }

  // 단일 레시피 상세 정보 생성 메서드
  Future<Recipe?> getSingleRecipeDetails({
    required String mealName,
    required UserData userData,
    Duration? timeout,
  }) async {
    // generateRecipe 메서드를 재사용 (동일한 기능이므로)
    return generateRecipe(
      mealName: mealName,
      userData: userData,
      timeout: timeout,
    );
  }

  // 메뉴 후보 생성 메서드
  Future<List<SimpleMenu>?> generateMenuCandidates({
    required String mealType,
    int count = 10,
    Duration? timeout,
  }) async {
    try {
      // 현재 언어 정보 로깅
      final langCode = languageProvider?.getLanguageCode() ?? 'ko';
      print('메뉴 후보 생성 시작 - 사용 언어: $langCode');
      
      // 템플릿 서비스에서 시스템 지시문 가져오기
      final systemInstruction = _templateService.getMenuSystemInstruction();
      
      // 템플릿 서비스에서 프롬프트 생성
      final prompt = _templateService.generateMenuCandidatesPrompt(
        mealType: mealType,
        count: count,
      );
      
      // 로깅
      print("메뉴 후보 생성 프롬프트 길이: ${prompt.length}자");
      
      // Vertex AI 호출
      final candidatesResponse = await _callGenerativeModelWithTimeout(
        systemInstruction,
        prompt,
        timeout: timeout,
      );
      
      if (candidatesResponse == null || !(candidatesResponse is List)) {
        print("❌ 메뉴 후보 생성 실패 - AI 응답이 유효하지 않습니다");
        return null;
      }
      
      // SimpleMenu 객체 리스트로 변환
      final List<SimpleMenu> menuCandidates = [];
      for (var menuJson in candidatesResponse) {
        try {
          final menu = SimpleMenu.fromJson(menuJson);
          menuCandidates.add(menu);
        } catch (e) {
          print("메뉴 후보 파싱 오류: $e");
        }
      }
      
      print("✅ ${menuCandidates.length}개의 메뉴 후보 생성 완료");
      return menuCandidates;
    } catch (e) {
      print("❌ 메뉴 후보 생성 중 오류 발생: $e");
      return null;
    }
  }

  // 카테고리별 기본 메뉴 생성
  List<SimpleMenu> _getDefaultMenuForCategory(String category, [int count = 3]) {
    // 언어 설정 확인 - 기본값은 한국어로 설정
    final bool isKorean = languageProvider?.isKorean() ?? true;
    
    List<SimpleMenu> defaults = [];
    
    if (isKorean) {
      // 한국어 메뉴
      switch (category) {
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
        case 'snacks':
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
              dishName: "과일 믹스",
              category: "snack",
              description: "다양한 비타민과 섬유질을 제공하는 간식",
              mealType: "snack",
              calories: "약 150kcal",
              ingredients: ["사과", "바나나", "오렌지", "키위", "딸기"]
            ),
          ];
      }
    } else {
      // 영어 메뉴
      switch (category) {
        case 'breakfast':
          defaults = [
            SimpleMenu(
              dishName: "Nutritious Oatmeal Porridge Set",
              category: "breakfast",
              description: "A simple, nutritious breakfast with creamy oatmeal topped with nuts and seasonal fruits",
              mealType: "breakfast",
              calories: "about 350kcal",
              ingredients: ["Oatmeal", "Milk", "Honey", "Almonds", "Blueberries", "Banana"]
            ),
            SimpleMenu(
              dishName: "Vegetable Egg Toast Plate",
              category: "breakfast",
              description: "Whole wheat bread with fried eggs, avocado, and fresh vegetables for a protein-rich breakfast",
              mealType: "breakfast",
              calories: "about 420kcal",
              ingredients: ["Whole wheat bread", "Eggs", "Avocado", "Spinach", "Cherry tomatoes", "Olive oil"]
            ),
            SimpleMenu(
              dishName: "Greek Yogurt Fruit Granola Bowl",
              category: "breakfast",
              description: "Protein-rich Greek yogurt with various berries and homemade granola for a healthy breakfast",
              mealType: "breakfast",
              calories: "about 380kcal",
              ingredients: ["Greek yogurt", "Granola", "Blueberries", "Strawberries", "Honey", "Chia seeds"]
            ),
          ];
          break;
        case 'lunch':
          defaults = [
            SimpleMenu(
              dishName: "Seasonal Vegetable Bibimbap Set",
              category: "lunch",
              description: "A Korean dish with multigrain rice topped with various seasonal vegetables, beef, fried egg, and mixed with gochujang",
              mealType: "lunch",
              calories: "about 550kcal",
              ingredients: ["Multigrain rice", "Beef", "Carrots", "Spinach", "Mushrooms", "Egg", "Gochujang", "Sesame oil"]
            ),
            SimpleMenu(
              dishName: "Green Salad with Whole Wheat Ciabatta Set",
              category: "lunch",
              description: "Fresh vegetables with nuts and cheese in a salad, served with whole wheat ciabatta bread for a light lunch",
              mealType: "lunch",
              calories: "about 450kcal",
              ingredients: ["Lettuce", "Baby spinach", "Tomatoes", "Cucumber", "Avocado", "Walnuts", "Feta cheese", "Whole wheat ciabatta", "Balsamic dressing"]
            ),
            SimpleMenu(
              dishName: "High-Protein Tuna Kimbap Lunchbox",
              category: "lunch",
              description: "A balanced meal with tuna, vegetables, and eggs in seaweed-wrapped rice rolls, served with mini fruit assortment",
              mealType: "lunch",
              calories: "about 520kcal",
              ingredients: ["Rice", "Seaweed", "Tuna", "Carrots", "Cucumber", "Spinach", "Eggs", "Apple", "Tangerine"]
            ),
          ];
          break;
        case 'dinner':
          defaults = [
            SimpleMenu(
              dishName: "Low-Fat Chicken Breast Grill Set",
              category: "dinner",
              description: "Herb-marinated grilled chicken breast with brown rice and roasted vegetables for a high-protein dinner",
              mealType: "dinner",
              calories: "about 480kcal",
              ingredients: ["Chicken breast", "Brown rice", "Rosemary", "Mushrooms", "Zucchini", "Broccoli", "Olive oil", "Garlic"]
            ),
            SimpleMenu(
              dishName: "Tofu Vegetable Steak Set",
              category: "dinner",
              description: "Tofu steak with roasted vegetables and oat rice, rich in plant-based protein",
              mealType: "dinner",
              calories: "about 430kcal",
              ingredients: ["Tofu", "Oat rice", "Bell peppers", "Onions", "Mushrooms", "Asparagus", "Soy sauce", "Nut topping"]
            ),
            SimpleMenu(
              dishName: "Bean Sprout Soup Rice Bowl Set",
              category: "dinner",
              description: "Easy-to-digest bean sprout soup with rice, seasonal greens and kimchi for a light Korean dinner set",
              mealType: "dinner",
              calories: "about 380kcal",
              ingredients: ["Rice", "Bean sprouts", "Green onions", "Garlic", "Anchovy broth", "Seasonal greens", "Kimchi", "Sesame oil"]
            ),
          ];
          break;
        case 'snack':
        case 'snacks':
          defaults = [
            SimpleMenu(
              dishName: "Seasonal Fruit Mix",
              category: "snack", 
              description: "Fresh seasonal fruit assortment providing various vitamins and fiber",
              mealType: "snack",
              calories: "about 150kcal",
              ingredients: ["Apple", "Banana", "Orange", "Kiwi", "Strawberries"]
            ),
            SimpleMenu(
              dishName: "High-Protein Nut Mix",
              category: "snack",
              description: "Assortment of nuts and dried fruits rich in healthy fats and protein",
              mealType: "snack",
              calories: "about 200kcal",
              ingredients: ["Almonds", "Walnuts", "Sunflower seeds", "Raisins", "Dried blueberries"]
            ),
            SimpleMenu(
              dishName: "Berry Greek Yogurt Parfait",
              category: "snack",
              description: "Protein-rich Greek yogurt layered with various berries and nuts for a nutritious snack",
              mealType: "snack",
              calories: "about 220kcal",
              ingredients: ["Greek yogurt", "Blueberries", "Raspberries", "Honey", "Walnuts", "Almonds"]
            ),
          ];
          break;
        default:
          defaults = [
            SimpleMenu(
              dishName: "Fruit Mix",
              category: "snack",
              description: "A snack rich in various vitamins and fiber",
              mealType: "snack",
              calories: "about 150kcal",
              ingredients: ["Apple", "Banana", "Orange", "Kiwi", "Strawberries"]
            ),
          ];
      }
    }
    
    // 요청된 수만큼 반환
    return defaults.take(count).toList();
  }
}


