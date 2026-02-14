import 'dart:ui';

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

class ActivityData {
  ActivityData(this.activity, this.percentage, this.color);
  final String activity;
  final double percentage;
  final Color color;
}

class EmotionData {
  EmotionData(this.emotion, this.percentage, this.color);
  final String emotion;
  final double percentage;
  final Color color;
}