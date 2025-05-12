// services/dislike_summary_service.dart
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/user_data.dart'; // UserData 모델 임포트 추가

class DislikeSummaryService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.5-flash-preview-04-17';

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
    List<String> cookingTools = const [],
    List<String> dislikedCookingMethods = const [],
    String? religionDetails,
    bool veganStatus = false,
    List<String> dislikedIngredients = const [],
    List<String> dislikedSeasonings = const [],
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

  /// 사용자 데이터 기반 기피 사항 요약 (분해된 정보 활용)
  Future<String?> summarizeUserDislikes(UserData userData) async {
    const systemInstructionText = '''
당신은 영양과 요리 전문가입니다. 
사용자의 식품 기피 정보를 간결하게 요약하는 역할을 합니다.
''';

    final userPrompt = '''
다음 사용자의 식품 기피 정보를 요약해주세요:

기피 정보:
* 기피 식재료: ${userData.dislikedIngredients.isEmpty ? '정보 없음' : userData.dislikedIngredients.join(', ')}
* 기피 양념: ${userData.dislikedSeasonings.isEmpty ? '정보 없음' : userData.dislikedSeasonings.join(', ')}
* 기피 조리 방식: ${userData.dislikedCookingStyles.isEmpty ? '정보 없음' : userData.dislikedCookingStyles.join(', ')}
* 기존 기피 음식: ${userData.dislikedFoods.isEmpty ? '정보 없음' : userData.dislikedFoods.join(', ')}
* 알레르기: ${userData.allergies.isEmpty ? '없음' : userData.allergies.join(', ')}
* 비건 여부: ${userData.isVegan ? '예' : '아니오'}
* 종교적 제한: ${userData.isReligious ? (userData.religionDetails ?? '있음 (상세 정보 없음)') : '없음'}
* 가용 조리 도구: ${userData.availableCookingTools.isEmpty ? '모든 도구 사용 가능' : userData.availableCookingTools.join(', ')}

요약은 위 정보를 바탕으로 사용자의 식품 기피 정보를 2-3문장으로 압축하여 서술해주세요.
알레르기, 비건 여부, 종교적 제한, 기피 식재료와 조리 방식 등을 언급하되, 중요한 정보만 간결하게 포함해주세요.
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
      print('기피 사항 요약 중 오류: $e');
      return null;
    }
  }
}
