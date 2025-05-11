// services/nutrient_calculation_service.dart
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
// import 'dart:typed_data';

class NutrientCalculationService {
  final FirebaseVertexAI _vertexAI;
  final String _modelName = 'gemini-2.0-flash-001';

  NutrientCalculationService({FirebaseVertexAI? vertexAI})
      : _vertexAI = vertexAI ?? FirebaseVertexAI.instanceFor(location: 'us-central1');

  Future<Map<String, dynamic>?> calculateNutrients({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activityLevel,
  }) async {
    final generationConfig = GenerationConfig(
      maxOutputTokens: 8192,
      temperature: 1,
      topP: 0.95,
      responseMimeType: 'application/json', // JSON 응답 요청
    );

    final safetySettings = [
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.severity /* TODO: */),
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
        'You are a professional nutritionist. Your task is to calculate the daily recommended nutrients based on the user\'s personal information. Use a professional tone.';
    final systemInstruction = Content.system(siText1);

    final model = _vertexAI.generativeModel(
      model: _modelName, // API 스펙에 명시된 모델 사용
      generationConfig: generationConfig,
      safetySettings: safetySettings,
      systemInstruction: systemInstruction,
    );

    final userPrompt = '''
You will be provided with the following information:
Age: $age
Gender: $gender
Height: $height
Weight: $weight
Activity Level: $activityLevel

Based on the information provided, calculate the daily recommended calories and protein intake for the given activity level. Output ONLY the results in JSON format, including both calorie and protein recommendations for the provided activity level. Provide exact numerical values, avoiding ranges or estimations. Enclose the numerical values within the JSON format with quotation marks. Do not include any additional text or explanations. Keep the answer concise.
Example JSON output:
{
  "recommended_calories": "2200",
  "recommended_protein": "110"
}
''';

    try {
      final chat = model.startChat();
      final response = await chat.sendMessage(Content.text(userPrompt));
      print("Nutrient Calculation API Response: ${response.text}");
      if (response.text != null) {
        try {
          final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          print("Nutrient Calculation API JSON parsing error: $e. Original text: ${response.text}");
          return null;
        }
      }
      return null;
    } catch (e) {
      print("Error calling Nutrient Calculation API: $e");
      return null;
    }
  }
}
