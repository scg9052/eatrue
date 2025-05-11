// widgets/survey_pages/survey_page_food_preference.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일,
// UserData 모델에 dislikedCookingMethods, favoriteSeasonings, dislikedSeasonings 필드 추가 시 해당 UI 요소 추가 필요)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPageFoodPreference extends StatefulWidget {
  final Function(bool isVegan, bool isReligious, String? religionDetails, List<String> mealPurposes, double? mealBudget, List<String> favFoods, List<String> dislikedFoods, List<String> cookingMethods) onUpdate;

  const SurveyPageFoodPreference({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _SurveyPageFoodPreferenceState createState() => _SurveyPageFoodPreferenceState();
}

class _SurveyPageFoodPreferenceState extends State<SurveyPageFoodPreference> {
  bool _isVegan = false;
  bool _isReligiousDiet = false;

  final TextEditingController _religionDetailsController = TextEditingController();
  final TextEditingController _mealPurposeController = TextEditingController();
  List<String> _mealPurposes = [];

  final TextEditingController _mealBudgetController = TextEditingController();
  final TextEditingController _favoriteFoodController = TextEditingController();
  final TextEditingController _dislikedFoodController = TextEditingController();
  // final TextEditingController _favoriteSeasoningController = TextEditingController(); // 필요시 추가
  // final TextEditingController _dislikedSeasoningController = TextEditingController(); // 필요시 추가

  List<String> _favoriteFoods = [];
  List<String> _dislikedFoods = [];
  // List<String> _favoriteSeasonings = []; // 필요시 추가
  // List<String> _dislikedSeasonings = []; // 필요시 추가


  List<String> _allCookingMethods = ['상관없음','구이', '찜', '조림', '볶음', '튀김', '국/탕', '무침', '생식', '데치기', '굽기(오븐/에어프라이어)'];
  List<String> _selectedCookingMethods = [];
  // List<String> _allDislikedCookingMethods = ['튀김', '볶음', '기타 직접 입력']; // 예시, 필요시 확장
  // List<String> _selectedDislikedCookingMethods = []; // 필요시 추가

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final UserData existingData = surveyDataProvider.userData;

    _isVegan = existingData.isVegan;
    _isReligiousDiet = existingData.isReligious;
    _religionDetailsController.text = existingData.religionDetails ?? '';
    _mealPurposes = List<String>.from(existingData.mealPurpose);
    if (existingData.mealBudget != null) _mealBudgetController.text = existingData.mealBudget.toString();
    _favoriteFoods = List<String>.from(existingData.favoriteFoods);
    _dislikedFoods = List<String>.from(existingData.dislikedFoods);
    _selectedCookingMethods = List<String>.from(existingData.preferredCookingMethods);
    // _selectedDislikedCookingMethods = List<String>.from(existingData.dislikedCookingMethods ?? []);
    // _favoriteSeasonings = List<String>.from(existingData.favoriteSeasonings ?? []);
    // _dislikedSeasonings = List<String>.from(existingData.dislikedSeasonings ?? []);


    _religionDetailsController.addListener(_onReligionDetailsChanged);
  }

  void _onReligionDetailsChanged() {
    setState(() {}); // SurveyScreen의 버튼 상태 갱신 유도
    _updateParent();
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontFamily: 'NotoSansKR'),
          children: <TextSpan>[
            if (isRequired)
              TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).primaryColor) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[400]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey[400]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0)),
      filled: true, fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _updateParent() {
    widget.onUpdate(
      _isVegan,
      _isReligiousDiet,
      _religionDetailsController.text.trim().isEmpty ? null : _religionDetailsController.text.trim(),
      List<String>.from(_mealPurposes),
      double.tryParse(_mealBudgetController.text),
      List<String>.from(_favoriteFoods),
      List<String>.from(_dislikedFoods),
      List<String>.from(_selectedCookingMethods),
      // List<String>.from(_selectedDislikedCookingMethods), // UserData 확장 시 전달
      // List<String>.from(_favoriteSeasonings),
      // List<String>.from(_dislikedSeasonings),
    );
  }

  Widget _buildChipInputList({
    required String fieldLabel, required String inputLabel, required TextEditingController controller,
    required List<String> itemList, required Function(String) onAdd, required Function(String) onRemove,
    IconData? listIcon, String? hintText, Color chipBackgroundColor = const Color(0xFFE0F2F1),
    Color chipLabelColor = const Color(0xFF00796B), bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
            children: [
              TextSpan(text: fieldLabel),
              if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: itemList.isNotEmpty ? EdgeInsets.all(10) : EdgeInsets.zero,
          decoration: itemList.isNotEmpty ? BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)
          ) : null,
          child: Wrap(
            spacing: 8.0, runSpacing: 6.0,
            children: itemList.map((item) => Chip(
              avatar: listIcon != null ? Icon(listIcon, size: 18, color: chipLabelColor) : null,
              label: Text(item, style: TextStyle(color: chipLabelColor)),
              onDeleted: () { setState(() { onRemove(item); _updateParent(); }); },
              deleteIcon: Icon(Icons.close, size: 18), deleteIconColor: Colors.red[400],
              backgroundColor: chipBackgroundColor, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            )).toList(),
          ),
        ),
        SizedBox(height: itemList.isNotEmpty ? 12 : 0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: _inputDecoration(inputLabel, hint: hintText ?? '$inputLabel 입력 후 \'추가\' 또는 Enter', icon: Icons.edit_note),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) { setState(() { onAdd(value.trim()); controller.clear(); _updateParent(); }); }
                },
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) { setState(() { onAdd(value); controller.clear(); _updateParent(); }); }
              },
              child: Icon(Icons.add, size: 24),
              style: ElevatedButton.styleFrom(minimumSize: Size(60, 52), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCookingMethodSelector({required String fieldLabel, required List<String> allMethods, required List<String> selectedMethods, required Function(String, bool) onSelected, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
            children: [
              TextSpan(text: fieldLabel),
              if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 10.0, runSpacing: 8.0,
          children: allMethods.map((method) {
            final isSelected = selectedMethods.contains(method);
            return ChoiceChip(
              label: Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() { onSelected(method, selected); }); // 내부 로직은 onSelected 콜백으로 위임
                _updateParent();
              },
              selectedColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Theme.of(context).primaryColorDark : Colors.grey[300]!)),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRequiredLabel(String labelText) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
        children: [
          TextSpan(text: labelText),
          TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text('채식주의(Vegan)이신가요?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          value: _isVegan,
          onChanged: (bool value) { setState(() { _isVegan = value; }); _updateParent(); },
          secondary: Icon(Icons.eco_outlined, color: Theme.of(context).primaryColor, size: 28),
          activeColor: Theme.of(context).primaryColor, contentPadding: EdgeInsets.symmetric(horizontal: 8),
          tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        SizedBox(height: 16),

        SwitchListTile(
          title: Text('종교적 식단 제한이 있으신가요?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          subtitle: Text('(예: 할랄, 코셔 등 특정 음식 제한)', style: TextStyle(fontSize: 13)),
          value: _isReligiousDiet,
          onChanged: (bool value) {
            setState(() { _isReligiousDiet = value; if (!_isReligiousDiet) _religionDetailsController.clear(); });
            _updateParent();
          },
          secondary: Icon(Icons.kebab_dining_outlined, color: Theme.of(context).primaryColor, size: 28),
          activeColor: Theme.of(context).primaryColor, contentPadding: EdgeInsets.symmetric(horizontal: 8),
          tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        if (_isReligiousDiet)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0, bottom: 20.0),
            child: TextField(
              controller: _religionDetailsController,
              decoration: _inputDecoration('종교 또는 식단 제한 상세 정보', hint: '예: 이슬람교 (할랄)', icon: Icons.info_outline, isRequired: true),
            ),
          ),
        if (!_isReligiousDiet) SizedBox(height: 24),

        _buildChipInputList(
          fieldLabel: '주요 식사 목적 (다중 선택 가능)', inputLabel: '목적 입력', hintText: '예: 근성장, 다이어트 (입력 후 추가)',
          controller: _mealPurposeController, itemList: _mealPurposes,
          onAdd: (purpose) { if (!_mealPurposes.contains(purpose)) setState(() => _mealPurposes.add(purpose)); },
          onRemove: (purpose) => setState(() => _mealPurposes.remove(purpose)),
          listIcon: Icons.flag_circle_outlined, chipBackgroundColor: Colors.blue[100]!, chipLabelColor: Colors.blue[800]!,
          isRequired: true,
        ),

        _buildRequiredLabel("한 끼 식비 한도 (원)"),
        SizedBox(height: 10),
        TextField(
          controller: _mealBudgetController,
          decoration: _inputDecoration('식비 한도 입력', hint: '예: 10000 (숫자만)', icon: Icons.payments_outlined, suffixIcon: Text("원  ", style: TextStyle(color: Colors.grey[600])), isRequired: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
          onChanged: (_) => _updateParent(),
        ),
        SizedBox(height: 24),

        _buildChipInputList(
          fieldLabel: '선호하는 음식 또는 식재료', inputLabel: '선호 음식/식재료 입력',
          controller: _favoriteFoodController, itemList: _favoriteFoods,
          onAdd: (food) { if (!_favoriteFoods.contains(food)) setState(() => _favoriteFoods.add(food)); },
          onRemove: (food) => setState(() => _favoriteFoods.remove(food)),
          listIcon: Icons.favorite_outline, chipBackgroundColor: Colors.pink[50]!, chipLabelColor: Colors.pink[700]!,
        ),

        _buildChipInputList(
          fieldLabel: '기피하는 음식 또는 식재료', inputLabel: '기피 음식/식재료 입력',
          controller: _dislikedFoodController, itemList: _dislikedFoods,
          onAdd: (food) { if (!_dislikedFoods.contains(food)) setState(() => _dislikedFoods.add(food)); },
          onRemove: (food) => setState(() => _dislikedFoods.remove(food)),
          listIcon: Icons.sentiment_very_dissatisfied_outlined, chipBackgroundColor: Colors.grey[300]!, chipLabelColor: Colors.black54,
        ),

        _buildCookingMethodSelector(
            fieldLabel: "선호하는 조리 방식 (다중 선택 가능)",
            allMethods: _allCookingMethods,
            selectedMethods: _selectedCookingMethods,
            onSelected: (method, selected) {
              if (method == '상관없음') {
                if (selected) { _selectedCookingMethods.clear(); _selectedCookingMethods.add(method); }
                else { _selectedCookingMethods.remove(method); }
              } else {
                _selectedCookingMethods.remove('상관없음');
                if (selected) { _selectedCookingMethods.add(method); }
                else { _selectedCookingMethods.remove(method); }
              }
            },
            isRequired: true
        ),
        // 여기에 비선호 조리 방식, 선호/비선호 양념 입력 UI 추가 가능
      ],
    );
  }

  @override
  void dispose() {
    _religionDetailsController.removeListener(_onReligionDetailsChanged);
    _religionDetailsController.dispose();
    _mealPurposeController.dispose();
    _mealBudgetController.dispose();
    _favoriteFoodController.dispose();
    _dislikedFoodController.dispose();
    // _favoriteSeasoningController.dispose();
    // _dislikedSeasoningController.dispose();
    super.dispose();
  }
}