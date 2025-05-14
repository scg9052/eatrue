// screens/recipe_detail_screen.dart
// (이전 flutter_recipe_detail_screen_ingredient_fix 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
// import '../models/ingredient.dart'; // Recipe 모델에서 직접 사용하지 않으므로 주석 처리 또는 제거
import '../providers/meal_provider.dart';
import '../widgets/dialogs/save_to_meal_base_dialog.dart'; // 식단 베이스 저장 다이얼로그 추가

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  RecipeDetailScreen({required this.recipe});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  double _currentRating = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.recipe.rating;
    print('레시피 상세 화면 초기화 - 레시피: ${widget.recipe.title}, 평점: $_currentRating');
    _printRecipeDetails();
  }
  
  // 디버깅용 레시피 세부 정보 출력
  void _printRecipeDetails() {
    print('레시피 ID: ${widget.recipe.id}');
    print('레시피 제목: ${widget.recipe.title}');
    print('조리 시간: ${widget.recipe.cookingTimeMinutes}');
    print('난이도: ${widget.recipe.difficulty}');
    print('조리 단계 수: ${widget.recipe.cookingInstructions.length}');
    
    if (widget.recipe.ingredients != null) {
      print('재료 수: ${widget.recipe.ingredients!.length}');
      widget.recipe.ingredients!.forEach((name, quantity) {
        print('- $name: $quantity');
      });
    } else {
      print('재료 정보 없음');
    }
    
    if (widget.recipe.nutritionalInformation != null) {
      print('영양 정보: ${widget.recipe.nutritionalInformation!.keys.join(', ')}');
    } else {
      print('영양 정보 없음');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    print('레시피 디테일 화면 빌드 - 다크모드: $isDarkMode');
    
    // 상태 업데이트 및 UI 갱신을 위한 PostFrame 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final latestRating = Provider.of<MealProvider>(context, listen: false).getRatingForRecipe(widget.recipe.id);
        if (latestRating != null && latestRating != _currentRating) {
          setState(() { _currentRating = latestRating; });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('레시피 상세'),
        elevation: 0,
        actions: [
          // 식단 베이스 저장 버튼 추가 (추후 구현)
          IconButton(
            icon: Icon(Icons.bookmark_border),
            tooltip: '식단 베이스에 저장',
            onPressed: () => _saveToMealBase(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 레시피 헤더 (제목, 평점 등)
            _buildRecipeHeader(context),
            
            SizedBox(height: 24),
            
            // 영양 정보 섹션
            if (_hasNutritionalInformation())
              _buildNutritionalInfoSection(context),
            
            // 재료 섹션
            _buildIngredientsSection(context),
            
            // 조리 순서 섹션
            _buildSectionTitle('조리 순서', Icons.restaurant, context),
            _buildCookingInstructionsCard(context),
            
            SizedBox(height: 24),
            
            // 레시피 평가 섹션
            _buildRatingSection(context),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 레시피 헤더 위젯 (제목, 평점, 기본 정보)
  Widget _buildRecipeHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레시피 제목
          Text(
            widget.recipe.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          
          // 칼로리 정보
          _buildCaloriesInfo(context),
          
          SizedBox(height: 16),
          
          // 평점 표시
          Row(
            children: [
              Text('평점: ', style: textTheme.bodyLarge),
              _buildRatingStars(),
            ],
          ),
          
          SizedBox(height: 16),
          
          // 레시피 기본 정보 (조리 시간, 난이도)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.access_time, 
                '${widget.recipe.cookingTimeMinutes ?? '30'}분',
                context
              ),
              _buildInfoItem(
                Icons.trending_up, 
                '난이도: ${_getDifficulty(widget.recipe.difficulty)}',
                context
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 칼로리 정보 표시 위젯
  Widget _buildCaloriesInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 영양 정보에서 칼로리 찾기
    if (widget.recipe.nutritionalInformation != null) {
      // 대소문자 구분 없이 'calories' 키 찾기
      final caloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
      String? caloriesValue;
      
      // 여러 가능한 키를 확인
      for (final key in caloriesKeys) {
        if (widget.recipe.nutritionalInformation!.containsKey(key)) {
          caloriesValue = widget.recipe.nutritionalInformation![key].toString();
          break;
        }
      }
      
      // 칼로리 정보가 있으면 표시
      if (caloriesValue != null && caloriesValue.isNotEmpty) {
        // 숫자 뒤에 "kcal" 없으면 추가
        if (!caloriesValue.toLowerCase().contains('kcal')) {
          caloriesValue = "$caloriesValue kcal";
        }
        
        return Row(
          children: [
            Icon(Icons.local_fire_department, 
              size: 20, 
              color: Colors.orange[700]
            ),
            SizedBox(width: 8),
            Text(
              '칼로리: $caloriesValue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.orange[300] : Colors.orange[800],
              ),
            ),
          ],
        );
      }
    }
    
    // 대체 텍스트
    return Text(
      '건강한 식단',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }
  
  // 영양 정보가 있는지 확인
  bool _hasNutritionalInformation() {
    return widget.recipe.nutritionalInformation != null && 
           widget.recipe.nutritionalInformation!.isNotEmpty;
  }
  
  // 영양 정보 섹션 위젯
  Widget _buildNutritionalInfoSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 영양 정보 필터링 - 칼로리 정보는 위에서 이미 표시하므로 제외
    final filteredNutritionInfo = Map<String, dynamic>.from(widget.recipe.nutritionalInformation!);
    final caloriesKeys = ['calories', 'calorie', 'Calories', '칼로리'];
    
    // 중요 영양소 순서와 번역
    final importantNutrients = {
      'protein': '단백질',
      'carbohydrates': '탄수화물', 
      'carbs': '탄수화물',
      'fats': '지방',
      'fat': '지방',
      'fiber': '식이섬유',
      'sodium': '나트륨',
      'sugar': '당류',
    };
    
    // 중요 영양소 위젯 목록 생성
    List<Widget> nutrientWidgets = [];
    
    // 먼저 중요 영양소 표시
    importantNutrients.forEach((engKey, korName) {
      if (filteredNutritionInfo.containsKey(engKey)) {
        final value = filteredNutritionInfo[engKey];
        nutrientWidgets.add(
          _buildNutrientItem(context, korName, value.toString())
        );
        // 처리 완료된 항목 제거
        filteredNutritionInfo.remove(engKey);
      }
    });
    
    // 칼로리 정보 제거
    for (final key in caloriesKeys) {
      filteredNutritionInfo.remove(key);
    }
    
    // 나머지 영양소 정보 표시
    filteredNutritionInfo.forEach((key, value) {
      final translatedKey = _translateNutritionKey(key);
      nutrientWidgets.add(
        _buildNutrientItem(context, translatedKey, value.toString())
      );
    });
    
    if (nutrientWidgets.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('영양 정보', Icons.monitor_heart_outlined, context),
        Card(
          elevation: 1, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: nutrientWidgets,
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
  
  // 영양소 항목 위젯
  Widget _buildNutrientItem(BuildContext context, String name, String value) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, size: 8, 
            color: Theme.of(context).colorScheme.secondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(name, 
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500
              )
            ),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700]
            ),
          ),
        ],
      ),
    );
  }

  // 재료 섹션 위젯
  Widget _buildIngredientsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주재료 섹션
        if (widget.recipe.ingredients != null && widget.recipe.ingredients!.isNotEmpty) ...[
          _buildSectionTitle('준비재료', Icons.shopping_cart, context),
          _buildMapIngredientListCard(widget.recipe.ingredients!, "주재료", context),
          SizedBox(height: 16),
        ],
        
        // 양념 섹션
        if (widget.recipe.seasonings != null && widget.recipe.seasonings!.isNotEmpty) ...[
          _buildSectionTitle('양념', Icons.spa_outlined, context),
          _buildMapIngredientListCard(widget.recipe.seasonings!, "양념", context),
          SizedBox(height: 24),
        ],
        
        // 재료가 없는 경우 기본 재료 표시
        if ((widget.recipe.ingredients == null || widget.recipe.ingredients!.isEmpty) &&
            (widget.recipe.seasonings == null || widget.recipe.seasonings!.isEmpty)) ...[
          _buildSectionTitle('준비재료', Icons.shopping_cart, context),
          _buildDefaultIngredientsCard(context),
          SizedBox(height: 24),
        ],
      ],
    );
  }

  // 기본 재료 카드 (재료 정보가 없을 때 표시)
  Widget _buildDefaultIngredientsCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 레시피 제목에서 주요 재료 추출 시도
    final List<String> possibleIngredients = [];
    final title = widget.recipe.title.toLowerCase();
    
    // 일반적인 한식 재료
    final commonIngredients = [
      '쌀', '김치', '고추장', '된장', '간장', '마늘', '파', '양파', '고기', '돼지고기', 
      '소고기', '닭고기', '계란', '달걀', '참기름', '들기름', '깨', '두부'
    ];
    
    for (var ingredient in commonIngredients) {
      if (title.contains(ingredient.toLowerCase())) {
        possibleIngredients.add(ingredient);
      }
    }
    
    // 기본 재료 추가 (항상 표시)
    final defaultIngredients = {'소금': '약간', '후추': '약간', '물': '적당량'};
    if (possibleIngredients.isNotEmpty) {
      for (var ingredient in possibleIngredients) {
        defaultIngredients[ingredient] = '적당량';
      }
    } else {
      // 제목에서 재료를 찾지 못한 경우 기본 재료 추가
      defaultIngredients['주 재료'] = '적당량';
      defaultIngredients['양념'] = '적당량';
    }
    
    return Card(
      elevation: 1, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: defaultIngredients.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0), 
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 10, color: Theme.of(context).colorScheme.secondary), 
                SizedBox(width: 10), 
                Expanded(child: Text(entry.key, style: textTheme.bodyLarge?.copyWith(fontSize: 15))),
                Text(
                  entry.value, 
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 15, 
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700]
                  )
                )
              ]
            )
          )).toList()
        )
      )
    );
  }

  // 조리 지침 카드 위젯
  Widget _buildCookingInstructionsCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    // 조리 지침이 없거나 비어있는 경우 기본 지침 제공
    List<String> instructions = widget.recipe.cookingInstructions;
    if (instructions.isEmpty || (instructions.length == 1 && instructions[0] == '조리 지침이 없습니다.')) {
      instructions = _generateDefaultInstructions();
    }
    
    return Card(
      elevation: 1, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: ListView.builder(
          shrinkWrap: true, 
          physics: NeverScrollableScrollPhysics(), 
          itemCount: instructions.length, 
          itemBuilder: (context, index) {
            final step = instructions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Container(
                    padding: EdgeInsets.all(6), 
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer, 
                      shape: BoxShape.circle
                    ), 
                    child: Text(
                      '${index + 1}', 
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13
                      )
                    )
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step, 
                      style: textTheme.bodyLarge?.copyWith(
                        height: 1.5, 
                        fontSize: 16
                      )
                    )
                  ),
                ]
              )
            );
          }
        )
      )
    );
  }
  
  // 기본 조리 지침 생성
  List<String> _generateDefaultInstructions() {
    return [
      "재료를 깨끗이 씻고 손질합니다.",
      "준비된 재료와 양념을 잘 섞어줍니다.",
      "적당한 온도로 가열하여 익힙니다.",
      "완성된 요리를 그릇에 담아 마무리합니다."
    ];
  }
  
  // 레시피 평가 섹션 위젯
  Widget _buildRatingSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('레시피 평가하기', Icons.thumb_up_alt_outlined, context),
        Card(
          elevation: 1, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
          child: Padding(
            padding: const EdgeInsets.all(20.0), 
            child: Column(
              children: [
                Text('이 레시피, 어떠셨나요? 별점으로 알려주세요!', style: textTheme.titleMedium),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: List.generate(
                    5, 
                    (index) => IconButton(
                      icon: Icon(
                        index < _currentRating ? Icons.star_rounded : Icons.star_border_rounded, 
                        color: Colors.amber, 
                        size: 36
                      ), 
                      onPressed: () => _updateRating(index + 1.0)
                    )
                  )
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.send_outlined), 
                  label: Text('평점 제출하기'), 
                  onPressed: _currentRating > 0 ? () { 
                    Provider.of<MealProvider>(context, listen: false).rateRecipe(widget.recipe.id, _currentRating);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('소중한 평점 감사합니다: ${_currentRating.toStringAsFixed(1)}점'), 
                        backgroundColor: Colors.green, 
                        behavior: SnackBarBehavior.floating, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
                        margin: EdgeInsets.all(10)
                      )
                    );
                  } : null, 
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12))
                ),
              ]
            )
          )
        ),
      ],
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top:8.0, bottom: 8.0), 
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26), 
          SizedBox(width: 8), 
          Text(
            title, 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600, 
              color: Theme.of(context).colorScheme.primary
            )
          )
        ]
      )
    );
  }

  // 정보 아이템 위젯 (조리 시간, 난이도 등)
  Widget _buildInfoItem(IconData icon, String text, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 4),
        Text(
          text, 
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  // 재료 목록 카드 위젯
  Widget _buildMapIngredientListCard(Map<String, String> items, String title, BuildContext context) {
    if (items.isEmpty) return SizedBox.shrink();
    
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 1, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: items.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0), 
            child: Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 10, color: Theme.of(context).colorScheme.secondary), 
                SizedBox(width: 10), 
                Expanded(child: Text(entry.key, style: textTheme.bodyLarge?.copyWith(fontSize: 15))),
                Text(
                  entry.value, 
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 15, 
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700]
                  )
                )
              ]
            )
          )).toList()
        )
      )
    );
  }
  
  // 영양성분 키 번역
  String _translateNutritionKey(String key) {
    final translationMap = {
      'calories': '칼로리',
      'protein': '단백질',
      'carbohydrates': '탄수화물',
      'carbs': '탄수화물',
      'fats': '지방',
      'fat': '지방',
      'sodium': '나트륨',
      'sugar': '당류',
      'fiber': '식이섬유',
      'vitamins': '비타민',
      'minerals': '미네랄',
      'cholesterol': '콜레스테롤',
    };
    
    final lowercaseKey = key.toLowerCase();
    return translationMap[lowercaseKey] ?? key;
  }

  // 별점 위젯
  Widget _buildRatingStars() {
    return Row(
      children: List.generate(5, (index) => IconButton(
        icon: Icon(
          index < _currentRating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: 36
        ),
        onPressed: () => _updateRating(index + 1.0)
      )),
    );
  }

  // 평점 업데이트
  void _updateRating(double rating) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    setState(() {
      _currentRating = rating;
    });
    print('레시피 평점 업데이트: $rating');
    mealProvider.rateRecipe(widget.recipe.id, rating);
  }

  // 난이도 텍스트 변환
  String _getDifficulty(String? difficulty) {
    if (difficulty == null) return '보통';
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '쉬움';
      case 'medium':
      case 'normal':
        return '보통';
      case 'hard':
      case 'difficult':
        return '어려움';
      default:
        return difficulty;
    }
  }
  
  // 식단 베이스에 저장
  void _saveToMealBase(BuildContext context) {
    // 카테고리 선택 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => SaveToMealBaseDialog(recipe: widget.recipe),
    );
  }
}