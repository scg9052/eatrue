import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../utils/meal_type_utils.dart';

/// 하나의 식단 카드를 표시하는 위젯
class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  
  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealTypeIcon = getMealTypeIcon(meal.category);
    
    Text mealTitleText = Text(
      translateMenuName(meal.name),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget mealCategoryText = Text(
      meal.category.isNotEmpty ? meal.category : '기타',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 식단 이름 및 삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(mealTypeIcon, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: mealTitleText,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null) 
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: onDelete,
                    ),
                ],
              ),
              
              // 카테고리 표시
              Padding(
                padding: EdgeInsets.only(top: 4, left: 32),
                child: mealCategoryText,
              ),
              
              // 식단 설명
              if (meal.description?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 32),
                  child: Text(
                    meal.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // 칼로리 정보
              if (meal.calories?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(top: 4, left: 32),
                  child: Text(
                    meal.calories!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              // 레시피 상세 보기 안내
              if (meal.recipeJson != null)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 32),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '레시피 보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 