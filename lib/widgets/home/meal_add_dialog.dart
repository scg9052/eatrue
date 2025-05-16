import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_provider.dart';
import '../../models/simple_menu.dart';
import '../../utils/meal_type_utils.dart';
import '../../l10n/app_localizations.dart';

/// 식사 추가 다이얼로그 표시
void showMealAddDialog(BuildContext context, DateTime date, String mealType) {
  final mealProvider = Provider.of<MealProvider>(context, listen: false);
  final localization = AppLocalizations.of(context);
  
  // 표준화된 카테고리 매핑
  String standardCategory;
  
  // mealType을 영어 카테고리로 변환 시도
  if (mealType == localization.breakfast || 
      mealType == localization.lunch || 
      mealType == localization.dinner || 
      mealType == localization.snack) {
    standardCategory = getEnglishCategory(mealType, context);
  } else {
    // 기존 방식으로 폴백
    standardCategory = standardizeCategory(mealType, toKorean: false);
  }
  
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
    final localization = AppLocalizations.of(context);
    
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
            localization.selectFromMealBase,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          // 식단 베이스 목록은 MealBaseList 위젯으로 분리 예정
          Text(localization.isKorean() ? '식단 베이스에서 선택 기능 (추가 예정)' : 'Select from meal base (coming soon)'),
          
          // 직접 추가 섹션
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text(localization.addMealManually),
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
    final localization = AppLocalizations.of(context);
    
    // 표시할 카테고리 이름 (지역화)
    String displayCategory;
    if (['breakfast', 'lunch', 'dinner', 'snack', 'snacks'].contains(widget.standardCategory.toLowerCase())) {
      displayCategory = getLocalizedCategory(widget.standardCategory, context);
    } else {
      displayCategory = widget.mealType; // 기존 이름 사용
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$displayCategory ${localization.addMealTitle}',
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
    final localization = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            localization.recommendedMenus,
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
    final localization = AppLocalizations.of(context);
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
            label: localization.saveButton,
            color: Colors.green,
            onPressed: () async {
              await _saveToMealBase(context, menu, mealProvider);
            },
          ),
          
          // 기각 버튼
          _buildActionButton(
            icon: Icons.thumb_down,
            label: localization.rejectButton,
            color: Colors.red[400]!,
            onPressed: () {
              _showRejectMenuDialog(context, menu);
            },
          ),
          
          // 캘린더에 추가 버튼
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: localization.addButton,
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
    final localization = AppLocalizations.of(context);
    try {
      // 메뉴를 식단 베이스에 저장
      await mealProvider.saveSimpleMenuToMealBase(
        menu, 
        widget.mealType, // 한글 카테고리 사용
        [localization.isKorean() ? '추천 메뉴' : 'Recommended Menu'], // 기본 태그
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.isKorean() 
              ? '${menu.dishName}${localization.mealSavedMessage}' 
              : '${menu.dishName}${localization.mealSavedMessage}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.mealSaveErrorMessage}$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // 캘린더에 추가
  Future<void> _addToCalendar(BuildContext context, SimpleMenu menu, MealProvider mealProvider) async {
    final localization = AppLocalizations.of(context);
    
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
          content: Text('${menu.dishName}${localization.addSuccess}'),
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
          content: Text('${localization.addFail}$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  // 메뉴 기각 다이얼로그
  void _showRejectMenuDialog(BuildContext context, SimpleMenu menu) {
    final localization = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.rejectMenuTitle),
        content: Text('${menu.dishName} ${localization.rejectMenuConfirm}'),
        actions: [
          TextButton(
            child: Text(localization.cancelButton),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(localization.rejectButton, style: TextStyle(color: Colors.red)),
            onPressed: () {
              // 기각 로직 추가
              Navigator.pop(context); // 다이얼로그 닫기
              
              // 사용자에게 피드백 제공
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${menu.dishName} ${localization.rejectMenuSuccess}'),
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
    final localization = AppLocalizations.of(context);
    String name = '';
    String description = '';
    String calories = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.addMealManuallyTitle),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localization.mealNameLabel,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? localization.mealNameValidation : null,
                  onSaved: (value) => name = value!,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localization.descriptionLabel,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? localization.descriptionValidation : null,
                  onSaved: (value) => description = value!,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: localization.caloriesLabel,
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
            child: Text(localization.cancelButton),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(localization.addButton),
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
                      content: Text('$name${localization.addSuccess}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${localization.addFail}$e'),
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