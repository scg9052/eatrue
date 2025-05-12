// screens/recipe_detail_screen.dart
// (이전 flutter_recipe_detail_screen_ingredient_fix 문서 내용과 동일)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
// import '../models/ingredient.dart'; // Recipe 모델에서 직접 사용하지 않으므로 주석 처리 또는 제거
import '../providers/meal_provider.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final latestRating = Provider.of<MealProvider>(context, listen: false).getRatingForRecipe(widget.recipe.id);
        if (latestRating != null && latestRating != _currentRating) {
          setState(() { _currentRating = latestRating; });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.title), elevation: 1),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipe.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            if (widget.recipe.costInformation != null && widget.recipe.costInformation!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("예상 비용: ${widget.recipe.costInformation}", style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]))),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (widget.recipe.cookingTimeMinutes != null && widget.recipe.cookingTimeMinutes! > 0) 
                      _buildInfoColumn(Icons.timer_outlined, '조리 시간', '${widget.recipe.cookingTimeMinutes}분', context),
                    if (widget.recipe.difficulty != null && widget.recipe.difficulty!.isNotEmpty) 
                      _buildInfoColumn(Icons.leaderboard_outlined, '난이도', widget.recipe.difficulty!, context),
                    _buildInfoColumn(Icons.star_outline, '현재 평점', _currentRating > 0 ?
                      '${_currentRating.toStringAsFixed(1)} / 5.0' : '평가없음', context),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (widget.recipe.nutritionalInformation != null && widget.recipe.nutritionalInformation!.isNotEmpty) ...[
              _buildSectionTitle('영양 정보', Icons.monitor_heart_outlined, context),
              Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widget.recipe.nutritionalInformation!.entries.map((entry) {
                if (entry.value is List) return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('${_translateNutritionKey(entry.key)}: ${(entry.value as List).join(', ')}', style: textTheme.bodyLarge));
                return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Text('${_translateNutritionKey(entry.key)}: ${entry.value}', style: textTheme.bodyLarge));
              }).toList()))),
              SizedBox(height: 24),
            ],
            if (widget.recipe.ingredients != null && widget.recipe.ingredients!.isNotEmpty) ...[
              _buildSectionTitle('준비재료', Icons.inventory_2_outlined, context),
              _buildMapIngredientListCard(widget.recipe.ingredients!, "주재료", context),
              SizedBox(height: 16),
            ],
            if (widget.recipe.seasonings != null && widget.recipe.seasonings!.isNotEmpty) ...[
              _buildSectionTitle('양념', Icons.spa_outlined, context),
              _buildMapIngredientListCard(widget.recipe.seasonings!, "양념", context),
              SizedBox(height: 24),
            ],
            _buildSectionTitle('조리 순서', Icons.list_alt_outlined, context),
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), itemCount: widget.recipe.cookingInstructions.length, itemBuilder: (context, index) {
              final step = widget.recipe.cookingInstructions[index];
              return Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle), child: Text('${index + 1}', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(width: 12),
                Expanded(child: Text(step, style: textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 16))),
              ]));
            }))),
            SizedBox(height: 24),
            _buildSectionTitle('레시피 평가하기', Icons.thumb_up_alt_outlined, context),
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
              Text('이 레시피, 어떠셨나요? 별점으로 알려주세요!', style: textTheme.titleMedium),
              SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(icon: Icon(index < _currentRating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 36), onPressed: () => setState(() => _currentRating = index + 1.0)))),
              SizedBox(height: 16),
              ElevatedButton.icon(icon: Icon(Icons.send_outlined), label: Text('평점 제출하기'), onPressed: _currentRating > 0 ? () { Provider.of<MealProvider>(context, listen: false).rateRecipe(widget.recipe.id, _currentRating); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('소중한 평점 감사합니다: ${_currentRating.toStringAsFixed(1)}점'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: EdgeInsets.all(10))); } : null, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12))),
            ]))),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, BuildContext context) => Padding(padding: const EdgeInsets.only(top:8.0, bottom: 8.0), child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26), SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary))]));
  Widget _buildInfoColumn(IconData icon, String title, String value, BuildContext context) { /* ... 이전과 동일 ... */ final textTheme = Theme.of(context).textTheme; return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28), SizedBox(height: 8), Text(title, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])), SizedBox(height: 4), Text(value, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)])); }
  Widget _buildMapIngredientListCard(Map<String, String> items, String title, BuildContext context) { /* ... 이전과 동일 ... */ if (items.isEmpty) return SizedBox.shrink(); final textTheme = Theme.of(context).textTheme; return Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items.entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(children: [Icon(Icons.fiber_manual_record, size: 10, color: Theme.of(context).colorScheme.secondary), SizedBox(width: 10), Expanded(child: Text(entry.key, style: textTheme.bodyLarge?.copyWith(fontSize: 15))), Text(entry.value, style: textTheme.bodyLarge?.copyWith(fontSize: 15, color: Colors.grey[700]))]))).toList()))); }
  String _translateNutritionKey(String key) { /* ... 이전과 동일 ... */ switch (key.toLowerCase()) { case 'calories': return '칼로리'; case 'protein': return '단백질'; case 'carbohydrates': return '탄수화물'; case 'fats': return '지방'; case 'vitamins': return '비타민'; case 'minerals': return '미네랄'; default: return key; } }
}