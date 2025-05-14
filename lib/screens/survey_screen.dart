// screens/survey_screen.dart
// (이전 flutter_screens_updated_flowchart 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/survey_data_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/survey_stepper.dart';
import '../widgets/progress_loading.dart';
import '../widgets/survey_pages/survey_page_personal_info.dart';
import '../widgets/survey_pages/survey_page_health_info.dart';
import '../widgets/survey_pages/survey_page_food_preference.dart';
import '../widgets/survey_pages/survey_page_cooking_data.dart';
import '../widgets/survey_pages/survey_page_review.dart';
import '../widgets/survey_page_container.dart';

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
    
    _surveyPages = [
      // 1단계: 기본 정보
      SurveyPageContainer(
        title: '기본 정보',
        child: SurveyPagePersonalInfo(
          onUpdate: (age, gender, height, weight, activityLevel, conditions, allergies) {
            // 여기에서 SurveyDataProvider 업데이트 로직 직접 구현
            surveyDataProvider.userData.age = age;
            surveyDataProvider.userData.gender = gender;
            surveyDataProvider.userData.height = height;
            surveyDataProvider.userData.weight = weight;
            surveyDataProvider.userData.activityLevel = activityLevel;
            surveyDataProvider.userData.underlyingConditions = conditions;
            surveyDataProvider.userData.allergies = allergies;
            surveyDataProvider.notifyListeners();
          },
        ),
      ),
      
      // 2단계: 건강 상태
      SurveyPageContainer(
        title: '건강 상태',
        child: SurveyPageHealthInfo(
          onUpdate: (underlyingConditions, allergies) {
            // 여기에서 SurveyDataProvider 업데이트 로직 직접 구현
            surveyDataProvider.userData.underlyingConditions = underlyingConditions;
            surveyDataProvider.userData.allergies = allergies;
            surveyDataProvider.notifyListeners();
          },
        ),
      ),
      
      // 3단계: 식습관
      SurveyPageContainer(
        title: '식습관',
        child: SurveyPageFoodPreference(
          onUpdate: (isVegan, isReligious, religionDetails, mealPurposes, mealBudget, favFoods, dislikedFoods, cookingMethods) {
            // 여기에서 SurveyDataProvider 업데이트 로직 직접 구현
            surveyDataProvider.userData.isVegan = isVegan;
            surveyDataProvider.userData.isReligious = isReligious;
            surveyDataProvider.userData.religionDetails = religionDetails;
            surveyDataProvider.userData.mealPurpose = mealPurposes;
            surveyDataProvider.userData.mealBudget = mealBudget;
            surveyDataProvider.userData.favoriteFoods = favFoods;
            surveyDataProvider.userData.dislikedFoods = dislikedFoods;
            surveyDataProvider.userData.preferredCookingMethods = cookingMethods;
            surveyDataProvider.notifyListeners();
          },
        ),
      ),
      
      // 4단계: 조리 환경
      SurveyPageContainer(
        title: '조리 환경',
        child: SurveyPageCookingData(
          onUpdate: (cookingTools, preferredTime) {
            // 여기에서 SurveyDataProvider 업데이트 로직 직접 구현
            surveyDataProvider.userData.availableCookingTools = cookingTools;
            surveyDataProvider.userData.preferredCookingTime = preferredTime;
            surveyDataProvider.notifyListeners();
          },
        ),
      ),
      
      // 5단계: 최종 검토
      SurveyPageContainer(
        title: '검토',
        child: SurveyPageReview(),
      ),
    ];
  }

  bool _isPageValid() {
    // 실제 앱에서는 각 페이지별 유효성 검사 로직을 구현
    // 일단은 간단하게 진행할 수 있도록 항상 true를 반환
    return true;
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
      
      // 설문 완료 후 메인 화면(홈 화면)으로 이동하고 성공 메시지 표시
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      
      // 다음 프레임에서 스낵바 표시 (네비게이션 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설문이 완료되었습니다. 이제 메뉴 생성 버튼을 눌러 식단을 생성해보세요.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      });
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필요
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('맞춤 설문'),
        elevation: 0,
        actions: [
          // 이미 설문을 완료한 사용자를 위한 액션 버튼
          if (surveyDataProvider.isSurveyCompleted)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('메인 화면으로 돌아가기'),
                    content: Text('설문을 이미 완료했습니다. 변경 사항을 저장하지 않고 메인 화면으로 돌아가시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        child: Text('돌아가기'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.home, color: Colors.white),
              label: Text('메인 화면', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? FullScreenProgressLoading(message: '설문 데이터를 저장하는 중...')
          : Column(
        children: [
          // 설문 스텝퍼 표시
          Theme(
            data: Theme.of(context).copyWith(
              tabBarTheme: TabBarTheme(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR'),
                unselectedLabelStyle: TextStyle(fontSize: 14, fontFamily: 'NotoSansKR'),
              ),
            ),
            child: SurveyStepper(
              steps: _steps,
              currentStep: _currentPageIndex,
              onStepTapped: _goToStep,
              totalSteps: _steps.length,
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: _surveyPages,
            ),
          ),
          
          // 하단 버튼
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 버튼
                if (_currentPageIndex > 0)
                  ElevatedButton.icon(
                    onPressed: _previousPage,
                    icon: Icon(Icons.arrow_back),
                    label: Text('이전'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  SizedBox(width: 100),
                
                // 다음 또는 완료 버튼
                ElevatedButton.icon(
                  onPressed: _nextPage,
                  icon: Icon(_currentPageIndex < _surveyPages.length - 1 ? Icons.arrow_forward : Icons.check),
                  label: Text(_currentPageIndex < _surveyPages.length - 1 ? '다음' : '완료'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}