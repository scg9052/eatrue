import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'l10n_translations.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  late Map<String, String> _localizedStrings;
  
  Future<bool> load() async {
    _localizedStrings = L10nTranslations.getTranslations(locale.languageCode);
    return true;
  }
  
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
  
  // 현재 설정된 언어가 한국어인지 확인
  bool isKorean() {
    return locale.languageCode == 'ko';
  }
  
  // 앱 내 모든 번역 텍스트는 여기에 getter로 정의합니다
  
  // 초기 화면 관련 텍스트
  String get appTitle => translate('appTitle');
  String get appTagline => translate('appTagline');
  String get feature1Title => translate('feature1Title');
  String get feature1Description => translate('feature1Description');
  String get feature2Title => translate('feature2Title');
  String get feature2Description => translate('feature2Description');
  String get feature3Title => translate('feature3Title');
  String get feature3Description => translate('feature3Description');
  String get startSurveyButton => translate('startSurveyButton');
  String get getCustomMealPlan => translate('getCustomMealPlan');
  String get surveyDescription => translate('surveyDescription');
  String get skipButton => translate('skipButton');
  
  // 홈 화면 관련 텍스트
  String get homeTitle => translate('homeTitle');
  String get todayMeals => translate('todayMeals');
  String get breakfast => translate('breakfast');
  String get lunch => translate('lunch');
  String get dinner => translate('dinner');
  String get snack => translate('snack');
  String get caloriesInfo => translate('caloriesInfo');
  String get noMealsToday => translate('noMealsToday');
  String get addMeal => translate('addMeal');
  String get viewRecipe => translate('viewRecipe');
  String get createTodayMeal => translate('createTodayMeal');
  
  // 탭 이름
  String get tabHome => translate('tabHome');
  String get tabCreateMeal => translate('tabCreateMeal');
  String get tabMealBase => translate('tabMealBase');
  String get tabProfile => translate('tabProfile');
  
  // 식단 생성 화면 관련 텍스트
  String get mealGenerationTitle => translate('mealGenerationTitle');
  String get mealGenerationSubtitle => translate('mealGenerationSubtitle');
  String get mealGenerationDescription => translate('mealGenerationDescription');
  String get generateMealButton => translate('generateMealButton');
  String get generatingMealMessage => translate('generatingMealMessage');
  
  // 메뉴 생성 진행 메시지
  String get initialMenuGenerating => translate('initialMenuGenerating');
  String get menuGenerationProgress => translate('menuGenerationProgress');
  String get recommendedMenuCount => translate('recommendedMenuCount');
  String get startMenuGeneration => translate('startMenuGeneration');
  String get calculatingNutrients => translate('calculatingNutrients');
  String get gettingPreferences => translate('gettingPreferences');
  String get gettingDislikes => translate('gettingDislikes');
  String get retryingMenuGeneration => translate('retryingMenuGeneration');
  String get verifyingMenu => translate('verifyingMenu');
  String get menuVerificationPassed => translate('menuVerificationPassed');
  String get menuVerificationEmpty => translate('menuVerificationEmpty');
  String get regeneratingMenu => translate('regeneratingMenu');
  String get menuVerificationProblem => translate('menuVerificationProblem');
  String get addingMenuToBase => translate('addingMenuToBase');
  String get menuReady => translate('menuReady');
  
  // 에러 메시지
  String get errorMissingUserInfo => translate('errorMissingUserInfo');
  String get errorNutrientsCalculation => translate('errorNutrientsCalculation');
  String get errorPreferencesSummary => translate('errorPreferencesSummary');
  String get errorDislikesSummary => translate('errorDislikesSummary');
  String get errorMenuGeneration => translate('errorMenuGeneration');
  
  // 설정 화면 관련 텍스트
  String get settingsTitle => translate('settingsTitle');
  String get languageSettings => translate('languageSettings');
  String get koreanLanguage => translate('koreanLanguage');
  String get englishLanguage => translate('englishLanguage');
  String get closeButton => translate('closeButton');
  
  // 로딩 메시지
  String get loadingUserInfo => translate('loadingUserInfo');
  
  // 설문 화면 관련 텍스트
  String get surveyTitle => translate('surveyTitle');
  String get surveySubtitle => translate('surveySubtitle');
  String get personalInfoTitle => translate('personalInfoTitle');
  String get healthInfoTitle => translate('healthInfoTitle');
  String get foodPreferenceTitle => translate('foodPreferenceTitle');
  String get cookingDataTitle => translate('cookingDataTitle');
  String get reviewTitle => translate('reviewTitle');
  String get nextButton => translate('nextButton');
  String get prevButton => translate('prevButton');
  String get submitButton => translate('submitButton');
  String get ageLabel => translate('ageLabel');
  String get genderLabel => translate('genderLabel');
  String get maleOption => translate('maleOption');
  String get femaleOption => translate('femaleOption');
  String get heightLabel => translate('heightLabel');
  String get weightLabel => translate('weightLabel');
  String get activityLevelLabel => translate('activityLevelLabel');
  String get activityLevel1 => translate('activityLevel1');
  String get activityLevel2 => translate('activityLevel2');
  String get activityLevel3 => translate('activityLevel3');
  String get activityLevel4 => translate('activityLevel4');
  String get activityLevel5 => translate('activityLevel5');
  String get favoriteFoodsLabel => translate('favoriteFoodsLabel');
  String get dislikedFoodsLabel => translate('dislikedFoodsLabel');
  String get allergiesLabel => translate('allergiesLabel');
  String get isVeganLabel => translate('isVeganLabel');
  String get isReligiousLabel => translate('isReligiousLabel');
  String get religionDetailsLabel => translate('religionDetailsLabel');
  String get cookingMethodsLabel => translate('cookingMethodsLabel');
  String get cookingToolsLabel => translate('cookingToolsLabel');
  String get cookingTimeLabel => translate('cookingTimeLabel');
  String get reviewDescription => translate('reviewDescription');
  
  // 프로필 화면 관련 텍스트
  String get profileBasicInfo => translate('profileBasicInfo');
  String get profileAge => translate('profileAge');
  String get profileGender => translate('profileGender');
  String get profileHeight => translate('profileHeight');
  String get profileWeight => translate('profileWeight');
  String get profileActivityLevel => translate('profileActivityLevel');
  String get dietaryRestrictions => translate('dietaryRestrictions');
  String get isVegan => translate('isVegan');
  String get religiousRestrictions => translate('religiousRestrictions');
  String get allergies => translate('allergies');
  String get favoriteFoods => translate('favoriteFoods');
  String get dislikedFoods => translate('dislikedFoods');
  String get preferredFoodAnalysis => translate('preferredFoodAnalysis');
  String get dislikedFoodAnalysis => translate('dislikedFoodAnalysis');
  String get ingredients => translate('ingredients');
  String get seasonings => translate('seasonings');
  String get cookingStyles => translate('cookingStyles');
  String get noAnalysisResults => translate('noAnalysisResults');
  String get analyzeButton => translate('analyzeButton');
  String get reanalyzeButton => translate('reanalyzeButton');
  String get cookingEnvironment => translate('cookingEnvironment');
  String get preferredCookingMethods => translate('preferredCookingMethods');
  String get availableCookingTools => translate('availableCookingTools');
  String get preferredCookingTime => translate('preferredCookingTime');
  String get none => translate('none');
  String get minutes => translate('minutes');
  String get editProfile => translate('editProfile');
  String get yes => translate('yes');
  String get no => translate('no');
  String get analysisDone => translate('analysisDone');
  String get notAnalyzed => translate('notAnalyzed');
  String get analyzingMessage => translate('analyzingMessage');
  String get analysisComplete => translate('analysisComplete');
  String get analysisError => translate('analysisError');
  String get userName => translate('userName');
  String get surveyCompleted => translate('surveyCompleted');
  String get surveyErrorSaving => translate('surveyErrorSaving');
  
  // 버튼 텍스트
  String get cancelButton => translate('cancelButton');
  String get backButton => translate('backButton');
  
  // 설문 화면 다이얼로그 텍스트
  String get backToHomeTitle => translate('backToHomeTitle');
  String get backToHomeContent => translate('backToHomeContent');
  String get homeScreenButton => translate('homeScreenButton');
  String get validationErrorMessage => translate('validationErrorMessage');
  
  // 날짜 관련 텍스트
  String get year => translate('year');
  String get month => translate('month');
  String get previousWeek => translate('previousWeek');
  String get nextWeek => translate('nextWeek');
  List<String> get weekdays => [
    translate('monday'),
    translate('tuesday'),
    translate('wednesday'),
    translate('thursday'),
    translate('friday'),
    translate('saturday'),
    translate('sunday'),
  ];
  List<String> get months => [
    translate('january'),
    translate('february'),
    translate('march'),
    translate('april'),
    translate('may'),
    translate('june'),
    translate('july'),
    translate('august'),
    translate('september'),
    translate('october'),
    translate('november'),
    translate('december'),
  ];
  
  // 식단 베이스 화면 텍스트
  String get mealBaseTitle => translate('mealBaseTitle');
  String get mealBaseSubtitle => translate('mealBaseSubtitle');
  String get searchMealBase => translate('searchMealBase');
  String get sort => translate('sort');
  String get sortByNewest => translate('sortByNewest');
  String get sortByRating => translate('sortByRating');
  String get sortByUsage => translate('sortByUsage');
  String get sortByCalories => translate('sortByCalories');
  String get all => translate('all');
  String get noSearchResults => translate('noSearchResults');
  String get resetSearch => translate('resetSearch');
  
  // 식사 추가 다이얼로그 관련 텍스트
  String get addMealTitle => translate('addMealTitle');
  String get recommendedMenus => translate('recommendedMenus');
  String get selectFromMealBase => translate('selectFromMealBase');
  String get addMealManually => translate('addMealManually');
  String get saveButton => translate('saveButton');
  String get rejectButton => translate('rejectButton');
  String get addButton => translate('addButton');
  String get mealSavedMessage => translate('mealSavedMessage');
  String get mealSaveErrorMessage => translate('mealSaveErrorMessage');
  
  // 식단 삭제 관련 텍스트
  String get deleteMealTitle => translate('deleteMealTitle');
  String get deleteMealConfirm => translate('deleteMealConfirm');
  String get deleteMealSuccess => translate('deleteMealSuccess');
  String get deleteMealError => translate('deleteMealError');
  
  // 메뉴 기각 관련 텍스트
  String get rejectMenuTitle => translate('rejectMenuTitle');
  String get rejectMenuConfirm => translate('rejectMenuConfirm');
  String get rejectMenuSuccess => translate('rejectMenuSuccess');
  
  // 레시피 관련 메시지
  String get loadingRecipe => translate('loadingRecipe');
  String get recipeGenerationFail => translate('recipeGenerationFail');
  String get recipeLoadError => translate('recipeLoadError');
  
  // 추가 메시지
  String get addSuccess => translate('addSuccess');
  String get addFail => translate('addFail');
  String get addTag => translate('addTag');
  String get addTagError => translate('addTagError');
  String get deleteButton => translate('deleteButton');
  
  // 프로필 화면 추가 텍스트
  String get viewInitialSurvey => translate('viewInitialSurvey');
  
  // 설문 화면 추가 텍스트
  String get basicInfoDesc => translate('basicInfoDesc');
  String get healthInfoDesc => translate('healthInfoDesc');
  String get foodPrefDesc => translate('foodPrefDesc');
  String get cookingEnvDesc => translate('cookingEnvDesc');
  String get medicalConditionLabel => translate('medicalConditionLabel');
  String get otherMedicalConditionHint => translate('otherMedicalConditionHint');
  String get otherAllergiesHint => translate('otherAllergiesHint');
  String get otherCookingToolsHint => translate('otherCookingToolsHint');
  String get cookingTimeHint => translate('cookingTimeHint');
  String get cookingTipTitle => translate('cookingTipTitle');
  String get cookingToolTip => translate('cookingToolTip');
  String get cookingTimeTip => translate('cookingTimeTip');
  String get dietaryRestrictionLabel => translate('dietaryRestrictionLabel');
  String get noticeTitle => translate('noticeTitle');
  String get noticeDesc => translate('noticeDesc');
  String get multipleFoodsHint => translate('multipleFoodsHint');
  String get mealPurposeLabel => translate('mealPurposeLabel');
  String get mealPurposeHint => translate('mealPurposeHint');
  
  // 직접 입력 다이얼로그 관련
  String get addMealManuallyTitle => translate('addMealManuallyTitle');
  String get mealNameLabel => translate('mealNameLabel');
  String get mealNameValidation => translate('mealNameValidation');
  String get descriptionLabel => translate('descriptionLabel');
  String get descriptionValidation => translate('descriptionValidation');
  String get caloriesLabel => translate('caloriesLabel');
  
  // 식단 베이스 상세 관련
  String get deleteMealBaseTitle => translate('deleteMealBaseTitle');
  String get deleteMealBaseConfirm => translate('deleteMealBaseConfirm');
  String get deleteMealBaseSuccess => translate('deleteMealBaseSuccess');
  String get deleteMealBaseError => translate('deleteMealBaseError');
  String get addingMealInProgress => translate('addingMealInProgress');
  String get mealAddedToCalendar => translate('mealAddedToCalendar');
  String get mealAddError => translate('mealAddError');
  String get ratingDialogTitle => translate('ratingDialogTitle');
  String get notRated => translate('notRated');
  String get ratingSaved => translate('ratingSaved');
  String get ratingSaveError => translate('ratingSaveError');
  String get tagInputHint => translate('tagInputHint');
  String get tagAdded => translate('tagAdded');
  
  // 레시피 상세 화면 텍스트
  String get recipeDetailTitle => translate('recipeDetailTitle');
  String get saveToMealBase => translate('saveToMealBase');
  String get healthyMeal => translate('healthyMeal');
  String get rating => translate('rating');
  String get cookingTime => translate('cookingTime');
  String get difficultyLevel => translate('difficultyLevel');
  String get difficultyEasy => translate('difficultyEasy');
  String get difficultyMedium => translate('difficultyMedium');
  String get difficultyHard => translate('difficultyHard');
  String get nutritionalInfo => translate('nutritionalInfo');
  String get cookingInstructions => translate('cookingInstructions');
  String get rateRecipe => translate('rateRecipe');
  String get howWasRecipe => translate('howWasRecipe');
  String get submitRating => translate('submitRating');
  String get thankYouRating => translate('thankYouRating');
  String get protein => translate('protein');
  String get carbohydrates => translate('carbohydrates');
  String get fats => translate('fats');
  String get fiber => translate('fiber');
  String get sodium => translate('sodium');
  String get sugar => translate('sugar');
  String get calories => translate('calories');
  String get vitamins => translate('vitamins');
  String get minerals => translate('minerals');
  String get cholesterol => translate('cholesterol');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'ko'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 