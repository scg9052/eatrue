// widgets/survey_page_container.dart
// (이전 답변의 flutter_widgets_updated_flowchart 문서 내용과 동일하게 유지)
import 'package:flutter/material.dart';

class SurveyPageContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const SurveyPageContainer({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Divider(thickness: 1.5, color: Theme.of(context).dividerColor, height: 24),
          SizedBox(height: 18),
          child,
          SizedBox(height: 10), // 하단에 여유 공간 추가
        ],
      ),
    );
  }
}