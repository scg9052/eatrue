// widgets/survey_pages/survey_page_cooking_data.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일하게 유지)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';

class SurveyPageCookingData extends StatefulWidget {
  final Function(List<String>, int?) onUpdate;

  const SurveyPageCookingData({
    Key? key,
    required this.onUpdate,
  }) : super(key: key);

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

  @override
  void dispose() {
    _preferredTimeController.dispose();
    _cookingToolController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon, Widget? suffixIcon, bool isRequired = false}) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return InputDecoration(
      label: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color, 
            fontSize: isSmallScreen ? 14 : 16, 
            fontFamily: 'NotoSansKR'
          ),
          children: <TextSpan>[
            if (isRequired) TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      hintText: hint,
      hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
      prefixIcon: icon != null ? Icon(icon, color: theme.colorScheme.primary, size: isSmallScreen ? 20 : 24) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), 
        borderSide: BorderSide(color: theme.dividerColor)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), 
        borderSide: BorderSide(color: theme.dividerColor)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0), 
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0)
      ),
      filled: true, 
      fillColor: theme.inputDecorationTheme.fillColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16, 
        vertical: isSmallScreen ? 10 : 14
      ),
      isDense: isSmallScreen,
    );
  }

  void _updateParent() {
    widget.onUpdate(
      List<String>.from(_selectedCookingTools),
      int.tryParse(_preferredTimeController.text),
    );
  }

  Widget _buildSectionLabel(String labelText, {bool isRequired = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w600, 
            color: theme.colorScheme.primary,
            fontFamily: 'NotoSansKR'
          ),
          children: [
            TextSpan(text: labelText),
            if (isRequired)
              TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function() onTap, {Color? accentColor}) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) => onTap(),
      backgroundColor: theme.cardColor,
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 0),
      elevation: isSelected ? 2 : 0,
      shadowColor: isSelected ? color.withOpacity(0.3) : Colors.transparent,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? color : theme.dividerColor,
          width: 1.0,
        ),
      ),
    );
  }

  Widget _buildCookingToolSelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("사용 가능한 조리 도구", isRequired: true),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonCookingTools.map((tool) => _buildFilterChip(
                  tool,
                  _selectedCookingTools.contains(tool),
                  () {
                    setState(() {
                      if (tool == '상관없음') {
                        if (!_selectedCookingTools.contains(tool)) { 
                          _selectedCookingTools.clear(); 
                          _selectedCookingTools.add(tool); 
                        } else {
                          _selectedCookingTools.remove(tool);
                        }
                      } else {
                        _selectedCookingTools.remove('상관없음');
                        if (_selectedCookingTools.contains(tool)) {
                          _selectedCookingTools.remove(tool);
                        } else {
                          _selectedCookingTools.add(tool);
                        }
                      }
                      _updateParent();
                    });
                  },
                  accentColor: Color(0xFF5E35B1), // 딥 퍼플 계열
                )).toList(),
              ),
              SizedBox(height: 16),
              Text(
                "기타 조리 도구",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cookingToolController,
                      decoration: _inputDecoration(
                        '도구명 입력', 
                        hint: '기타 조리 도구가 있다면 입력하세요', 
                        icon: Icons.add_circle_outline,
                      ),
                      onSubmitted: (value) => _addCustomTool(value),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _addCustomTool(_cookingToolController.text),
                    child: Icon(Icons.add, size: 24),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5E35B1),
                      minimumSize: Size(60, 52), 
                      padding: EdgeInsets.zero, 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (_selectedCookingTools.any((tool) => !_commonCookingTools.contains(tool))) ...[
                SizedBox(height: 8),
                Text(
                  "추가한 조리 도구",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8.0, 
                  runSpacing: 8.0,
                  children: _selectedCookingTools
                    .where((tool) => !_commonCookingTools.contains(tool))
                    .map((tool) => Chip(
                      label: Text(
                        tool, 
                        style: TextStyle(
                          color: Color(0xFF5E35B1),
                          fontWeight: FontWeight.w500
                        )
                      ),
                      avatar: Icon(Icons.build_circle_outlined, size: 18, color: Color(0xFF5E35B1)),
                      onDeleted: () { 
                        setState(() { 
                          _selectedCookingTools.remove(tool); 
                          _updateParent(); 
                        }); 
                      },
                      deleteIcon: Icon(Icons.close, size: 18), 
                      deleteIconColor: Colors.red[400],
                      backgroundColor: Color(0xFF5E35B1).withOpacity(0.1), 
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Color(0xFF5E35B1).withOpacity(0.3), width: 1)
                      ),
                    )
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
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
        SnackBar(
          content: Text("'$toolName'은(는) 이미 목록에 있습니다."), 
          duration: Duration(seconds: 2), 
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cookingToolController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목 추가
        Container(
          margin: EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '조리 환경 정보',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '조리 환경과 가능한 시간에 맞는 레시피를 추천해 드립니다.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 조리 도구 선택기
        _buildCookingToolSelector(),
        
        SizedBox(height: 24),
        
        // 선호 조리 시간
        _buildSectionLabel('선호하는 조리 시간 (분)', isRequired: true),
        TextField(
          controller: _preferredTimeController,
          decoration: _inputDecoration(
            '조리 시간', 
            hint: '예: 30 (숫자만 입력)', 
            icon: Icons.timer,
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text(
                '분', 
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey[600]
                )
              ),
            ),
            isRequired: true,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3)
          ],
          onChanged: (_) => _updateParent(),
        ),
        
        SizedBox(height: 24),
        
        // 조리 환경 팁
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blueGrey[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    '조리 환경 팁',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[700],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• 현재 사용 가능한 조리 도구를 모두 선택해주세요.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[800]),
              ),
              SizedBox(height: 4),
              Text(
                '• 선호하는 조리 시간은 한 번에 요리하는 데 투자할 수 있는 시간을 의미합니다.',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}