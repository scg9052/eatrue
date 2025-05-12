import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal_base.dart';
import '../widgets/app_bar_widget.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'package:intl/intl.dart';

class MealBaseScreen extends StatefulWidget {
  const MealBaseScreen({Key? key}) : super(key: key);

  @override
  _MealBaseScreenState createState() => _MealBaseScreenState();
}

class _MealBaseScreenState extends State<MealBaseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
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
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: '식단 베이스',
        subtitle: '저장된 식단을 관리하세요',
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '식단 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 탭바
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: '전체'),
              Tab(text: '아침'),
              Tab(text: '점심'),
              Tab(text: '저녁'),
              Tab(text: '간식'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.label,
          ),
          
          // 식단 베이스 목록
          Expanded(
            child: mealProvider.isLoadingMealBases
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMealBaseList(mealProvider.mealBases, '전체'),
                      _buildMealBaseList(mealProvider.mealBasesByCategory['아침'] ?? [], '아침'),
                      _buildMealBaseList(mealProvider.mealBasesByCategory['점심'] ?? [], '점심'),
                      _buildMealBaseList(mealProvider.mealBasesByCategory['저녁'] ?? [], '저녁'),
                      _buildMealBaseList(mealProvider.mealBasesByCategory['간식'] ?? [], '간식'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealBaseList(List<MealBase> mealBases, String category) {
    // 검색 필터링
    final filteredMealBases = _searchQuery.isNotEmpty
        ? mealBases.where((mealBase) {
            final searchText = '${mealBase.name} ${mealBase.description}'.toLowerCase();
            return searchText.contains(_searchQuery.toLowerCase());
          }).toList()
        : mealBases;
    
    if (filteredMealBases.isEmpty) {
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
                  ? '검색 결과가 없습니다'
                  : '저장된 $category 식단이 없습니다',
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
                label: Text('검색 초기화'),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredMealBases.length,
      itemBuilder: (context, index) {
        final mealBase = filteredMealBases[index];
        return _buildMealBaseCard(mealBase);
      },
    );
  }
  
  Widget _buildMealBaseCard(MealBase mealBase) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final bool hasRejectionReasons = mealBase.rejectionReasons != null && mealBase.rejectionReasons!.isNotEmpty;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
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
          padding: EdgeInsets.all(16),
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
                        ),
                        SizedBox(height: 4),
                        Text(
                          mealBase.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      if (hasRejectionReasons)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '기각됨',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: Colors.orange[400],
                  ),
                  SizedBox(width: 4),
                  Text(
                    mealBase.calories != null && mealBase.calories!.isNotEmpty
                        ? mealBase.calories!
                        : '칼로리 정보 없음',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  Spacer(),
                  if (mealBase.usageCount > 0) ...[
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: Colors.blue[400],
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${mealBase.usageCount}회 사용',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  SizedBox(width: 8),
                  if (mealBase.rating != null) ...[
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      mealBase.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
              if (mealBase.tags != null && mealBase.tags!.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: mealBase.tags!.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case '아침':
        return Colors.orange[700]!;
      case '점심':
        return Colors.green[700]!;
      case '저녁':
        return Colors.indigo[700]!;
      case '간식':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
  
  void _showMealBaseDetailsDialog(MealBase mealBase) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
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
                mealBase.description,
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
                        title: Text('식단 삭제'),
                        content: Text('${mealBase.name}을(를) 식단 베이스에서 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('삭제', style: TextStyle(color: Colors.red)),
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
                            content: Text('식단이 삭제되었습니다: ${mealBase.name}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('식단 삭제 중 오류: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  label: Text('식단 삭제', style: TextStyle(color: Colors.red)),
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    
    if (pickedDate != null) {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      Navigator.pop(context);
      
      try {
        await mealProvider.saveMealFromMealBase(mealBase, pickedDate);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mealBase.name}이(가) ${DateFormat('yyyy년 MM월 dd일').format(pickedDate)}에 추가되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('식단 추가 중 오류: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  void _showRatingDialog(BuildContext context, MealBase mealBase) {
    double currentRating = mealBase.rating ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('식단 평가'),
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
                      currentRating > 0 ? '$currentRating / 5.0' : '평가하지 않음',
                      style: TextStyle(fontSize: 16),
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
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    
                    if (currentRating > 0) {
                      final mealProvider = Provider.of<MealProvider>(context, listen: false);
                      try {
                        await mealProvider.rateMealBase(mealBase.id, currentRating);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('평가가 저장되었습니다: ${mealBase.name} (${currentRating.toStringAsFixed(1)}/5)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('평가 저장 중 오류: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('저장'),
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
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('태그 추가'),
          content: TextField(
            controller: tagController,
            decoration: InputDecoration(
              hintText: '태그 입력',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
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
                        content: Text('태그가 추가되었습니다: $tag'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('태그 추가 중 오류: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }
} 