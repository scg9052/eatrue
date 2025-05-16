// widgets/survey_pages/survey_page_cooking_data.dart
// (이전 답변의 flutter_recipe_app_v1_religious_required 문서 내용과 거의 동일하게 유지)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_data_provider.dart';
import '../../models/user_data.dart';
import '../../l10n/app_localizations.dart';

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

  late List<String> _commonCookingTools;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localization = AppLocalizations.of(context);
    
    // 지역화된 요리 도구 목록
    _commonCookingTools = localization.isKorean() ? 
      ['상관없음','전자레인지', '가스레인지', '인덕션', '에어프라이어', '오븐', '전기밥솥', '냄비', '프라이팬', '칼', '도마', '믹서기', '커피포트'] :
      ['Any','Microwave', 'Gas Stove', 'Induction', 'Air Fryer', 'Oven', 'Rice Cooker', 'Pot', 'Pan', 'Knife', 'Cutting Board', 'Blender', 'Kettle'];
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
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(localization.cookingToolsLabel, isRequired: true),
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
                      if (tool == _commonCookingTools[0]) { // 상관없음 또는 Any
                        if (!_selectedCookingTools.contains(tool)) { 
                          _selectedCookingTools.clear(); 
                          _selectedCookingTools.add(tool); 
                        } else {
                          _selectedCookingTools.remove(tool);
                        }
                      } else {
                        _selectedCookingTools.remove(_commonCookingTools[0]);
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cookingToolController,
                      decoration: InputDecoration(
                        hintText: localization.isKorean() ? '기타 조리도구 입력' : 'Enter other cooking tools',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final value = _cookingToolController.text.trim();
                      if (value.isNotEmpty) {
                        setState(() {
                          if (!_selectedCookingTools.contains(value)) {
                            _selectedCookingTools.add(value);
                          }
                          _cookingToolController.clear();
                          _updateParent();
                        });
                      }
                    },
                    child: Text(localization.isKorean() ? '추가' : 'Add'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreferredCookingTime() {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(localization.cookingTimeLabel, isRequired: true),
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
              TextField(
                controller: _preferredTimeController,
                decoration: InputDecoration(
                  hintText: localization.isKorean() ? '조리 시간 입력 (분)' : 'Enter cooking time (minutes)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixText: localization.minutes,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _updateParent(),
              ),
              SizedBox(height: 8),
              Text(
                localization.isKorean() 
                    ? '선호하는 최대 조리 시간을 분 단위로 입력해주세요.' 
                    : 'Enter your preferred maximum cooking time in minutes.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final localization = AppLocalizations.of(context);
    
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
                localization.cookingDataTitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                localization.isKorean() 
                    ? '조리 환경 정보를 입력하시면 당신의 상황에 맞는 레시피를 추천해 드립니다.'
                    : 'Enter your cooking environment information to get recipes that fit your situation.',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // 조리 도구 선택
        _buildCookingToolSelector(),
        
        SizedBox(height: 24),
        
        // 선호 조리 시간
        _buildPreferredCookingTime(),
        
        SizedBox(height: 24),
        
        // 조리 팁
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    localization.isKorean() ? '조리 환경 팁' : 'Cooking Environment Tips',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                localization.isKorean()
                    ? '• 가지고 있는 조리 도구를 선택하면 사용 가능한 조리법의 레시피를 추천받을 수 있습니다.'
                    : '• Selecting the cooking tools you have will help recommend recipes with available cooking methods.',
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
              SizedBox(height: 4),
              Text(
                localization.isKorean()
                    ? '• 선호하는 조리 시간을 입력하면 해당 시간 내에 완성할 수 있는 레시피를 우선적으로 추천해 드립니다.'
                    : '• Entering your preferred cooking time will prioritize recipes that can be completed within that time.',
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}