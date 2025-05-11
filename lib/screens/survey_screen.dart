// screens/survey_screen.dart
// (이전 flutter_screens_updated_flowchart 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/survey_data_provider.dart';
import '../models/user_data.dart';
import '../widgets/survey_page_container.dart';
import '../widgets/survey_pages/survey_page_personal_info.dart';
import '../widgets/survey_pages/survey_page_food_preference.dart';
import '../widgets/survey_pages/survey_page_cooking_data.dart';

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late List<Widget> _surveyPages;

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);

    _surveyPages = [
      SurveyPagePersonalInfo(
        onUpdate: (age, gender, height, weight, activityLevel, conditions, allergies) {
          surveyDataProvider.updateUserAge(age);
          surveyDataProvider.updateUserGender(gender);
          surveyDataProvider.updateUserHeight(height);
          surveyDataProvider.updateUserWeight(weight);
          surveyDataProvider.updateUserActivityLevel(activityLevel);
          surveyDataProvider.updateUnderlyingConditions(conditions);
          surveyDataProvider.updateAllergies(allergies);
          if (mounted) setState(() {});
        },
      ),
      SurveyPageFoodPreference(
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
      SurveyPageCookingData(
        onUpdate: (tools, time) {
          surveyDataProvider.updateAvailableCookingTools(tools);
          surveyDataProvider.updatePreferredCookingTime(time);
          if (mounted) setState(() {});
        },
      ),
    ];
  }

  bool _isPageValid() {
    final UserData userData = Provider.of<SurveyDataProvider>(context, listen: false).userData;
    switch (_currentPageIndex) {
      case 0:
        return userData.age != null &&
            (userData.gender != null && userData.gender!.isNotEmpty) &&
            userData.height != null &&
            userData.weight != null &&
            (userData.activityLevel != null && userData.activityLevel!.isNotEmpty);
      case 1:
        if (userData.isReligious && (userData.religionDetails == null || userData.religionDetails!.trim().isEmpty)) {
          return false;
        }
        return userData.mealPurpose.isNotEmpty &&
            userData.mealBudget != null &&
            userData.preferredCookingMethods.isNotEmpty;
      case 2:
        return userData.availableCookingTools.isNotEmpty &&
            userData.preferredCookingTime != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_isPageValid()) {
      if (_currentPageIndex < _surveyPages.length - 1) {
        _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        Provider.of<SurveyDataProvider>(context, listen: false).completeSurvey();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 페이지의 필수 항목을 모두 입력해주세요.'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 2)),
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canProceed = _isPageValid();
    return Scaffold(
      appBar: AppBar(
        title: Text('맞춤 정보 입력 (${_currentPageIndex + 1}/${_surveyPages.length})'),
        automaticallyImplyLeading: _currentPageIndex > 0,
        leading: _currentPageIndex > 0 ? IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: _previousPage) : null,
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.symmetric(horizontal:16.0, vertical: 8.0),
      child: LinearProgressIndicator(
        value: (_currentPageIndex + 1) / _surveyPages.length,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        minHeight: 6,
      ),
    ),
    Expanded(
    child: PageView.builder(
    controller: _pageController,
    itemCount: _surveyPages.length,
    physics: NeverScrollableScrollPhysics(),
    onPageChanged: (index) => setState(() => _currentPageIndex = index),
    itemBuilder: (context, index) => SurveyPageContainer(title: _getPageTitle(index), child: _surveyPages[index]),
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
    mainAxisAlignment: _currentPageIndex == 0 ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
    children: [
    if (_currentPageIndex > 0) // 조건이 참일 때 아래 위젯을 리스트에 포함
    ElevatedButton.icon(
    icon: Icon(Icons.arrow_back_ios_new),
    label: Text('이전'),
    onPressed: _previousPage,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[600],
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
    ),
    )
    else // 조건이 거짓일 때 아래 위젯을 리스트에 포함
    SizedBox.shrink(),

    // 다음 버튼 (항상 표시)
    ElevatedButton.icon(
    icon: Icon(_currentPageIndex == _surveyPages.length - 1 ? Icons.check_circle_outline : Icons.arrow_forward_ios),
    label: Text(_currentPageIndex == _surveyPages.length - 1 ? '완료하고 추천받기' : '다음'),
    onPressed: canProceed ? _nextPage : null,
    style: ElevatedButton.styleFrom(backgroundColor: canProceed ? Theme.of(context).primaryColor : Colors.grey, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
    ),
    ],
    ),
    ),
    ],
    ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return '기본 정보';
      case 1: return '음식 취향 및 식습관';
      case 2: return '나의 조리 환경';
      default: return '설문';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}