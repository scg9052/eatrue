// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/survey_data_provider.dart';
import 'providers/meal_provider.dart';
import 'screens/initial_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/progress_loading.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 바인딩 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SurveyDataProvider()),
        ChangeNotifierProvider(
          create: (context) => MealProvider(Provider.of<SurveyDataProvider>(context, listen: false))
        ),
      ],
      child: MaterialApp(
        title: 'Eatrue - 맞춤형 식단 추천',
        theme: AppTheme.getLightTheme(), // 라이트 테마 사용
        themeMode: ThemeMode.light, // 항상 라이트 테마 사용
        
        // 한국어 지원을 위한 로컬리제이션 위젯 설정
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'), // 한국어 선택
          Locale('en', 'US'), // 영어도 지원
        ],
        
        // 앱 초기 경로 설정
        initialRoute: '/',
        routes: {
          '/': (_) => InitialScreenDecider(),
          '/survey': (_) => SurveyScreen(),
          '/home': (_) => MainScreen(),
          '/initial': (_) => InitialScreen(),
        },
      ),
    );
  }
}

class InitialScreenDecider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyDataProvider>(
      builder: (context, surveyData, _) {
        if (surveyData.isLoading) {
          print("InitialScreenDecider: SurveyData is loading. UID from Auth: ${FirebaseAuth.instance.currentUser?.uid}");
          return Scaffold(
            body: FullScreenProgressLoading(
              message: "사용자 정보 로딩 중...",
            ),
          );
        }
        print("InitialScreenDecider: SurveyData loaded. isSurveyCompleted: ${surveyData.isSurveyCompleted}. UID from Auth: ${FirebaseAuth.instance.currentUser?.uid}");
        return surveyData.isSurveyCompleted ? MainScreen() : InitialScreen();
      },
    );
  }
}
