// widgets/survey_pages/survey_page_personal_info.dart
// (UserData에 activityLevel 추가됨에 따라, 해당 정보 입력 UI 추가)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPagePersonalInfo extends StatefulWidget {
  final Function(int? age, String? gender, double? height, double? weight, String? activityLevel, List<String> conditions, List<String> allergies) onUpdate;

  const SurveyPagePersonalInfo({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _SurveyPagePersonalInfoState createState() => _SurveyPagePersonalInfoState();
}

class _SurveyPagePersonalInfoState extends State<SurveyPagePersonalInfo> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['남성', '여성', '기타', '선택 안함'];

  // 활동 수준 옵션
  String? _selectedActivityLevel;
  final List<String> _activityLevels = ['매우 낮음 (거의 운동 안함)', '낮음 (주 1-2회 가벼운 운동)', '보통 (주 3-5회 중간 강도 운동)', '높음 (주 6-7회 고강도 운동)', '매우 높음 (매일 매우 고강도 운동 또는 육체노동)'];


  List<String> _underlyingConditions = [];
  List<String> _allergies = [];

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final UserData existingData = surveyDataProvider.userData;

    if (existingData.age != null) _ageController.text = existingData.age.toString();
    _selectedGender = existingData.gender;
    if (existingData.height != null) _heightController.text = existingData.height.toString();
    if (existingData.weight != null) _weightController.text = existingData.weight.toString();
    _selectedActivityLevel = existingData.activityLevel ?? _activityLevels[2]; // 기본값 '보통'
    _underlyingConditions = List<String>.from(existingData.underlyingConditions);
    _allergies = List<String>.from(existingData.allergies);
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontFamily: 'NotoSansKR'), // 테마 기본 폰트 적용
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
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _updateParent() {
    widget.onUpdate(
      int.tryParse(_ageController.text),
      _selectedGender,
      double.tryParse(_heightController.text),
      double.tryParse(_weightController.text),
      _selectedActivityLevel,
      List<String>.from(_underlyingConditions),
      List<String>.from(_allergies),
    );
    // SurveyScreen의 _isPageValid()가 재평가되도록 setState 호출
    if (mounted) {
      // 이 위젯 자체의 상태 변경이 없더라도, 부모의 버튼 활성화 상태를 위해 호출
      // Provider를 통해 데이터가 업데이트되면 SurveyScreen의 Consumer가 반응하여 _isPageValid가 호출될 수 있지만,
      // 명시적으로 setState를 호출하여 SurveyScreen의 build를 유도하는 것이 더 확실할 수 있습니다.
      // 다만, 이 페이지 자체의 UI 변경이 없다면 불필요할 수 있습니다.
      // 여기서는 SurveyScreen의 setState(() {}); 호출에 의존합니다.
    }
  }

  Widget _buildChipInputList({
    required String fieldLabel,
    required String inputLabel,
    required TextEditingController controller,
    required List<String> itemList,
    required Function(String) onAdd,
    required Function(String) onRemove,
    IconData? listIcon,
    String? hintText,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
            children: [
              TextSpan(text: fieldLabel),
              if (isRequired)
                TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: itemList.isNotEmpty ? EdgeInsets.all(10) : EdgeInsets.zero,
          decoration: itemList.isNotEmpty ? BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!)
          ) : null,
          child: Wrap(
            spacing: 8.0, runSpacing: 6.0,
            children: itemList.map((item) => Chip(
              avatar: listIcon != null ? Icon(listIcon, size: 18, color: Colors.green[700]) : null,
              label: Text(item, style: TextStyle(color: Colors.green[800])),
              onDeleted: () {
                setState(() { onRemove(item); _updateParent(); });
              },
              deleteIcon: Icon(Icons.close, size: 18), deleteIconColor: Colors.red[400],
              backgroundColor: Colors.green[100], padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  if (value.trim().isNotEmpty) {
                    setState(() { onAdd(value.trim()); controller.clear(); _updateParent(); });
                  }
                },
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  setState(() { onAdd(value); controller.clear(); _updateParent(); });
                }
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
        _buildRequiredLabel("연령 (만 나이)"),
        SizedBox(height: 10),
        TextField(
          controller: _ageController,
          decoration: _inputDecoration('나이 입력', hint: '예: 30', icon: Icons.cake_outlined, isRequired: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
          onChanged: (_) => _updateParent(),
        ),
        SizedBox(height: 24),

        _buildRequiredLabel("성별"),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('성별 선택', icon: Icons.wc_outlined, isRequired: true),
          value: _selectedGender,
          hint: Text('선택해주세요'),
          items: _genders.map((String gender) => DropdownMenuItem<String>(value: gender, child: Text(gender))).toList(),
          onChanged: (String? newValue) {
            setState(() { _selectedGender = newValue; });
            _updateParent();
          },
          isExpanded: true,
        ),
        SizedBox(height: 24),

        _buildRequiredLabel("신장 (cm)"),
        SizedBox(height: 10),
        TextField(
          controller: _heightController,
          decoration: _inputDecoration('신장 입력', hint: '예: 175.5', icon: Icons.height_outlined, suffixIcon: Text("cm  ", style: TextStyle(color: Colors.grey[600])), isRequired: true),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{1,3}(\.?\d{0,1})?$'))],
          onChanged: (_) => _updateParent(),
        ),
        SizedBox(height: 24),

        _buildRequiredLabel("체중 (kg)"),
        SizedBox(height: 10),
        TextField(
          controller: _weightController,
          decoration: _inputDecoration('체중 입력', hint: '예: 68.2', icon: Icons.monitor_weight_outlined, suffixIcon: Text("kg  ", style: TextStyle(color: Colors.grey[600])), isRequired: true),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{1,3}(\.?\d{0,1})?$'))],
          onChanged: (_) => _updateParent(),
        ),
        SizedBox(height: 24),

        // 활동 수준 드롭다운 추가
        _buildRequiredLabel("평소 활동 수준"),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('활동 수준 선택', icon: Icons.directions_run_outlined, isRequired: true),
          value: _selectedActivityLevel,
          hint: Text('선택해주세요'),
          items: _activityLevels.map((String level) => DropdownMenuItem<String>(value: level, child: Text(level, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (String? newValue) {
            setState(() { _selectedActivityLevel = newValue; });
            _updateParent();
          },
          isExpanded: true,
        ),
        SizedBox(height: 24),


        _buildChipInputList(
          fieldLabel: '지병 정보 (선택 사항)', inputLabel: '지병명 입력', hintText: '예: 당뇨, 고혈압 (입력 후 추가)',
          controller: _conditionsController, itemList: _underlyingConditions,
          onAdd: (condition) { if (!_underlyingConditions.contains(condition)) setState(() => _underlyingConditions.add(condition)); },
          onRemove: (condition) => _underlyingConditions.remove(condition),
          listIcon: Icons.local_hospital_outlined,
        ),

        _buildChipInputList(
          fieldLabel: '알레르기 정보 (선택 사항)', inputLabel: '알레르기 유발 식품/성분 입력', hintText: '예: 견과류, 갑각류 (입력 후 추가)',
          controller: _allergiesController, itemList: _allergies,
          onAdd: (allergy) { if (!_allergies.contains(allergy)) setState(() => _allergies.add(allergy)); },
          onRemove: (allergy) => _allergies.remove(allergy),
          listIcon: Icons.no_food_outlined,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _conditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}