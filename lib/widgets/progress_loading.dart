import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ProgressLoadingBar extends StatelessWidget {
  final String message;
  final double? progress; // 0.0부터 1.0 사이의 값, null이면 불확정적 로딩
  final Color? color;

  const ProgressLoadingBar({
    Key? key,
    required this.message,
    this.progress,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final localization = AppLocalizations.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로딩 진행률 및 텍스트를 포함한 컨테이너
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 진행률 표시 (progress가 있을 때는 LinearProgressIndicator, 없을 때는 불확정적 로딩)
              if (progress != null)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: themeColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(progress! * 100).toInt()}% ${localization.menuGenerationProgress}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                LinearProgressIndicator(
                  backgroundColor: themeColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
              
              SizedBox(height: 16),
              
              // 메시지 표시
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 전체 화면 로딩 위젯
class FullScreenProgressLoading extends StatelessWidget {
  final String message;
  final double? progress;
  final Color? color;

  const FullScreenProgressLoading({
    Key? key,
    required this.message,
    this.progress,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: ProgressLoadingBar(
          message: message,
          progress: progress,
          color: color,
        ),
      ),
    );
  }
} 