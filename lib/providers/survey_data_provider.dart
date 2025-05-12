// providers/survey_data_provider.dart
import 'dart:async'; // StreamSubscription 사용을 위해 import
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/food_analysis_service.dart'; // 음식 분석 서비스 추가
import '../services/preference_summary_service.dart'; // 선호도 요약 서비스 추가
import '../services/dislike_summary_service.dart'; // 기피 요약 서비스 추가

class SurveyDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // 선호도 및 기피 정보 요약 서비스
  final PreferenceSummaryService _preferenceSummaryService = PreferenceSummaryService();
  final DislikeSummaryService _dislikeSummaryService = DislikeSummaryService();

  late UserData _userData;
  bool _isSurveyCompleted = false;
  bool _isLoading = true; // 초기에는 항상 로딩 상태로 시작
  String? _currentUserId; // 현재 사용자의 UID 저장

  // 선호도 및 기피 정보 요약 캐싱
  String? _preferenceSummary;
  String? _dislikeSummary;
  DateTime? _lastPreferenceSummaryUpdate;
  DateTime? _lastDislikeSummaryUpdate;
  bool _needsPreferenceSummaryUpdate = false;
  bool _needsDislikeSummaryUpdate = false;

  StreamSubscription<User?>? _authSubscription; // 인증 상태 변경 리스너 구독 관리

  SurveyDataProvider() {
    _userData = _getDefaultUserData();
    print("SurveyProvider: Initializing... _isLoading is true.");

    // Firebase Auth 초기화 및 UID 복구
    initializeAuth().then((_) {
      // authStateChanges 리스너 설정
      _authSubscription = _firebaseAuth.authStateChanges().listen(
          _handleAuthStateChanged,
          onError: (error) {
            print("SurveyProvider: AuthStateChanges stream error: $error");
            _isLoading = false;
            notifyListeners();
          }
      );
    });
  }

  // 인증 상태 변경 처리
  Future<void> _handleAuthStateChanged(User? user) async {
    print("SurveyProvider (_handleAuthStateChanged): Received user: ${user?.uid}");
    if (user != null) {
      // 사용자가 있거나, 익명 로그인 성공 후
      if (_currentUserId != user.uid || _isLoading) { // 사용자 ID가 변경되었거나 아직 로딩 중일 때만 데이터 로드
        print("SurveyProvider (_handleAuthStateChanged): User is signed in. UID: ${user.uid}. Loading data.");
        await _handleUserAuthenticated(user.uid);
      } else {
        print("SurveyProvider (_handleAuthStateChanged): User is signed in but data already loaded/loading for UID: ${user.uid}. _isLoading: $_isLoading");
        // 이미 처리된 사용자이므로 로딩 상태만 확실히 false로
        if (_isLoading) {
          _isLoading = false;
          notifyListeners();
        }
      }
    } else {
      // 사용자가 없음 (로그아웃 상태 또는 초기 상태) -> 익명 로그인 시도
      print("SurveyProvider (_handleAuthStateChanged): User is null. Attempting anonymous sign-in.");
      await _signInAnonymouslyAndLoadData();
    }
  }

  // 사용자가 인증되었을 때 데이터 로드 처리
  Future<void> _handleUserAuthenticated(String userId) async {
    // 이미 로딩 중이거나, 현재 사용자에 대한 데이터 로드가 완료되었다면 중복 실행 방지
    if (_currentUserId == userId && !_isLoading) {
      print("SurveyProvider (_handleUserAuthenticated): Data already loaded for UID: $userId.");
      return;
    }
    if (_isLoading && _currentUserId == userId) {
      print("SurveyProvider (_handleUserAuthenticated): Data is already loading for UID: $userId.");
      return;
    }

    _currentUserId = userId;
    // loadSurveyDataFromFirestore가 내부적으로 isLoading을 관리하고 notifyListeners를 호출합니다.
    await loadSurveyDataFromFirestore(userId);
  }

  // 익명 로그인 시도 및 데이터 로드
  Future<void> _signInAnonymouslyAndLoadData() async {
    // 이미 사용자가 있거나(다른 경로로 로그인 처리됨), 이미 로딩 중이라면 중복 실행 방지
    if (_firebaseAuth.currentUser != null) {
      print("SurveyProvider (_signInAnonymouslyAndLoadData): User already exists (UID: ${_firebaseAuth.currentUser!.uid}). Skipping anonymous sign-in.");
      // 이미 사용자가 있다면, _handleAuthStateChanged가 해당 사용자로 호출될 것이므로 여기서 추가 작업 불필요
      // 또는 여기서 _handleUserAuthenticated를 호출할 수도 있지만, 중복 호출 가능성 있음
      // 만약 이 함수가 호출된 시점에 currentUser가 있다면, authStateChanges가 이미 처리했을 가능성이 높음
      // 로딩 상태만 확실히 해제
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    // 익명 로그인 시도 전, 로딩 상태를 true로 설정 (이미 true일 수 있지만 명시)
    if (!_isLoading) { // 이미 로딩 중이 아니라면 true로 설정하고 알림
      _isLoading = true;
      notifyListeners();
    }
    print("SurveyProvider (_signInAnonymouslyAndLoadData): Attempting to sign in anonymously.");

    try {
      final UserCredential userCredential = await _firebaseAuth.signInAnonymously();
      print("SurveyProvider (_signInAnonymouslyAndLoadData): New anonymous user signed in. UID: ${userCredential.user?.uid}");
      // authStateChanges 리스너가 이 새로운 사용자 상태를 감지하고 _handleAuthStateChanged를 호출할 것입니다.
      // 따라서 여기서 직접 _handleUserAuthenticated를 호출할 필요는 없습니다.
      // 리스너가 처리하도록 두면 로직이 일관됩니다.
      // 만약 리스너가 즉시 반응하지 않는다면, 여기서 직접 호출하는 것을 고려할 수 있습니다.
      // 예: if (userCredential.user != null) await _handleUserAuthenticated(userCredential.user!.uid);
    } catch (e) {
      print("SurveyProvider (_signInAnonymouslyAndLoadData): Error signing in anonymously: $e");
      _isLoading = false; // 익명 로그인 실패 시 로딩 상태 해제
      notifyListeners();
    }
    // 익명 로그인 성공/실패 후 authStateChanges 리스너가 새 상태를 받아 처리하고,
    // 그 과정에서 loadSurveyDataFromFirestore가 호출되어 최종적으로 _isLoading = false가 됩니다.
  }


  UserData _getDefaultUserData() {
    return UserData(
      age: null, gender: null, height: null, weight: null,
      activityLevel: "보통 (주 3-5회 중간 강도 운동)",
      underlyingConditions: [], allergies: [],
      isVegan: false, isReligious: false, religionDetails: null,
      mealPurpose: [], mealBudget: null,
      favoriteFoods: [], dislikedFoods: [], preferredCookingMethods: [],
      availableCookingTools: [], preferredCookingTime: null,
    );
  }

  UserData get userData => _userData;
  bool get isSurveyCompleted => _isSurveyCompleted;
  bool get isLoading => _isLoading;

  Future<void> loadSurveyDataFromFirestore(String userId) async {
    if (userId.isEmpty) {
      print("SurveyProvider (loadSurveyDataFromFirestore): Invalid userId (empty).");
      _isLoading = false; // 로드 시도조차 할 수 없으므로 로딩 완료
      notifyListeners();
      return;
    }

    // 이미 로딩 중이 아니라면 로딩 상태로 설정
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners(); // UI에 로딩 시작 알림
    }
    print("SurveyProvider: Firestore에서 설문 데이터 로드 시도 (UID: $userId)");

    try {
      DocumentSnapshot doc = await _firestore.collection('userSurveys').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _userData = UserData.fromJson(data);
        _isSurveyCompleted = data['isSurveyCompleted'] as bool? ?? true;
        
        // 캐시된 요약 정보 로드
        if (data.containsKey('preferenceSummary') && data['preferenceSummary'] != null) {
          _preferenceSummary = data['preferenceSummary'] as String;
          _lastPreferenceSummaryUpdate = data['lastPreferenceSummaryUpdate'] != null 
              ? (data['lastPreferenceSummaryUpdate'] as Timestamp).toDate()
              : null;
          
          // 7일 이상 지난 요약 정보는 무효화
          if (_lastPreferenceSummaryUpdate != null && 
              DateTime.now().difference(_lastPreferenceSummaryUpdate!).inDays > 7) {
            _needsPreferenceSummaryUpdate = true;
          }
        }
        
        if (data.containsKey('dislikeSummary') && data['dislikeSummary'] != null) {
          _dislikeSummary = data['dislikeSummary'] as String;
          _lastDislikeSummaryUpdate = data['lastDislikeSummaryUpdate'] != null 
              ? (data['lastDislikeSummaryUpdate'] as Timestamp).toDate()
              : null;
          
          // 7일 이상 지난 요약 정보는 무효화
          if (_lastDislikeSummaryUpdate != null && 
              DateTime.now().difference(_lastDislikeSummaryUpdate!).inDays > 7) {
            _needsDislikeSummaryUpdate = true;
          }
        }
        
        print("Firestore에서 설문 데이터 로드 완료 (UID: $userId). isSurveyCompleted: $_isSurveyCompleted");
      } else {
        print("Firestore에 저장된 설문 데이터 없음 (UID: $userId). 기본값 사용.");
        _userData = _getDefaultUserData();
        _isSurveyCompleted = false;
        _preferenceSummary = null;
        _dislikeSummary = null;
        _needsPreferenceSummaryUpdate = true;
        _needsDislikeSummaryUpdate = true;
      }
    } catch (e) {
      print("Firestore에서 설문 데이터 로드 중 오류 (UID: $userId): $e");
      _userData = _getDefaultUserData();
      _isSurveyCompleted = false;
      _preferenceSummary = null;
      _dislikeSummary = null;
      _needsPreferenceSummaryUpdate = true;
      _needsDislikeSummaryUpdate = true;
    } finally {
      _isLoading = false;
      print("SurveyProvider (loadSurveyDataFromFirestore): Loading finished for UID: $userId. _isLoading: $_isLoading");
      notifyListeners();
    }
  }

  Future<void> completeSurvey() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      print("익명 사용자가 없어 설문 데이터를 저장할 수 없습니다.");
      return;
    }
    
    // 음식 선호도 분석 수행
    try {
      final foodAnalysisService = FoodAnalysisService();
      
      print("선호/기피 식품 분석 시작...");
      // 선호/기피 식품을 분석하여 식재료, 양념, 조리 방식으로 분해
      _userData = await foodAnalysisService.analyzeUserFoodPreferences(_userData);
      print("선호/기피 식품 분석 완료");
      
      print("선호 식재료: ${_userData.preferredIngredients}");
      print("선호 양념: ${_userData.preferredSeasonings}");
      print("선호 조리 방식: ${_userData.preferredCookingStyles}");
      print("기피 식재료: ${_userData.dislikedIngredients}");
      print("기피 양념: ${_userData.dislikedSeasonings}");
      print("기피 조리 방식: ${_userData.dislikedCookingStyles}");
    } catch (e) {
      print('음식 선호도 분석 중 오류 발생: $e');
    }
    
    // 선호 및 기피 요약 정보 생성
    _needsPreferenceSummaryUpdate = true;
    _needsDislikeSummaryUpdate = true;
    await getPreferenceSummary();
    await getDislikeSummary();
    
    // 설문 완료 표시 및 저장
    _isSurveyCompleted = true;
    
    try {
      // 사용자 데이터를 저장하는 Map 생성
      final Map<String, dynamic> userData = _userData.toJson();
      
      // 추가 정보를 Map에 포함
      userData['isSurveyCompleted'] = true;
      userData['lastUpdated'] = FieldValue.serverTimestamp();
      
      // 요약 정보도 저장
      if (_preferenceSummary != null) {
        userData['preferenceSummary'] = _preferenceSummary;
        userData['lastPreferenceSummaryUpdate'] = _lastPreferenceSummaryUpdate;
      }
      
      if (_dislikeSummary != null) {
        userData['dislikeSummary'] = _dislikeSummary;
        userData['lastDislikeSummaryUpdate'] = _lastDislikeSummaryUpdate;
      }
      
      // Firestore에 저장
      await _firestore.collection('userSurveys').doc(user.uid).set(userData);
      print("설문 데이터가 Firestore에 저장되었습니다. (UID: ${user.uid})");
      
      notifyListeners();
    } catch (e) {
      print('설문 데이터 저장 중 오류 발생: $e');
      throw Exception('설문 데이터 저장에 실패했습니다.');
    }
  }

  void resetSurveyForEditing() {
    // ... (이전과 동일) ...
    _isSurveyCompleted = false;
    notifyListeners();
  }

  Future<void> clearAllSurveyDataAndReset() async {
    // ... (이전과 동일, 단, _currentUserId 사용) ...
    final User? user = _firebaseAuth.currentUser;
    // String? userIdToClear = _currentUserId; // _currentUserId를 사용하는 것이 더 안전할 수 있음

    if (user == null) { // 또는 userIdToClear == null || userIdToClear.isEmpty
      _userData = _getDefaultUserData();
      _isSurveyCompleted = false;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    _isSurveyCompleted = false;
    _userData = _getDefaultUserData();
    try {
      await _firestore.collection('userSurveys').doc(user.uid).delete(); // user.uid 사용
      print('Firestore에서 설문 데이터 삭제 완료. (UID: ${user.uid})');
    } catch (e) {
      print('Firestore 데이터 삭제 중 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // 리스너 해제
    super.dispose();
  }

  // 개별 필드 업데이트 메소드들은 이전과 동일
  void updateUserData(UserData newData) { _userData = newData; notifyListeners(); }
  void updateUserAge(int? age) { _userData.age = age; notifyListeners(); }
  void updateUserGender(String? gender) { _userData.gender = gender; notifyListeners(); }
  void updateUserHeight(double? height) { _userData.height = height; notifyListeners(); }
  void updateUserWeight(double? weight) { _userData.weight = weight; notifyListeners(); }
  void updateUserActivityLevel(String? level) { _userData.activityLevel = level; notifyListeners(); }
  void updateUnderlyingConditions(List<String> conditions) { _userData.underlyingConditions = conditions; notifyListeners(); }
  void updateAllergies(List<String> allergies) { _userData.allergies = allergies; notifyListeners(); }
  void updateIsVegan(bool isVegan) { _userData.isVegan = isVegan; notifyListeners(); }
  void updateIsReligious(bool isReligious) { _userData.isReligious = isReligious; if (!isReligious) _userData.religionDetails = null; notifyListeners(); }
  void updateReligionDetails(String? details) { _userData.religionDetails = details; notifyListeners(); }
  void updateMealPurpose(List<String> purposes) { _userData.mealPurpose = purposes; notifyListeners(); }
  void updateMealBudget(double? budget) { _userData.mealBudget = budget; notifyListeners(); }
  void updateFavoriteFoods(List<String> foods) { _userData.favoriteFoods = foods; notifyListeners(); }
  void updateDislikedFoods(List<String> foods) { _userData.dislikedFoods = foods; notifyListeners(); }
  void updatePreferredCookingMethods(List<String> methods) { _userData.preferredCookingMethods = methods; notifyListeners(); }
  void updateAvailableCookingTools(List<String> tools) { _userData.availableCookingTools = tools; notifyListeners(); }
  void updatePreferredCookingTime(int? time) { _userData.preferredCookingTime = time; notifyListeners(); }
  
  // Firestore에 사용자 데이터 저장
  Future<void> saveUserDataToFirestore() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      print("사용자가 없어 설문 데이터를 저장할 수 없습니다.");
      return;
    }
    
    try {
      Map<String, dynamic> dataToSave = _userData.toJson();
      dataToSave['isSurveyCompleted'] = _isSurveyCompleted;
      
      await _firestore.collection('userSurveys').doc(user.uid).set(dataToSave);
      print('설문 데이터가 Firestore에 저장되었습니다. (UID: ${user.uid})');
    } catch (e) {
      print('Firestore 저장 중 오류 발생: $e');
    }
  }

  // 선호도 요약 정보 가져오기 (캐싱된 정보 활용)
  Future<String?> getPreferenceSummary() async {
    // 캐시된 정보가 있고 업데이트가 필요없으면 반환
    if (_preferenceSummary != null && !_needsPreferenceSummaryUpdate) {
      print("캐시된 선호도 요약 정보 사용");
      return _preferenceSummary;
    }
    
    print("선호도 요약 정보 생성 중...");
    try {
      // 새로운 요약 정보 생성
      _preferenceSummary = await _preferenceSummaryService.summarizeUserPreferences(_userData);
      
      if (_preferenceSummary == null) {
        _preferenceSummary = await _preferenceSummaryService.summarizePreferences(
          preferredCookingMethod: _userData.preferredCookingMethods,
          preferredIngredients: _userData.preferredIngredients.isEmpty ? _userData.favoriteFoods : _userData.preferredIngredients,
          preferredSeasonings: _userData.preferredSeasonings,
          desiredCookingTime: _userData.preferredCookingTime ?? 30,
          desiredFoodCost: _userData.mealBudget ?? 10000,
        );
      }
      
      _lastPreferenceSummaryUpdate = DateTime.now();
      _needsPreferenceSummaryUpdate = false;
      
      // 요약 정보 저장 (선택적)
      if (_currentUserId != null) {
        await _firestore.collection('userSurveys').doc(_currentUserId).update({
          'preferenceSummary': _preferenceSummary,
          'lastPreferenceSummaryUpdate': _lastPreferenceSummaryUpdate,
        }).catchError((e) => print("선호도 요약 정보 저장 실패: $e"));
      }
      
      print("선호도 요약 정보 생성 완료");
      return _preferenceSummary;
    } catch (e) {
      print("선호도 요약 정보 생성 중 오류: $e");
      return null;
    }
  }
  
  // 기피 요약 정보 가져오기 (캐싱된 정보 활용)
  Future<String?> getDislikeSummary() async {
    // 캐시된 정보가 있고 업데이트가 필요없으면 반환
    if (_dislikeSummary != null && !_needsDislikeSummaryUpdate) {
      print("캐시된 기피 요약 정보 사용");
      return _dislikeSummary;
    }
    
    print("기피 요약 정보 생성 중...");
    try {
      // 새로운 요약 정보 생성
      _dislikeSummary = await _dislikeSummaryService.summarizeUserDislikes(_userData);
      
      if (_dislikeSummary == null) {
        _dislikeSummary = await _dislikeSummaryService.summarizeDislikes(
          cookingTools: _userData.availableCookingTools,
          dislikedCookingMethods: _userData.dislikedCookingStyles,
          religionDetails: _userData.religionDetails,
          veganStatus: _userData.isVegan,
          dislikedIngredients: _userData.dislikedIngredients.isEmpty ? _userData.dislikedFoods : _userData.dislikedIngredients,
          dislikedSeasonings: _userData.dislikedSeasonings,
        );
      }
      
      _lastDislikeSummaryUpdate = DateTime.now();
      _needsDislikeSummaryUpdate = false;
      
      // 요약 정보 저장 (선택적)
      if (_currentUserId != null) {
        await _firestore.collection('userSurveys').doc(_currentUserId).update({
          'dislikeSummary': _dislikeSummary,
          'lastDislikeSummaryUpdate': _lastDislikeSummaryUpdate,
        }).catchError((e) => print("기피 요약 정보 저장 실패: $e"));
      }
      
      print("기피 요약 정보 생성 완료");
      return _dislikeSummary;
    } catch (e) {
      print("기피 요약 정보 생성 중 오류: $e");
      return null;
    }
  }

  // 선호도나 기피 정보가 변경되었을 때 호출
  void updatePreferenceState({bool preferenceChanged = false, bool dislikeChanged = false}) {
    if (preferenceChanged) {
      _needsPreferenceSummaryUpdate = true;
      _preferenceSummary = null; // 캐시 무효화
    }
    
    if (dislikeChanged) {
      _needsDislikeSummaryUpdate = true;
      _dislikeSummary = null; // 캐시 무효화
    }
    
    if (preferenceChanged || dislikeChanged) {
      notifyListeners();
    }
  }

  // 선호 식품 추가 시 요약 정보 업데이트 플래그 설정
  void addFavoriteFood(String food) {
    if (!_userData.favoriteFoods.contains(food)) {
      _userData.favoriteFoods.add(food);
      updatePreferenceState(preferenceChanged: true);
    }
  }
  
  // 선호 식품 제거 시 요약 정보 업데이트 플래그 설정
  void removeFavoriteFood(String food) {
    if (_userData.favoriteFoods.remove(food)) {
      updatePreferenceState(preferenceChanged: true);
    }
  }
  
  // 기피 식품 추가 시 요약 정보 업데이트 플래그 설정
  void addDislikedFood(String food) {
    if (!_userData.dislikedFoods.contains(food)) {
      _userData.dislikedFoods.add(food);
      updatePreferenceState(dislikeChanged: true);
    }
  }
  
  // 기피 식품 제거 시 요약 정보 업데이트 플래그 설정
  void removeDislikedFood(String food) {
    if (_userData.dislikedFoods.remove(food)) {
      updatePreferenceState(dislikeChanged: true);
    }
  }
}

// UID를 로컬에 저장
Future<void> saveUidLocally(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('firebase_anonymous_uid', uid);
  print('DEBUG: UID 저장 완료: $uid'); // 디버그 로그 추가
}

// 로컬에서 UID 읽기
Future<String?> getSavedUid() async {
  final prefs = await SharedPreferences.getInstance();
  final savedUid = prefs.getString('firebase_anonymous_uid');
  print('DEBUG: 저장된 UID 불러오기: $savedUid'); // 디버그 로그 추가
  return savedUid;
}

// Cloud Functions에서 커스텀 토큰 받아오기
Future<String> getCustomTokenFromServer(String uid) async {
  print('DEBUG: Cloud Functions에서 커스텀 토큰 요청 (UID: $uid)'); // 디버그 로그 추가
  final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getCustomToken');
  final result = await callable.call({'uid': uid});
  print('DEBUG: 커스텀 토큰 수신 완료'); // 디버그 로그 추가
  return result.data['token'];
}

// Firebase Auth 초기화
Future<void> initializeAuth() async {
  print('DEBUG: Firebase Auth 초기화 시작'); // 디버그 로그 추가
  final savedUid = await getSavedUid();
  
  if (savedUid != null) {
    print('DEBUG: 저장된 UID 발견: $savedUid'); // 디버그 로그 추가
    try {
      final customToken = await getCustomTokenFromServer(savedUid);
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      print('DEBUG: 커스텀 토큰으로 로그인 성공'); // 디버그 로그 추가
    } catch (e) {
      print('DEBUG: 커스텀 토큰 로그인 실패: $e'); // 디버그 로그 추가
      // 실패 시 익명 로그인으로 폴백
      await _signInAnonymously();
    }
  } else {
    print('DEBUG: 저장된 UID 없음, 익명 로그인 시도'); // 디버그 로그 추가
    await _signInAnonymously();
  }
}

// 익명 로그인
Future<void> _signInAnonymously() async {
  print('DEBUG: 익명 로그인 시작'); // 디버그 로그 추가
  final userCredential = await FirebaseAuth.instance.signInAnonymously();
  final uid = userCredential.user?.uid;
  if (uid != null) {
    print('DEBUG: 익명 로그인 성공, UID: $uid'); // 디버그 로그 추가
    await saveUidLocally(uid);
  } else {
    print('DEBUG: 익명 로그인 실패 - UID가 null'); // 디버그 로그 추가
  }
}