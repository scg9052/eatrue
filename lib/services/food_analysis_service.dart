import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/user_data.dart';
import 'dart:async';
import 'dart:math';

/// 음식명을 입력받아 식재료, 양념, 조리 방식으로 분석하는 서비스
class FoodAnalysisService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';

  FoodAnalysisService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  /// 기본 생성 구성 설정
  GenerationConfig _getBaseGenerationConfig({String? responseMimeType}) {
    return GenerationConfig(
      maxOutputTokens: 4096,
      temperature: 0.2, // 낮은 temperature로 일관된 결과 도출
      topP: 0.95,
      responseMimeType: responseMimeType,
    );
  }

  /// 안전 설정
  List<SafetySetting> _getSafetySettings() {
    return [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity),
    ];
  }

  /// JSON 출력을 위한 Vertex AI 모델 호출
  Future<Map<String, dynamic>?> _callGenerativeModelForJson(
      String systemInstructionText, String userPrompt) async {
    try {
      final systemInstruction = Content.system(systemInstructionText);
      final model = _vertexAI.generativeModel(
        model: _modelName,
        generationConfig: _getBaseGenerationConfig(responseMimeType: 'application/json'),
        safetySettings: _getSafetySettings(),
        systemInstruction: systemInstruction,
      );
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      
      if (response.text != null) {
        try {
          final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          print("음식 분석 응답 JSON 파싱 오류: $e. 원본 텍스트: ${response.text}");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Vertex AI 모델 호출 중 오류: $e");
      return null;
    }
  }

  /// 음식명을 분석하여 식재료, 양념, 조리 방식으로 분리
  /// 
  /// [dishName] 분석할 음식명
  /// 반환값: 식재료, 양념, 조리 방식 정보가 포함된 Map 또는 null (오류 시)
  Future<Map<String, dynamic>?> analyzeDish(String dishName) async {
    const systemInstructionText = '''
당신은 요리 전문가입니다. 음식명을 분석하여 식재료, 양념, 조리 방식으로 분리하는 역할을 수행합니다.
정확하고 객관적인 분석 결과만 JSON 형식으로 제공해주세요.
''';

    final userPrompt = '''
다음 음식명을 분석하여 식재료, 양념, 조리 방식으로 분리해주세요: "$dishName"

응답은 다음 JSON 형식으로 제공해주세요:
{
  "dish_name": "원본 음식명",
  "ingredients": ["주요 식재료1", "주요 식재료2", ...],
  "seasonings": ["양념1", "양념2", ...],
  "cooking_methods": ["조리 방식1", "조리 방식2", ...],
  "estimated_cooking_time_minutes": 예상 조리 시간(분)
}

참고사항:
1. 식재료는 해당 요리의 주요 재료들을 나열해주세요.
2. 양념은 맛을 내기 위한 조미료나 향신료를 나열해주세요.
3. 조리 방식은 '찌기', '굽기', '볶기', '끓이기' 등과 같은 요리 방법을 나열해주세요.
4. 예상 조리 시간은 해당 요리를 만드는 데 걸리는 대략적인 시간을 분 단위로 표시해주세요.
5. 확실하지 않은 항목은 빈 배열로 두세요. (예: "seasonings": [])

분석할 음식명: "$dishName"
''';

    return await _callGenerativeModelForJson(systemInstructionText, userPrompt);
  }

  /// 특정 음식의 영양 정보 분석
  ///
  /// [dishName] 분석할 음식명
  /// [ingredients] 식재료 목록 (선택적)
  /// 반환값: 영양 정보가 포함된 Map 또는 null (오류 시)
  Future<Map<String, dynamic>?> analyzeNutrition(String dishName, {List<String>? ingredients}) async {
    const systemInstructionText = '''
당신은 영양학 전문가입니다. 음식의 영양 성분을 분석하는 역할을 수행합니다.
정확하고 객관적인 영양 정보만 JSON 형식으로 제공해주세요.
''';

    final ingredientsInfo = ingredients != null && ingredients.isNotEmpty 
        ? "식재료: ${ingredients.join(', ')}\n" 
        : "";

    final userPrompt = '''
다음 음식의 영양 정보를 분석해 주세요: "$dishName"
$ingredientsInfo

응답은 다음 JSON 형식으로 제공해주세요:
{
  "dish_name": "원본 음식명",
  "calories": "칼로리(kcal)",
  "protein": "단백질(g)",
  "carbohydrates": "탄수화물(g)",
  "fat": "지방(g)",
  "fiber": "식이섬유(g)",
  "sodium": "나트륨(mg)",
  "vitamins": ["비타민A", "비타민C", ...],
  "minerals": ["칼슘", "철분", ...],
  "health_index": 건강 지수(1-10),
  "suitable_for": ["다이어트", "근육 증가", ...]
}

참고사항:
1. 모든 영양소 값은 1인분 기준으로 작성해주세요.
2. 건강 지수는 영양 균형, 칼로리, 나트륨 함량 등을 고려하여 1~10점 사이로 평가해주세요.
3. suitable_for는 이 음식이 적합한 식단 목적을 나열해주세요.
4. 확실하지 않은 항목은 빈 배열이나 "unknown"으로 표시해주세요.

분석할 음식명: "$dishName"
''';

    return await _callGenerativeModelForJson(systemInstructionText, userPrompt);
  }

  /// 식재료와 양념에 기반하여 조리법 제안
  ///
  /// [dishName] 음식명
  /// [ingredients] 식재료 목록
  /// [seasonings] 양념 목록
  /// 반환값: 조리법이 포함된 Map 또는 null (오류 시)
  Future<Map<String, dynamic>?> suggestCookingMethod(
      String dishName, List<String> ingredients, List<String> seasonings) async {
    const systemInstructionText = '''
당신은 요리 전문가입니다. 주어진 식재료와 양념으로 음식을 만드는 최적의 조리법을 제안하는 역할을 수행합니다.
실용적이고 구체적인 조리법만 JSON 형식으로 제공해주세요.
''';

    final userPrompt = '''
다음 음식을 만들기 위한 최적의 조리법을 제안해주세요.

음식명: "$dishName"
식재료: ${ingredients.join(', ')}
양념: ${seasonings.join(', ')}

응답은 다음 JSON 형식으로 제공해주세요:
{
  "dish_name": "원본 음식명",
  "cooking_methods": ["주요 조리 방식1", "주요 조리 방식2", ...],
  "cooking_steps": [
    "1. 첫 번째 조리 단계",
    "2. 두 번째 조리 단계",
    ...
  ],
  "cooking_time_minutes": 총 조리 시간(분),
  "difficulty": "난이도(쉬움/보통/어려움)",
  "tips": ["조리 팁1", "조리 팁2", ...]
}

참고사항:
1. 조리 단계는 누구나 따라할 수 있도록 명확하고 구체적으로 작성해주세요.
2. 조리 팁은 음식을 더 맛있게 만들거나 실패를 방지하는 조언을 제공해주세요.
3. 난이도는 해당 요리의 기술적 복잡성을 기준으로 평가해주세요.

음식명: "$dishName"
''';

    return await _callGenerativeModelForJson(systemInstructionText, userPrompt);
  }

  /// 여러 음식명을 분석하여 식재료, 양념, 조리 방식으로 분리
  /// 
  /// [dishNames] 분석할 음식명 목록
  /// 반환값: 식재료, 양념, 조리 방식 정보가 포함된 Map 또는 null (오류 시)
  Future<Map<String, dynamic>?> analyzeDishes(List<String> dishNames) async {
    if (dishNames.isEmpty) {
      return {
        "ingredients": [],
        "seasonings": [],
        "cooking_methods": []
      };
    }

    const systemInstructionText = '''
당신은 요리 전문가입니다. 여러 음식명을 분석하여 사용된 식재료, 양념, 조리 방식을 추출하는 역할을 수행합니다.
각 음식에 대한 세부 분석이 아닌, 전체 음식 목록에서 추출된 고유한 식재료, 양념, 조리 방식의 집합을 제공해주세요.
정확하고 객관적인 분석 결과만 JSON 형식으로 제공해주세요.
''';

    final userPrompt = '''
다음 음식명 목록을 분석하여 사용된 모든 식재료, 양념, 조리 방식으로 분리해주세요:
${dishNames.map((name) => "- $name").join('\n')}

응답은 다음 JSON 형식으로 제공해주세요:
{
  "ingredients": ["식재료1", "식재료2", ...],
  "seasonings": ["양념1", "양념2", ...],
  "cooking_methods": ["조리 방식1", "조리 방식2", ...]
}

참고사항:
1. 식재료는 해당 요리들의 주요 재료들을 모두 포함해야 합니다. 중복된 식재료는 한 번만 포함하세요.
2. 양념은 맛을 내기 위한 모든 조미료나 향신료를 포함해야 합니다. 중복된 양념은 한 번만 포함하세요.
3. 조리 방식은 '찌기', '굽기', '볶기', '끓이기' 등과 같은 요리 방법을 모두 포함해야 합니다. 중복된 조리 방식은 한 번만 포함하세요.
4. 확실하지 않은 항목은 포함하지 마세요.
''';

    return await _callGenerativeModelForJson(systemInstructionText, userPrompt);
  }

  /// 여러 음식명에서 추출한 식재료, 양념, 조리 방식을 사용자 모델에 적용
  /// 
  /// [userData] 사용자 데이터 모델
  /// [favoriteFoods] 선호 음식 목록
  /// [dislikedFoods] 기피 음식 목록
  /// 반환값: 업데이트된 사용자 데이터 모델
  Future<UserData> analyzeUserFoodPreferences(
      UserData userData,
      {List<String>? favoriteFoods,
      List<String>? dislikedFoods}) async {
    
    // 기존 선호/기피 정보 사용 또는 파라미터 값 사용
    favoriteFoods ??= userData.favoriteFoods;
    dislikedFoods ??= userData.dislikedFoods;
    
    // 선호 음식 분석
    if (favoriteFoods.isNotEmpty) {
      final favoriteAnalysis = await analyzeDishes(favoriteFoods);
      if (favoriteAnalysis != null) {
        userData = userData.copyWith(
          preferredIngredients: parseStringList(favoriteAnalysis['ingredients']),
          preferredSeasonings: parseStringList(favoriteAnalysis['seasonings']),
          preferredCookingStyles: parseStringList(favoriteAnalysis['cooking_methods']),
        );
      }
    }
    
    // 기피 음식 분석
    if (dislikedFoods.isNotEmpty) {
      final dislikedAnalysis = await analyzeDishes(dislikedFoods);
      if (dislikedAnalysis != null) {
        userData = userData.copyWith(
          dislikedIngredients: parseStringList(dislikedAnalysis['ingredients']),
          dislikedSeasonings: parseStringList(dislikedAnalysis['seasonings']),
          dislikedCookingStyles: parseStringList(dislikedAnalysis['cooking_methods']),
        );
      }
    }
    
    return userData;
  }

  // 문자열 리스트 파싱 헬퍼 메서드 (private에서 public으로 변경)
  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// 식단에 포함된 특정 메뉴의 상세 정보 가져오기
  Future<Map<String, dynamic>?> getDetailedRecipeForMenu(String menuName, UserData userData) async {
    // ... existing code ...
    // 구현이 필요한 메서드이므로 기본값 반환
    return null;
  }

  FutureOr<Map<String, dynamic>?> analyzeNutritionalValues(String foodName) async {
    try {
      // 간략한 예시: 웹 API 호출 구현
      // final response = await http.get(Uri.parse('$API_URL/nutritional-values?food=$foodName'));
      // if (response.statusCode == 200) {
      //   return json.decode(response.body);
      // } 
      
      // 임시로 랜덤 영양소 값 반환 (실제로는 API에서 받아옴)
      final rng = Random();
      return {
        'calories': '${100 + rng.nextInt(300)} kcal',
        'protein': '${3 + rng.nextInt(20)}g',
        'carbohydrates': '${10 + rng.nextInt(40)}g',
        'fat': '${2 + rng.nextInt(15)}g',
      };
    } catch (e) {
      print("⚠️ 영양 분석 중 오류: $e");
      return null;
    }
  }
} 