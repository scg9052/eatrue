// services/preference_summary_service.dart
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/user_data.dart'; // UserData 모델 임포트 추가
// import 'dart:typed_data'; // 현재 코드에서는 직접 사용되지 않음

class PreferenceSummaryService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';

  PreferenceSummaryService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  Future<String?> summarizePreferences({
    List<String> preferredCookingMethod = const [],
    List<String> preferredIngredients = const [],
    List<String> preferredSeasonings = const [],
    int desiredCookingTime = 30,
    double desiredFoodCost = 10000,
    List<String> mealPurpose = const [], // 사용자의 식단 목적 추가
  }) async {
    final generationConfig = GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1,
      topP: 0.95,
    );

    // SafetySetting: HarmBlockThreshold와 HarmBlockMethod의 정확한 사용법은
    // firebase_vertexai 패키지 버전에 따라 다를 수 있습니다.
    // 이전 논의를 바탕으로 HarmBlockMethod.SEVERITY를 사용합니다.
    // 실제 사용 가능한 값인지 IDE 자동완성 또는 문서를 통해 확인하세요.
    final safetySettings = [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: 또는 HarmBlockMethod.SEVERITY 등 확인된 값 */),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
    ];
    // 참고: HarmBlockMethod.methodUnspecified는 일반적으로 기본 동작을 의미합니다.
    // 명시적으로 SEVERITY나 PROBABILITY를 사용하려면 해당 상수가 HarmBlockMethod enum에 있는지 확인해야 합니다.
    // 만약 HarmBlockMethod.SEVERITY가 없다면, HarmBlockMethod.block 등을 고려하거나,
    // SafetySetting 생성자가 2개의 인자만 받는다면 이전처럼 사용해야 합니다.
    // 여기서는 사용자가 3개의 인자를 확인했다고 가정하고, 임시로 methodUnspecified를 넣었습니다.
    // 실제로는 HarmBlockMethod.SEVERITY 또는 HarmBlockMethod.PROBABILITY로 대체해야 합니다.

    const siText1 =
        'You are a menu planning assistant that helps users create personalized menu recommendations based on their preferences.';
    final systemInstruction = Content.system(siText1);

    final model = _vertexAI.generativeModel(
      model: _modelName, // API 스펙에 명시된 모델 사용 (예: gemini-2.0-flash-001)
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      systemInstruction: systemInstruction,
    );

    final userPrompt = '''
Please provide the following information to create a summary document of user preferences for menu generation:

Preferred Cooking Method: ${preferredCookingMethod.join(', ')}
Preferred Ingredients: ${preferredIngredients.join(', ')}
Preferred Seasonings: ${preferredSeasonings.join(', ')}
Desired Cooking Time: $desiredCookingTime
Desired Food Cost: $desiredFoodCost
Meal Purpose: ${mealPurpose.isEmpty ? 'Not specified' : mealPurpose.join(', ')}

Organize the provided information into a concise summary document suitable for guiding menu creation.
''';

    try {
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      print("Preference Summary API Response: ${response.text}");
      return response.text;
    } catch (e) {
      print("Error calling Preference Summary API: $e");
      return null;
    }
  }
  
  /// 사용자 데이터 기반 선호도 요약 (분해된 정보 활용)
  Future<String?> summarizeUserPreferences(UserData userData) async {
    const systemInstructionText = '''
당신은 영양과 요리 전문가입니다. 
사용자의 식품 선호도 정보를 정확하고 구체적으로 요약하는 역할을 합니다.
항상 모든 항목을 구체적으로 나열하고, '등 다양한 식재료'와 같은 모호한 표현은 사용하지 마세요.
''';

    final userPrompt = '''
다음 사용자의 식품 선호도 정보를 요약해주세요:

선호 정보:
* 선호 식재료: ${userData.preferredIngredients.isEmpty ? '정보 없음' : userData.preferredIngredients.join(', ')}
* 선호 양념: ${userData.preferredSeasonings.isEmpty ? '정보 없음' : userData.preferredSeasonings.join(', ')}
* 선호 조리 방식: ${userData.preferredCookingStyles.isEmpty ? '정보 없음' : userData.preferredCookingStyles.join(', ')}
* 선호 조리 방법: ${userData.preferredCookingMethods.isEmpty ? '정보 없음' : userData.preferredCookingMethods.join(', ')}
* 기존 선호 음식: ${userData.favoriteFoods.isEmpty ? '정보 없음' : userData.favoriteFoods.join(', ')}
* 조리 시간 선호: ${userData.preferredCookingTime ?? 30}분 이내
* 식사 비용 선호: ${userData.mealBudget ?? 10000}원 이내
* 식단 목적: ${userData.mealPurpose.isEmpty ? '정보 없음' : userData.mealPurpose.join(', ')}

요약 작성 요구사항:
1. 요약은 사용자의 식품 선호도를 2-3문장으로 압축하여 서술해주세요.
2. 모든 선호 식재료, 양념, 조리 방식을 구체적으로 언급하세요.
3. "등"이나 "다양한"과 같은 모호한 표현을 사용하지 마세요.
4. 리스트가 길 경우, 가장 중요한 3-4개 항목을 선택하여 구체적으로 언급하세요.
5. 없는 정보나 지나치게 일반적인 정보는 생략하세요.
6. 식단 목적을 반드시 포함하여 사용자의 영양학적 니즈가 잘 드러나도록 요약해주세요.
''';

    final generationConfig = GenerationConfig(
      maxOutputTokens: 2048,
      temperature: 0.2,
    );
    final safetySettings = [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.severity),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.severity),
    ];

    try {
      final model = _vertexAI.generativeModel(
        model: _modelName,
        generationConfig: generationConfig,
        safetySettings: safetySettings,
        systemInstruction: Content.system(systemInstructionText),
      );
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      
      if (response.text != null) {
        return response.text;
      }
      return null;
    } catch (e) {
      print('선호도 요약 중 오류: $e');
      return null;
    }
  }
}
