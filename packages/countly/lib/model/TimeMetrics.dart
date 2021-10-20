class TimeMetrics {
  late final int tz;
  late final int dow;
  late final int hour;
  final int timestamp;

  TimeMetrics({required this.timestamp}) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    hour = dateTime.hour;
    dow = dateTime.weekday;
    tz = dateTime.timeZoneOffset.inHours;
  }
}
