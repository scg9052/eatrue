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
import '../l10n/app_localizations.dart';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSurveyPages();
    _updateStepTitles();
  }

  // 지역화된 단계 제목 업데이트
  void _updateStepTitles() {
    final localization = AppLocalizations.of(context);
    
    setState(() {
      _steps[0] = StepData(title: localization.personalInfoTitle, icon: Icons.person);
      _steps[1] = StepData(title: localization.healthInfoTitle, icon: Icons.favorite);
      _steps[2] = StepData(title: localization.foodPreferenceTitle, icon: Icons.restaurant);
      _steps[3] = StepData(title: localization.cookingDataTitle, icon: Icons.kitchen);
      _steps[4] = StepData(title: localization.reviewTitle, icon: Icons.check_circle);
    });
  }

  void _initializeSurveyPages() {
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final localization = AppLocalizations.of(context);
    
    _surveyPages = [
      // 1단계: 기본 정보
      SurveyPageContainer(
        title: localization.personalInfoTitle,
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
        title: localization.healthInfoTitle,
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
        title: localization.foodPreferenceTitle,
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
        title: localization.cookingDataTitle,
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
        title: localization.reviewTitle,
        child: SurveyPageReview(),
      ),
    ];
  }

  bool _isPageValid() {
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final userData = surveyDataProvider.userData;
    
    // 각 페이지별 유효성 검사 로직 구현
    switch (_currentPageIndex) {
      case 0: // 기본 정보
        return userData.age != null && 
               userData.gender != null && 
               userData.height != null && 
               userData.weight != null && 
               userData.activityLevel != null;
      case 1: // 건강 상태
        // 건강 상태에는 필수 필드가 없으므로 항상 유효
        return true;
      case 2: // 식습관
        // 식습관 페이지에서는 선호 조리 방법과 한 끼 예산이 필수
        return userData.preferredCookingMethods.isNotEmpty && userData.mealBudget != null;
      case 3: // 조리 환경
        // 요리 도구는 필수 선택
        return userData.availableCookingTools.isNotEmpty && 
               userData.preferredCookingTime != null;
      case 4: // 검토
        // 검토 페이지는 항상 유효
        return true;
      default:
        return true;
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
      final localization = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.validationErrorMessage),
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
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      
      // 다음 프레임에서 스낵바 표시 (네비게이션 후)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localization = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.surveyCompleted),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      });
    } catch (e) {
      final localization = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.surveyErrorSaving}: $e'),
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
    final localization = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.surveyTitle,
        subtitle: _steps[_currentPageIndex].title,
        showBackButton: _currentPageIndex > 0,
        onBackPressed: _previousPage,
        actions: [
          if (surveyDataProvider.isSurveyCompleted)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(localization.backToHomeTitle),
                    content: Text(localization.backToHomeContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localization.cancelButton),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                        child: Text(localization.backButton),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.home, color: Colors.white),
              label: Text(localization.homeScreenButton, style: TextStyle(color: Colors.white)),
            ),
        ],
        stepper: SurveyStepper(
          steps: _steps,
          currentStep: _currentPageIndex,
          onStepTapped: _goToStep,
          totalSteps: _steps.length,
          allowStepSelection: true,
        ),
      ),
      body: _isLoading
          ? FullScreenProgressLoading(message: localization.loadingUserInfo)
          : Column(
        children: [
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
                    label: Text(localization.prevButton),
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
                  label: Text(_currentPageIndex < _surveyPages.length - 1 ? localization.nextButton : localization.submitButton),
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