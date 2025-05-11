// services/dislike_summary_service.dart
import 'package:firebase_vertexai/firebase_vertexai.dart';

class DislikeSummaryService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.0-flash-001';

  DislikeSummaryService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  List<SafetySetting> _getSafetySettings() {
    // TODO: firebase_vertexai 패키지 버전에 맞는 정확한 HarmBlockThreshold 및 HarmBlockMethod 값으로 수정하세요.
    return [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium , HarmBlockMethod.severity),
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium , HarmBlockMethod.severity),
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium , HarmBlockMethod.severity),
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium , HarmBlockMethod.severity),
    ];
  }

  Future<String?> summarizeDislikes({
    required List<String> cookingTools,
    required List<String> dislikedCookingMethods,
    String? religionDetails,
    required bool veganStatus,
    required List<String> dislikedIngredients,
    required List<String> dislikedSeasonings,
  }) async {
    final generationConfig = GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1, // 요약 작업이므로 약간 낮춰도 좋습니다 (예: 0.7)
      topP: 0.95,
    );

    const siText1 =
        'You are a personal cooking assistant that summarizes user\'s cooking preferences and dietary restrictions to help an AI menu generator create suitable menu options.';
    final systemInstruction = Content.system(siText1);

    final model = _vertexAI.generativeModel(
      model: _modelName,
      generationConfig: generationConfig,
      safetySettings: _getSafetySettings(),
      systemInstruction: systemInstruction,
    );

    final religionDetailsText = religionDetails ?? "None";
    final veganStatusText = veganStatus ? "Vegan" : "Not Vegan";

    // 프롬프트 수정: "Based on the following information..."으로 시작하여 이미 정보가 주어졌음을 명시
    final userPrompt = '''
Based on the following user's cooking preferences and dietary restrictions, create a summary of the user's dislikes that can be used by an AI menu generator. The summary should be concise and easy to understand.

User's Information:
* Cooking Tools: ${cookingTools.isNotEmpty ? cookingTools.join(', ') : "Not specified"}
* Disliked Cooking Methods: ${dislikedCookingMethods.isNotEmpty ? dislikedCookingMethods.join(', ') : "None specified"}
* Religion Details (if any, specify any dietary restrictions): $religionDetailsText
* Vegan Status (Vegan or Not Vegan): $veganStatusText
* Disliked Seasonings: ${dislikedSeasonings.isNotEmpty ? dislikedSeasonings.join(', ') : "None specified"}
* Disliked Ingredients: ${dislikedIngredients.isNotEmpty ? dislikedIngredients.join(', ') : "None specified"}

Summary Example:
If the user has an oven, dislikes deep frying and anise, is not vegan, and has no religious dietary restrictions, the summary should be something like:
"The user has an oven. They dislike deep frying and anise. They are not vegan and have no religious dietary restrictions."

Please generate the summary now based on the provided user's information.
''';

    try {
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      print("Dislike Summary API Response: ${response.text}");
      // 응답이 "Okay, I'm ready..." 와 같은지 확인하고, 그렇다면 프롬프트나 입력 데이터 문제를 의심
      if (response.text != null && response.text!.toLowerCase().contains("ready for your preferences")) {
        print("Warning: Dislike Summary API seems to be asking for input again. Check prompt and input data.");
        return "기피 정보를 요약하는 데 문제가 발생했습니다. 입력 데이터를 확인해주세요."; // 사용자에게 보여줄 메시지
      }
      return response.text;
    } catch (e) {
      print("Error calling Dislike Summary API: $e");
      return null;
    }
  }
}
