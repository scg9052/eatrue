// screens/survey_screen.dart
// (이전 flutter_screens_updated_flowchart 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/survey_data_provider.dart';
import '../models/user_data.dart';
import '../widgets/survey_stepper.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/survey_pages/survey_page_personal_info.dart';
import '../widgets/survey_pages/survey_page_food_preference.dart';
import '../widgets/survey_pages/survey_page_cooking_data.dart';
import '../widgets/survey_pages/survey_page_health_info.dart';
import '../widgets/survey_pages/survey_page_review.dart';

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late List<Widget> _surveyPages;
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  // 설문 단계 정의 - 더 적합한 아이콘으로 변경
  final List<StepData> _steps = [
    StepData(title: '기본 정보', icon: Icons.person),
    StepData(title: '건강 상태', icon: Icons.favorite),
    StepData(title: '식습관', icon: Icons.restaurant),
    StepData(title: '조리 환경', icon: Icons.kitchen),
    StepData(title: '검토', icon: Icons.check_circle),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSurveyPages();
  }

  void _initializeSurveyPages() {
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    
    // 설문 페이지 정의
    _surveyPages = [
      // 1단계: 기본 정보 (나이, 성별, 키, 체중)
      SurveyPagePersonalInfo(
        key: UniqueKey(), // 고유 키 추가
        onUpdate: (age, gender, height, weight, activityLevel, conditions, allergies) {
          surveyDataProvider.updateUserAge(age);
          surveyDataProvider.updateUserGender(gender);
          surveyDataProvider.updateUserHeight(height);
          surveyDataProvider.updateUserWeight(weight);
          surveyDataProvider.updateUserActivityLevel(activityLevel);
          // 1페이지에서는 건강 정보 업데이트 제거 (중복 방지)
          if (mounted) setState(() {});
        },
      ),
      
      // 2단계: 건강 상태 (기저질환, 알레르기)
      SurveyPageHealthInfo(
        key: UniqueKey(), // 고유 키 추가
        onUpdate: (conditions, allergies) {
          surveyDataProvider.updateUnderlyingConditions(conditions);
          surveyDataProvider.updateAllergies(allergies);
          if (mounted) setState(() {});
        },
      ),
      
      // 3단계: 식습관
      SurveyPageFoodPreference(
        key: UniqueKey(), // 고유 키 추가
        onUpdate: (isVegan, isReligious, religionDetails, purposes, budget, favFoods, dislikedFoods, cookingMethods) {
          surveyDataProvider.updateIsVegan(isVegan);
          surveyDataProvider.updateIsReligious(isReligious);
          surveyDataProvider.updateReligionDetails(religionDetails);
          surveyDataProvider.updateMealPurpose(purposes);
          surveyDataProvider.updateMealBudget(budget);
          surveyDataProvider.updateFavoriteFoods(favFoods);
          surveyDataProvider.updateDislikedFoods(dislikedFoods);
          surveyDataProvider.updatePreferredCookingMethods(cookingMethods);
          if (mounted) setState(() {});
        },
      ),
      
      // 4단계: 조리 환경
      SurveyPageCookingData(
        key: UniqueKey(), // 고유 키 추가
        onUpdate: (tools, time) {
          surveyDataProvider.updateAvailableCookingTools(tools);
          surveyDataProvider.updatePreferredCookingTime(time);
          if (mounted) setState(() {});
        },
      ),
      
      // 5단계: 최종 검토
      SurveyPageReview(key: UniqueKey()), // 고유 키 추가
    ];
  }

  bool _isPageValid() {
    final UserData userData = Provider.of<SurveyDataProvider>(context, listen: false).userData;
    
    switch (_currentPageIndex) {
      case 0: // 기본 정보
        return userData.age != null &&
            (userData.gender != null && userData.gender!.isNotEmpty) &&
            userData.height != null &&
            userData.weight != null &&
            (userData.activityLevel != null && userData.activityLevel!.isNotEmpty);
      
      case 1: // 건강 상태
        return true; // 선택 사항이므로 항상 유효
      
      case 2: // 식습관
        if (userData.isReligious && (userData.religionDetails == null || userData.religionDetails!.trim().isEmpty)) {
          return false;
        }
        return userData.mealPurpose.isNotEmpty &&
            userData.mealBudget != null;
      
      case 3: // 조리 환경
        return userData.availableCookingTools.isNotEmpty &&
            userData.preferredCookingTime != null;
      
      case 4: // 최종 검토
        return true; // 검토 페이지는 항상 유효
      
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_isPageValid()) {
      if (_currentPageIndex < _surveyPages.length - 1) {
        _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _completeSurvey();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('현재 페이지의 필수 항목을 모두 입력해주세요.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
  
  Future<void> _completeSurvey() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<SurveyDataProvider>(context, listen: false).completeSurvey();
      
      // 설문 완료 후 메인 화면(홈 화면)으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('설문 저장 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _goToStep(int index) {
    // 해당 스텝으로 직접 이동 (완료된 스텝이나 현재 스텝만 이동 가능)
    if (index <= _currentPageIndex) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 현재 설문 단계에 맞는 부제목 반환
  String _getSubtitle() {
    switch (_currentPageIndex) {
      case 0:
        return '기본적인 신체 정보를 입력해주세요';
      case 1:
        return '건강 상태에 대한 정보를 입력해주세요';
      case 2:
        return '식습관과 선호 식품에 대한 정보를 입력해주세요';
      case 3:
        return '주로 사용하는 조리 도구와 시간을 알려주세요';
      case 4:
        return '입력한 정보를 확인하고 수정해주세요';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 요구사항
    final bool canProceed = _isPageValid();
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700; // 작은 화면 기기 감지
    
    // 스텝퍼 위젯 생성
    final stepperWidget = SurveyStepper(
      currentStep: _currentPageIndex,
      totalSteps: _steps.length,
      steps: _steps,
      onStepTapped: _goToStep,
      allowStepSelection: true,
    );
    
    return GestureDetector(
      // 화면 탭 시 키보드 닫기
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // 키보드가 올라와도 화면이 리사이즈되도록 변경 (스크롤 가능하므로)
        resizeToAvoidBottomInset: true,
        appBar: EatrueAppBar(
          showBackButton: _currentPageIndex > 0,
          onBackPressed: _previousPage,
          title: '맞춤 정보 입력',
          subtitle: _getSubtitle(),
          bottom: stepperWidget,
          // 화면 크기에 따라 더 넉넉한 앱바 높이 설정
          height: isSmallScreen ? kToolbarHeight + 100 : kToolbarHeight + 120,
        ),
        body: _isLoading
            ? _buildLoadingView()
            : SafeArea(
                bottom: true,
                child: Column(
                  children: [
                    // 설문 내용 - 확장하여 남은 공간 모두 차지
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _surveyPages.length,
                        physics: NeverScrollableScrollPhysics(), // 터치로 페이지 전환은 비활성화
                        onPageChanged: (index) => setState(() => _currentPageIndex = index),
                        itemBuilder: (context, index) {
                          // 각 페이지를 스크롤 가능한 컨테이너로 감싸기
                          return SingleChildScrollView(
                            // 항상 스크롤 가능하도록 설정 (작은 콘텐츠에도 스크롤 가능)
                            physics: AlwaysScrollableScrollPhysics(),
                            // 키보드가 올라와도 여백을 확보하기 위한 추가 패딩
                            padding: EdgeInsets.only(
                              left: isSmallScreen ? 12.0 : 16.0,
                              right: isSmallScreen ? 12.0 : 16.0, 
                              top: isSmallScreen ? 20.0 : 24.0, // 앱바와의 간격 확대
                              // 키보드가 올라올 때 하단 여백 추가
                              bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                            ),
                            child: _surveyPages[index],
                          );
                        },
                      ),
                    ),
                    
                    // 하단 버튼 - 항상 화면 하단에 고정
                    Container(
                      color: theme.scaffoldBackgroundColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: isSmallScreen ? 8.0 : 12.0 // 화면 크기에 따라 패딩 조정
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: _currentPageIndex == 0
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPageIndex > 0)
                              ElevatedButton.icon(
                                icon: Icon(Icons.arrow_back_ios_new, size: isSmallScreen ? 16 : 20),
                                label: Text(
                                  '이전',
                                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                ),
                                onPressed: _previousPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 24,
                                    vertical: isSmallScreen ? 8 : 12
                                  ),
                                ),
                              ),
                            
                            ElevatedButton.icon(
                              icon: Icon(
                                _currentPageIndex == _surveyPages.length - 1
                                    ? Icons.check_circle_outline
                                    : Icons.arrow_forward_ios,
                                size: isSmallScreen ? 16 : 20
                              ),
                              label: Text(
                                _currentPageIndex == _surveyPages.length - 1
                                    ? '완료하고 추천받기'
                                    : '다음',
                                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                              ),
                              onPressed: canProceed ? _nextPage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canProceed
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 8 : 12
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            '설문 정보를 저장하는 중...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}