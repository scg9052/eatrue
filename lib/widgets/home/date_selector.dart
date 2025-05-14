import 'package:flutter/material.dart';

/// 홈 화면의 날짜 선택 위젯
/// 주간 캘린더 형태로 표시되며, 선택된 날짜를 강조 표시합니다.
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDates;
  final Function(DateTime) onDateSelected;
  
  /// 생성자
  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.weekDates,
    required this.onDateSelected,
  }) : super(key: key);
  
  // 날짜가 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 32) / 7; // 양쪽 패딩 16씩 제외하고 7등분
    
    return Container(
      // 배경색을 스크린샷과 같이 다크한 색상으로 변경
      color: Color(0xFF2D2D2D),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // 현재 월 표시 및 주차 이동 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 주 버튼
                IconButton(
                  onPressed: () {
                    // 일주일 전 날짜로 이동
                    final previousWeekDate = selectedDate.subtract(Duration(days: 7));
                    onDateSelected(previousWeekDate);
                  },
                  icon: Icon(Icons.chevron_left, color: Colors.white),
                  tooltip: '이전 주',
                ),
                
                // 현재 월 표시
                Text(
                  '${selectedDate.year}년 ${selectedDate.month}월',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                
                // 다음 주 버튼
                IconButton(
                  onPressed: () {
                    // 일주일 후 날짜로 이동
                    final nextWeekDate = selectedDate.add(Duration(days: 7));
                    onDateSelected(nextWeekDate);
                  },
                  icon: Icon(Icons.chevron_right, color: Colors.white),
                  tooltip: '다음 주',
                ),
              ],
            ),
          ),
          
          // 요일 표시 행
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeekdayLabel('월', Colors.white, buttonWidth),
                _buildWeekdayLabel('화', Colors.white, buttonWidth),
                _buildWeekdayLabel('수', Colors.white, buttonWidth),
                _buildWeekdayLabel('목', Colors.white, buttonWidth),
                _buildWeekdayLabel('금', Colors.white, buttonWidth),
                _buildWeekdayLabel('토', Colors.blue[300]!, buttonWidth),
                _buildWeekdayLabel('일', Colors.red[300]!, buttonWidth),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // 날짜 선택 행
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 날짜 버튼들을 동적으로 생성하고 Row의 공간을 균등하게 차지하도록 수정
                for (int index = 0; index < weekDates.length; index++)
                  _buildDateButton(context, weekDates[index], buttonWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 요일 레이블 위젯
  Widget _buildWeekdayLabel(String text, Color color, double width) {
    return Container(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // 날짜 버튼 위젯
  Widget _buildDateButton(BuildContext context, DateTime date, double width) {
    final isSelected = date.year == selectedDate.year && 
                      date.month == selectedDate.month && 
                      date.day == selectedDate.day;
    final isToday = _isToday(date);
    final isDifferentMonth = date.month != selectedDate.month;
    
    // 선택된 날짜와 오늘 날짜 스타일링 준비
    final buttonSize = width * 0.8; // 버튼 크기를 너비의 80%로 설정
    
    return GestureDetector(
      onTap: () => onDateSelected(date),
      child: Container(
        width: width,
        height: 56, // 충분한 높이 제공
        child: Center(
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF7EC176) : Colors.transparent, // 선택된 날짜는 초록색 배경
              border: isToday && !isSelected 
                  ? Border.all(color: Color(0xFF7EC176), width: 2) // 오늘 날짜는 초록색 테두리
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: _getDateTextColor(isSelected, isToday, isDifferentMonth, date),
                  fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 날짜 텍스트 색상 결정 함수
  Color _getDateTextColor(bool isSelected, bool isToday, bool isDifferentMonth, DateTime date) {
    // 선택된 날짜는 항상 하얀색
    if (isSelected) {
      return Colors.white;
    }
    
    // 다른 달의 날짜는 회색
    if (isDifferentMonth) {
      return Colors.grey;
    }
    
    // 요일에 따른 색상
    if (date.weekday == 6) { // 토요일
      return Colors.blue[300]!;
    } else if (date.weekday == 7) { // 일요일
      return Colors.red[300]!;
    }
    
    // 기본 색상
    return Colors.white;
  }
} 