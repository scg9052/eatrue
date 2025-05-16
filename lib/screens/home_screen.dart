// screens/home_screen.dart
// (이전 flutter_home_screen_with_vertex_ai_call 문서 내용과 동일 - 식단 저장 기능 복원된 버전)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/meal_provider.dart';
import '../providers/survey_data_provider.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../widgets/app_bar_widget.dart';
import 'recipe_detail_screen.dart';
import 'saved_meals_screen.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/progress_loading.dart';
import '../l10n/app_localizations.dart';

// 컴포넌트화된 위젯 임포트
import '../widgets/home/date_selector.dart';
import '../widgets/home/meal_list.dart';
import '../widgets/home/meal_add_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _initialMenuGenerated = false;
  bool _isLoadingDate = false;
  bool _firstLoad = true; // 첫 로드 여부를 추적
  
  // 날짜 포맷 지역화
  String _getFormattedDate(BuildContext context, DateTime date) {
    final localization = AppLocalizations.of(context);
    
    if (localization.isKorean()) {
      return '${date.month}월 ${date.day}일 (${_getKoreanWeekday(date.weekday)})';
    } else {
      return DateFormat('MMMM d (EEEE)').format(date);
    }
  }
  
  // 한국어 요일 반환
  String _getKoreanWeekday(int weekday) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  @override
  void initState() {
    super.initState();
    // 첫 로드 시 오늘 날짜의 식단 불러오기
    _loadMealsForDate(_selectedDate);
    
    // 앱이 시작되고 1초 후 지연 로드 (UI가 준비된 후 시작)
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        // 생성된 식단이 없더라도 자동생성 하지 않음
        // final mealProvider = Provider.of<MealProvider>(context, listen: false);
        // final surveyProvider = Provider.of<SurveyDataProvider>(context, listen: false);
        // 
        // // 이미 생성된 메뉴가 없고, 설문이 완료된 경우에만 자동 생성
        // if (mealProvider.recommendedMeals.isEmpty && 
        //     mealProvider.generatedMenuByMealType.isEmpty &&
        //     surveyProvider.isSurveyCompleted) {
        //   _triggerGeneratePersonalizedMenu();
        // }
        
        if (mounted) {
          setState(() {
            _firstLoad = false;
          });
        }
      }
    });
  }

  Future<void> _loadMealsForDate(DateTime date) async {
    if (!mounted) return; // 위젯이 이미 제거된 경우 즉시 반환
    
    setState(() {
      _isLoadingDate = true;
    });
    
    try {
      // 0.5초 지연 (애니메이션 효과 확인용, 실제 앱에서는 제거)
      await Future.delayed(Duration(milliseconds: 500));
      
      if (!mounted) return; // 비동기 작업 후 위젯이 여전히 존재하는지 확인
      
      setState(() {
        _selectedDate = date;
        _isLoadingDate = false;
      });
      
      // 콘솔에 선택된 날짜 출력
      print("날짜 선택됨: ${DateFormat('yyyy-MM-dd').format(date)}");
    } catch (e) {
      print("날짜 로드 중 오류: $e");
      
      if (!mounted) return; // 예외 처리 후에도 위젯이 여전히 존재하는지 확인
      
      setState(() {
        _isLoadingDate = false;
      });
    }
  }

  // 앱바 캘린더 아이콘 버튼 onPressed 핸들러
  Future<void> _selectDate(BuildContext context) async {
    if (!mounted) return; // mounted 상태 확인 추가
    
    try {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2023),
        lastDate: DateTime(2025),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );
      
      if (pickedDate != null && mounted) { // mounted 상태 확인 추가
        print("showDatePicker에서 선택된 날짜: ${DateFormat('yyyy-MM-dd').format(pickedDate)}");
        await _loadMealsForDate(pickedDate);
      }
    } catch (e) {
      print("DatePicker 오류: $e");
    }
  }

  // 메뉴 생성 최적화 (중복 API 호출 방지)
  void _triggerGeneratePersonalizedMenu() {
    if (!mounted) return;
    
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    // 이미 로딩 중인 경우 중복 실행 방지
    if (mealProvider.isLoading) {
      print("이미 메뉴 생성 중입니다.");
      return;
    }
    
    // 이미 생성된 메뉴가 있는 경우 중복 실행 방지
    if (mealProvider.recommendedMeals.isNotEmpty || 
        mealProvider.generatedMenuByMealType.isNotEmpty) {
      print("이미 생성된 메뉴가 있습니다.");
      return;
    }
    
    setState(() {
      _initialMenuGenerated = true;
    });
    
    mealProvider.orchestrateMenuGeneration();
  }
  
  // 선택한 날짜가 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // 날짜를 주 단위로 나누어 헤더와 함께 반환
  List<DateTime> _getDatesForWeek() {
    // 선택된 날짜가 속한 주의 월요일 찾기
    final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    // 해당 주의 7일 생성
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final theme = Theme.of(context);
    final List<DateTime> weekDates = _getDatesForWeek();
    final localization = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.homeTitle,
        subtitle: localization.todayMeals,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 선택 섹션
          DateSelector(
            selectedDate: _selectedDate,
            weekDates: weekDates,
            onDateSelected: _loadMealsForDate,
          ),
          
          // 식단 내용 섹션
          Expanded(
            child: _isLoadingDate || _firstLoad
              ? HomeScreenSkeleton() 
              : MealList(
                  mealProvider: mealProvider,
                  selectedDate: _selectedDate,
                ),
          ),
          
          // 하단 섹션 (로딩 인디케이터 또는 버튼)
          _buildBottomSection(mealProvider),
        ],
      ),
    );
  }
  
  // 하단 섹션 (로딩 인디케이터 또는 버튼)
  Widget _buildBottomSection(MealProvider mealProvider) {
    final localization = AppLocalizations.of(context);
    
    // 로딩 중인 경우 진행 메시지 표시
    if (mealProvider.isLoading) {
      return Container(
        padding: EdgeInsets.all(16),
        child: ProgressLoadingBar(
          message: mealProvider.progressMessage ?? localization.generatingMealMessage,
          progress: mealProvider.progressPercentage,
        ),
      );
    }
    
    // 에러 메시지가 있는 경우
    if (mealProvider.errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              mealProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _triggerGeneratePersonalizedMenu,
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    }
    
    // 메뉴가 생성되지 않은 경우 생성 버튼 표시
    if (mealProvider.generatedMenuByMealType.isEmpty && mealProvider.recommendedMeals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localization.noMealsToday,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.grey[700]
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _triggerGeneratePersonalizedMenu,
              icon: Icon(Icons.auto_awesome),
              label: Text(localization.createTodayMeal),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    }
    
    // 그 외의 경우 빈 컨테이너 반환
    return SizedBox(height: 16);
  }
}