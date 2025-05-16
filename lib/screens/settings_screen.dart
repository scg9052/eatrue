import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_bar_widget.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localization = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: EatrueAppBar(
        title: localization.settingsTitle,
        showBackButton: true,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(localization.languageSettings),
            subtitle: Text(languageProvider.isKorean() 
                ? "한국어"
                : "English"),
            leading: Icon(Icons.language),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => LanguageDialog()
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text(localization.isKorean() ? '테마 설정' : 'Theme Settings'),
            subtitle: Text(
              themeProvider.isDarkMode 
                ? (localization.isKorean() ? '다크 모드' : 'Dark Mode')
                : (localization.isKorean() ? '라이트 모드' : 'Light Mode')
            ),
            leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ThemeDialog()
              );
            },
          ),
          Divider(),
          // 여기에 추가 설정 항목들을 추가할 수 있습니다
        ],
      ),
    );
  }
}

class LanguageDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localization = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(localization.languageSettings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: Text("한국어"),
            value: 'ko',
            groupValue: languageProvider.currentLocale.languageCode,
            onChanged: (value) {
              languageProvider.setKorean();
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: Text("English"),
            value: 'en',
            groupValue: languageProvider.currentLocale.languageCode,
            onChanged: (value) {
              languageProvider.setEnglish();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localization.closeButton),
        ),
      ],
    );
  }
}

class ThemeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localization = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(localization.isKorean() ? '테마 설정' : 'Theme Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: Text(localization.isKorean() ? '라이트 모드' : 'Light Mode'),
            subtitle: Text(localization.isKorean() ? '밝은 화면 테마' : 'Bright screen theme'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            secondary: Icon(Icons.light_mode, color: Colors.amber),
            onChanged: (value) {
              themeProvider.setLightMode();
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(localization.isKorean() ? '다크 모드' : 'Dark Mode'),
            subtitle: Text(localization.isKorean() ? '어두운 화면 테마' : 'Dark screen theme'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            secondary: Icon(Icons.dark_mode, color: Colors.indigo),
            onChanged: (value) {
              themeProvider.setDarkMode();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localization.closeButton),
        ),
      ],
    );
  }
} 