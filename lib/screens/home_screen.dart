// screens/home_screen.dart
// (이전 flutter_home_screen_with_vertex_ai_call 문서 내용과 동일 - 식단 저장 기능 복원된 버전)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../providers/survey_data_provider.dart';
import '../models/recipe.dart';
import '../models/meal.dart';
import '../widgets/app_bar_widget.dart';
import 'recipe_detail_screen.dart';
import 'saved_meals_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/skeleton_loading.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _initialMenuGenerated = false;
  bool _isLoadingDate = false;

  @override
  void initState() {
    super.initState();
    // 첫 로드 시 오늘 날짜의 식단 불러오기
    _loadMealsForDate(_selectedDate);
  }

  Future<void> _loadMealsForDate(DateTime date) async {
    setState(() {
      _isLoadingDate = true;
    });
    
    // 0.5초 지연 (애니메이션 효과 확인용, 실제 앱에서는 제거)
    await Future.delayed(Duration(milliseconds: 500));
    
    setState(() {
      _selectedDate = date;
      _isLoadingDate = false;
    });
  }

  void _triggerGeneratePersonalizedMenu() {
    setState(() {
      _initialMenuGenerated = true;
    });
    Provider.of<MealProvider>(context, listen: false).orchestrateMenuGeneration();
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
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: '나의 식단',
        subtitle: '건강한 식단 관리를 시작해보세요',
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2025),
              );
              if (pickedDate != null) {
                _loadMealsForDate(pickedDate);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 날짜 선택 섹션
          _buildDateSelector(weekDates, theme),
          
          // 식단 내용 섹션
          Expanded(
            child: _isLoadingDate 
              ? HomeScreenSkeleton() 
              : _buildMealsList(mealProvider),
          ),
          
          // 생성 버튼 섹션
          if (!mealProvider.isLoading && mealProvider.generatedMenuByMealType.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _triggerGeneratePersonalizedMenu,
                icon: Icon(Icons.auto_awesome),
                label: Text('오늘의 식단 생성하기'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 날짜 선택 UI
  Widget _buildDateSelector(List<DateTime> weekDates, ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withOpacity(0.05),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // 현재 월 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () {
                    _loadMealsForDate(_selectedDate.subtract(Duration(days: 7)));
                  },
                ),
                Text(
                  DateFormat('yyyy년 MM월').format(_selectedDate),
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    _loadMealsForDate(_selectedDate.add(Duration(days: 7)));
                  },
                ),
              ],
            ),
          ),
          
          // 요일 라벨
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['월', '화', '수', '목', '금', '토', '일'].map((day) => 
                Expanded(
                  child: Text(
                    day, 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: day == '토' ? Colors.blue[700] : 
                            day == '일' ? Colors.red[700] : null,
                    ),
                  ),
                )
              ).toList(),
            ),
          ),
          
          SizedBox(height: 8),
          
          // 날짜 선택 버튼들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDates.map((date) {
                final bool isSelected = date.day == _selectedDate.day && 
                                        date.month == _selectedDate.month && 
                                        date.year == _selectedDate.year;
                final bool isToday = _isToday(date);
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => _loadMealsForDate(date),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : 
                                isToday ? theme.colorScheme.primary.withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected ? 
                                Border.all(color: theme.colorScheme.primary) : null,
                        ),
                        child: Text(
                          date.day.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected || isToday ? FontWeight.bold : null,
                            color: isSelected ? theme.colorScheme.onPrimary : 
                                  date.weekday == 6 ? Colors.blue[700] : 
                                  date.weekday == 7 ? Colors.red[700] : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  // 식단 목록 UI
  Widget _buildMealsList(MealProvider mealProvider) {
    // 수정: Map<String, Meal?>에서 null이 아닌 항목만 필터링하여 새로운 Map 생성
    final mealsByDateWithNulls = mealProvider.getMealsByDate(_selectedDate);
    final Map<String, Meal> mealsByType = {};
    
    // null이 아닌 항목만 새 Map에 추가
    mealsByDateWithNulls.forEach((key, meal) {
      if (meal != null) {
        mealsByType[key] = meal;
      }
    });
    
    if (mealProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(mealProvider.progressMessage ?? '식단 생성 중...'),
          ],
        ),
      );
    }
    
    if (mealProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(mealProvider.errorMessage!),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _triggerGeneratePersonalizedMenu,
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    // 생성된 메뉴가 있고 날짜가 오늘인 경우 표시
    final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty;
    final bool isToday = _isToday(_selectedDate);
    
    if (mealsByType.isEmpty && !_initialMenuGenerated && !hasGeneratedMenus) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 120,
              color: Colors.green[300],
            ),
            SizedBox(height: 24),
            Text(
              '이 날의 식단이 비어있습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              '새로운 식단을 생성하거나 기존 식단을 추가해보세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // 식단 요약 카드
        Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMealSummaryItem(
                      context: context,
                      mealCount: mealsByType.length,
                      icon: Icons.restaurant,
                      label: '등록된 식사',
                    ),
                    _buildMealSummaryItem(
                      context: context,
                      mealCount: 4 - mealsByType.length,
                      icon: Icons.add_circle_outline,
                      label: '추가 가능',
                      color: Colors.grey[600]!,
                    ),
                  ],
                ),
                
                // 오늘 날짜이고 생성된 메뉴가 있다면 안내 메시지 표시
                if (isToday && hasGeneratedMenus)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        '아래 각 식사 유형을 눌러 메뉴를 캘린더에 추가하세요',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // 각 식사별 카드
        ..._buildMealTypeCards(mealsByType, mealProvider),
      ],
    );
  }
  
  // 식단 요약 아이템
  Widget _buildMealSummaryItem({
    required BuildContext context,
    required int mealCount,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 8),
        Text(
          mealCount.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  // 식사 타입별 카드 목록
  List<Widget> _buildMealTypeCards(Map<String, Meal> mealsByType, MealProvider mealProvider) {
    // 카테고리 매핑 정의
    final mealTypes = {
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
      'snack': '간식',
    };
    
    return mealTypes.entries.map((entry) {
      final mealType = entry.key;
      final mealTypeKorean = entry.value;
      
      // 수정: 키가 한글인지 영문인지 확인
      // getMealsByDate는 한글 키를 사용하므로 한글 키로 접근
      final meal = mealsByType[mealTypeKorean];
      
      return Card(
        elevation: 1,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: meal != null ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // 식사 타입 헤더
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: meal != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMealTypeIcon(mealType),
                    color: meal != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    mealTypeKorean,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: meal != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  if (meal != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                      onPressed: () => _removeMeal(mealProvider, meal),
                      tooltip: '식단 삭제',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
            ),
            
            // 식사 내용 또는 추가 버튼
            meal != null
                ? _buildMealCard(meal)
                : _buildAddMealButton(mealTypeKorean),
          ],
        ),
      );
    }).toList();
  }
  
  // 식사 카드 UI
  Widget _buildMealCard(Meal meal) {
    return InkWell(
      onTap: () {
        if (meal.recipeJson != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipe: Recipe.fromJson(meal.recipeJson!),
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              meal.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color: Colors.orange[400],
                ),
                SizedBox(width: 4),
                Text(
                  meal.calories != null && meal.calories!.isNotEmpty
                      ? meal.calories!
                      : '칼로리 정보 없음',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 식사 추가 버튼
  Widget _buildAddMealButton(String mealType) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    // 영어 카테고리 매핑
    final String englishMealType = 
      mealType == '아침' ? 'breakfast' :
      mealType == '점심' ? 'lunch' :
      mealType == '저녁' ? 'dinner' : 'snacks';
    
    // 생성된 메뉴가 있는지 확인
    final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty &&
                                 mealProvider.generatedMenuByMealType.containsKey(englishMealType);
    final bool isToday = _isToday(_selectedDate);
    
    // 오늘 날짜이고 생성된 메뉴가 있는 경우 다른 스타일 적용
    final bool showRecommended = isToday && hasGeneratedMenus;
    
    return InkWell(
      onTap: () => _addMeal(mealType),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 24),
        decoration: showRecommended 
          ? BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ) 
          : null,
        child: Column(
          children: [
            Icon(
              showRecommended ? Icons.recommend : Icons.add_circle_outline,
              size: 36,
              color: showRecommended 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey[500],
            ),
            SizedBox(height: 8),
            Text(
              showRecommended 
                ? '$mealType 추천 메뉴 보기' 
                : '$mealType 식사 추가하기',
              style: TextStyle(
                color: showRecommended 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey[600],
                fontWeight: showRecommended 
                  ? FontWeight.bold 
                  : FontWeight.w500,
              ),
            ),
            if (showRecommended)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '${mealProvider.generatedMenuByMealType[englishMealType]?.length ?? 0}개의 추천 메뉴가 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 식사 추가 다이얼로그
  void _addMeal(String mealType) {
    showMealCandidatesDialog(context, _selectedDate, mealType);
  }
  
  // 식사 후보 다이얼로그 표시
  void showMealCandidatesDialog(BuildContext context, DateTime date, String mealType) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    // 영어 카테고리 매핑
    final String englishMealType = 
      mealType == '아침' ? 'breakfast' :
      mealType == '점심' ? 'lunch' :
      mealType == '저녁' ? 'dinner' : 'snacks';
    
    // 생성된 메뉴가 있는지 확인
    final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty &&
                                 mealProvider.generatedMenuByMealType.containsKey(englishMealType);
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$mealType 식사 추가',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              
              // 생성된 메뉴가 있는 경우 표시
              if (hasGeneratedMenus) ... [
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '추천 메뉴',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).colorScheme.primary
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.only(bottom: 16),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: mealProvider.generatedMenuByMealType[englishMealType]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final menu = mealProvider.generatedMenuByMealType[englishMealType]![index];
                      return ListTile(
                        leading: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary),
                        title: Text(_translateMenuName(menu.dishName)),
                        subtitle: Text(menu.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 식단 베이스에 저장 버튼
                            IconButton(
                              icon: Icon(Icons.save_alt, color: Colors.green),
                              tooltip: '식단 베이스에 저장',
                              onPressed: () async {
                                try {
                                  // 메뉴를 식단 베이스에 저장
                                  await mealProvider.saveSimpleMenuToMealBase(
                                    menu, 
                                    mealType, // 한글 카테고리 사용
                                    ['추천 메뉴'], // 기본 태그
                                  );
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${menu.dishName}이(가) 식단 베이스에 저장되었습니다'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('저장 실패: $e'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                            
                            // 기각 버튼
                            IconButton(
                              icon: Icon(Icons.thumb_down, color: Colors.red[400]),
                              tooltip: '메뉴 기각',
                              onPressed: () {
                                _showRejectMenuDialog(context, menu, mealType);
                              },
                            ),
                            
                            // 캘린더 추가 버튼
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                              tooltip: '캘린더에 추가',
                              onPressed: () async {
                                Navigator.pop(context);
                                
                                // 메뉴 저장
                                await mealProvider.saveSimpleMenuAsMeal(menu, date, mealType);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${menu.dishName}이(가) $mealType에 추가되었습니다'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      );
                    },
                  ),
                ),
                
                Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '다른 선택지',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              Expanded(
                child: FutureBuilder<List<SimpleMenu>>(
                  future: mealProvider.menuGenerationService.generateMealCandidates(
                    mealType: englishMealType,
                    count: 5,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('식사 옵션을 불러오는 중...'),
                          ],
                        ),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('오류가 발생했습니다'),
                            SizedBox(height: 8),
                            Text(snapshot.error.toString()),
                          ],
                        ),
                      );
                    }
                    
                    final meals = snapshot.data ?? [];
                    
                    if (meals.isEmpty) {
                      return Center(
                        child: Text('추가 식사 옵션이 없습니다'),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(_translateMenuName(meal.dishName)),
                            subtitle: Text(meal.description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 식단 베이스에 저장 버튼
                                IconButton(
                                  icon: Icon(Icons.save_alt, color: Colors.green),
                                  tooltip: '식단 베이스에 저장',
                                  onPressed: () async {
                                    try {
                                      // 메뉴를 식단 베이스에 저장
                                      await mealProvider.saveSimpleMenuToMealBase(
                                        meal, 
                                        mealType, // 한글 카테고리 사용
                                        ['추가 메뉴'], // 기본 태그
                                      );
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${meal.dishName}이(가) 식단 베이스에 저장되었습니다'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('저장 실패: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                
                                // 기각 버튼
                                IconButton(
                                  icon: Icon(Icons.thumb_down, color: Colors.red[400]),
                                  tooltip: '메뉴 기각',
                                  onPressed: () {
                                    _showRejectMenuDialog(context, meal, mealType);
                                  },
                                ),
                                
                                // 캘린더 추가 버튼
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  tooltip: '캘린더에 추가',
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    
                                    // 레시피 상세 정보 로드 및 저장
                                    final loadedRecipe = await mealProvider.loadRecipeDetails(meal.dishName);
                                    if (loadedRecipe != null) {
                                      final newMeal = Meal(
                                        id: loadedRecipe.id,
                                        name: _translateMenuName(loadedRecipe.title),
                                        description: loadedRecipe.ingredients?.keys.take(3).join(', ') ?? '주요 재료 정보 없음',
                                        calories: loadedRecipe.nutritionalInformation?['calories']?.toString() ?? '',
                                        date: date,
                                        category: mealType,
                                        recipeJson: loadedRecipe.toJson(),
                                      );
                                      
                                      mealProvider.saveMeal(newMeal, date);
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${meal.dishName}이(가) $mealType에 추가되었습니다'),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 메뉴 기각 다이얼로그
  void _showRejectMenuDialog(BuildContext context, SimpleMenu menu, String mealType) {
    final TextEditingController detailsController = TextEditingController();
    String selectedReason = '비용이 너무 높음';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('메뉴 기각'),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.dishName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('이 메뉴를 기각하는 이유는 무엇인가요?'),
                    SizedBox(height: 8),
                    
                    // 라디오 버튼으로 기각 사유 선택
                    Column(
                      children: [
                        _buildRadioOption(
                          context, '비용이 너무 높음', selectedReason, 
                          (value) => setState(() => selectedReason = value),
                        ),
                        _buildRadioOption(
                          context, '레시피가 복잡함', selectedReason, 
                          (value) => setState(() => selectedReason = value),
                        ),
                        _buildRadioOption(
                          context, '좋아하지 않는 식재료 포함', selectedReason, 
                          (value) => setState(() => selectedReason = value),
                        ),
                        _buildRadioOption(
                          context, '영양 균형이 맞지 않음', selectedReason, 
                          (value) => setState(() => selectedReason = value),
                        ),
                        _buildRadioOption(
                          context, '기타', selectedReason, 
                          (value) => setState(() => selectedReason = value),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(
                        hintText: '상세한 이유를 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final mealProvider = Provider.of<MealProvider>(context, listen: false);
                    final details = detailsController.text.trim().isEmpty 
                        ? '상세 이유 없음' 
                        : detailsController.text.trim();
                    
                    Navigator.pop(context);
                    
                    try {
                      await mealProvider.rejectMenu(menu, mealType, selectedReason, details);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${menu.dishName}이(가) 기각되고 기록되었습니다'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('메뉴 기각 중 오류: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text('기각하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 라디오 버튼 옵션 빌더
  Widget _buildRadioOption(BuildContext context, String title, String groupValue, Function(String) onChanged) {
    return InkWell(
      onTap: () => onChanged(title),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<String>(
              value: title,
              groupValue: groupValue,
              onChanged: (value) => onChanged(value!),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
  
  // 식사 삭제 확인 다이얼로그
  void _removeMeal(MealProvider mealProvider, Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('식단 삭제'),
        content: Text('${meal.name}을(를) 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              mealProvider.removeMeal(meal, _selectedDate);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${meal.name}이(가) 삭제되었습니다'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // 식사 유형별 아이콘
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.icecream;
      default:
        return Icons.restaurant;
    }
  }

  // 간단한 영어 메뉴 이름을 한국어로 변환하는 함수
  String _translateMenuName(String englishName) {
    // 자주 사용되는 메뉴 이름 매핑
    final Map<String, String> menuTranslations = {
      // 아침
      'Scrambled Eggs': '스크램블 에그',
      'Oatmeal': '오트밀',
      'Yogurt': '요거트',
      'Granola': '그래놀라',
      'Toast': '토스트',
      'Pancakes': '팬케이크',
      'Waffles': '와플',
      
      // 점심
      'Salad': '샐러드',
      'Sandwich': '샌드위치',
      'Soup': '수프',
      'Bowl': '볼',
      'Wrap': '랩',
      'Pasta': '파스타',
      'Rice': '밥',
      'Noodles': '국수',
      
      // 저녁
      'Chicken': '닭고기',
      'Beef': '소고기',
      'Fish': '생선',
      'Salmon': '연어',
      'Pork': '돼지고기',
      'Tofu': '두부',
      'Vegetable': '채소',
      'Stir-fry': '볶음',
      'Curry': '카레',
      'Stew': '스튜',
      
      // 간식
      'Fruit': '과일',
      'Nuts': '견과류',
      'Cottage Cheese': '코티지 치즈',
      'Hard-Boiled Eggs': '삶은 계란',
      'Apple': '사과',
      'Banana': '바나나',
      'Peanut Butter': '땅콩 버터',
    };
    
    // 영어 메뉴 이름을 한국어로 변환
    String koreanName = englishName;
    
    // 여러 단어가 포함된 메뉴는 각 단어를 번역하고 결합
    for (var englishWord in menuTranslations.keys) {
      if (englishName.contains(englishWord)) {
        koreanName = koreanName.replaceAll(englishWord, menuTranslations[englishWord]!);
      }
    }
    
    // 번역 후에도 영어가 주로 남아있다면 원래 이름 반환
    int koreanCharCount = 0;
    for (int i = 0; i < koreanName.length; i++) {
      if (koreanName.codeUnitAt(i) > 127) koreanCharCount++;
    }
    
    // 50% 이상 영어면 원래 영어 이름 사용
    if (koreanCharCount < koreanName.length * 0.5) {
      return englishName;
    }
    
    return koreanName;
  }
}