// providers/meal_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import

// 각 API 호출을 위한 서비스 import
import '../services/preference_summary_service.dart';
import '../services/nutrient_calculation_service.dart';
import '../services/dislike_summary_service.dart';
import '../services/menu_generation_service.dart';
import '../services/menu_verification_service.dart';

import '../models/user_data.dart';
import '../models/meal.dart';
import '../models/recipe.dart';
import '../providers/survey_data_provider.dart';

class MealProvider with ChangeNotifier {
  // 서비스 인스턴스
  final PreferenceSummaryService _preferenceSummaryService = PreferenceSummaryService();
  final NutrientCalculationService _nutrientCalculationService = NutrientCalculationService();
  final DislikeSummaryService _dislikeSummaryService = DislikeSummaryService();
  final MenuGenerationService _menuGenerationService = MenuGenerationService();
  final MenuVerificationService _menuVerificationService = MenuVerificationService();

  final SurveyDataProvider _surveyDataProvider; // UserData 접근용
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 상태 변수
  String? _currentUserId; // 현재 익명 사용자의 UID
  String? _preferenceSummary;
  String? _dislikeSummary;
  Map<String, dynamic>? _nutrientInfo;
  Map<String, List<SimpleMenu>> _generatedMenuByMealType = {};
  Map<String, dynamic>? _lastGeneratedMenuJson; // 검증 및 재생성을 위한 원본 JSON
  Map<String, String>? _verificationFeedback; // 검증 API 결과 (이상 메뉴 정보)

  List<Meal> _recommendedMeals = []; // HomeScreen UI 호환용 (점차 _generatedMenuByMealType으로 대체)
  Recipe? _currentRecipe; // 상세 보기용 현재 레시피
  bool _isLoadingRecipe = false; // 단일 레시피 로딩 상태
  bool _isLoading = false; // 전체 메뉴 생성 과정 로딩 상태
  String? _progressMessage; // 로딩 중 상세 메시지
  String? _errorMessage;

  // Getters
  String? get preferenceSummary => _preferenceSummary;
  String? get dislikeSummary => _dislikeSummary;
  Map<String, dynamic>? get nutrientInfo => _nutrientInfo;
  Map<String, List<SimpleMenu>> get generatedMenuByMealType => _generatedMenuByMealType;
  List<Meal> get recommendedMeals => _recommendedMeals;
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoadingRecipe => _isLoadingRecipe;
  bool get isLoading => _isLoading;
  String? get progressMessage => _progressMessage;
  String? get errorMessage => _errorMessage;

  // 저장된 식단 데이터
  Map<String, List<Meal>> _savedMealsByDate = {};
  Map<String, List<Meal>> get savedMealsByDate => _savedMealsByDate;

  MenuGenerationService get menuGenerationService => _menuGenerationService;

  MealProvider(this._surveyDataProvider) {
    // 인증 상태 변경 감지
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_currentUserId != user.uid) { // 사용자가 변경되었거나, 처음 로그인한 경우
          _currentUserId = user.uid;
          print("MealProvider: User is signed in with UID - $_currentUserId");
          loadSavedMealsFromFirestore(); // 저장된 식단 로드
        }
      } else {
        _currentUserId = null;
        _savedMealsByDate.clear(); // 로그아웃 시 데이터 초기화
        print("MealProvider: User is signed out. Cleared saved meals.");
        notifyListeners();
      }
    });

    // 초기 사용자 상태 확인
    final User? initialUser = _firebaseAuth.currentUser;
    if (initialUser != null) {
      _currentUserId = initialUser.uid;
      print("MealProvider 초기화: 익명 사용자 UID - $_currentUserId");
      loadSavedMealsFromFirestore();
    } else {
      print("MealProvider 초기화: 익명 사용자를 찾을 수 없음.");
    }
  }

  Future<void> orchestrateMenuGeneration() async {
    // ... (이전 답변의 orchestrateMenuGeneration 메소드 내용과 동일) ...
    // 이 메소드 내부에서 _surveyDataProvider.userData를 사용하여 사용자 정보를 가져옵니다.
    _setLoading(true, "개인 맞춤 메뉴 생성 시작...");
    _clearPreviousResults();
    final UserData userData = _surveyDataProvider.userData;

    try {
      if (userData.age == null || userData.gender == null || userData.height == null || userData.weight == null || userData.activityLevel == null) {
        throw Exception("사용자의 기본 정보(나이, 성별, 키, 체중, 활동량)가 누락되었습니다.");
      }

      _setProgressMessage("일일 권장 영양소 계산 중...");
      _nutrientInfo = await _nutrientCalculationService.calculateNutrients(
        age: userData.age!, gender: userData.gender!, height: userData.height!, weight: userData.weight!, activityLevel: userData.activityLevel!,
      );
      if (_nutrientInfo == null) throw Exception("영양소 계산에 실패했습니다.");
      print("영양소 계산 완료: $_nutrientInfo");
      notifyListeners();

      _setProgressMessage("선호 정보 요약 중...");
      _preferenceSummary = await _preferenceSummaryService.summarizePreferences(
        preferredCookingMethod: userData.preferredCookingMethods,
        preferredIngredients: userData.favoriteFoods,
        preferredSeasonings: [], // TODO: UserData에 선호 양념 필드 추가 시 반영
        desiredCookingTime: userData.preferredCookingTime ?? 30,
        desiredFoodCost: userData.mealBudget ?? 10000,
      );
      if (_preferenceSummary == null) throw Exception("선호 정보 요약에 실패했습니다.");
      print("선호 정보 요약 완료: $_preferenceSummary");
      notifyListeners();

      _setProgressMessage("기피 정보 요약 중...");
      _dislikeSummary = await _dislikeSummaryService.summarizeDislikes(
        cookingTools: userData.availableCookingTools,
        dislikedCookingMethods: [], // TODO: UserData에 기피 조리법 필드 추가 시 반영
        religionDetails: userData.religionDetails,
        veganStatus: userData.isVegan,
        dislikedIngredients: userData.dislikedFoods,
        dislikedSeasonings: [], // TODO: UserData에 기피 양념 필드 추가 시 반영
      );
      if (_dislikeSummary == null) throw Exception("기피 정보 요약에 실패했습니다.");
      print("기피 정보 요약 완료: $_dislikeSummary");
      notifyListeners();

      _setProgressMessage("초기 메뉴 생성 중...");
      Map<String, dynamic>? currentMenuJson = await _menuGenerationService.generateMenu(
        userRecommendedNutrients: _nutrientInfo!,
        summarizedDislikes: _dislikeSummary!,
        summarizedPreferences: _preferenceSummary!,
      );
      if (currentMenuJson == null) throw Exception("초기 메뉴 생성에 실패했습니다.");
      _lastGeneratedMenuJson = currentMenuJson;
      print("초기 메뉴 생성 완료 (JSON): $currentMenuJson");

      int regenerationAttempts = 0;
      const maxRegenerationAttempts = 2;
      _verificationFeedback = null;

      while (regenerationAttempts < maxRegenerationAttempts) {
        _setProgressMessage("메뉴 검증 중 (시도: ${regenerationAttempts + 1})...");
        final verificationResult = await _menuVerificationService.verifyMenu(
          userPreferences: _preferenceSummary!,
          userDislikes: _dislikeSummary!,
          userRecommendedNutrients: _nutrientInfo!,
          customizedDietPlan: currentMenuJson!,
        );
        print("메뉴 검증 결과: $verificationResult");

        if (verificationResult == true || (verificationResult is String && verificationResult.trim().toLowerCase() == 'true')) {
          _setProgressMessage("메뉴 검증 통과!");
          _verificationFeedback = null;
          break;
        } else if (verificationResult is Map<String, dynamic> && verificationResult.isNotEmpty) {
          _verificationFeedback = verificationResult.cast<String, String>()..removeWhere((key, value) => key == "error");
          if (_verificationFeedback!.isEmpty && verificationResult.containsKey("error")) {
            print("검증 API에서 오류 반환: ${verificationResult['error']}");
            _verificationFeedback = null;
            break;
          } else if (_verificationFeedback!.isEmpty) {
            _setProgressMessage("메뉴 검증 결과가 비어있습니다. 현재 메뉴를 사용합니다.");
            _verificationFeedback = null;
            break;
          }
          _setProgressMessage("검증된 피드백으로 메뉴 재 생성 중...");
          currentMenuJson = await _menuGenerationService.generateMenu(
            userRecommendedNutrients: _nutrientInfo!,
            summarizedDislikes: _dislikeSummary!,
            summarizedPreferences: _preferenceSummary!,
            previousMenu: _lastGeneratedMenuJson,
            verificationFeedback: _verificationFeedback,
          );
          if (currentMenuJson == null) throw Exception("메뉴 재 생성에 실패했습니다.");
          _lastGeneratedMenuJson = currentMenuJson;
          print("메뉴 재 생성 완료 (JSON): $currentMenuJson");
        } else {
          _setProgressMessage("메뉴 검증 결과 처리 중 문제 발생. 현재 메뉴를 사용합니다.");
          _verificationFeedback = null;
          break;
        }
        regenerationAttempts++;
      }
      _parseAndSetGeneratedMenu(currentMenuJson);
      _setProgressMessage("맞춤 식단이 준비되었습니다!");
    } catch (e) {
      print("메뉴 오케스트레이션 중 오류: $e");
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      if (_errorMessage == null && _generatedMenuByMealType.isEmpty && _recommendedMeals.isEmpty) {
        _errorMessage = "메뉴를 생성하지 못했습니다. 입력값을 확인하거나 다시 시도해주세요.";
      }
      notifyListeners();
    }
  }

  void _parseAndSetGeneratedMenu(Map<String, dynamic>? menuJson) {
    if (menuJson == null) {
      _generatedMenuByMealType = {};
      _recommendedMeals = [];
      print("_parseAndSetGeneratedMenu: menuJson is null, clearing menus.");
      return;
    }
    print("_parseAndSetGeneratedMenu: Parsing menuJson: $menuJson");
    final Map<String, List<SimpleMenu>> parsedMenu = {};
    menuJson.forEach((mealType, menuList) {
      if (menuList is List && menuList.isNotEmpty) {
        print("Parsing for mealType: $mealType, menuList count: "+menuList.length.toString());
        parsedMenu[mealType] = menuList
            .map((item) {
          try {
            print("  Attempting to parse item for $mealType: $item");
            return SimpleMenu.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print("  메뉴 파싱 오류 (항목: $item): $e");
            return null;
          }
        })
            .where((menu) => menu != null)
            .cast<SimpleMenu>()
            .toList();
      } else {
        parsedMenu[mealType] = [];
        print("No menus or invalid format for mealType: $mealType, menuList: $menuList");
      }
    });
    _generatedMenuByMealType = parsedMenu;
    print("최종 파싱된 메뉴 (SimpleMenu 객체): $_generatedMenuByMealType");
  }

  Future<void> generateRecipe(Meal meal) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _errorMessage = "레시피를 생성하려면 먼저 사용자 정보가 필요합니다 (익명 로그인 확인).";
      notifyListeners();
      return;
    }
    _isLoadingRecipe = true;
    _currentRecipe = null;
    _errorMessage = null;
    notifyListeners();

    final UserData userData = _surveyDataProvider.userData;

    try {
      final Recipe? fetchedRecipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: meal.name,
        userData: userData,
      );

      if (fetchedRecipe != null) {
        _currentRecipe = fetchedRecipe;
      } else {
        _errorMessage = "${meal.name}의 레시피를 가져오지 못했습니다.";
      }
    } catch (e) {
      print("${meal.name} 레시피 생성 중 오류: $e");
      _errorMessage = "레시피 생성 중 오류가 발생했습니다: ${e.toString()}";
    }
    _isLoadingRecipe = false;
    notifyListeners();
  }

  void setCurrentRecipe(Recipe recipe) {
    _currentRecipe = recipe;
    notifyListeners();
  }

  Future<void> loadSavedMealsFromFirestore() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print("사용자 ID가 없어 저장된 식단을 불러올 수 없습니다 (MealProvider).");
      _savedMealsByDate.clear();
      notifyListeners();
      return;
    }
    print("Firestore에서 저장된 식단 로드 시도 (UID: $_currentUserId)");
    try {
      DocumentSnapshot doc = await _firestore.collection('savedUserMeals').doc(_currentUserId!).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _savedMealsByDate.clear();
        data.forEach((dateString, mealListJson) {
          if (mealListJson is List) {
            _savedMealsByDate[dateString] = mealListJson
                .map((mealJson) => Meal.fromJson(mealJson as Map<String, dynamic>))
                .toList();
          }
        });
        print("Firestore에서 저장된 식단 로드 완료.");
      } else {
        print("Firestore에 저장된 식단 없음 (UID: $_currentUserId).");
        _savedMealsByDate.clear();
      }
    } catch (e) {
      print("Firestore에서 저장된 식단 로드 중 오류: $e");
      _savedMealsByDate.clear();
    }
    notifyListeners();
  }

  Future<void> saveMeal(Meal meal, DateTime date) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print("익명 사용자가 없어 식단을 저장할 수 없습니다.");
      return;
    }
    String dateString = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    if (_savedMealsByDate.containsKey(dateString)) {
      if (!_savedMealsByDate[dateString]!.any((m) => m.id == meal.id)) {
        _savedMealsByDate[dateString]!.add(meal);
      }
    } else {
      _savedMealsByDate[dateString] = [meal];
    }
    notifyListeners();

    try {
      Map<String, dynamic> dataToSave = {};
      _savedMealsByDate.forEach((key, value) {
        dataToSave[key] = value.map((m) => m.toJson()).toList();
      });
      await _firestore.collection('savedUserMeals').doc(_currentUserId!).set(dataToSave, SetOptions(merge: true));
      print('저장된 식단이 Firestore에 업데이트되었습니다. (UID: $_currentUserId)');
    } catch (e) {
      print('Firestore에 저장된 식단 업데이트 중 오류: $e');
    }
  }

  void _setLoading(bool loading, String? message) {
    _isLoading = loading;
    _progressMessage = message;
    if (!loading) _progressMessage = null;
    notifyListeners();
  }

  void _setProgressMessage(String message) {
    _progressMessage = message;
    notifyListeners();
  }

  void _clearPreviousResults() {
    _preferenceSummary = null;
    _dislikeSummary = null;
    _nutrientInfo = null;
    _generatedMenuByMealType = {};
    _lastGeneratedMenuJson = null;
    _verificationFeedback = null;
    _recommendedMeals = [];
    _currentRecipe = null;
    _errorMessage = null;
  }

  void clearRecommendations() {
    _clearPreviousResults();
    notifyListeners();
  }

  // rateRecipe, getRatingForRecipe, getSavedMealsForDate는 이전과 동일하게 유지
  Map<String, double> _recipeRatings = {};
  void rateRecipe(String recipeId, double rating) {
    _recipeRatings[recipeId] = rating;
    if (_currentRecipe != null && _currentRecipe!.id == recipeId) {
      _currentRecipe!.rating = rating;
    }
    notifyListeners();
  }
  double? getRatingForRecipe(String recipeId) {
    return _recipeRatings[recipeId];
  }

  List<Meal> getSavedMealsForDate(DateTime date) {
    String dateString = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    return _savedMealsByDate[dateString] ?? [];
  }

  Future<void> generateRecipeFromSimpleMenu(SimpleMenu menu) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _errorMessage = "레시피를 생성하려면 먼저 사용자 정보가 필요합니다 (익명 로그인 확인).";
      notifyListeners();
      return;
    }
    _isLoadingRecipe = true;
    _currentRecipe = null;
    _errorMessage = null;
    notifyListeners();

    final UserData userData = _surveyDataProvider.userData;

    try {
      final Recipe? fetchedRecipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: menu.dishName,
        userData: userData,
      );

      if (fetchedRecipe != null) {
        _currentRecipe = fetchedRecipe;
      } else {
        _errorMessage = "${menu.dishName}의 레시피를 가져오지 못했습니다.";
      }
    } catch (e) {
      print("${menu.dishName} 레시피 생성 중 오류: $e");
      _errorMessage = "레시피 생성 중 오류가 발생했습니다: "+e.toString();
    }
    _isLoadingRecipe = false;
    notifyListeners();
  }

  // 날짜별로 아침/점심/저녁/간식 Map<String, Meal?> 반환
  Map<String, Meal?> getMealsByDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();
    final meals = savedMealsByDate[dateKey] ?? [];
    Map<String, Meal?> result = {
      '아침': null,
      '점심': null,
      '저녁': null,
      '간식': null,
    };
    for (final meal in meals) {
      result[meal.category] = meal;
    }
    return result;
  }

  Future<void> saveSimpleMenuAsMeal(SimpleMenu menu, DateTime date, String mealType) async {
    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: menu.dishName,
      description: menu.description,
      calories: menu.calories,
      date: date,
      category: mealType,
      recipeJson: null,
    );
    await saveMeal(meal, date);
  }
}