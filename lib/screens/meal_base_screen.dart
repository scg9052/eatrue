import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_base.dart';
import '../widgets/app_bar_widget.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

enum SortOption {
  newest,
  rating,
  usageCount,
  calories
}

class MealBaseScreen extends StatefulWidget {
  const MealBaseScreen({Key? key}) : super(key: key);

  @override
  _MealBaseScreenState createState() => _MealBaseScreenState();
}

class _MealBaseScreenState extends State<MealBaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSortOption = SortOption.newest;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // 식단 베이스 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealProvider>(context, listen: false).loadMealBases();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final localization = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.mealBaseTitle,
        subtitle: localization.mealBaseSubtitle,
      ),
      body: Column(
        children: [
          // 검색 및 정렬 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 검색 입력 필드
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localization.searchMealBase,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // 정렬 버튼
                PopupMenuButton<SortOption>(
                  icon: Row(
                    children: [
                      Icon(Icons.sort),
                      SizedBox(width: 4),
                      Text(localization.sort),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _currentSortOption = value;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOption.newest,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _currentSortOption == SortOption.newest ? Theme.of(context).primaryColor : null,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(localization.sortByNewest),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.rating,
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rate,
                            color: _currentSortOption == SortOption.rating ? Theme.of(context).primaryColor : null,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(localization.sortByRating),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.usageCount,
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            color: _currentSortOption == SortOption.usageCount ? Theme.of(context).primaryColor : null,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(localization.sortByUsage),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.calories,
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: _currentSortOption == SortOption.calories ? Theme.of(context).primaryColor : null,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(localization.sortByCalories),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 탭바
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: localization.all),
                _buildCategoryTab(localization.breakfast),
                _buildCategoryTab(localization.lunch),
                _buildCategoryTab(localization.dinner),
                _buildCategoryTab(localization.snack),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelStyle: TextStyle(fontSize: 14),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
            ),
          ),
          
          // 식단 베이스 목록
          Expanded(
            child: mealProvider.isLoadingMealBases
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMealBaseGrid(mealProvider.mealBases, localization.all),
                      _buildMealBaseGrid(mealProvider.mealBasesByCategory[localization.breakfast] ?? [], localization.breakfast),
                      _buildMealBaseGrid(mealProvider.mealBasesByCategory[localization.lunch] ?? [], localization.lunch),
                      _buildMealBaseGrid(mealProvider.mealBasesByCategory[localization.dinner] ?? [], localization.dinner),
                      _buildMealBaseGrid(mealProvider.mealBasesByCategory[localization.snack] ?? [], localization.snack),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category) {
    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _getCategoryColor(category).withOpacity(0.1),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: _getCategoryColor(category),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMealBaseGrid(List<MealBase> mealBases, String category) {
    final localization = AppLocalizations.of(context);
    
    // 검색 필터링
    final filteredMealBases = _searchQuery.isNotEmpty
        ? mealBases.where((mealBase) {
            final searchText = '${mealBase.name} ${mealBase.description}'.toLowerCase();
            return searchText.contains(_searchQuery.toLowerCase());
          }).toList()
        : mealBases;
    
    // 정렬 옵션에 따라 정렬
    List<MealBase> sortedMealBases = [...filteredMealBases];
    switch (_currentSortOption) {
      case SortOption.newest:
        sortedMealBases.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
      case SortOption.rating:
        sortedMealBases.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case SortOption.usageCount:
        sortedMealBases.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case SortOption.calories:
        sortedMealBases.sort((a, b) {
          // 칼로리 추출 및 비교
          int getCalorieValue(String? calories) {
            if (calories == null || calories.isEmpty) return 0;
            // 숫자만 추출
            final numMatch = RegExp(r'(\d+)').firstMatch(calories);
            return numMatch != null ? int.parse(numMatch.group(1)!) : 0;
          }
          return getCalorieValue(b.calories).compareTo(getCalorieValue(a.calories));
        });
        break;
    }
    
    if (sortedMealBases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? localization.noSearchResults
                  : localization.isKorean()
                      ? '$category ${localization.none}'
                      : 'No $category meals saved',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            if (_searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: Icon(Icons.clear),
                label: Text(localization.resetSearch),
              ),
          ],
        ),
      );
    }
    
    // 화면 너비에 따라 열 수 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 300).floor().clamp(1, 3);
    
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedMealBases.length,
      itemBuilder: (context, index) {
        final mealBase = sortedMealBases[index];
        return _buildMealBaseCard(mealBase);
      },
    );
  }
  
  Widget _buildMealBaseCard(MealBase mealBase) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final localization = AppLocalizations.of(context);
    final bool hasRejectionReasons = mealBase.rejectionReasons != null && mealBase.rejectionReasons!.isNotEmpty;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasRejectionReasons ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showMealBaseDetailsDialog(mealBase);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealBase.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          mealBase.description ?? '설명 없음',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(mealBase.category).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getCategoryColor(mealBase.category).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      mealBase.category,
                      style: TextStyle(
                        fontSize: 13,
                        color: _getCategoryColor(mealBase.category),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Divider(),
              // 칼로리 정보
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.orange[600],
                  ),
                  SizedBox(width: 4),
                  Text(
                    mealBase.calories != null && mealBase.calories!.isNotEmpty
                        ? mealBase.calories!
                        : '${localization.calories} ${localization.none}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              // 사용 횟수와 별점
              Row(
                children: [
                  if (mealBase.usageCount > 0) ...[
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: Colors.blue[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${mealBase.usageCount}회',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  Spacer(),
                  if (mealBase.rating != null) ...[
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                    SizedBox(width: 2),
                    Text(
                      mealBase.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              // 태그 표시
              if (mealBase.tags != null && mealBase.tags!.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: mealBase.tags!.map((tag) => _buildTagChip(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 태그 칩 위젯
  Widget _buildTagChip(String tag) {
    Color tagColor;
    
    // 특별한 태그에 대한 색상 지정
    if (tag == '자동 생성') {
      tagColor = Colors.blue;
    } else if (tag == '추천 메뉴') {
      tagColor = Colors.purple;
    } else if (tag == '인기 메뉴') {
      tagColor = Colors.red;
    } else {
      // 기본 태그 색상
      tagColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tagColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          color: tagColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    // 한국어 카테고리명
    if (category == '아침' || category == 'Breakfast') {
      return Colors.orange[700]!;
    } else if (category == '점심' || category == 'Lunch') {
      return Colors.green[700]!;
    } else if (category == '저녁' || category == 'Dinner') {
      return Colors.indigo[700]!;
    } else if (category == '간식' || category == 'Snack') {
      return Colors.purple[700]!;
    } else {
      return Colors.grey[700]!;
    }
  }
  
  void _showMealBaseDetailsDialog(MealBase mealBase) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final localization = AppLocalizations.of(context);
    final bool hasRejectionReasons = mealBase.rejectionReasons != null && mealBase.rejectionReasons!.isNotEmpty;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mealBase.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(mealBase.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealBase.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getCategoryColor(mealBase.category),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                mealBase.description ?? '설명 없음',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Divider(height: 32),
              
              // 레시피 정보
              if (mealBase.recipeJson != null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(
                          recipe: Recipe.fromJson(mealBase.recipeJson!),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.restaurant_menu),
                  label: Text('레시피 보기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // 기각 사유 표시
              if (hasRejectionReasons) ...[
                Text(
                  '기각 사유',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: mealBase.rejectionReasons!.length,
                    itemBuilder: (context, index) {
                      final reason = mealBase.rejectionReasons![index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: Colors.red[50],
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reason.reason,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                reason.details,
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                DateFormat('yyyy년 MM월 dd일').format(reason.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // 액션 버튼
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showDatePicker(context, mealBase);
                          },
                          icon: Icon(Icons.calendar_today),
                          label: Text('캘린더에 추가'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showRatingDialog(context, mealBase);
                          },
                          icon: Icon(Icons.star),
                          label: Text('평가하기'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 태그 관리
                Text(
                  '태그',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...(mealBase.tags ?? []).map((tag) {
                      return InputChip(
                        label: Text(tag),
                        onDeleted: () async {
                          Navigator.pop(context);
                          try {
                            await mealProvider.removeTagFromMealBase(mealBase.id, tag);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('태그가 제거되었습니다: $tag'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('태그 제거 중 오류: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                    ActionChip(
                      avatar: Icon(Icons.add, size: 16),
                      label: Text('태그 추가'),
                      onPressed: () {
                        _showAddTagDialog(context, mealBase);
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(localization.deleteMealBaseTitle),
                        content: Text('${mealBase.name}${localization.deleteMealBaseConfirm}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(localization.cancelButton),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(localization.deleteButton, style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      Navigator.pop(context);
                      try {
                        await mealProvider.deleteMealBase(mealBase);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${localization.deleteMealBaseSuccess}${mealBase.name}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${localization.deleteMealBaseError}$e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(localization.deleteMealBaseTitle, style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  void _showDatePicker(BuildContext context, MealBase mealBase) async {
    final localization = AppLocalizations.of(context);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    
    if (pickedDate != null) {
      // 로딩 인디케이터 표시
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('${mealBase.name}${localization.addingMealInProgress}')
            ],
          ),
          duration: Duration(seconds: 30), // 충분히 긴 시간으로 설정
        ),
      );
      
      Navigator.pop(context); // 상세 다이얼로그 닫기
      
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      try {
        // 비동기 작업 시작 전에 상태 업데이트를 위해 약간의 지연 추가
        await Future.delayed(Duration(milliseconds: 300));
        
        await mealProvider.saveMealFromMealBase(mealBase, pickedDate);
        
        // 기존 스낵바 제거
        scaffoldMessenger.hideCurrentSnackBar();
        
        // 성공 메시지 표시
        String formattedDate;
        if (localization.isKorean()) {
          formattedDate = DateFormat('yyyy년 MM월 dd일').format(pickedDate);
        } else {
          formattedDate = DateFormat('MMMM d, yyyy').format(pickedDate);
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${mealBase.name}${localization.mealAddedToCalendar}$formattedDate'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        // 기존 스낵바 제거
        scaffoldMessenger.hideCurrentSnackBar();
        
        // 오류 메시지 표시
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${localization.mealAddError}$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        print('식단 베이스에서 캘린더 추가 중 오류: $e');
      }
    }
  }
  
  void _showRatingDialog(BuildContext context, MealBase mealBase) {
    double currentRating = mealBase.rating ?? 0.0;
    final localization = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localization.ratingDialogTitle),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mealBase.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 26,
                          ),
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              currentRating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Text(
                      currentRating > 0 ? '$currentRating / 5.0' : localization.notRated,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localization.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    
                    if (currentRating > 0) {
                      final mealProvider = Provider.of<MealProvider>(context, listen: false);
                      try {
                        await mealProvider.rateMealBase(mealBase.id, currentRating);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${localization.ratingSaved}${mealBase.name} (${currentRating.toStringAsFixed(1)}/5)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${localization.ratingSaveError}$e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(localization.saveButton),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showAddTagDialog(BuildContext context, MealBase mealBase) {
    final TextEditingController tagController = TextEditingController();
    final localization = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localization.addTag),
          content: TextField(
            controller: tagController,
            decoration: InputDecoration(
              hintText: localization.tagInputHint,
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localization.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final tag = tagController.text.trim();
                if (tag.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  
                  final mealProvider = Provider.of<MealProvider>(context, listen: false);
                  try {
                    await mealProvider.addTagToMealBase(mealBase.id, tag);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localization.tagAdded}$tag'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${localization.addTagError}$e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(localization.addButton),
            ),
          ],
        );
      },
    );
  }
} 