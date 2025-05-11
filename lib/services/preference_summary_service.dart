// services/preference_summary_service.dart
import 'package:firebase_vertexai/firebase_vertexai.dart';
// import 'dart:typed_data'; // 현재 코드에서는 직접 사용되지 않음

class PreferenceSummaryService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.0-flash-001';

  PreferenceSummaryService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  Future<String?> summarizePreferences({
    required List<String> preferredCookingMethod,
    required List<String> preferredIngredients,
    required List<String> preferredSeasonings,
    required int desiredCookingTime,
    required double desiredFoodCost,
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
}
