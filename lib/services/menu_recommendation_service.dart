import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/dish_analysis.dart';
import '../models/user_data.dart';
import '../models/recipe.dart';
import './food_analysis_service.dart';

/// FoodAnalysisService와 MenuGenerationService를 활용하여 
/// 사용자 맞춤형 메뉴 추천 서비스를 제공하는 서비스
class MenuRecommendationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';
  final FoodAnalysisService _foodAnalysisService;

  MenuRecommendationService({
    FirebaseVertexAI? vertexAI,
    FoodAnalysisService? foodAnalysisService,
  }) : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1'),
       _foodAnalysisService = foodAnalysisService ?? FoodAnalysisService();

  /// 기본 생성 구성 설정
  GenerationConfig _getBaseGenerationConfig({String? responseMimeType}) {
    return GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 0.8, // 다양한 결과를 위해 약간 높은 temperature
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
  Future<dynamic> _callGenerativeModelForJson(
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
          return jsonDecode(jsonString);
        } catch (e) {
          print("메뉴 추천 응답 JSON 파싱 오류: $e. 원본 텍스트: ${response.text}");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Vertex AI 모델 호출 중 오류: $e");
      return null;
    }
  }

  /// 단일 음식 분석 프로세스
  /// 1. 음식명을 분석하여 식재료, 양념, 조리 방식으로 분리
  /// 2. 식재료 기반으로 영양 정보 분석
  /// 3. 식재료와 양념 기반으로 조리법 제안
  Future<DishAnalysis?> analyzeDishComprehensively(String dishName) async {
    try {
      // 1. 기본 분석
      final basicAnalysisJson = await _foodAnalysisService.analyzeDish(dishName);
      if (basicAnalysisJson == null) {
        return null;
      }
      
      final basicAnalysis = DishAnalysis.fromBasicAnalysis(basicAnalysisJson);
      
      // 2. 영양 정보 분석
      final nutritionJson = await _foodAnalysisService.analyzeNutrition(
        dishName, 
        ingredients: basicAnalysis.ingredients
      );
      
      DishAnalysis analysisWithNutrition = basicAnalysis;
      if (nutritionJson != null) {
        analysisWithNutrition = DishAnalysis.withNutrition(basicAnalysis, nutritionJson);
      }
      
      // 3. 조리법 제안
      final cookingMethodJson = await _foodAnalysisService.suggestCookingMethod(
        dishName, 
        basicAnalysis.ingredients, 
        basicAnalysis.seasonings
      );
      
      if (cookingMethodJson != null) {
        return DishAnalysis.withCookingMethod(analysisWithNutrition, cookingMethodJson);
      }
      
      return analysisWithNutrition;
    } catch (e) {
      print("음식 분석 중 오류 발생: $e");
      return null;
    }
  }
  
  /// 사용자 프로필에 기반한 메뉴 추천
  Future<List<String>> recommendMenusBasedOnProfile(UserData userData, {int count = 5}) async {
    const systemInstructionText = '''
당신은 영양과 요리 전문가입니다. 
사용자의 건강 정보, 식이 제한, 취향에 기반하여 추천 메뉴를 제공합니다.
''';

    final userPrompt = '''
다음 사용자 정보를 바탕으로 $count개의 추천 메뉴를 제안해주세요:

사용자 정보:
* 나이: ${userData.age ?? '정보 없음'}
* 성별: ${userData.gender ?? '정보 없음'}
* 키: ${userData.height ?? '정보 없음'} cm
* 체중: ${userData.weight ?? '정보 없음'} kg
* 활동 수준: ${userData.activityLevel ?? '정보 없음'}
* 알레르기: ${userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')}
* 기저질환: ${userData.underlyingConditions.isEmpty ? '없음' : userData.underlyingConditions.join(', ')}
* 비건 여부: ${userData.isVegan ? '예' : '아니오'}
* 종교적 제한: ${userData.isReligious ? (userData.religionDetails ?? '있음 (상세 정보 없음)') : '없음'}

선호 정보:
* 선호 식재료: ${userData.preferredIngredients.isEmpty ? '정보 없음' : userData.preferredIngredients.join(', ')}
* 선호 양념: ${userData.preferredSeasonings.isEmpty ? '정보 없음' : userData.preferredSeasonings.join(', ')}
* 선호 조리 방식: ${userData.preferredCookingStyles.isEmpty ? '정보 없음' : userData.preferredCookingStyles.join(', ')}
* 기존 선호 음식: ${userData.favoriteFoods.isEmpty ? '정보 없음' : userData.favoriteFoods.join(', ')}

기피 정보:
* 기피 식재료: ${userData.dislikedIngredients.isEmpty ? '정보 없음' : userData.dislikedIngredients.join(', ')}
* 기피 양념: ${userData.dislikedSeasonings.isEmpty ? '정보 없음' : userData.dislikedSeasonings.join(', ')}
* 기피 조리 방식: ${userData.dislikedCookingStyles.isEmpty ? '정보 없음' : userData.dislikedCookingStyles.join(', ')}
* 기존 기피 음식: ${userData.dislikedFoods.isEmpty ? '정보 없음' : userData.dislikedFoods.join(', ')}

추가 정보: 
* 선호 조리 방법: ${userData.preferredCookingMethods.isEmpty ? '정보 없음' : userData.preferredCookingMethods.join(', ')}
* 주 식사 목적: ${userData.mealPurpose.isEmpty ? '정보 없음' : userData.mealPurpose.join(', ')}

응답은 다음 JSON 형식으로 제공해주세요:
{
  "recommended_menus": ["메뉴1", "메뉴2", "메뉴3", "메뉴4", "메뉴5"]
}

추천 시 다음 사항을 고려해주세요:
1. 사용자의 알레르기와 기피 식재료가 포함되지 않은 메뉴
2. 사용자의 식이 제한(비건, 종교적 제한 등)을 준수하는 메뉴
3. 사용자의 선호 식재료, 양념, 조리 방식을 최대한 활용한 메뉴
4. 사용자의 건강 상태와 식사 목적에 적합한 메뉴
5. 다양한 영양소를 고르게 섭취할 수 있는 메뉴 구성

추천 메뉴는 구체적인 음식명으로 작성해주세요. (예: "닭가슴살 샐러드", "소고기 불고기", "두부 스테이크" 등)
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse == null || !(jsonResponse is Map)) {
      return [];
    }

    final recommendedMenus = (jsonResponse['recommended_menus'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return recommendedMenus;
  }

  /// 특정 메뉴 목록에 기반하여 전체 식단 생성
  Future<Map<String, dynamic>?> generateFullMealPlan(
      List<String> selectedMenus, UserData userData) async {
    const systemInstructionText = '''
당신은 영양과 요리 전문가입니다. 
사용자가 선택한 메뉴를 기반으로 아침, 점심, 저녁, 간식으로 구성된 균형 잡힌 식단을 제안합니다.
''';

    final userPrompt = '''
다음 사용자 정보와 선택한 메뉴를 바탕으로 일주일 간의 식단 계획을 작성해주세요:

사용자 정보:
* 나이: ${userData.age ?? '정보 없음'}
* 성별: ${userData.gender ?? '정보 없음'}
* 키: ${userData.height ?? '정보 없음'} cm
* 체중: ${userData.weight ?? '정보 없음'} kg
* 활동 수준: ${userData.activityLevel ?? '정보 없음'}
* 알레르기: ${userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')}
* 선호 조리 방법: ${userData.preferredCookingMethods.isEmpty ? '정보 없음' : userData.preferredCookingMethods.join(', ')}
* 주 식사 목적: ${userData.mealPurpose.isEmpty ? '정보 없음' : userData.mealPurpose.join(', ')}

선택한 메뉴:
${selectedMenus.map((menu) => "- $menu").join('\n')}

응답은 다음 JSON 형식으로 제공해주세요:
{
  "meal_plan": {
    "monday": {
      "breakfast": "메뉴1",
      "lunch": "메뉴2",
      "dinner": "메뉴3",
      "snack": "메뉴4"
    },
    ... (화요일부터 일요일까지 동일한 형식으로)
  },
  "nutritional_balance": "식단의 영양 균형에 대한 설명",
  "meal_tips": ["식단 관련 팁1", "식단 관련 팁2", ...]
}

식단 계획 시 다음 사항을 고려해주세요:
1. 사용자가 선택한 메뉴를 적절히 분배하여 일주일 식단에 포함
2. 영양 균형을 고려한 식단 구성
3. 사용자의 식사 목적에 맞는 식단 구성
4. 현실적으로 준비 가능한 식단 구성
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    return jsonResponse is Map ? Map<String, dynamic>.from(jsonResponse) : null;
  }
  
  /// 식단에 포함된 특정 메뉴의 상세 정보 가져오기
  Future<Recipe?> getDetailedRecipeForMenu(String menuName, UserData userData) async {
    const systemInstructionText = '''
당신은 요리 전문가입니다. 
사용자의 정보와 선호도에 맞게 특정 메뉴의 조리법과 영양 정보를 제공합니다.
''';

    final userPrompt = '''
다음 메뉴에 대한 상세 레시피를 작성해주세요: "$menuName"

사용자 정보:
* 알레르기: ${userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')}
* 비건 여부: ${userData.isVegan ? '예' : '아니오'}
* 선호 조리 방법: ${userData.preferredCookingMethods.isEmpty ? '정보 없음' : userData.preferredCookingMethods.join(', ')}
* 가용 조리 도구: ${userData.availableCookingTools.isEmpty ? '정보 없음' : userData.availableCookingTools.join(', ')}

레시피는 다음 JSON 형식으로 제공해주세요:
{
  "id": "자동생성된 ID",
  "dish_name": "$menuName",
  "cost_information": "예상 비용",
  "nutritional_information": {
    "calories": "칼로리",
    "protein": "단백질",
    "carbohydrates": "탄수화물",
    "fat": "지방"
  },
  "ingredients": {
    "식재료1": "수량",
    "식재료2": "수량",
    ...
  },
  "seasonings": {
    "양념1": "수량",
    "양념2": "수량",
    ...
  },
  "cooking_instructions": [
    "1단계 설명",
    "2단계 설명",
    ...
  ],
  "cookingTimeMinutes": 예상 소요 시간(분),
  "difficulty": "난이도(쉬움/보통/어려움)"
}

다음 사항을 고려해서 레시피를 작성해주세요:
1. 사용자의 알레르기 정보와 비건 여부 고려
2. 사용자가 선호하는 조리 방법 활용
3. 사용자가 가진 조리 도구를 활용한 현실적인 레시피
4. 자세하고 명확한 조리 단계
''';

    final jsonResponse = await _callGenerativeModelForJson(systemInstructionText, userPrompt);
    if (jsonResponse != null && jsonResponse is Map<String, dynamic>) {
      try {
        return Recipe.fromJson(jsonResponse);
      } catch (e) {
        print("레시피 변환 중 오류: $e");
        return null;
      }
    }
    return null;
  }
} 