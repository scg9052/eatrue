// providers/meal_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction; // Firestore import
import 'package:intl/intl.dart'; // DateFormat import 추가

// 각 API 호출을 위한 서비스 import
import '../services/preference_summary_service.dart';
import '../services/nutrient_calculation_service.dart';
import '../services/dislike_summary_service.dart';
import '../services/menu_generation_service.dart';
import '../services/menu_verification_service.dart';
import '../services/meal_base_service.dart'; // 식단 베이스 서비스 추가

import '../models/user_data.dart';
import '../models/meal.dart';
import '../models/recipe.dart';
import '../models/meal_base.dart'; // 식단 베이스 모델 추가
import '../providers/survey_data_provider.dart';

class MealProvider with ChangeNotifier {
  // 서비스 인스턴스
  final PreferenceSummaryService _preferenceSummaryService = PreferenceSummaryService();
  final NutrientCalculationService _nutrientCalculationService = NutrientCalculationService();
  final DislikeSummaryService _dislikeSummaryService = DislikeSummaryService();
  final MenuGenerationService _menuGenerationService = MenuGenerationService();
  final MenuVerificationService _menuVerificationService = MenuVerificationService();
  final MealBaseService _mealBaseService = MealBaseService(); // 식단 베이스 서비스 추가

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

  MealProvider(this._surveyDataProvider) {
    // 인증 상태 변경 감지
    _firebaseAuth.authStateChanges().listen((User? user) {
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
    final User? initialUser = _firebaseAuth.currentUser;
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
      _preferenceSummary = await _preferenceSummaryService.summarizeUserPreferences(userData);
      if (_preferenceSummary == null) {
        _preferenceSummary = await _preferenceSummaryService.summarizePreferences(
          preferredCookingMethod: userData.preferredCookingMethods,
          preferredIngredients: userData.preferredIngredients.isEmpty ? userData.favoriteFoods : userData.preferredIngredients,
          preferredSeasonings: userData.preferredSeasonings,
          desiredCookingTime: userData.preferredCookingTime ?? 30,
          desiredFoodCost: userData.mealBudget ?? 10000,
        );
      }
      if (_preferenceSummary == null) throw Exception("선호 정보 요약에 실패했습니다.");
      print("선호 정보 요약 완료: $_preferenceSummary");
      notifyListeners();

      _setProgressMessage("기피 정보 요약 중...");
      _dislikeSummary = await _dislikeSummaryService.summarizeUserDislikes(userData);
      if (_dislikeSummary == null) {
        _dislikeSummary = await _dislikeSummaryService.summarizeDislikes(
          cookingTools: userData.availableCookingTools,
          dislikedCookingMethods: userData.dislikedCookingStyles,
          religionDetails: userData.religionDetails,
          veganStatus: userData.isVegan,
          dislikedIngredients: userData.dislikedIngredients.isEmpty ? userData.dislikedFoods : userData.dislikedIngredients,
          dislikedSeasonings: userData.dislikedSeasonings,
        );
      }
      if (_dislikeSummary == null) throw Exception("기피 정보 요약에 실패했습니다.");
      print("기피 정보 요약 완료: $_dislikeSummary");
      notifyListeners();

      _setProgressMessage("초기 메뉴 생성 중...");
      Map<String, dynamic>? currentMenuJson = await _menuGenerationService.generateMenu(
        userRecommendedNutrients: _nutrientInfo!,
        summarizedDislikes: _dislikeSummary!,
        summarizedPreferences: _preferenceSummary!,
      );
      
      if (currentMenuJson == null) {
        print("첫 번째 메뉴 생성 시도 실패, 재시도 중...");
        _setProgressMessage("메뉴 생성 재시도 중...");
        
        // 두 번째 시도
        currentMenuJson = await _menuGenerationService.generateMenu(
          userRecommendedNutrients: _nutrientInfo!,
          summarizedDislikes: _dislikeSummary!,
          summarizedPreferences: _preferenceSummary!,
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
          
          for (var item in menuList) {
            try {
              if (item is Map<String, dynamic>) {
                // meal_type이 없는 경우 추가
                if (!item.containsKey('meal_type') && !item.containsKey('mealType')) {
                  item['meal_type'] = mealType;
                }
                
                // 필수 필드 확인
                if (!item.containsKey('dish_name') || !item.containsKey('category') || !item.containsKey('description')) {
                  print("  경고: 항목에 필수 필드가 누락됨: $item");
                  
                  // 필수 필드 채우기
                  if (!item.containsKey('dish_name') || item['dish_name'] == null || item['dish_name'].toString().isEmpty) {
                    item['dish_name'] = "메뉴 ${menus.length + 1}";
                  }
                  
                  if (!item.containsKey('category') || item['category'] == null || item['category'].toString().isEmpty) {
                    item['category'] = mealType;
                  }
                  
                  if (!item.containsKey('description') || item['description'] == null || item['description'].toString().isEmpty) {
                    item['description'] = "${item['dish_name']} 메뉴입니다.";
                  }
                }
                
                final menu = SimpleMenu.fromJson(item);
                menus.add(menu);
                print("  메뉴 파싱 성공: ${menu.dishName}");
              } else {
                print("  경고: 메뉴 항목이 Map 형식이 아님: $item");
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
    print("메뉴 파싱 완료: 총 ${_generatedMenuByMealType.length}개 카테고리");
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
              final String dateKey = "${mealDate.year}-${mealDate.month.toString().padLeft(2,'0')}-${mealDate.day.toString().padLeft(2,'0')}";
              
              // Meal 객체 생성 전 유효성 검사
              final meal = Meal.fromJson(mealData);
              if (!_savedMealsByDate.containsKey(dateKey)) {
                _savedMealsByDate[dateKey] = [];
              }
              _savedMealsByDate[dateKey]!.add(meal);
            } catch (e) {
              print('Meal 변환 오류: $e, 데이터: $mealData');
            }
          }
        }
        
        print("Firestore에서 저장된 식단 로드 완료: ${_savedMealsByDate.length} 일자의 식단");
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
    final formatter = DateFormat('yyyy-MM-dd');
    
    // 3일치 샘플 데이터 (오늘, 어제, 내일)
    for (int dayOffset = -1; dayOffset <= 1; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final dateKey = formatter.format(date);
      
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
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print("익명 사용자가 없어 식단을 저장할 수 없습니다.");
      return;
    }
    
    String dateString = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    
    // 메모리에 저장
    if (_savedMealsByDate.containsKey(dateString)) {
      if (!_savedMealsByDate[dateString]!.any((m) => m.id == meal.id)) {
        _savedMealsByDate[dateString]!.add(meal);
      }
    } else {
      _savedMealsByDate[dateString] = [meal];
    }
    notifyListeners();

    try {
      // 단순화된 컬렉션 구조로 저장
      final Map<String, dynamic> dataToSave = meal.toJson();
      dataToSave['userId'] = _currentUserId; // 사용자 ID 추가
      
      await _firestore
          .collection('meals')
          .doc(meal.id)
          .set(dataToSave);
      
      print('식단이 Firestore에 저장되었습니다: ${meal.name} (UID: $_currentUserId)');
    } catch (e) {
      print('Firestore에 식단 저장 중 오류: $e');
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
    try {
      // 메뉴 이름이 영어인 경우 한글로 변환 시도
      String menuName = _translateMenuToKorean(menu.dishName);

      // 먼저 레시피 상세 정보 로드 시도
      final Recipe? loadedRecipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: menu.dishName,
        userData: _surveyDataProvider.userData,
      );
      
      Meal meal;
      
      if (loadedRecipe != null) {
        // 레시피 정보가 있는 경우
        meal = Meal(
          id: loadedRecipe.id,
          name: _translateMenuToKorean(loadedRecipe.title),
          description: loadedRecipe.ingredients?.keys.take(3).join(', ') ?? menu.description,
          calories: loadedRecipe.nutritionalInformation?['calories']?.toString() ?? '',
          date: date,
          category: mealType,
          recipeJson: loadedRecipe.toJson(),
        );
      } else {
        // 레시피 정보가 없는 경우 SimpleMenu 정보만으로 생성
        meal = Meal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: menuName,
          description: menu.description,
          calories: menu.calories ?? '',
          date: date,
          category: mealType,
          recipeJson: null,
        );
      }
      
      await saveMeal(meal, date);
      print('메뉴가 저장되었습니다: ${menu.dishName}');
    } catch (e) {
      print('메뉴 저장 중 오류 발생: $e');
      // 오류가 발생해도 기본 정보로 저장 시도
      final meal = Meal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _translateMenuToKorean(menu.dishName),
        description: menu.description,
        calories: menu.calories ?? '',
        date: date,
        category: mealType,
        recipeJson: null,
      );
      
      await saveMeal(meal, date);
    }
  }

  // 간단한 영어 메뉴 이름을 한국어로 변환하는 유틸리티 함수
  String _translateMenuToKorean(String englishName) {
    // 자주 사용되는 메뉴 이름 매핑
    final Map<String, String> menuTranslations = {
      // 아침
      'Scrambled Eggs': '스크램블 에그',
      'Oatmeal': '오트밀',
      'Yogurt': '요거트',
      'Greek Yogurt': '그릭 요거트',
      'Granola': '그래놀라',
      'Toast': '토스트',
      'Pancakes': '팬케이크',
      'Waffles': '와플',
      'Berries': '베리',
      
      // 점심
      'Salad': '샐러드',
      'Sandwich': '샌드위치',
      'Soup': '수프',
      'Bowl': '볼',
      'Wrap': '랩',
      'Pasta': '파스타',
      'Rice': '밥',
      'Noodles': '국수',
      'Tuna': '참치',
      'Chicken': '닭고기',
      'Lentil': '렌틸콩',
      'Quinoa': '퀴노아',
      
      // 저녁
      'Beef': '소고기',
      'Fish': '생선',
      'Salmon': '연어',
      'Pork': '돼지고기',
      'Tofu': '두부',
      'Vegetable': '채소',
      'Vegetables': '채소',
      'Stir-fry': '볶음',
      'Curry': '카레',
      'Stew': '스튜',
      'Roasted': '구운',
      'Baked': '구운',
      'Grilled': '구운',
      'Steamed': '찐',
      'Broccoli': '브로콜리',
      'Asparagus': '아스파라거스',
      'Bean': '콩',
      'Beans': '콩',
      
      // 간식
      'Fruit': '과일',
      'Fruits': '과일',
      'Nuts': '견과류',
      'Cottage Cheese': '코티지 치즈',
      'Hard-Boiled Eggs': '삶은 계란',
      'Apple': '사과',
      'Banana': '바나나',
      'Pineapple': '파인애플',
      'Peanut Butter': '땅콩 버터',
    };
    
    // 이미 한글이 포함된 경우는 그대로 반환
    bool containsKorean = false;
    for (int i = 0; i < englishName.length; i++) {
      if (englishName.codeUnitAt(i) > 127) {
        containsKorean = true;
        break;
      }
    }
    
    if (containsKorean) return englishName;
    
    // 영어 메뉴 이름을 한국어로 변환
    String koreanName = englishName;
    
    // 여러 단어가 포함된 메뉴는 각 단어를 번역하고 결합
    for (var englishWord in menuTranslations.keys) {
      if (englishName.contains(englishWord)) {
        koreanName = koreanName.replaceAll(englishWord, menuTranslations[englishWord]!);
      }
    }
    
    return koreanName;
  }

  // 식단 삭제 메소드
  Future<void> removeMeal(Meal meal, DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    try {
      // 메모리에서 삭제
      if (_savedMealsByDate.containsKey(dateKey)) {
        _savedMealsByDate[dateKey]?.removeWhere((m) => m.id == meal.id);
        notifyListeners();
      }
      
      // Firestore에서 삭제 - 단순화된 구조 사용
      await _firestore
          .collection('meals')
          .doc(meal.id)
          .delete();
          
      print('식단이 Firestore에서 삭제되었습니다: ${meal.name}');
    } catch (e) {
      print('식단 삭제 중 오류: $e');
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

  // 식단 베이스 관련 메소드
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
      // 메뉴 이름이 영어인 경우 한글로 변환
      String menuName = _translateMenuToKorean(menu.dishName);
      
      // 레시피 상세 정보 로드 시도
      final Recipe? recipe = await _menuGenerationService.getSingleRecipeDetails(
        mealName: menu.dishName,
        userData: _surveyDataProvider.userData,
      );
      
      // MealBase 모델 생성
      final String mealBaseId = DateTime.now().millisecondsSinceEpoch.toString();
      final MealBase mealBase = MealBase(
        id: mealBaseId,
        name: recipe != null ? _translateMenuToKorean(recipe.title) : menuName,
        description: menu.description,
        category: category,
        calories: menu.calories,
        recipeJson: recipe?.toJson(),
        tags: tags,
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
      print("메뉴가 식단 베이스에 저장되었습니다: ${menu.dishName}");
    } catch (e) {
      print("메뉴를 식단 베이스에 저장하는 중 오류: $e");
      throw Exception("메뉴 저장에 실패했습니다: $e");
    }
  }
  
  // 식단 베이스에서 식단 저장
  Future<void> saveMealFromMealBase(MealBase mealBase, DateTime date) async {
    try {
      // 사용 횟수 증가
      await _mealBaseService.incrementUsageCount(mealBase.id);
      
      // MealBase에서 Meal로 변환
      final Meal meal = mealBase.toMeal(date);
      
      // 식단 저장
      await saveMeal(meal, date);
      
      print("식단 베이스에서 식단이 저장되었습니다: ${mealBase.name}");
    } catch (e) {
      print("식단 베이스에서 식단 저장 중 오류: $e");
      throw Exception("식단 저장에 실패했습니다: $e");
    }
  }
  
  // 메뉴 기각 사유 저장
  Future<void> rejectMenu(SimpleMenu menu, String category, String reason, String details) async {
    try {
      // 메뉴 이름이 영어인 경우 한글로 변환
      String menuName = _translateMenuToKorean(menu.dishName);
      
      // SimpleMenu로부터 MealBase 생성
      final String mealBaseId = DateTime.now().millisecondsSinceEpoch.toString();
      final MealBase mealBase = MealBase(
        id: mealBaseId,
        name: menuName,
        description: menu.description,
        category: category, // 직접 카테고리 매개변수 사용
        calories: menu.calories,
        recipeJson: null,
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
  
  // 영어 카테고리를 한글로 변환
  String _getKoreanMealCategory(String englishCategory) {
    switch (englishCategory.toLowerCase()) {
      case 'breakfast':
        return '아침';
      case 'lunch':
        return '점심';
      case 'dinner':
        return '저녁';
      case 'snacks':
      case 'snack':
        return '간식';
      default:
        return '기타';
    }
  }
  
  // 한글 카테고리를 영어로 변환
  String _getEnglishMealCategory(String koreanCategory) {
    switch (koreanCategory) {
      case '아침':
        return 'breakfast';
      case '점심':
        return 'lunch';
      case '저녁':
        return 'dinner';
      case '간식':
        return 'snacks';
      default:
        return 'other';
    }
  }
}