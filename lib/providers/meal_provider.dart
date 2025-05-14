// providers/meal_provider.dart
// import 'dart:convert'; // 미사용 임포트 제거
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction; // Firestore import
import 'package:intl/intl.dart'; // DateFormat import 추가

// 각 API 호출을 위한 서비스 import
// import '../services/preference_summary_service.dart';
import '../services/nutrient_calculation_service.dart';
// import '../services/dislike_summary_service.dart';
import '../services/menu_generation_service.dart';
import '../services/menu_verification_service.dart';
import '../services/meal_base_service.dart'; // 식단 베이스 서비스 추가

import '../models/user_data.dart';
import '../models/meal.dart';
import '../models/recipe.dart';
import '../models/meal_base.dart'; // 식단 베이스 모델 추가
import '../models/simple_menu.dart'; // SimpleMenu 모델 추가
import '../utils/meal_type_utils.dart'; // 식단 타입 유틸리티 추가
import '../providers/survey_data_provider.dart'; // SurveyDataProvider 임포트 추가

class MealProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 서비스 인스턴스
  // final PreferenceSummaryService _preferenceSummaryService = PreferenceSummaryService();
  final NutrientCalculationService _nutrientCalculationService = NutrientCalculationService();
  // final DislikeSummaryService _dislikeSummaryService = DislikeSummaryService();
  final MenuGenerationService _menuGenerationService = MenuGenerationService();
  final MenuVerificationService _menuVerificationService = MenuVerificationService();
  final MealBaseService _mealBaseService = MealBaseService();
  
  final SurveyDataProvider _surveyDataProvider; // UserData 접근용

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
  double? _progressPercentage; // 로딩 진행률 (0.0 ~ 1.0)
  String? _errorMessage;

  // 식단 베이스 관련 상태 변수
  List<MealBase> _mealBases = []; // 모든 식단 베이스
  Map<String, List<MealBase>> _mealBasesByCategory = {}; // 카테고리별 식단 베이스
  bool _isLoadingMealBases = false; // 식단 베이스 로딩 상태
  String? _mealBaseErrorMessage; // 식단 베이스 관련 오류 메시지

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
  double? get progressPercentage => _progressPercentage;
  String? get errorMessage => _errorMessage;

  // 식단 베이스 관련 Getters
  List<MealBase> get mealBases => _mealBases;
  Map<String, List<MealBase>> get mealBasesByCategory => _mealBasesByCategory;
  bool get isLoadingMealBases => _isLoadingMealBases;
  String? get mealBaseErrorMessage => _mealBaseErrorMessage;

  // 저장된 식단 데이터
  Map<String, List<Meal>> _savedMealsByDate = {};
  Map<String, List<Meal>> get savedMealsByDate => _savedMealsByDate;

  MenuGenerationService get menuGenerationService => _menuGenerationService;

  bool _isProcessingSave = false; // 저장 작업 진행 중 여부
  bool get isProcessingSave => _isProcessingSave;

  // 진행 메시지와 진행률 설정
  void _setProgressMessage(String message, {double? progressPercentage}) {
    _progressMessage = message;
    _progressPercentage = progressPercentage;
    notifyListeners();
  }

  // 로딩 상태 설정 (진행률 포함)
  void _setLoading(bool loading, String? message, {double? progressPercentage}) {
    _isLoading = loading;
    _progressMessage = message;
    _progressPercentage = progressPercentage;
    if (!loading) {
      _progressMessage = null;
      _progressPercentage = null;
    }
    notifyListeners();
  }

  // 진행 상태 및 메시지 초기화
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
    _progressPercentage = null;
  }

  MealProvider(this._surveyDataProvider) {
    // 인증 상태 변경 감지
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_currentUserId != user.uid) { // 사용자가 변경되었거나, 처음 로그인한 경우
          _currentUserId = user.uid;
          print("MealProvider: User is signed in with UID - $_currentUserId");
          loadSavedMealsFromFirestore(); // 저장된 식단 로드
          loadMealBases(); // 식단 베이스 로드
        }
      } else {
        _currentUserId = null;
        _savedMealsByDate.clear(); // 로그아웃 시 데이터 초기화
        _mealBases.clear(); // 로그아웃 시 식단 베이스 초기화
        _mealBasesByCategory.clear();
        print("MealProvider: User is signed out. Cleared saved meals and meal bases.");
        notifyListeners();
      }
    });

    // 초기 사용자 상태 확인
    final User? initialUser = _auth.currentUser;
    if (initialUser != null) {
      _currentUserId = initialUser.uid;
      print("MealProvider 초기화: 익명 사용자 UID - $_currentUserId");
      loadSavedMealsFromFirestore();
      loadMealBases(); // 식단 베이스 로드
    } else {
      print("MealProvider 초기화: 익명 사용자를 찾을 수 없음.");
    }
  }

  Future<void> orchestrateMenuGeneration() async {
    _setLoading(true, "개인 맞춤 메뉴 생성 시작...", progressPercentage: 0.05);
    _clearPreviousResults();
    final UserData userData = _surveyDataProvider.userData;

    try {
      // 디버그 출력 추가 - 사용자 정보 확인
      print("메뉴 생성 시작 - 사용자 정보: ");
      print("  나이: ${userData.age}");
      print("  성별: ${userData.gender}");
      print("  키: ${userData.height}");
      print("  체중: ${userData.weight}");
      print("  활동량: ${userData.activityLevel}");
      print("  선호 재료: ${userData.favoriteFoods}");
      print("  기피 재료: ${userData.dislikedFoods}");
      print("  선호 조리법: ${userData.preferredCookingMethods}");
      print("  가능한 조리도구: ${userData.availableCookingTools}");
      print("  알레르기: ${userData.allergies}");
      print("  비건 여부: ${userData.isVegan}");
      print("  종교적 제한: ${userData.isReligious ? '있음' : '없음'}");

      if (userData.age == null || userData.gender == null || userData.height == null || userData.weight == null || userData.activityLevel == null) {
        throw Exception("사용자의 기본 정보(나이, 성별, 키, 체중, 활동량)가 누락되었습니다.");
      }

      _setProgressMessage("일일 권장 영양소 계산 중...", progressPercentage: 0.1);
      _nutrientInfo = await _nutrientCalculationService.calculateNutrients(
        age: userData.age!, gender: userData.gender!, height: userData.height!, weight: userData.weight!, activityLevel: userData.activityLevel!,
      );
      if (_nutrientInfo == null) throw Exception("영양소 계산에 실패했습니다.");
      print("영양소 계산 완료: $_nutrientInfo");
      notifyListeners();

      // 캐시된 선호도 정보 사용
      _setProgressMessage("선호 정보 가져오는 중...", progressPercentage: 0.2);
      _preferenceSummary = await _surveyDataProvider.getPreferenceSummary();
      if (_preferenceSummary == null) throw Exception("선호 정보 요약에 실패했습니다.");
      print("선호 정보 요약: $_preferenceSummary");
      notifyListeners();

      // 캐시된 기피 정보 사용
      _setProgressMessage("기피 정보 가져오는 중...", progressPercentage: 0.3);
      _dislikeSummary = await _surveyDataProvider.getDislikeSummary();
      if (_dislikeSummary == null) throw Exception("기피 정보 요약에 실패했습니다.");
      print("기피 정보 요약: $_dislikeSummary");
      notifyListeners();

      _setProgressMessage("초기 메뉴 생성 중...", progressPercentage: 0.4);
      Map<String, dynamic>? currentMenuJson = await _menuGenerationService.generateMenu(
        userRecommendedNutrients: _nutrientInfo!,
        summarizedDislikes: _dislikeSummary!,
        summarizedPreferences: _preferenceSummary!,
        userData: userData, // 사용자 정보 전체를 전달
      );
      
      if (currentMenuJson == null) {
        print("첫 번째 메뉴 생성 시도 실패, 재시도 중...");
        _setProgressMessage("메뉴 생성 재시도 중...", progressPercentage: 0.5);
        
        // 두 번째 시도
        currentMenuJson = await _menuGenerationService.generateMenu(
          userRecommendedNutrients: _nutrientInfo!,
          summarizedDislikes: _dislikeSummary!,
          summarizedPreferences: _preferenceSummary!,
          userData: userData, // 사용자 정보 전체를 전달
        );
        
        if (currentMenuJson == null) {
          throw Exception("초기 메뉴 생성에 실패했습니다. 네트워크 연결을 확인하거나 나중에 다시 시도해 주세요.");
        }
      }
      
      _lastGeneratedMenuJson = currentMenuJson;
      print("초기 메뉴 생성 완료");

      int regenerationAttempts = 0;
      const maxRegenerationAttempts = 2;
      _verificationFeedback = null;

      while (regenerationAttempts < maxRegenerationAttempts) {
        _setProgressMessage("메뉴 검증 중 (시도: ${regenerationAttempts + 1})...", progressPercentage: 0.6 + (regenerationAttempts * 0.1));
        final verificationResult = await _menuVerificationService.verifyMenu(
          userPreferences: _preferenceSummary!,
          userDislikes: _dislikeSummary!,
          userRecommendedNutrients: _nutrientInfo!,
          customizedDietPlan: currentMenuJson!,
          userData: userData, // 사용자 정보 전체를 전달
        );
        
        if (verificationResult == true || (verificationResult is String && verificationResult.trim().toLowerCase() == 'true')) {
          _setProgressMessage("메뉴 검증 통과!", progressPercentage: 0.8);
          _verificationFeedback = null;
          break;
        } else if (verificationResult is Map<String, dynamic> && verificationResult.isNotEmpty) {
          _verificationFeedback = verificationResult.cast<String, String>()..removeWhere((key, value) => key == "error");
          if (_verificationFeedback!.isEmpty && verificationResult.containsKey("error")) {
            print("검증 API에서 오류 반환: ${verificationResult['error']}");
            _verificationFeedback = null;
            break;
          } else if (_verificationFeedback!.isEmpty) {
            _setProgressMessage("메뉴 검증 결과가 비어있습니다. 현재 메뉴를 사용합니다.", progressPercentage: 0.8);
            _verificationFeedback = null;
            break;
          }
          
          regenerationAttempts++;
          _setProgressMessage("검증된 피드백으로 메뉴 재생성 중 (시도: $regenerationAttempts)...", progressPercentage: 0.7 + (regenerationAttempts * 0.05));
          
          // 기존 구현에 맞춰서 메뉴 재생성
          final regeneratedMenuJson = await _menuGenerationService.generateMenu(
            userRecommendedNutrients: _nutrientInfo!,
            summarizedDislikes: _dislikeSummary!,
            summarizedPreferences: _preferenceSummary!,
            previousMenu: _lastGeneratedMenuJson,
            verificationFeedback: _verificationFeedback,
            timeout: Duration(seconds: 30 + (regenerationAttempts * 5)), // 재시도마다 타임아웃 증가
            userData: userData, // 사용자 정보 전체를 전달
          );
          
          if (regeneratedMenuJson != null) {
            currentMenuJson = regeneratedMenuJson;
            _lastGeneratedMenuJson = currentMenuJson;
            print("메뉴 재생성 완료");
          } else {
            print("메뉴 재생성 실패, 원본 메뉴 유지");
            break;
          }
        } else {
          _setProgressMessage("메뉴 검증 결과 처리 중 문제 발생. 현재 메뉴를 사용합니다.", progressPercentage: 0.8);
          _verificationFeedback = null;
          break;
        }
      }
      
      print("최종 메뉴 JSON: $currentMenuJson");
      _parseAndSetGeneratedMenu(currentMenuJson);
      
      // 생성된 메뉴를 자동으로 식단 베이스에 추가
      _setProgressMessage("식단 베이스에 메뉴 추가 중...", progressPercentage: 0.9);
      await _autoSaveMainMenusToMealBase();
      
      _setProgressMessage("맞춤 식단이 준비되었습니다!", progressPercentage: 1.0);
      // 짧은 지연 후에 로딩 표시 해제 (완료 메시지 확인을 위해)
      await Future.delayed(Duration(milliseconds: 800));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("메뉴 생성 오류: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 생성된 메인 메뉴를 자동으로 식단 베이스에 저장하는 메서드
  Future<void> _autoSaveMainMenusToMealBase() async {
    try {
      if (_generatedMenuByMealType.isEmpty) {
        print("저장할 생성된 메뉴가 없습니다.");
        return;
      }
      
      // 각 식사 유형별 메인 메뉴를 식단 베이스에 저장
      final mealTypeMap = {
        'breakfast': '아침',
        'lunch': '점심', 
        'dinner': '저녁'
      };
      
      for (var entry in mealTypeMap.entries) {
        final englishType = entry.key;
        final koreanType = entry.value;
        
        if (_generatedMenuByMealType.containsKey(englishType) && 
            _generatedMenuByMealType[englishType]!.isNotEmpty) {
          // 각 식사 유형의 첫 번째 메뉴만 자동 저장
          final menu = _generatedMenuByMealType[englishType]!.first;
          
          try {
            await saveSimpleMenuToMealBase(
              menu, 
              koreanType, 
              ['자동 생성', '추천 메뉴']
            );
            print("'$koreanType' 메뉴가 자동으로 식단 베이스에 저장되었습니다: ${menu.dishName}");
          } catch (e) {
            print("'$koreanType' 메뉴 자동 저장 중 오류: $e");
            // 개별 메뉴 저장 실패는 전체 프로세스를 중단하지 않음
          }
        }
      }
    } catch (e) {
      print("메뉴 자동 저장 중 오류: $e");
    }
  }

  void _parseAndSetGeneratedMenu(Map<String, dynamic>? menuJson) {
    if (menuJson == null) {
      _generatedMenuByMealType = {};
      _recommendedMeals = [];
      print("_parseAndSetGeneratedMenu: menuJson이 null입니다. 메뉴를 초기화합니다.");
      return;
    }
    
    print("_parseAndSetGeneratedMenu: menuJson 파싱 시작");
    final Map<String, List<SimpleMenu>> parsedMenu = {};
    
    // 필수 카테고리 확인
    final expectedCategories = ['breakfast', 'lunch', 'dinner', 'snacks'];
    bool hasValidStructure = false;
    
    for (var category in expectedCategories) {
      if (menuJson.containsKey(category)) hasValidStructure = true;
    }
    
    if (!hasValidStructure) {
      print("경고: menuJson에 예상 카테고리가 없습니다. JSON 구조: ${menuJson.keys}");
    }
    
    // 각 카테고리별 파싱
    menuJson.forEach((mealType, menuList) {
      if (menuList is List && menuList.isNotEmpty) {
        print("$mealType 카테고리 파싱: ${menuList.length}개 메뉴 항목 발견");
        
        try {
          final List<SimpleMenu> menus = [];
          
          for (int i = 0; i < menuList.length; i++) {
            try {
              dynamic item = menuList[i];
              
              // 데이터 유효성 확인
              if (item is Map<String, dynamic>) {
                // 디버그 정보 로깅
                print("  메뉴 항목 $i 원본 데이터: ${_getShortDebugView(item)}");
                
                // meal_type이 없는 경우 추가
                if (!item.containsKey('meal_type') && !item.containsKey('mealType')) {
                  item['meal_type'] = mealType;
                }
                
                // 필수 필드 확인 및 기본값 설정
                _ensureRequiredFields(item, mealType, i);
                
                // SimpleMenu로 변환
                try {
                  final menu = SimpleMenu.fromJson(item);
                  menus.add(menu);
                  print("  메뉴 파싱 성공: ${menu.dishName}");
                } catch (e) {
                  print("  SimpleMenu 변환 실패, 기본값 사용: $e");
                  
                  // 실패 시 기본 메뉴 항목 추가
                  final defaultMenuItem = SimpleMenu(
                    dishName: item['dish_name']?.toString() ?? "메뉴 ${i + 1}",
                    category: mealType,
                    description: item['description']?.toString() ?? "${mealType} 메뉴입니다.",
                    mealType: mealType,
                  );
                  menus.add(defaultMenuItem);
                }
              } else {
                print("  경고: 메뉴 항목이 Map 형식이 아님: $item (${item.runtimeType})");
                
                // 문자열인 경우 기본 메뉴 생성
                if (item is String && item.isNotEmpty) {
                  final defaultMenuItem = SimpleMenu(
                    dishName: item,
                    category: mealType,
                    description: "$item 메뉴입니다.",
                    mealType: mealType,
                  );
                  menus.add(defaultMenuItem);
                }
              }
            } catch (e) {
              print("  항목 파싱 오류: $e");
            }
          }
          
          parsedMenu[mealType] = menus;
          print("$mealType 카테고리 파싱 완료: ${menus.length}개 메뉴");
        } catch (e) {
          print("$mealType 카테고리 전체 파싱 오류: $e");
          parsedMenu[mealType] = [];
        }
      } else {
        parsedMenu[mealType] = [];
        print("$mealType 카테고리에 메뉴가 없거나 형식이 유효하지 않음: $menuList");
      }
    });
    
    // 필수 카테고리가 비어있는지 확인하고 기본값 추가
    for (var category in expectedCategories) {
      if (!parsedMenu.containsKey(category) || parsedMenu[category]!.isEmpty) {
        print("$category 카테고리가 비어있어 기본 메뉴 추가");
        parsedMenu[category] = _getDefaultMenuForCategory(category);
      }
    }
    
    _generatedMenuByMealType = parsedMenu;
    
    // SimpleMenu에서 Meal 객체로 변환하여 _recommendedMeals 업데이트
    _updateRecommendedMealsFromSimpleMenu();
    
    print("메뉴 파싱 완료: 총 ${_generatedMenuByMealType.length}개 카테고리");
  }
  
  // 디버깅을 위한 짧은 Map 내용 출력 헬퍼
  String _getShortDebugView(Map<String, dynamic> data) {
    final keys = data.keys.join(', ');
    final dishName = data['dish_name'] ?? data['dishName'] ?? '이름 없음';
    return "{keys: [$keys], dish_name: $dishName}";
  }

  // 필수 필드가 누락된 경우 기본값으로 설정
  void _ensureRequiredFields(Map<String, dynamic> item, String mealType, int index) {
    // dish_name 필드 확인
    if (!item.containsKey('dish_name') || item['dish_name'] == null || item['dish_name'].toString().isEmpty) {
      print("  경고: dish_name 필드 누락, 기본값 설정");
      item['dish_name'] = "메뉴 ${index + 1}";
    }
    
    // category 필드 확인
    if (!item.containsKey('category') || item['category'] == null || item['category'].toString().isEmpty) {
      print("  경고: category 필드 누락, 기본값 설정");
      item['category'] = mealType;
    }
    
    // description 필드 확인
    if (!item.containsKey('description') || item['description'] == null || item['description'].toString().isEmpty) {
      print("  경고: description 필드 누락, 기본값 설정");
      item['description'] = "${item['dish_name']} 메뉴입니다.";
    }
    
    // ingredients 필드가 있지만 유효하지 않은 경우 처리
    if (item.containsKey('ingredients') && item['ingredients'] != null) {
      if (!(item['ingredients'] is List) && !(item['ingredients'] is String) && !(item['ingredients'] is Map)) {
        print("  경고: ingredients 필드가 예상 형식이 아님, 기본값 설정");
        item['ingredients'] = [item['dish_name'].toString()];
      }
    }
    
    // 영양 정보 필드 확인 (various formats)
    final nutritionKeys = ['nutrition', 'nutritional_information', 'approximate_nutrients'];
    bool hasNutrition = false;
    
    for (final key in nutritionKeys) {
      if (item.containsKey(key) && item[key] != null) {
        hasNutrition = true;
        break;
      }
    }
    
    // 칼로리 정보 있는지 확인
    if (!item.containsKey('calories') && !hasNutrition) {
      print("  경고: 칼로리/영양 정보 누락, 기본값 설정");
      item['calories'] = "300~500 kcal";
    }
  }
  
  // SimpleMenu에서 Meal 객체로 변환하여 _recommendedMeals 업데이트
  void _updateRecommendedMealsFromSimpleMenu() {
    _recommendedMeals = [];
    
    // 카테고리별로 메뉴 변환
    _generatedMenuByMealType.forEach((category, simpleMenus) {
      for (final simpleMenu in simpleMenus) {
        try {
          // 칼로리 정보 추출
          String calorieInfo = '';
          
          // 1. SimpleMenu의 calories 필드 확인
          if (simpleMenu.calories != null && simpleMenu.calories!.isNotEmpty) {
            calorieInfo = simpleMenu.calories!;
          }
          // 2. nutritionInfo에서 칼로리 정보 확인
          else if (simpleMenu.nutritionInfo != null) {
            final nutritionInfo = simpleMenu.nutritionInfo!;
            final possibleCaloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
            
            for (final key in possibleCaloriesKeys) {
              if (nutritionInfo.containsKey(key) && nutritionInfo[key] != null) {
                calorieInfo = nutritionInfo[key].toString();
                break;
              }
            }
          }
          
          // 칼로리 정보 포맷팅
          if (calorieInfo.isNotEmpty && !calorieInfo.toLowerCase().contains('kcal')) {
            calorieInfo = "$calorieInfo kcal";
          }
          
          // 카테고리 매핑 (영문 -> 한글)
          final mappedCategory = _mapCategoryToKorean(category, simpleMenu.category);
          
          // RecipeJson 준비
          final Map<String, dynamic> recipeJson = {
            'dish_name': simpleMenu.dishName,
            'description': simpleMenu.description,
          };
          
          // 재료 정보 추가
          if (simpleMenu.ingredients != null && simpleMenu.ingredients!.isNotEmpty) {
            recipeJson['ingredients'] = simpleMenu.ingredients;
          }
          
          // 영양 정보 추가
          if (simpleMenu.nutritionInfo != null) {
            recipeJson['nutritional_information'] = simpleMenu.nutritionInfo;
          }
          
          // ID 생성
          final String mealId = '${category}_${_recommendedMeals.length}_${DateTime.now().millisecondsSinceEpoch}';
          
          // Meal 객체 생성 및 추가
          final meal = Meal(
            id: mealId,
            name: simpleMenu.dishName,
            category: mappedCategory,
            description: simpleMenu.description,
            calories: calorieInfo.isNotEmpty ? calorieInfo : '칼로리 정보 없음',
            date: DateTime.now(),
            recipeJson: recipeJson,
          );
          
          _recommendedMeals.add(meal);
        } catch (e) {
          print("SimpleMenu에서 Meal 변환 중 오류: $e");
        }
      }
    });
    
    print("추천 메뉴 리스트 생성 완료: ${_recommendedMeals.length}개 항목");
  }
  
  // 카테고리 영문 -> 한글 매핑
  String _mapCategoryToKorean(String englishCategory, String originalCategory) {
    // 이미 한글인 경우 그대로 사용
    final koreanCategories = ['아침', '점심', '저녁', '간식', '기타'];
    for (final category in koreanCategories) {
      if (originalCategory.contains(category)) {
        return originalCategory;
      }
    }
    
    // 영문 -> 한글 매핑
    final mapping = {
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
      'snack': '간식',
      'snacks': '간식',
      'dessert': '간식',
      'brunch': '브런치',
      'supper': '저녁',
      'other': '기타',
    };
    
    // 1. 원본 카테고리 확인
    if (mapping.containsKey(originalCategory.toLowerCase())) {
      return mapping[originalCategory.toLowerCase()]!;
    }
    
    // 2. 부모 카테고리 확인
    if (mapping.containsKey(englishCategory.toLowerCase())) {
      return mapping[englishCategory.toLowerCase()]!;
    }
    
    // 3. 기본값
    return '기타';
  }

  Future<Recipe?> generateRecipe(Meal meal) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _errorMessage = "레시피를 생성하려면 먼저 사용자 정보가 필요합니다 (익명 로그인 확인).";
      notifyListeners();
      return null;
    }
    
    print("레시피 생성 시도: ${meal.name}");
    print("메뉴 칼로리 정보: ${meal.calories}");
    print("레시피 JSON 존재 여부: ${meal.recipeJson != null ? '있음' : '없음'}");
    _isLoadingRecipe = true;
    _currentRecipe = null;
    _errorMessage = null;
    notifyListeners();

    final UserData userData = _surveyDataProvider.userData;

    try {
      // 이미 저장된 레시피 JSON이 있는지 확인
      if (meal.recipeJson != null && meal.recipeJson!.isNotEmpty) {
        print("레시피 생성 시작: ${meal.name}");
        print("식단 칼로리 정보: ${meal.calories}");
        print("저장된 레시피 JSON 사용: ${meal.name}");
        print("레시피 JSON: ${meal.recipeJson}");
        try {
          // 저장된 JSON에서 레시피 생성 시도
          final Recipe recipe = Recipe.fromJson(meal.recipeJson!);
          print("저장된 레시피 변환 성공: ${recipe.title}");
          print("레시피 세부 정보: 조리 단계: ${recipe.cookingInstructions.length}, 재료: ${recipe.ingredients?.length ?? 0}");
          
          // 저장된 레시피가 정보가 부족한 경우 (조리 단계가 1개만 있거나 재료 정보가 '적당량'만 있는 경우)
          bool needDetailedRecipe = recipe.cookingInstructions.length <= 1 || 
              (recipe.ingredients != null && recipe.ingredients!.values.every((v) => v == '적당량'));
          
          if (needDetailedRecipe) {
            print("저장된 레시피 정보가 불완전하여 API 호출로 보강합니다.");
            // API 호출로 상세 정보 보강 (아래 코드 계속 실행)
          } else {
            // 칼로리 정보가 누락된 경우 meal에서 가져와 추가
            if (recipe.nutritionalInformation == null || !recipe.nutritionalInformation!.containsKey('calories')) {
              print("레시피에 영양 정보가 없어 새로 생성합니다.");
              Map<String, dynamic> nutritionInfo = recipe.nutritionalInformation ?? {};
              
              // meal의 calories 정보가 있으면 추가
              if (meal.calories != null && meal.calories.isNotEmpty && meal.calories != '칼로리 정보 없음') {
                String caloriesValue = meal.calories;
                // kcal 문자열 정리
                if (caloriesValue.contains('kcal')) {
                  caloriesValue = caloriesValue.replaceAll('kcal', '').trim();
                }
                nutritionInfo['calories'] = caloriesValue;
                print("Meal에서 가져온 칼로리 정보: $caloriesValue");
              }
              
              final updatedRecipe = Recipe(
                id: recipe.id,
                mealId: recipe.mealId,
                title: recipe.title,
                costInformation: recipe.costInformation,
                nutritionalInformation: nutritionInfo.isNotEmpty ? nutritionInfo : null,
                ingredients: recipe.ingredients,
                seasonings: recipe.seasonings,
                cookingInstructions: recipe.cookingInstructions,
                cookingTimeMinutes: recipe.cookingTimeMinutes,
                difficulty: recipe.difficulty,
                rating: recipe.rating,
              );
              
              _currentRecipe = updatedRecipe;
            } else {
              _currentRecipe = recipe;
            }
            
            print("레시피 생성 성공: ${recipe.title}");
            print("레시피 세부 정보 - 조리단계: ${recipe.cookingInstructions.length}, 재료: ${recipe.ingredients?.length ?? 0}");
            _isLoadingRecipe = false;
            notifyListeners();
            return _currentRecipe;
          }
        } catch (jsonError) {
          print("저장된 레시피 JSON 변환 실패, API 호출 시도: $jsonError");
          // JSON 변환 실패 시 API 호출로 대체 (아래 계속 진행)
        }
      }

      // API를 통해 레시피 상세 정보 가져오기
      print("메뉴 생성 서비스 API 호출: ${meal.name}");
      Recipe? fetchedRecipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: meal.name,
        userData: userData,
      );

      if (fetchedRecipe != null) {
        print("API에서 레시피 가져오기 성공: ${fetchedRecipe.title}");
        print("API 레시피 세부 정보: 조리 단계: ${fetchedRecipe.cookingInstructions.length}, 재료: ${fetchedRecipe.ingredients?.length ?? 0}");
        
        // 칼로리 정보가 없고 meal에 정보가 있는 경우 추가
        if ((fetchedRecipe.nutritionalInformation == null || 
           !fetchedRecipe.nutritionalInformation!.containsKey('calories')) && 
           meal.calories != null && meal.calories.isNotEmpty && meal.calories != '칼로리 정보 없음') {
          
          Map<String, dynamic> nutritionInfo = fetchedRecipe.nutritionalInformation ?? {};
          String caloriesValue = meal.calories;
          
          // kcal 문자열 정리
          if (caloriesValue.contains('kcal')) {
            caloriesValue = caloriesValue.replaceAll('kcal', '').trim();
          }
          
          nutritionInfo['calories'] = caloriesValue;
          print("Meal에서 가져온 칼로리 정보를 레시피에 추가: $caloriesValue");
          
          fetchedRecipe = Recipe(
            id: fetchedRecipe.id,
            mealId: fetchedRecipe.mealId,
            title: fetchedRecipe.title,
            costInformation: fetchedRecipe.costInformation,
            nutritionalInformation: nutritionInfo,
            ingredients: fetchedRecipe.ingredients,
            seasonings: fetchedRecipe.seasonings,
            cookingInstructions: fetchedRecipe.cookingInstructions,
            cookingTimeMinutes: fetchedRecipe.cookingTimeMinutes,
            difficulty: fetchedRecipe.difficulty,
            rating: fetchedRecipe.rating,
          );
        }
        
        _currentRecipe = fetchedRecipe;
        _isLoadingRecipe = false;
        notifyListeners();
        return fetchedRecipe;
      } else {
        print("API에서 레시피 가져오기 실패: ${meal.name}");
        _errorMessage = "${meal.name}의 레시피를 가져오지 못했습니다.";
        _isLoadingRecipe = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      print("${meal.name} 레시피 생성 중 오류: $e");
      _errorMessage = "레시피 생성 중 오류가 발생했습니다: ${e.toString()}";
      _isLoadingRecipe = false;
      notifyListeners();
      return null;
    }
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
      // 더 단순한 구조: 사용자 ID 필드를 사용하여 필터링
      final QuerySnapshot mealsSnapshot = 
          await _firestore.collection('meals')
                          .where('userId', isEqualTo: _currentUserId)
                          .get();
      
      if (mealsSnapshot.docs.isNotEmpty) {
        _savedMealsByDate.clear();
        
        // 각 Meal 문서를 처리
        for (var doc in mealsSnapshot.docs) {
          final mealData = doc.data() as Map<String, dynamic>;
          if (mealData.containsKey('date')) {
            try {
              // date 필드에서 날짜 문자열 추출
              final DateTime mealDate = DateTime.parse(mealData['date']);
              
              // 일관된 형식으로 날짜 키 생성
              final String dateKey = _getDateKey(mealDate);
              
              // 디버깅을 위한 로그 추가
              print('Meal date parsing - 원본: ${mealData['date']}, 파싱됨: $mealDate, 키: $dateKey');
              
              // Meal 객체 생성 전 유효성 검사
              final meal = Meal.fromJson(mealData);
              if (!_savedMealsByDate.containsKey(dateKey)) {
                _savedMealsByDate[dateKey] = [];
              }
              _savedMealsByDate[dateKey]!.add(meal);
              print('식단 로드됨: ${meal.name}, 날짜: $dateKey, 카테고리: ${meal.category}');
            } catch (e) {
              print('Meal 변환 오류: $e, 데이터: $mealData');
            }
          }
        }
        
        print("Firestore에서 저장된 식단 로드 완료: ${_savedMealsByDate.length} 일자의 식단");
        print("저장된 날짜 목록: ${_savedMealsByDate.keys.join(', ')}");
      } else {
        print("Firestore에 저장된 식단 없음 (UID: $_currentUserId).");
        _savedMealsByDate.clear();
      }
    } catch (e) {
      print("Firestore에서 저장된 식단 로드 중 오류: $e");
      
      // 권한 오류인 경우 로컬 샘플 데이터 생성
      if (e.toString().contains('permission-denied')) {
        print("Firebase 권한 오류로 임시 식단 데이터 생성");
        _createSampleMealData();
      } else {
        // 오류 발생해도 빈 맵으로 초기화하여 앱 기능은 정상 작동하도록 함
        _savedMealsByDate.clear();
      }
    }
    
    notifyListeners();
  }

  // 임시 식단 데이터 생성 (Firebase 연결 불가시 사용)
  void _createSampleMealData() {
    _savedMealsByDate.clear();
    
    // 오늘 날짜 및 전후 날짜용 임시 데이터 생성
    final today = DateTime.now();
    
    // 3일치 샘플 데이터 (오늘, 어제, 내일)
    for (int dayOffset = -1; dayOffset <= 1; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final dateKey = _getDateKey(date);
      
      // 각 날짜별 1-3개 식단 생성
      _savedMealsByDate[dateKey] = [];
      
      // 식사 종류
      final mealTypes = ['아침', '점심', '저녁'];
      for (int i = 0; i < 3; i++) {
        // 랜덤하게 일부 식사는 추가하지 않음
        if (dayOffset != 0 && i % 2 == 0) continue;
        
        _savedMealsByDate[dateKey]!.add(
          Meal(
            id: 'sample_${dateKey}_${i}',
            name: '로컬 ${mealTypes[i]} 메뉴 ${i+1}',
            description: '로컬에서 생성된 임시 식단 데이터입니다.',
            calories: '약 ${300 + i * 150}kcal',
            date: date,
            category: mealTypes[i],
            recipeJson: null,
          )
        );
      }
    }
  }

  Future<void> saveMeal(Meal meal, DateTime date) async {
    // 이미 저장 처리 중이면 중복 호출 방지
    if (_isProcessingSave) {
      print("⚠️ 이미 식단 저장 작업이 진행 중입니다. 중복 요청 무시.");
      return;
    }
    
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print("⚠️ 익명 사용자가 없어 식단을 저장할 수 없습니다.");
      _errorMessage = "사용자 인증이 필요합니다.";
      notifyListeners();
      return;
    }
    
    // 저장 상태 설정
    _isProcessingSave = true;
    _errorMessage = null; // 이전 오류 메시지 초기화
    try {
      // 날짜 문자열 포맷 수정 - 일관된 날짜 형식 사용
      String dateString = _getDateKey(date);
      print("저장할 날짜: $dateString, 원본 날짜: ${date.toString()}");
      print("현재 저장된 날짜 키 목록: ${_savedMealsByDate.keys.join(', ')}");
      
      // Firestore에 먼저 저장 (주요 저장소)
      print("Firestore에 식단 저장 시작: meals/${meal.id}");
      
      // 단순화된 컬렉션 구조로 저장
      final Map<String, dynamic> dataToSave = meal.toJson();
      
      // Firebase에 저장하기 위한 추가 필드
      dataToSave['userId'] = _currentUserId; // 사용자 ID 추가
      
      // 날짜 필드 확인 및 보정
      if (!dataToSave.containsKey('date') || dataToSave['date'] == null) {
        print("⚠️ 날짜 필드가 없거나 null입니다. 현재 날짜로 설정합니다.");
        dataToSave['date'] = date.toIso8601String();
      }
      
      // 현재 카테고리가 설정되어 있는지 확인
      if (!dataToSave.containsKey('category') || dataToSave['category'] == null || dataToSave['category'].toString().isEmpty) {
        print("⚠️ 카테고리 필드가 없거나 비어있습니다. 기본값으로 설정합니다.");
        dataToSave['category'] = '기타';
      }
      
      // 칼로리 정보 확인 및 개선
      if (!dataToSave.containsKey('calories') || dataToSave['calories'] == null || dataToSave['calories'].toString().isEmpty) {
        print("⚠️ 칼로리 정보가 없습니다. 기본값으로 설정합니다.");
        dataToSave['calories'] = '칼로리 정보 없음';
      } else {
        print("ℹ️ 식단 칼로리 정보: ${dataToSave['calories']}");
        
        // 숫자만 있는 경우 'kcal' 추가
        String caloriesStr = dataToSave['calories'].toString();
        if (caloriesStr.isNotEmpty && 
            !caloriesStr.toLowerCase().contains('kcal') && 
            !caloriesStr.toLowerCase().contains('칼로리') &&
            !caloriesStr.contains('정보 없음')) {
          dataToSave['calories'] = '$caloriesStr kcal';
          print("🔄 칼로리 정보 보정: ${dataToSave['calories']}");
        }
      }
      
      // 레시피 정보 확인 및 개선
      if (dataToSave.containsKey('recipeJson') && dataToSave['recipeJson'] != null) {
        final recipeJson = dataToSave['recipeJson'] as Map<String, dynamic>;
        print("ℹ️ 레시피 정보 포함됨 (키 수: ${recipeJson.length})");
        
        // 요리 시간이 없는 경우 기본값 설정
        if (!recipeJson.containsKey('cookingTimeMinutes') && !recipeJson.containsKey('cooking_time_minutes')) {
          // 요리 시간 추정 - 카테고리별 기본값
          int defaultTime = 30; // 기본 30분
          final category = dataToSave['category'].toString().toLowerCase();
          if (category.contains('아침')) defaultTime = 20;
          else if (category.contains('점심')) defaultTime = 30;
          else if (category.contains('저녁')) defaultTime = 40;
          else if (category.contains('간식')) defaultTime = 15;
          
          recipeJson['cookingTimeMinutes'] = defaultTime;
          print("🔄 요리 시간 기본값 설정: $defaultTime 분");
        }
        
        // 난이도가 없는 경우 기본값 설정
        if (!recipeJson.containsKey('difficulty')) {
          recipeJson['difficulty'] = '보통';
          print("🔄 난이도 기본값 설정: 보통");
        }
        
        // 조리 지침이 없거나 부족한 경우 템플릿 제공
        if (!recipeJson.containsKey('cooking_instructions') || 
            recipeJson['cooking_instructions'] == null ||
            (recipeJson['cooking_instructions'] is List && (recipeJson['cooking_instructions'] as List).length <= 1)) {
          recipeJson['cooking_instructions'] = [
            "1. 재료를 준비합니다.",
            "2. 재료를 손질합니다.",
            "3. 조리합니다.",
            "4. 완성된 요리를 그릇에 담아 제공합니다."
          ];
          print("🔄 조리 지침 기본 템플릿 추가");
        }
        
        // 재료 정보가 모두 '적당량'인 경우 개선
        if (recipeJson.containsKey('ingredients') && recipeJson['ingredients'] is Map) {
          final ingredients = recipeJson['ingredients'] as Map;
          bool allDefaultQuantity = true;
          ingredients.forEach((k, v) {
            if (v != '적당량') allDefaultQuantity = false;
          });
          
          if (allDefaultQuantity && ingredients.length > 0) {
            // 재료마다 다른 양 지정
            List<String> defaultQuantities = ['1개', '100g', '1/2개', '1/4개', '1컵', '2큰술', '1작은술'];
            int index = 0;
            Map<String, String> updatedIngredients = {};
            
            ingredients.forEach((k, v) {
              updatedIngredients[k.toString()] = defaultQuantities[index % defaultQuantities.length];
              index++;
            });
            
            recipeJson['ingredients'] = updatedIngredients;
            print("🔄 재료 수량 정보 개선");
          }
        }
        
        // 수정된 recipeJson 저장
        dataToSave['recipeJson'] = recipeJson;
      } else {
        print("⚠️ 레시피 정보가 없습니다.");
      }
      
      // Firestore 저장 전 로그
      print("Firestore 저장 데이터: $dataToSave");
      
      // 데이터 저장 시도
      try {
        await _firestore
            .collection('meals')
            .doc(meal.id)
            .set(dataToSave);
        
        print('✅ 식단이 Firestore에 성공적으로 저장되었습니다: ${meal.name} (UID: $_currentUserId, 문서ID: ${meal.id})');
        
        // 확인을 위해 바로 다시 읽기 시도
        try {
          final docSnapshot = await _firestore.collection('meals').doc(meal.id).get();
          if (docSnapshot.exists) {
            print('✅ 저장 확인 성공: Firestore에 문서가 정상적으로 생성되었습니다.');
            
            // Firestore 저장이 성공한 후 메모리에 저장
            if (_savedMealsByDate.containsKey(dateString)) {
              // 같은 카테고리가 있는지 확인하고 기존 항목 교체
              int existingIndex = -1;
              for (int i = 0; i < _savedMealsByDate[dateString]!.length; i++) {
                if (_savedMealsByDate[dateString]![i].category == meal.category) {
                  existingIndex = i;
                  break;
                }
              }
              
              if (existingIndex >= 0) {
                // 같은 카테고리의 기존 식단이 있으면 교체
                print("기존 날짜($dateString)에 동일 카테고리(${meal.category})의 식단이 있어 교체합니다.");
                _savedMealsByDate[dateString]![existingIndex] = meal;
              } else {
                // 같은 카테고리가 없으면 추가
                _savedMealsByDate[dateString]!.add(meal);
                print("기존 날짜($dateString)에 새 식단 추가됨. 총 ${_savedMealsByDate[dateString]!.length}개");
              }
            } else {
              _savedMealsByDate[dateString] = [meal];
              print("새 날짜($dateString)에 첫번째 식단 추가됨");
            }
            
            // 디버깅 정보 출력
            print("현재 저장된 식단 정보:");
            _savedMealsByDate.forEach((date, meals) {
              print("  $date: ${meals.length}개 식단");
              for (var m in meals) {
                print("    - ${m.name} (${m.category}) 칼로리: ${m.calories}");
              }
            });
          } else {
            print('⚠️ 저장 확인 실패: 문서가 존재하지 않습니다!');
            throw Exception('저장된 문서를 확인할 수 없습니다.');
          }
        } catch (verifyError) {
          print('⚠️ 저장 확인 중 오류: $verifyError');
          // 저장은 성공했지만 확인에 실패한 경우 (애매한 상태)
          // 메모리에 저장을 시도해 볼 수 있음
          if (!_savedMealsByDate.containsKey(dateString)) {
            _savedMealsByDate[dateString] = [];
          }
          _savedMealsByDate[dateString]!.add(meal);
        }
      } catch (firestoreError) {
        print('❌ Firestore에 식단 저장 실패: $firestoreError');
        throw Exception('Firestore 저장 실패: $firestoreError');
      }
      
      notifyListeners(); // UI 업데이트
      print("UI 갱신을 위한 notifyListeners() 호출 완료");
    } catch (e) {
      print('❌ 식단 저장 중 오류 발생: $e');
      _errorMessage = '식단 저장에 실패했습니다: $e';
      // notifyListeners()는 finally 블록에서 호출
    } finally {
      // 저장 상태 초기화
      _isProcessingSave = false;
      notifyListeners(); // 상태가 변경되었으므로 리스너에게 알림
    }
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
    String dateString = _getDateKey(date);
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

  // 일관된 날짜 키 생성을 위한 헬퍼 메소드
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 날짜별로 아침/점심/저녁/간식 Map<String, Meal?> 반환
  Map<String, Meal?> getMealsByDate(DateTime date) {
    // 표준화된 날짜 키 형식 사용
    final dateString = _getDateKey(date);
    
    print("getMealsByDate 호출됨: $dateString");
    
    // 저장된 식단 정보 확인
    if (_savedMealsByDate.isEmpty) {
      print("  저장된 식단 정보가 없습니다.");
    } else {
      print("  저장된 날짜 키 목록: ${_savedMealsByDate.keys.join(', ')}");
      print("  찾는 날짜 키: $dateString");
    }
    
    final meals = _savedMealsByDate[dateString] ?? [];
    print("  찾은 식단 수: ${meals.length}");
    
    Map<String, Meal?> result = {
      '아침': null,
      '점심': null,
      '저녁': null,
      '간식': null,
      '기타': null,
    };
    
    for (final meal in meals) {
      print("  식단 정보: ${meal.id}, ${meal.name}, ${meal.category}");
      if (result.containsKey(meal.category)) {
        result[meal.category] = meal;
      } else {
        print("  경고: 알 수 없는 카테고리 - ${meal.category}, 식단 ID: ${meal.id}");
        result['기타'] = meal;
      }
    }
    
    return result;
  }

  Future<void> saveMealFromMealBase(MealBase mealBase, DateTime date) async {
    // 이미 저장 작업이 진행 중인지 확인
    if (_isProcessingSave) {
      print("⚠️ 이미 식단 저장 작업이 진행 중입니다. 중복 요청 무시.");
      return;
    }
    
    // 저장 상태 설정
    _isProcessingSave = true;
    notifyListeners(); // UI에 작업 시작을 알림
    
    try {
      print("식단 베이스에서 캘린더로 저장 시작: ${mealBase.name}, 날짜: ${_getDateKey(date)}");
      print("식단 베이스 칼로리 정보: ${mealBase.calories}");
      print("식단 베이스 레시피 JSON: ${mealBase.recipeJson != null ? '있음' : '없음'}");
      
      // 1. 사용 횟수 증가 - 실패해도 계속 진행
      try {
        await _mealBaseService.incrementUsageCount(mealBase.id);
      } catch (e) {
        print("사용 횟수 증가 실패 (무시하고 계속 진행): $e");
        // 사용 횟수 증가는 중요하지 않으므로 실패해도 계속 진행
      }
      
      // 2. MealBase에서 Meal로 변환
      final String caloriesValue = mealBase.calories != null && mealBase.calories!.isNotEmpty 
          ? mealBase.calories! 
          : "칼로리 정보 없음";
      
      // 레시피 JSON 변환 및 개선
      Map<String, dynamic>? recipeJsonData;
      if (mealBase.recipeJson != null) {
        // 기존 레시피 JSON 복사
        recipeJsonData = Map<String, dynamic>.from(mealBase.recipeJson!);
        
        // 필수 정보 확인 및 추가
        if (!recipeJsonData.containsKey('dish_name') || recipeJsonData['dish_name'] == null) {
          recipeJsonData['dish_name'] = mealBase.name;
        }
        
        if (!recipeJsonData.containsKey('description') && mealBase.description != null) {
          recipeJsonData['description'] = mealBase.description;
        }
        
        // 칼로리 정보 추가 (영양 정보가 있는 경우)
        if (caloriesValue.isNotEmpty && caloriesValue != '칼로리 정보 없음') {
          if (!recipeJsonData.containsKey('nutritional_information')) {
            recipeJsonData['nutritional_information'] = {};
          }
          if (recipeJsonData['nutritional_information'] is Map) {
            Map<String, dynamic> nutritionInfo = recipeJsonData['nutritional_information'] as Map<String, dynamic>;
            if (!nutritionInfo.containsKey('calories')) {
              nutritionInfo['calories'] = caloriesValue.replaceAll('kcal', '').trim();
              print("레시피 JSON에 칼로리 정보 추가: ${nutritionInfo['calories']}");
            }
          }
        }
        
        // 요리 시간이 없는 경우 추가
        if (!recipeJsonData.containsKey('cookingTimeMinutes') && !recipeJsonData.containsKey('cooking_time_minutes')) {
          // 카테고리별 기본값 설정
          int defaultTime = 30; // 기본 30분
          final category = mealBase.category.toLowerCase();
          if (category.contains('아침')) defaultTime = 20;
          else if (category.contains('점심')) defaultTime = 30;
          else if (category.contains('저녁')) defaultTime = 40;
          else if (category.contains('간식')) defaultTime = 15;
          
          recipeJsonData['cookingTimeMinutes'] = defaultTime;
          print("레시피 JSON에 요리 시간 추가: $defaultTime 분");
        }
      }
      
      final Meal meal = Meal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: mealBase.name,
        description: mealBase.description ?? "설명 없음",
        calories: caloriesValue,
        date: date,
        category: mealBase.category,
        recipeJson: recipeJsonData,
      );
      
      print("생성된 Meal 객체 정보 - 칼로리: ${meal.calories}, 레시피 JSON: ${meal.recipeJson != null ? '있음' : '없음'}");
      
      // 3. 식단 저장
      await saveMeal(meal, date);
      
      print("식단 베이스에서 식단이 저장되었습니다: ${mealBase.name}");
      print("캘린더에 식단이 추가되었습니다: ${meal.name}");
    } catch (e) {
      print("식단 베이스에서 식단 저장 중 오류: $e");
      _errorMessage = "식단 저장에 실패했습니다: $e";
    } finally {
      _isProcessingSave = false;
      notifyListeners();
    }
  }

  // 메뉴 기각 사유 저장
  Future<void> rejectMenu(SimpleMenu menu, String category, String reason, String details) async {
    try {
      // SimpleMenu로부터 MealBase 생성
      final String mealBaseId = DateTime.now().millisecondsSinceEpoch.toString();
      final MealBase mealBase = MealBase(
        id: mealBaseId,
        userId: _currentUserId ?? '', // 현재 사용자 ID 추가
        name: menu.dishName,
        description: menu.description,
        category: category, // 직접 카테고리 매개변수 사용
        rejectionReasons: [
          RejectionReason(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            reason: reason,
            details: details,
            timestamp: DateTime.now(),
          )
        ],
        createdAt: DateTime.now(),
        usageCount: 0,
      );
      
      // 식단 베이스에 저장
      await _mealBaseService.saveMealBase(mealBase);
      
      // 메모리에 추가
      _mealBases.add(mealBase);
      if (_mealBasesByCategory.containsKey(category)) {
        _mealBasesByCategory[category]!.add(mealBase);
      }
      
      notifyListeners();
      print("기각된 메뉴가 식단 베이스에 저장되었습니다: ${menu.dishName}");
    } catch (e) {
      print("메뉴 기각 저장 중 오류: $e");
      throw Exception("메뉴 기각 저장에 실패했습니다: $e");
    }
  }
  
  // 식단 베이스 삭제
  Future<void> deleteMealBase(MealBase mealBase) async {
    try {
      await _mealBaseService.deleteMealBase(mealBase.id);
      
      // 메모리에서 삭제
      _mealBases.removeWhere((base) => base.id == mealBase.id);
      for (var category in _mealBasesByCategory.keys) {
        _mealBasesByCategory[category]?.removeWhere((base) => base.id == mealBase.id);
      }
      
      notifyListeners();
      print("식단 베이스에서 삭제되었습니다: ${mealBase.name}");
    } catch (e) {
      print("식단 베이스 삭제 중 오류: $e");
      throw Exception("식단 베이스 삭제에 실패했습니다: $e");
    }
  }
  
  // 식단 베이스 평가
  Future<void> rateMealBase(String mealBaseId, double rating) async {
    try {
      await _mealBaseService.rateMealBase(mealBaseId, rating);
      
      // 메모리 업데이트
      final baseIndex = _mealBases.indexWhere((base) => base.id == mealBaseId);
      if (baseIndex != -1) {
        _mealBases[baseIndex].rating = rating;
      }
      
      for (var category in _mealBasesByCategory.keys) {
        final index = _mealBasesByCategory[category]?.indexWhere((base) => base.id == mealBaseId) ?? -1;
        if (index != -1) {
          _mealBasesByCategory[category]![index].rating = rating;
        }
      }
      
      notifyListeners();
      print("식단 베이스 평가가 저장되었습니다: $mealBaseId (평점: $rating)");
    } catch (e) {
      print("식단 베이스 평가 저장 중 오류: $e");
      throw Exception("식단 베이스 평가 저장에 실패했습니다: $e");
    }
  }
  
  // 태그 관리
  Future<void> addTagToMealBase(String mealBaseId, String tag) async {
    try {
      await _mealBaseService.addTagToMealBase(mealBaseId, tag);
      
      // 메모리 업데이트
      for (var mealBase in _mealBases) {
        if (mealBase.id == mealBaseId) {
          mealBase.tags ??= [];
          if (!mealBase.tags!.contains(tag)) {
            mealBase.tags!.add(tag);
          }
          break;
        }
      }
      
      for (var category in _mealBasesByCategory.keys) {
        for (var mealBase in _mealBasesByCategory[category] ?? []) {
          if (mealBase.id == mealBaseId) {
            mealBase.tags ??= [];
            if (!mealBase.tags!.contains(tag)) {
              mealBase.tags!.add(tag);
            }
            break;
          }
        }
      }
      
      notifyListeners();
      print("식단 베이스에 태그가 추가되었습니다: $mealBaseId (태그: $tag)");
    } catch (e) {
      print("식단 베이스 태그 추가 중 오류: $e");
      throw Exception("식단 베이스 태그 추가에 실패했습니다: $e");
    }
  }
  
  Future<void> removeTagFromMealBase(String mealBaseId, String tag) async {
    try {
      await _mealBaseService.removeTagFromMealBase(mealBaseId, tag);
      
      // 메모리 업데이트
      for (var mealBase in _mealBases) {
        if (mealBase.id == mealBaseId && mealBase.tags != null) {
          mealBase.tags!.remove(tag);
          break;
        }
      }
      
      for (var category in _mealBasesByCategory.keys) {
        for (var mealBase in _mealBasesByCategory[category] ?? []) {
          if (mealBase.id == mealBaseId && mealBase.tags != null) {
            mealBase.tags!.remove(tag);
            break;
          }
        }
      }
      
      notifyListeners();
      print("식단 베이스에서 태그가 제거되었습니다: $mealBaseId (태그: $tag)");
    } catch (e) {
      print("식단 베이스 태그 제거 중 오류: $e");
      throw Exception("식단 베이스 태그 제거에 실패했습니다: $e");
    }
  }
  
  // 태그로 식단 베이스 검색
  Future<List<MealBase>> searchMealBasesByTag(String tag) async {
    try {
      return await _mealBaseService.searchMealBasesByTag(tag);
    } catch (e) {
      print("태그로 식단 베이스 검색 중 오류: $e");
      return [];
    }
  }
  
  // 텍스트로 식단 베이스 검색
  Future<List<MealBase>> searchMealBasesByText(String query) async {
    try {
      return await _mealBaseService.searchMealBasesByText(query);
    } catch (e) {
      print("텍스트로 식단 베이스 검색 중 오류: $e");
      return [];
    }
  }
  
  // 인기 태그 가져오기
  Future<Map<String, int>> getPopularTags({int limit = 10}) async {
    try {
      return await _mealBaseService.getPopularTags(limit: limit);
    } catch (e) {
      print("인기 태그 가져오기 중 오류: $e");
      return {};
    }
  }
  
  // 식단을 캘린더에 추가
  Future<void> addMealToCalendar({
    required DateTime date,
    required String category,
    required String name,
    required String description,
    String? calories,
    Map<String, dynamic>? recipeJson,
  }) async {
    try {
      // 카테고리 유효성 검사 및 표준화
      final validCategory = standardizeCategory(category);
      
      // 식단 ID 생성 (현재 시간 기준)
      final String mealId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // 식단 생성
      final Meal meal = Meal(
        id: mealId,
        name: name,
        description: description,
        category: validCategory,
        date: date,
        calories: calories ?? '',
        recipeJson: recipeJson,
      );
      
      // 식단 저장
      await saveMeal(meal, date);
      
      print('캘린더에 식단이 추가되었습니다: $name');
    } catch (e) {
      print('캘린더에 식단 추가 중 오류: $e');
      throw Exception('식단 추가에 실패했습니다: $e');
    }
  }

  // 불필요한 문자열 보간식 수정
  void _logMealAction(String action, String mealId) {
    print("Meal action: $action - ID: $mealId");
  }

  // 식단 베이스 로드
  Future<void> loadMealBases() async {
    if (_currentUserId == null) {
      print("식단 베이스를 로드할 사용자가 없습니다.");
      return;
    }
    
    _isLoadingMealBases = true;
    _mealBaseErrorMessage = null;
    notifyListeners();
    
    try {
      // 모든 식단 베이스 로드
      _mealBases = await _mealBaseService.getAllMealBases();
      
      // 카테고리별로 식단 베이스 분류
      _mealBasesByCategory = {
        '아침': [],
        '점심': [],
        '저녁': [],
        '간식': [],
      };
      
      for (var mealBase in _mealBases) {
        if (_mealBasesByCategory.containsKey(mealBase.category)) {
          _mealBasesByCategory[mealBase.category]!.add(mealBase);
        }
      }
      
      print("식단 베이스 로드 완료: ${_mealBases.length}개의 식단");
    } catch (e) {
      print("식단 베이스 로드 중 오류: $e");
      
      // 권한 오류인 경우 기본 데이터 생성 (이미 meal_base_service에서 처리함)
      if (!e.toString().contains('permission-denied')) {
        _mealBaseErrorMessage = e.toString();
      }
    } finally {
      _isLoadingMealBases = false;
      notifyListeners();
    }
  }

  // SimpleMenu를 식단 베이스로 저장
  Future<void> saveSimpleMenuToMealBase(SimpleMenu menu, String category, [List<String>? tags]) async {
    try {
      // 레시피 상세 정보 로드 시도
      final Recipe? recipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: menu.dishName,
        userData: _surveyDataProvider.userData,
      );
      
      // 칼로리 정보 추출
      String? caloriesValue;
      
      // 레시피에서 칼로리 정보 추출 시도
      if (recipe != null && recipe.nutritionalInformation != null) {
        // 'calories' 또는 유사한 키를 찾음
        final caloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
        for (final key in caloriesKeys) {
          if (recipe.nutritionalInformation!.containsKey(key)) {
            caloriesValue = recipe.nutritionalInformation![key].toString();
            print("레시피에서 칼로리 정보 추출: $caloriesValue");
            break;
          }
        }
      }
      
      // SimpleMenu에서 칼로리 정보가 있으면 사용
      if (caloriesValue == null && menu.calories != null && menu.calories!.isNotEmpty) {
        caloriesValue = menu.calories;
        print("SimpleMenu에서 칼로리 정보 추출: $caloriesValue");
      }
      
      // 영양 정보에서 칼로리 정보 추출 시도
      if (caloriesValue == null && menu.nutritionInfo != null) {
        final caloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
        for (final key in caloriesKeys) {
          if (menu.nutritionInfo!.containsKey(key)) {
            caloriesValue = menu.nutritionInfo![key].toString();
            print("영양 정보에서 칼로리 정보 추출: $caloriesValue");
            break;
          }
        }
      }
      
      // 최종 칼로리 정보 포맷팅
      if (caloriesValue != null) {
        if (!caloriesValue.toLowerCase().contains('kcal')) {
          caloriesValue = "$caloriesValue kcal";
        }
      }
      
      // MealBase 모델 생성
      final String mealBaseId = DateTime.now().millisecondsSinceEpoch.toString();
      final MealBase mealBase = MealBase(
        id: mealBaseId,
        userId: _currentUserId ?? '', // 현재 사용자 ID 추가
        name: recipe != null ? recipe.title : menu.dishName,
        description: menu.description,
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
        usageCount: 0,
        recipeJson: recipe?.toJson(),
        calories: caloriesValue,
      );
      
      // 식단 베이스에 저장
      await _mealBaseService.saveMealBase(mealBase);
      
      // 메모리에 추가
      _mealBases.add(mealBase);
      if (_mealBasesByCategory.containsKey(category)) {
        _mealBasesByCategory[category]!.add(mealBase);
      }
      
      notifyListeners();
      print("메뉴가 식단 베이스에 저장되었습니다: ${menu.dishName}, 칼로리: $caloriesValue");
    } catch (e) {
      print("메뉴를 식단 베이스에 저장하는 중 오류: $e");
      throw Exception("메뉴 저장에 실패했습니다: $e");
    }
  }

  // 레시피 상세 정보 로드 메소드
  Future<Recipe?> loadRecipeDetails(String dishName) async {
    try {
      final userData = _surveyDataProvider.userData;
      return await _menuGenerationService.getSingleRecipeDetails(
        mealName: dishName,
        userData: userData,
      );
    } catch (e) {
      print('Error loading recipe details: $e');
      return null;
    }
  }

  // 식단 삭제 메소드
  Future<void> removeMeal(Meal meal, DateTime date) async {
    final dateKey = _getDateKey(date);
    
    try {
      // 메모리에서 삭제
      if (_savedMealsByDate.containsKey(dateKey)) {
        _savedMealsByDate[dateKey]?.removeWhere((m) => m.id == meal.id);
        notifyListeners();
      }
      
      // Firebase 문서 존재 여부 먼저 확인
      try {
        final docSnapshot = await _firestore
            .collection('meals')
            .doc(meal.id)
            .get();
            
        if (docSnapshot.exists) {
          // Firestore에서 삭제 - 단순화된 구조 사용
          await _firestore
              .collection('meals')
              .doc(meal.id)
              .delete();
              
          print('식단이 Firestore에서 삭제되었습니다: ${meal.name}');
        } else {
          print('삭제할 식단 문서가 Firestore에 존재하지 않습니다: ${meal.id}');
          // 문서가 없어도 메모리에서는 이미 제거됐으므로 성공으로 간주
        }
      } catch (firestoreError) {
        print('Firestore 연결 오류, 메모리에서만 삭제합니다: $firestoreError');
        // Firestore 오류가 발생해도 UI에는 삭제된 상태로 표시
      }
    } catch (e) {
      print('식단 삭제 중 오류: $e');
      throw Exception('식단 삭제에 실패했습니다: $e');
    }
  }

  // 레시피를 식단 베이스에 저장
  Future<void> saveRecipeToMealBase(Recipe recipe, String category, List<String>? tags, String? calories) async {
    try {
      print('레시피를 식단 베이스에 저장 시작: ${recipe.title}, 카테고리: $category');
      
      // MealBase 객체 생성
      final String mealBaseId = DateTime.now().millisecondsSinceEpoch.toString();
      final Map<String, dynamic> recipeJson = recipe.toJson();
      
      // 디버깅 정보
      print('레시피 JSON 생성: ${recipeJson.keys.join(', ')}');
      print('칼로리 정보: $calories');
      
      // MealBase 모델 생성
      final MealBase mealBase = MealBase(
        id: mealBaseId,
        userId: _currentUserId ?? '', // 현재 사용자 ID 추가
        name: recipe.title,
        description: '직접 저장한 레시피',
        category: category,
        tags: tags,
        createdAt: DateTime.now(),
        usageCount: 0,
        recipeJson: recipeJson,
        calories: calories,
      );
      
      // 식단 베이스에 저장
      await _mealBaseService.saveMealBase(mealBase);
      
      // 메모리에 추가
      _mealBases.add(mealBase);
      if (_mealBasesByCategory.containsKey(category)) {
        _mealBasesByCategory[category]!.add(mealBase);
      }
      
      notifyListeners();
      print("레시피가 식단 베이스에 저장되었습니다: ${recipe.title}");
    } catch (e) {
      print("레시피를 식단 베이스에 저장하는 중 오류: $e");
      throw Exception("레시피 저장에 실패했습니다: $e");
    }
  }

  // 카테고리별 기본 메뉴 생성
  List<SimpleMenu> _getDefaultMenuForCategory(String category) {
    switch (category) {
      case 'breakfast':
        return [
          SimpleMenu(
            dishName: "오트밀 죽",
            category: "breakfast",
            description: "간단하고 영양가 높은 아침 식사",
            mealType: "breakfast"
          ),
          SimpleMenu(
            dishName: "계란 토스트",
            category: "breakfast",
            description: "단백질이 풍부한 아침 메뉴",
            mealType: "breakfast"
          ),
          SimpleMenu(
            dishName: "요거트 과일 볼",
            category: "breakfast",
            description: "신선한 과일과 요거트로 만든 건강식",
            mealType: "breakfast"
          ),
        ];
      case 'lunch':
        return [
          SimpleMenu(
            dishName: "비빔밥",
            category: "lunch",
            description: "다양한 야채와 고기가 어우러진 한식 대표 메뉴",
            mealType: "lunch"
          ),
          SimpleMenu(
            dishName: "샐러드와 통밀 빵",
            category: "lunch",
            description: "가볍고 건강한 점심 식사",
            mealType: "lunch"
          ),
          SimpleMenu(
            dishName: "참치 김밥",
            category: "lunch",
            description: "단백질과 탄수화물의 균형 잡힌 한 끼",
            mealType: "lunch"
          ),
        ];
      case 'dinner':
        return [
          SimpleMenu(
            dishName: "닭가슴살 구이",
            category: "dinner",
            description: "저지방 고단백 저녁 식사",
            mealType: "dinner"
          ),
          SimpleMenu(
            dishName: "두부 스테이크",
            category: "dinner",
            description: "식물성 단백질이 풍부한 건강식",
            mealType: "dinner"
          ),
          SimpleMenu(
            dishName: "콩나물국밥",
            category: "dinner",
            description: "소화가 잘되는 가벼운 저녁 메뉴",
            mealType: "dinner"
          ),
        ];
      case 'snacks':
      default:
        return [
          SimpleMenu(
            dishName: "과일 믹스",
            category: "snack",
            description: "다양한 비타민과 섬유질을 제공하는 간식",
            mealType: "snack"
          ),
          SimpleMenu(
            dishName: "견과류 믹스",
            category: "snack",
            description: "건강한 지방과 단백질이 풍부한 간식",
            mealType: "snack"
          ),
          SimpleMenu(
            dishName: "그릭 요거트",
            category: "snack",
            description: "단백질이 풍부한 가벼운 간식",
            mealType: "snack"
          ),
        ];
    }
  }
}