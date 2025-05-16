import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/meal_provider.dart';
import '../../l10n/app_localizations.dart';

/// 식단 베이스에 저장하는 다이얼로그
class SaveToMealBaseDialog extends StatefulWidget {
  final Recipe recipe;
  
  const SaveToMealBaseDialog({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  _SaveToMealBaseDialogState createState() => _SaveToMealBaseDialogState();
}

class _SaveToMealBaseDialogState extends State<SaveToMealBaseDialog> {
  // 선택된 카테고리, 태그 목록 (초기값 설정)
  String _selectedCategory = '';
  final List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    // 초기 카테고리 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localization = AppLocalizations.of(context);
      setState(() {
        _selectedCategory = localization.lunch;
      });
    });
  }
  
  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    
    // 카테고리 옵션 목록
    final _categoryOptions = [
      localization.breakfast,
      localization.lunch,
      localization.dinner,
      localization.snack
    ];
    
    // 기본 태그 목록
    final _tagSuggestions = [
      localization.healthyMeal, 
      localization.protein, 
      'Diet', 
      'High Protein', 
      'Low Carb'
    ];
    
    return AlertDialog(
      title: Text(localization.saveToMealBase),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // 카테고리 선택
            Text('${localization.sort}', style: theme.textTheme.titleSmall),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryOptions.map((category) => 
                ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                )
              ).toList(),
            ),
            SizedBox(height: 16),
            
            // 태그 선택
            Text('${localization.addTag}', style: theme.textTheme.titleSmall),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagSuggestions.map((tag) => 
                FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                )
              ).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.cancelButton),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _saveToMealBase(context),
          child: _isSaving 
            ? SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(strokeWidth: 2)
              )
            : Text(localization.saveButton),
        ),
      ],
    );
  }
  
  // 식단 베이스에 저장하는 메서드
  void _saveToMealBase(BuildContext context) async {
    final localization = AppLocalizations.of(context);
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 칼로리 정보 추출
      String calories = '${localization.calories} ${localization.none}';
      if (widget.recipe.nutritionalInformation != null) {
        // 여러 가능한 칼로리 키 확인
        final caloriesKeys = ['calories', 'calorie', 'Calories', localization.calories.toLowerCase()];
        for (final key in caloriesKeys) {
          if (widget.recipe.nutritionalInformation!.containsKey(key)) {
            calories = widget.recipe.nutritionalInformation![key].toString();
            break;
          }
        }
      }
      
      // SimpleMenu 객체를 생성하여 식단 베이스에 저장
      await Provider.of<MealProvider>(context, listen: false)
          .saveRecipeToMealBase(
            widget.recipe, 
            _selectedCategory, 
            _selectedTags.isNotEmpty ? _selectedTags : null,
            calories,
          );
      
      Navigator.of(context).pop();
      
      // 저장 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.recipe.title}${localization.mealSavedMessage}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 에러 메시지 표시
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.mealSaveErrorMessage}$e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 