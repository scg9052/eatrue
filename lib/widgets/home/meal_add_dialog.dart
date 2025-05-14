import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_provider.dart';
import '../../models/simple_menu.dart';
import '../../utils/meal_type_utils.dart';

/// 식사 추가 다이얼로그 표시
void showMealAddDialog(BuildContext context, DateTime date, String mealType) {
  final mealProvider = Provider.of<MealProvider>(context, listen: false);
  
  // 표준화된 카테고리 매핑
  final String standardCategory = standardizeCategory(mealType, toKorean: false);
  
  // 생성된 메뉴가 있는지 확인
  final bool hasGeneratedMenus = mealProvider.generatedMenuByMealType.isNotEmpty &&
                               mealProvider.generatedMenuByMealType.containsKey(standardCategory);
  
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return MealAddDialog(
        date: date,
        mealType: mealType,
        standardCategory: standardCategory,
        hasGeneratedMenus: hasGeneratedMenus,
      );
    },
  );
}

class MealAddDialog extends StatefulWidget {
  final DateTime date;
  final String mealType;
  final String standardCategory;
  final bool hasGeneratedMenus;
  
  const MealAddDialog({
    Key? key,
    required this.date,
    required this.mealType,
    required this.standardCategory,
    required this.hasGeneratedMenus,
  }) : super(key: key);
  
  @override
  _MealAddDialogState createState() => _MealAddDialogState();
}

class _MealAddDialogState extends State<MealAddDialog> {
  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    
    return Container(
      padding: EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Divider(),
          
          // 추천 메뉴 섹션
          if (widget.hasGeneratedMenus) 
            _buildRecommendedMenuSection(mealProvider),
          
          // 식단 베이스 섹션 (추가 예정)
          SizedBox(height: 16),
          Text(
            '식단 베이스에서 추가',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          // 식단 베이스 목록은 MealBaseList 위젯으로 분리 예정
          Text('식단 베이스에서 선택 기능 (추가 예정)'),
          
          // 직접 추가 섹션
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('새 식단 직접 입력'),
            onPressed: () {
              // 직접 입력 다이얼로그 표시
              _showCustomMealDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // 헤더 위젯
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${widget.mealType} 식사 추가',
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
    );
  }
  
  // 추천 메뉴 섹션
  Widget _buildRecommendedMenuSection(MealProvider mealProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            itemCount: mealProvider.generatedMenuByMealType[widget.standardCategory]?.length ?? 0,
            itemBuilder: (context, index) {
              final menu = mealProvider.generatedMenuByMealType[widget.standardCategory]![index];
              return _buildRecommendedMenuItem(context, menu, mealProvider);
            },
          ),
        ),
      ],
    );
  }
  
  // 추천 메뉴 아이템
  Widget _buildRecommendedMenuItem(BuildContext context, SimpleMenu menu, MealProvider mealProvider) {
    return ListTile(
      leading: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary),
      title: Text(menu.dishName),
      subtitle: Text(menu.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 식단 베이스에 저장 버튼
          _buildActionButton(
            icon: Icons.save_alt,
            label: '저장',
            color: Colors.green,
            onPressed: () async {
              await _saveToMealBase(context, menu, mealProvider);
            },
          ),
          
          // 기각 버튼
          _buildActionButton(
            icon: Icons.thumb_down,
            label: '기각',
            color: Colors.red[400]!,
            onPressed: () {
              _showRejectMenuDialog(context, menu);
            },
          ),
          
          // 캘린더에 추가 버튼
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: '추가',
            color: Theme.of(context).colorScheme.primary,
            onPressed: () async {
              await _addToCalendar(context, menu, mealProvider);
            },
          ),
        ],
      ),
    );
  }
  
  // 액션 버튼 위젯
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 20),
          tooltip: label,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(),
          onPressed: onPressed,
        ),
        SizedBox(height: 4),
        Container(
          height: 20,
          child: Text(
            label, 
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
  
  // 식단 베이스에 저장
  Future<void> _saveToMealBase(BuildContext context, SimpleMenu menu, MealProvider mealProvider) async {
    try {
      // 메뉴를 식단 베이스에 저장
      await mealProvider.saveSimpleMenuToMealBase(
        menu, 
        widget.mealType, // 한글 카테고리 사용
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
  }
  
  // 캘린더에 추가
  Future<void> _addToCalendar(BuildContext context, SimpleMenu menu, MealProvider mealProvider) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      // 메뉴를 캘린더에 저장
      await mealProvider.addMealToCalendar(
        date: widget.date,
        category: widget.standardCategory,
        name: menu.dishName,
        description: menu.description,
        recipeJson: menu.toJson(),
      );
      
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);
      
      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${menu.dishName}이(가) ${widget.mealType}으로 추가되었습니다'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // 다이얼로그 닫기
      Navigator.pop(context);
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);
      
      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추가 실패: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // 메뉴 기각 다이얼로그
  void _showRejectMenuDialog(BuildContext context, SimpleMenu menu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('메뉴 기각'),
        content: Text('${menu.dishName} 메뉴를 기각하시겠습니까?\n메뉴를 기각하면 다시 추천받을 수 없습니다.'),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('기각', style: TextStyle(color: Colors.red)),
            onPressed: () {
              // 기각 로직 추가
              Navigator.pop(context); // 다이얼로그 닫기
              
              // 사용자에게 피드백 제공
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${menu.dishName} 메뉴가 기각되었습니다.'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // 직접 입력 다이얼로그
  void _showCustomMealDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    String calories = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('직접 식단 추가'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '식단 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? '식단 이름을 입력하세요' : null,
                  onSaved: (value) => name = value!,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '설명',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? '설명을 입력하세요' : null,
                  onSaved: (value) => description = value!,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: '칼로리 (kcal)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => calories = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('추가'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                
                final mealProvider = Provider.of<MealProvider>(context, listen: false);
                
                try {
                  await mealProvider.addMealToCalendar(
                    date: widget.date,
                    category: widget.standardCategory,
                    name: name,
                    description: description,
                    calories: calories,
                  );
                  
                  Navigator.pop(context); // 직접 입력 다이얼로그 닫기
                  Navigator.pop(context); // 추가 다이얼로그 닫기
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name이(가) ${widget.mealType}으로 추가되었습니다'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('추가 실패: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
} 