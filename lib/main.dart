// main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/survey_screen.dart';
import 'screens/home_screen.dart';
import 'providers/survey_data_provider.dart';
import 'providers/meal_provider.dart';

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
        // SurveyDataProvider는 생성자에서 인증 상태를 확인하고 데이터 로드/익명 로그인 시도
        ChangeNotifierProvider(create: (_) => SurveyDataProvider()),
        ChangeNotifierProxyProvider<SurveyDataProvider, MealProvider>(
          create: (context) => MealProvider(
            Provider.of<SurveyDataProvider>(context, listen: false),
          ),
          update: (context, surveyDataProvider, previousMealProvider) =>
              MealProvider(surveyDataProvider),
        ),
      ],
      child: MaterialApp(
        title: '맞춤형 레시피 앱',
        theme: ThemeData( // 테마 설정은 이전과 동일하게 유지
          primarySwatch: Colors.green,
          fontFamily: 'NotoSansKR',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            elevation: 2,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansKR',
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.green[800], fontFamily: 'NotoSansKR'),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontFamily: 'NotoSansKR'),
            bodyMedium: TextStyle(fontFamily: 'NotoSansKR'),
            titleLarge: TextStyle(fontFamily: 'NotoSansKR'),
          ),
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ko', 'KR'),
          const Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
        home: InitialScreenDecider(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/survey': (context) => SurveyScreen(),
        },
      ),
    );
  }
}

// InitialScreenDecider는 SurveyDataProvider의 isLoading 상태에 따라 화면을 결정합니다.
class InitialScreenDecider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyDataProvider>(
      builder: (context, surveyData, _) {
        if (surveyData.isLoading) {
          print("InitialScreenDecider: SurveyData is loading. UID from Auth: ${FirebaseAuth.instance.currentUser?.uid}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("사용자 정보 로딩 중..."),
                ],
              ),
            ),
          );
        }
        print("InitialScreenDecider: SurveyData loaded. isSurveyCompleted: ${surveyData.isSurveyCompleted}. UID from Auth: ${FirebaseAuth.instance.currentUser?.uid}");
        return surveyData.isSurveyCompleted ? HomeScreen() : SurveyScreen();
      },
    );
  }
}
