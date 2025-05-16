// 다국어 템플릿 처리를 위한 서비스
import 'dart:convert';
import '../utils/localized_templates.dart';
import '../models/user_data.dart';

/// 언어별 템플릿 처리 서비스
/// 
/// 이 서비스는 LocalizedTemplates을 사용하여 언어 코드에 맞는 템플릿을 관리합니다.
/// 다국어 지원을 위한 모든 템플릿 처리의 중앙 허브 역할을 합니다.
class TemplateService {
  // 싱글톤 패턴 구현
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();
  
  // 템플릿 관리자 인스턴스
  final LocalizedTemplates _templates = LocalizedTemplates();
  
  // 현재 언어 코드 (기본값: 한국어)
  String _currentLanguageCode = 'ko';
  
  // 현재 언어 코드 설정
  void setLanguageCode(String languageCode) {
    if (_templates.supportedLanguages.contains(languageCode)) {
      _currentLanguageCode = languageCode;
      print("TemplateService: 현재 언어 코드가 '$languageCode'로 설정되었습니다.");
    } else {
      print("TemplateService: 지원되지 않는 언어 코드 '$languageCode'. 기본 언어로 유지합니다.");
    }
  }
  
  // 현재 언어 코드 조회
  String get languageCode => _currentLanguageCode;
  
  // 메뉴 생성을 위한 시스템 지시문 생성
  String getMenuSystemInstruction({bool isRegeneration = false}) {
    String baseInstruction = _templates.getTemplate(
      _templates.menuSystemInstructionTemplates, 
      _currentLanguageCode
    );
    
    if (isRegeneration) {
      String regenerationAddition = _templates.getTemplate(
        _templates.menuRegenerationInstructionTemplates, 
        _currentLanguageCode
      );
      return baseInstruction + regenerationAddition;
    }
    
    return baseInstruction;
  }
  
  // 메뉴 생성 프롬프트 생성
  String generateMenuPrompt({
    required Map<String, dynamic> nutrients,
    required String dislikes,
    required String preferences,
    UserData? userData,
    Map<String, dynamic>? previousMenu,
    Map<String, String>? verificationFeedback,
  }) {
    // 기본 변수 초기화
    Map<String, String> variables = {
      'nutrients': json.encode(nutrients),
      'dislikes': dislikes,
      'preferences': preferences,
    };
    
    // 기본 프롬프트 템플릿 가져오기
    String promptTemplate = _templates.getTemplate(
      _templates.menuBasePromptTemplates, 
      _currentLanguageCode
    );
    
    // 사용자 데이터가 있는 경우 변수 설정 및 템플릿 추가
    if (userData != null) {
      variables.addAll(_getUserDataVariables(userData));
      
      String userDetailsTemplate = _templates.getTemplate(
        _templates.userDetailsTemplates, 
        _currentLanguageCode
      );
      
      promptTemplate += userDetailsTemplate;
    }
    
    // 재생성 모드인 경우 변수 설정 및 템플릿 추가
    if (previousMenu != null && verificationFeedback != null) {
      variables['userDetailNumber'] = userData != null ? '5' : '4';
      variables['feedbackNumber'] = userData != null ? '6' : '5';
      variables['previousMenu'] = json.encode(previousMenu);
      variables['verificationFeedback'] = json.encode(verificationFeedback);
      
      String regenerationTemplate = _templates.getTemplate(
        _templates.regenerationInfoTemplates, 
        _currentLanguageCode
      );
      
      promptTemplate += regenerationTemplate;
    }
    
    // 출력 형식 지시 템플릿 추가
    String outputFormatTemplate = _templates.getTemplate(
      _templates.outputFormatInstructionTemplates, 
      _currentLanguageCode
    );
    
    promptTemplate += outputFormatTemplate;
    
    // 변수 대체하여 최종 프롬프트 생성
    return _templates.processTemplate(promptTemplate, variables);
  }
  
  // 레시피 생성 시스템 지시문 조회
  String getRecipeSystemInstruction() {
    return _templates.getTemplate(
      _templates.recipeSystemInstructionTemplates, 
      _currentLanguageCode
    );
  }
  
  // 레시피 생성 프롬프트 생성
  String generateRecipePrompt({
    required String mealName,
    required UserData userData,
  }) {
    // 변수 초기화
    Map<String, String> variables = {
      'mealName': mealName,
      'allergies': userData.allergies.isNotEmpty ? userData.allergies.join(', ') : '없음',
      'dislikedFoods': userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : '없음',
      'preferredCookingMethods': userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : '제한 없음',
      'availableCookingTools': userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : '제한 없음',
      'isVegan': userData.isVegan ? '예' : '아니오',
      'religionDetails': userData.isReligious ? (userData.religionDetails ?? '있음 (상세 정보 없음)') : '없음',
    };
    
    // 템플릿 가져오기
    String promptTemplate = _templates.getTemplate(
      _templates.recipePromptTemplates, 
      _currentLanguageCode
    );
    
    // 변수 대체하여 최종 프롬프트 생성
    return _templates.processTemplate(promptTemplate, variables);
  }
  
  // 메뉴 후보 생성 프롬프트 생성
  String generateMenuCandidatesPrompt({
    required String mealType,
    required int count,
  }) {
    // 변수 초기화
    Map<String, String> variables = {
      'mealType': mealType,
      'count': count.toString(),
    };
    
    // 템플릿 가져오기
    String promptTemplate = _templates.getTemplate(
      _templates.menuCandidatesPromptTemplates, 
      _currentLanguageCode
    );
    
    // 변수 대체하여 최종 프롬프트 생성
    return _templates.processTemplate(promptTemplate, variables);
  }
  
  // UserData 객체에서 템플릿 변수 추출
  Map<String, String> _getUserDataVariables(UserData userData) {
    return {
      'age': userData.age?.toString() ?? '정보 없음',
      'gender': userData.gender ?? '정보 없음',
      'height': userData.height != null ? '${userData.height}cm' : '정보 없음',
      'weight': userData.weight != null ? '${userData.weight}kg' : '정보 없음',
      'activityLevel': userData.activityLevel ?? '보통',
      'favoriteFoods': userData.favoriteFoods.isNotEmpty ? userData.favoriteFoods.join(', ') : '특별한 선호 없음',
      'dislikedFoods': userData.dislikedFoods.isNotEmpty ? userData.dislikedFoods.join(', ') : '특별한 기피 없음',
      'preferredCookingMethods': userData.preferredCookingMethods.isNotEmpty ? userData.preferredCookingMethods.join(', ') : '특별한 선호 없음',
      'availableCookingTools': userData.availableCookingTools.isNotEmpty ? userData.availableCookingTools.join(', ') : '기본 조리도구',
      'allergies': userData.allergies.isNotEmpty ? userData.allergies.join(', ') : '없음',
      'isVegan': userData.isVegan ? '예' : '아니오',
      'religionDetails': userData.isReligious ? (userData.religionDetails ?? '있음') : '없음',
      'mealPurpose': userData.mealPurpose.isNotEmpty ? userData.mealPurpose.join(', ') : '일반적인 식사',
      'mealBudget': userData.mealBudget != null ? '${userData.mealBudget}원' : '정보 없음',
      'preferredCookingTime': userData.preferredCookingTime != null ? '${userData.preferredCookingTime}분 이내' : '제한 없음',
      'preferredIngredients': userData.preferredIngredients.isNotEmpty ? userData.preferredIngredients.join(', ') : '특별한 선호 없음',
      'preferredSeasonings': userData.preferredSeasonings.isNotEmpty ? userData.preferredSeasonings.join(', ') : '특별한 선호 없음',
      'preferredCookingStyles': userData.preferredCookingStyles.isNotEmpty ? userData.preferredCookingStyles.join(', ') : '특별한 선호 없음',
      'dislikedIngredients': userData.dislikedIngredients.isNotEmpty ? userData.dislikedIngredients.join(', ') : '특별한 기피 없음',
      'dislikedSeasonings': userData.dislikedSeasonings.isNotEmpty ? userData.dislikedSeasonings.join(', ') : '특별한 기피 없음',
      'dislikedCookingStyles': userData.dislikedCookingStyles.isNotEmpty ? userData.dislikedCookingStyles.join(', ') : '특별한 기피 없음',
    };
  }
} 