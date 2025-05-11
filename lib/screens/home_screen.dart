// screens/home_screen.dart
// (이전 flutter_home_screen_with_vertex_ai_call 문서 내용과 동일 - 식단 저장 기능 복원된 버전)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../providers/survey_data_provider.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import 'recipe_detail_screen.dart';
import 'saved_meals_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentWeekPage = 0;
  late DateTime _mondayOfWeek;
  int _selectedDayIndex = 3; // 중앙(수요일)부터 시작
  late PageController _dayController;
  bool _initialMenuGenerated = false;
  DateTime _selectedDateForSaving = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mondayOfWeek = _getMondayOfWeek(DateTime.now());
    _dayController = PageController(initialPage: _selectedDayIndex, viewportFraction: 0.45);
  }

  @override
  void dispose() {
    _dayController.dispose();
    super.dispose();
  }

  DateTime _getMondayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDates(DateTime monday) {
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _triggerGeneratePersonalizedMenu() {
    setState(() {
      _initialMenuGenerated = true;
    });
    Provider.of<MealProvider>(context, listen: false).orchestrateMenuGeneration();
  }

  Future<void> _selectDateAndSaveMeal(BuildContext context, Recipe recipeToSave, String category) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateForSaving,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      helpText: '식단을 저장할 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
      locale: const Locale('ko', 'KR'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateForSaving = picked;
      });
      final mealToSave = Meal(
        id: recipeToSave.id,
        name: recipeToSave.title,
        description: recipeToSave.ingredients?.keys.take(3).join(', ') ?? '주요 재료 정보 없음',
        calories: recipeToSave.nutritionalInformation?['calories']?.toString() ?? '',
        date: _selectedDateForSaving,
        category: category,
        recipeJson: recipeToSave.toJson(),
      );
      Provider.of<MealProvider>(context, listen: false).saveMeal(mealToSave, _selectedDateForSaving);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mealToSave.name}이(가) ${_selectedDateForSaving.year}년 ${_selectedDateForSaving.month}월 ${_selectedDateForSaving.day}일에 저장되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToRecommendPage(DateTime date, String mealType) {
    // TODO: 식단 추천 페이지로 이동 (arguments: date, mealType)
    Navigator.pushNamed(context, '/recommend', arguments: {'date': date, 'mealType': mealType});
  }

  void animateToDay(int idx) {
    setState(() {
      _selectedDayIndex = idx;
    });
    _dayController.animateToPage(idx, duration: Duration(milliseconds: 420), curve: Curves.easeOutExpo);
  }

  void animateToWeek(int weekDelta) {
    setState(() {
      _currentWeekPage += weekDelta;
      _selectedDayIndex = 3; // 중앙(수요일)로 초기화
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dayController.jumpToPage(_selectedDayIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final weekStart = _mondayOfWeek.add(Duration(days: 7 * _currentWeekPage));
    final weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekTitle = '${weekDates.first.month}월 ${((weekDates.first.day - 1) ~/ 7) + 1}번째 주 식단';
    final double cardWidth = 320;
    final double cardMargin = 16;

    return Scaffold(
      appBar: AppBar(
        title: Text('Eatrue', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.history_outlined),
            tooltip: '저장된 식단 보기',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SavedMealsScreen())),
          ),
          IconButton(
            icon: Icon(Icons.settings_backup_restore_outlined),
            tooltip: '내 정보 수정 (설문 다시하기)',
            onPressed: () {
              Provider.of<MealProvider>(context, listen: false).clearRecommendations();
              Provider.of<SurveyDataProvider>(context, listen: false).resetSurveyForEditing();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28),
                onPressed: _currentWeekPage > 0 ? () => animateToWeek(-1) : null,
              ),
              SizedBox(width: 8),
              Text(weekTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 28),
                onPressed: () => animateToWeek(1),
              ),
            ],
          ),
          SizedBox(height: 10),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 그림자+gradient만 적용된 center_content_section
                Container(
                  width: cardWidth * 1.5 + cardMargin * 2 + 36, // 버튼 공간 확보
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 좌우 gradient 구분선
                      Container(
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [primaryColor.withOpacity(0.13), Colors.transparent],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 500,
                          child: PageView.builder(
                            controller: _dayController,
                            itemCount: 7,
                            physics: ClampingScrollPhysics(),
                            onPageChanged: (idx) {
                              setState(() {
                                _selectedDayIndex = idx;
                              });
                            },
                            itemBuilder: (context, idx) {
                              final date = weekDates[idx];
                              final mealsByType = mealProvider.getMealsByDate(date);
                              final isCenter = idx == _selectedDayIndex;
                              // 카드 투명도: 중앙 1, 양끝 0.3~0.4
                              final double opacity = 1.0 - (0.7 * (idx - _selectedDayIndex).abs() / 3).clamp(0, 0.7);
                              return Opacity(
                                opacity: opacity.clamp(0.3, 1.0),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: cardMargin / 2, vertical: isCenter ? 0 : 32),
                                  width: cardWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCenter ? primaryColor : Colors.grey[300]!,
                                      width: isCenter ? 4 : 1,
                                    ),
                                    // 내부 카드에는 그림자/Glow 없음
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: 500,
                                      minHeight: 320,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('M/d (E)', 'ko').format(date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: isCenter ? primaryColor : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 18),
                                            ...['아침', '점심', '저녁', '간식'].map((mealType) {
                                              final meal = mealsByType[mealType];
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Card(
                                                  color: isCenter ? primaryColor.withOpacity(0.09) : Colors.grey[50],
                                                  elevation: isCenter ? 5 : 1,
                                                  shadowColor: isCenter ? primaryColor.withOpacity(0.18) : Colors.black12,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                    child: meal != null
                                                        ? Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(Icons.restaurant_menu, color: isCenter ? primaryColor : Colors.grey[600], size: 20),
                                                                  SizedBox(width: 8),
                                                                  Text('$mealType', style: TextStyle(fontWeight: FontWeight.bold, color: isCenter ? primaryColor : Colors.grey[800], fontSize: 15)),
                                                                ],
                                                              ),
                                                              SizedBox(height: 4),
                                                              Text(meal.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isCenter ? Colors.black : Colors.grey[900])),
                                                              SizedBox(height: 2),
                                                              Text(meal.calories != null && meal.calories!.isNotEmpty ? '${meal.calories} kcal' : '칼로리 정보 없음', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                            ],
                                                          )
                                                        : InkWell(
                                                            borderRadius: BorderRadius.circular(12),
                                                            onTap: () => showMealCandidatesDialog(context, date, mealType),
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.add_circle_outline, color: primaryColor, size: 20),
                                                                SizedBox(width: 8),
                                                                Text('$mealType 식사 추가', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 15)),
                                                              ],
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [primaryColor.withOpacity(0.13), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 좌우 이동 버튼 (Positioned)
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Icon(Icons.chevron_left, size: 36),
                    color: primaryColor,
                    onPressed: _selectedDayIndex > 0
                        ? () => animateToDay(_selectedDayIndex - 1)
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.chevron_right, size: 36),
                    color: primaryColor,
                    onPressed: _selectedDayIndex < 6
                        ? () => animateToDay(_selectedDayIndex + 1)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInitialView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ /* ... 이전과 동일 ... */ Icon(Icons.restaurant_menu_outlined, size: 120, color: Colors.green[300]), SizedBox(height: 30), Text('나만을 위한 맞춤 식단을\n추천 받아보세요!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800], height: 1.4,), textAlign: TextAlign.center,), SizedBox(height: 15), Text('입력하신 정보를 바탕으로 AI가 건강하고 맛있는 식단을 제안해 드립니다.', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center,), SizedBox(height: 40), ElevatedButton.icon(icon: Icon(Icons.auto_awesome, size: 24), label: Text('오늘의 식단 생성하기', style: TextStyle(fontSize: 18)), onPressed: _triggerGeneratePersonalizedMenu, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),),]));
  Widget _buildErrorView(String errorMessage) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ /* ... 이전과 동일 ... */ Icon(Icons.error_outline, color: Colors.red, size: 60), SizedBox(height: 20), Text("오류가 발생했습니다:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text(errorMessage, textAlign: TextAlign.center), SizedBox(height: 20), ElevatedButton.icon(icon: Icon(Icons.refresh), label: Text('다시 시도'), onPressed: _triggerGeneratePersonalizedMenu,)]));
  Widget _buildEmptyRecommendationsView(String message) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ /* ... 이전과 동일 ... */ Icon(Icons.sentiment_dissatisfied_outlined, size: 100, color: Colors.grey[400]), SizedBox(height: 24), Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[700]), textAlign: TextAlign.center,), SizedBox(height: 30), ElevatedButton.icon(icon: Icon(Icons.refresh), label: Text('다시 생성하기'), onPressed: _triggerGeneratePersonalizedMenu,)]));

  Widget _buildGeneratedMenuView(MealProvider mealProvider) {
    final menuData = mealProvider.generatedMenuByMealType;
    if (menuData.isEmpty) return _buildEmptyRecommendationsView("생성된 메뉴 데이터가 없습니다.\n(파싱 오류 또는 빈 응답)");
    return RefreshIndicator(
      onRefresh: () async => await mealProvider.orchestrateMenuGeneration(),
      child: ListView(children: [
        if (mealProvider.nutrientInfo != null) _buildNutrientInfoCard(mealProvider.nutrientInfo!),
        if (mealProvider.preferenceSummary != null) _buildSummaryCard("나의 선호 정보", mealProvider.preferenceSummary!),
        if (mealProvider.dislikeSummary != null) _buildSummaryCard("나의 기피 정보", mealProvider.dislikeSummary!),
        ...menuData.entries.map((entry) {
          final mealType = entry.key;
          final List<SimpleMenu> menus = entry.value;
          if (menus.isEmpty) return SizedBox.shrink();
          return ExpansionTile(
            title: Text(_getMealTypeKorean(mealType), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            initiallyExpanded: mealType.toLowerCase() == 'lunch' || mealType.toLowerCase() == 'dinner',
            children: menus.map((menu) => _buildSimpleMenuCard(context, menu, mealType)).toList(),
          );
        }).toList(),
        Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Center(child: TextButton.icon(icon: Icon(Icons.refresh, color: Colors.grey[700]), label: Text('다른 식단 추천받기', style: TextStyle(color: Colors.grey[700], fontSize: 16)), onPressed: _triggerGeneratePersonalizedMenu))),
      ]),
    );
  }

  Widget _buildSimpleMenuCard(BuildContext context, SimpleMenu menu, String mealType) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(menu.dishName, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(menu.description),
              trailing: Text(menu.category, style: TextStyle(color: Colors.grey[600])),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('캘린더에 저장'),
                  onPressed: () async {
                    final mealProvider = Provider.of<MealProvider>(context, listen: false);
                    // 날짜 선택 다이얼로그
                    DateTime initialDate = DateTime.now();
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime(DateTime.now().year + 1),
                      helpText: '식단을 저장할 날짜 선택',
                      cancelText: '취소',
                      confirmText: '선택',
                      locale: const Locale('ko', 'KR'),
                    );
                    if (picked == null) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('레시피 생성 및 저장 중...'), duration: Duration(seconds: 1)),
                    );
                    final userData = Provider.of<SurveyDataProvider>(context, listen: false).userData;
                    final recipe = await mealProvider.menuGenerationService.getSingleRecipeDetails(
                      mealName: menu.dishName,
                      userData: userData,
                    );
                    if (recipe != null) {
                      String? caloriesText;
                      try {
                        final calVal = recipe.nutritionalInformation?['calories'];
                        if (calVal != null) {
                          caloriesText = calVal.toString().replaceAll(' ', '');
                        }
                      } catch (_) {}
                      final mealToSave = Meal(
                        id: recipe.id,
                        name: recipe.title,
                        description: recipe.ingredients?.keys.take(3).join(', ') ?? '주요 재료 정보 없음',
                        calories: caloriesText,
                        date: picked,
                        category: menu.category,
                        recipeJson: recipe.toJson(),
                      );
                      mealProvider.saveMeal(mealToSave, picked);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${mealToSave.name}이(가) 저장되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('레시피 생성에 실패했습니다.'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMealTypeKorean(String mealType) { /* ... 이전과 동일 ... */ switch (mealType.toLowerCase()) { case 'breakfast': return '아침 식사'; case 'lunch': return '점심 식사'; case 'dinner': return '저녁 식사'; case 'snacks': return '간식'; default: return mealType.toUpperCase(); } }
  Widget _buildSummaryCard(String title, String summary) { /* ... 이전과 동일 ... */ return Card(margin: EdgeInsets.symmetric(vertical:8.0), elevation: 1, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), SizedBox(height: 6), Text(summary, style: TextStyle(fontSize: 14, height: 1.3))]))); }
  Widget _buildNutrientInfoCard(Map<String, dynamic> nutrientInfo) { /* ... 이전과 동일 ... */ return Card(margin: EdgeInsets.symmetric(vertical:8.0), elevation: 1, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("일일 권장 섭취량", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)), SizedBox(height: 6), Text("칼로리: ${nutrientInfo['recommended_calories'] ?? '정보 없음'} kcal", style: TextStyle(fontSize: 14)), Text("단백질: ${nutrientInfo['recommended_protein'] ?? '정보 없음'} g", style: TextStyle(fontSize: 14))]))); }

  Future<void> showMealCandidatesDialog(BuildContext context, DateTime date, String mealType) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder<List<SimpleMenu>>(
          future: mealProvider.menuGenerationService.generateMealCandidates(
            mealType: mealType,
            count: 3,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AlertDialog(
                title: Text('$mealType 식단 후보 생성 중...'),
                content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              );
            }
            final candidates = snapshot.data!;
            return AlertDialog(
              title: Text('$mealType 식단 후보 선택'),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: candidates.map((menu) => Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(menu.dishName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (menu.description.isNotEmpty) Text(menu.description, style: TextStyle(fontSize: 13)),
                          if (menu.calories != null && menu.calories!.isNotEmpty) Text('칼로리: ${menu.calories} kcal', style: TextStyle(fontSize: 12)),
                          if (menu.ingredients != null && menu.ingredients!.isNotEmpty) Text('재료: ${menu.ingredients!.join(", ")}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () async {
                        final meal = Meal(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: menu.dishName,
                          description: menu.description,
                          calories: menu.calories,
                          date: date,
                          category: mealType,
                          recipeJson: null,
                        );
                        
                        // Firestore에 저장
                        await mealProvider.saveMeal(meal, date);
                        
                        // UI 업데이트를 위해 Provider의 상태 변경
                        final dateKey = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
                        final meals = mealProvider.savedMealsByDate[dateKey] ?? [];
                        meals.add(meal);
                        mealProvider.savedMealsByDate[dateKey] = meals;
                        mealProvider.notifyListeners();
                        
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${menu.dishName}이(가) $mealType 식사로 저장되었습니다.')),
                        );
                      },
                    ),
                  )).toList(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('취소')),
              ],
            );
          },
        );
      },
    );
  }
}