import 'package:flutter/material.dart';

class AppTheme {
  // 앱 전체에서 공통으로 사용되는 색상 상수
  static const Color primaryLightColor = Color(0xFF4CAF50);
  static const Color secondaryLightColor = Color(0xFF009688);
  static const Color accentLightColor = Color(0xFFFF9800);
  
  // 다크 테마를 위한 현대적인 색상 (더 세련된 색상으로 업데이트)
  static const Color primaryDarkColor = Color(0xFF66BB6A);
  static const Color secondaryDarkColor = Color(0xFF26A69A);
  static const Color accentDarkColor = Color(0xFFFFA726);
  static const Color darkBackground = Color(0xFF1A1A1A); // 더 부드러운 블랙
  static const Color darkSurface = Color(0xFF242424); // 더 세련된 표면 색상
  static const Color darkCardColor = Color(0xFF2C2C2C); // 카드 색상 유지
  static const Color darkInputFillColor = Color(0xFF343434); // 입력 필드 배경색 조정
  static const Color darkAppBarColor = Color(0xFF2E7D32); // 앱바를 그린 계열로 변경
  
  // 추가 색상 - Grey 색상 상수로 정의
  static const Color greyLight = Color(0xFFBDBDBD); // ~Colors.grey[400]
  static const Color greyMedium = Color(0xFF757575); // ~Colors.grey[600]
  static const Color greyDark = Color(0xFF424242);   // ~Colors.grey[800]
  static const Color greyLightBorder = Color(0xFFE0E0E0); // ~Colors.grey[300]
  static const Color greyDarkBorder = Color(0xFF616161);  // ~Colors.grey[700]
  
  // 라이트 테마 가져오기
  static ThemeData getLightTheme() {
    return ThemeData(
      primaryColor: primaryLightColor,
      primarySwatch: Colors.green,
      fontFamily: 'NotoSansKR',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      
      // 색상 스키마
      colorScheme: const ColorScheme.light(
        primary: primaryLightColor,
        secondary: secondaryLightColor,
        tertiary: accentLightColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.black87,
        surface: Colors.white,
        background: Color(0xFFFAFAFA), // ~Colors.grey[50]
        error: Color(0xFFD32F2F), // ~Colors.red[700]
      ),
      
      // 앱바 테마 (새로운 디자인 가이드라인)
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryLightColor,
        foregroundColor: Colors.white,
        elevation: 0, // 현대적인 플랫 디자인
        centerTitle: false, // 왼쪽 정렬
        titleSpacing: 16, // 좌측 여백 추가
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'NotoSansKR',
          color: Colors.white,
        ),
      ),
      
      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            fontFamily: 'NotoSansKR'
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0, // 현대적인 플랫 디자인
        ),
      ),
      
      // 카드 테마
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      
      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: greyLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: greyLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryLightColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.0), // ~Colors.red[700]
        ),
        labelStyle: const TextStyle(color: greyMedium, fontFamily: 'NotoSansKR'),
        floatingLabelStyle: const TextStyle(color: primaryLightColor, fontFamily: 'NotoSansKR'),
      ),
      
      // 텍스트 테마
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.black87),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.black87),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.black87),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.black87),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.black87),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, fontFamily: 'NotoSansKR', color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, fontFamily: 'NotoSansKR', color: Colors.black87),
        bodySmall: TextStyle(fontSize: 12, fontFamily: 'NotoSansKR', color: Colors.black54),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Colors.black87),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Colors.black87),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Colors.black54),
      ),
      
      // 탭바 테마
      tabBarTheme: const TabBarTheme(
        labelColor: primaryLightColor,
        unselectedLabelColor: greyMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR'),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontFamily: 'NotoSansKR'),
      ),
      
      // 아이콘 테마
      iconTheme: const IconThemeData(
        color: greyDark,
        size: 24,
      ),
      
      // 진행 표시기 테마
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLightColor,
        linearTrackColor: Color(0xFFEEEEEE), // ~Colors.grey[200]
        circularTrackColor: Color(0xFFEEEEEE), // ~Colors.grey[200]
      ),
      
      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF424242), // ~Colors.grey[800]
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'NotoSansKR'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 분할선 색상
      dividerTheme: const DividerThemeData(
        color: greyLightBorder,
        thickness: 1,
        space: 1,
      ),
      
      // 스위치 테마
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryLightColor;
          return greyLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryLightColor.withOpacity(0.4);
          return const Color(0xFFE0E0E0); // ~Colors.grey[300]
        }),
      ),
      
      // 체크박스 테마
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryLightColor;
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // 라디오 버튼 테마
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryLightColor;
          return greyMedium;
        }),
      ),
    );
  }
  
  // 다크 테마 가져오기 (현대적인 다크 테마로 업데이트)
  static ThemeData getDarkTheme() {
    return ThemeData(
      primaryColor: primaryDarkColor,
      primarySwatch: Colors.green,
      fontFamily: 'NotoSansKR',
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // 색상 스키마 (현대적인 다크 모드 색상)
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkColor,
        secondary: secondaryDarkColor,
        tertiary: accentDarkColor,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onTertiary: Colors.black87,
        surface: darkSurface,
        background: darkBackground,
        error: Color(0xFFEF9A9A), // ~Colors.red[300]
      ),
      
      // 앱바 테마 (새로운 디자인 가이드라인)
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBarColor, // 앱바 색상 변경
        foregroundColor: Colors.white,
        elevation: 0, // 현대적인 플랫 디자인
        centerTitle: false, // 왼쪽 정렬
        titleSpacing: 16, // 좌측 여백 추가
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'NotoSansKR',
          color: Colors.white,
        ),
      ),
      
      // 버튼 테마 (좀 더 뚜렷한 색상으로 가시성 향상)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkColor,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            fontFamily: 'NotoSansKR'
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0, // 현대적인 플랫 디자인
        ),
      ),
      
      // 카드 테마 (좀 더 명확한 구분을 위한 테두리 추가)
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF424242), width: 0.5), // ~Colors.grey[800]
        ),
        clipBehavior: Clip.antiAlias,
        color: darkCardColor,
      ),
      
      // 입력 필드 테마 (좀 더 명확한 입력 필드)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: greyDarkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: greyDarkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDarkColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1.0), // ~Colors.red[300]
        ),
        labelStyle: const TextStyle(color: Color(0xFFBDBDBD), fontFamily: 'NotoSansKR'), // ~Colors.grey[400]
        floatingLabelStyle: const TextStyle(color: primaryDarkColor, fontFamily: 'NotoSansKR'),
      ),
      
      // 텍스트 테마 (좀 더 부드러운 색상으로 가독성 향상)
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.white),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.white),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR', color: Colors.white),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.white),
        headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.white),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR', color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, fontFamily: 'NotoSansKR', color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, fontFamily: 'NotoSansKR', color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, fontFamily: 'NotoSansKR', color: Color(0xFFBDBDBD)), // ~Colors.grey[400]
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Colors.white),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'NotoSansKR', color: Color(0xFFBDBDBD)),
      ),
      
      // 탭바 테마 (더 뚜렷한 선택 상태)
      tabBarTheme: const TabBarTheme(
        labelColor: primaryDarkColor,
        unselectedLabelColor: Color(0xFFBDBDBD), // ~Colors.grey[400]
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR'),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontFamily: 'NotoSansKR'),
      ),
      
      // 아이콘 테마
      iconTheme: const IconThemeData(
        color: Color(0xFFEEEEEE), // ~Colors.grey[200]
        size: 24,
      ),
      
      // 진행 표시기 테마
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryDarkColor,
        linearTrackColor: Color(0xFF424242), // ~Colors.grey[800]
        circularTrackColor: Color(0xFF424242), // ~Colors.grey[800]
      ),
      
      // 스낵바 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'NotoSansKR'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 분할선 색상
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242), // ~Colors.grey[800]
        thickness: 1,
        space: 1,
      ),
      
      // 스위치 테마
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryDarkColor;
          return const Color(0xFF757575); // ~Colors.grey[600]
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryDarkColor.withOpacity(0.4);
          return const Color(0xFF616161); // ~Colors.grey[700]
        }),
      ),
      
      // 체크박스 테마
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryDarkColor;
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // 라디오 버튼 테마
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return primaryDarkColor;
          return const Color(0xFFBDBDBD); // ~Colors.grey[400]
        }),
      ),
    );
  }
} 