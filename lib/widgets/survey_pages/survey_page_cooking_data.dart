// widgets/survey_pages/survey_page_cooking_data.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일하게 유지)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPageCookingData extends StatefulWidget {
  final Function(List<String> cookingTools, int? preferredTime) onUpdate;

  const SurveyPageCookingData({Key? key, required this.onUpdate}) : super(key: key);

  @override
  _SurveyPageCookingDataState createState() => _SurveyPageCookingDataState();
}

class _SurveyPageCookingDataState extends State<SurveyPageCookingData> {
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _cookingToolController = TextEditingController();

  List<String> _commonCookingTools = ['상관없음','전자레인지', '가스레인지', '인덕션', '에어프라이어', '오븐', '전기밥솥', '냄비', '프라이팬', '칼', '도마', '믹서기', '커피포트'];
  List<String> _selectedCookingTools = [];

  @override
  void initState() {
    super.initState();
    final surveyDataProvider = Provider.of<SurveyDataProvider>(context, listen: false);
    final UserData existingData = surveyDataProvider.userData;

    _selectedCookingTools = List<String>.from(existingData.availableCookingTools);
    if (existingData.preferredCookingTime != null) {
      _preferredTimeController.text = existingData.preferredCookingTime.toString();
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.grey[700], fontSize: 16, fontFamily: 'NotoSansKR'),
          children: <TextSpan>[
            if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      List<String>.from(_selectedCookingTools),
      int.tryParse(_preferredTimeController.text),
    );
    // SurveyScreen의 _isPageValid()가 재평가되도록 setState 호출
    if (mounted) {
      // Provider를 통해 데이터가 업데이트되면 SurveyScreen의 Consumer가 반응하여 _isPageValid가 호출될 수 있지만,
      // 명시적으로 setState를 호출하여 SurveyScreen의 build를 유도하는 것이 더 확실할 수 있습니다.
      // 이 페이지 자체의 UI 변경이 없다면 불필요할 수 있습니다.
    }
  }

  Widget _buildCookingToolSelector({bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'NotoSansKR'),
            children: [
              TextSpan(text: "사용 가능한 조리 도구 (다중 선택 가능)"),
              if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 10.0, runSpacing: 8.0,
          children: _commonCookingTools.map((tool) {
            final isSelected = _selectedCookingTools.contains(tool);
            return ChoiceChip(
              label: Text(tool, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (tool == '상관없음') {
                    if (selected) { _selectedCookingTools.clear(); _selectedCookingTools.add(tool); }
                    else { _selectedCookingTools.remove(tool); }
                  } else {
                    _selectedCookingTools.remove('상관없음');
                    if (selected) { _selectedCookingTools.add(tool); }
                    else { _selectedCookingTools.remove(tool); }
                  }
                  _updateParent();
                });
              },
              selectedColor: Theme.of(context).primaryColor, backgroundColor: Colors.grey[200],
              avatar: isSelected ? Icon(Icons.check, color: Colors.white, size: 16) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Theme.of(context).primaryColorDark : Colors.grey[300]!)),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Text("기타 조리 도구 (직접 추가)", style: TextStyle(fontSize: 15, color: Colors.grey[800], fontWeight: FontWeight.w500)),
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _cookingToolController,
                decoration: _inputDecoration('조리 도구명 입력', hint: '예: 멀티쿠커 (입력 후 추가)', icon: Icons.kitchen_outlined),
                onSubmitted: (value) => _addCustomTool(value),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _addCustomTool(_cookingToolController.text),
              child: Icon(Icons.add, size: 24),
              style: ElevatedButton.styleFrom(minimumSize: Size(60, 52), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 8.0, runSpacing: 6.0,
          children: _selectedCookingTools
              .where((tool) => !_commonCookingTools.contains(tool) && tool != '상관없음')
              .map((tool) => Chip(
            label: Text(tool, style: TextStyle(color: Colors.purple[800])),
            avatar: Icon(Icons.build_circle_outlined, size: 18, color: Colors.purple[700]),
            onDeleted: () { setState(() { _selectedCookingTools.remove(tool); _updateParent(); }); },
            deleteIcon: Icon(Icons.close, size: 18), deleteIconColor: Colors.red[400],
            backgroundColor: Colors.purple[100], padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )).toList(),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  void _addCustomTool(String value) {
    final toolName = value.trim();
    if (toolName.isNotEmpty && !_selectedCookingTools.contains(toolName)) {
      setState(() {
        _selectedCookingTools.remove('상관없음');
        _selectedCookingTools.add(toolName);
        _cookingToolController.clear();
        _updateParent();
      });
    } else if (toolName.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$toolName'은(는) 이미 목록에 있습니다."), duration: Duration(seconds: 2), backgroundColor: Colors.orange),
      );
      _cookingToolController.clear();
    }
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
        _buildCookingToolSelector(isRequired: true),
        _buildRequiredLabel("희망 조리 시간 (분 이내)"),
        SizedBox(height: 10),
        TextField(
          controller: _preferredTimeController,
          decoration: _inputDecoration('조리 시간 입력 (분)', hint: '예: 30 (숫자만)', icon: Icons.timer_outlined, suffixIcon: Text("분 이내  ", style: TextStyle(color: Colors.grey[600])), isRequired: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          onChanged: (_) => _updateParent(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _preferredTimeController.dispose();
    _cookingToolController.dispose();
    super.dispose();
  }
}