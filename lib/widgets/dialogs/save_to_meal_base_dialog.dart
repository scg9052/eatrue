import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/meal_provider.dart';

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
  String _selectedCategory = '점심';
  List<String> _selectedTags = [];
  final List<String> _availableTags = [
    '건강식', '단백질', '다이어트', '고단백', '저탄수화물', 
    '비건', '글루텐프리', '간편식', '한식', '양식', '일식', '중식'
  ];
  
  final _categoryOptions = ['아침', '점심', '저녁', '간식'];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text('식단 베이스에 저장'),
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
            Text('카테고리 선택', style: theme.textTheme.titleSmall),
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
            Text('태그 선택 (선택사항)', style: theme.textTheme.titleSmall),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) => 
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
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _saveToMealBase(context),
          child: _isSaving 
            ? SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(strokeWidth: 2)
              )
            : Text('저장'),
        ),
      ],
    );
  }
  
  // 식단 베이스에 저장하는 메서드
  void _saveToMealBase(BuildContext context) async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 칼로리 정보 추출
      String calories = '칼로리 정보 없음';
      if (widget.recipe.nutritionalInformation != null) {
        final caloriesKey = widget.recipe.nutritionalInformation!.keys
            .firstWhere(
              (key) => key.toLowerCase().contains('calor'), 
              orElse: () => ''
            );
            
        if (caloriesKey.isNotEmpty) {
          calories = widget.recipe.nutritionalInformation![caloriesKey].toString();
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
          content: Text('${widget.recipe.title}이(가) 식단 베이스에 저장되었습니다.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // 에러 메시지 표시
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 