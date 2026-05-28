class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.animeId,
    required this.title,
    required this.weekday,
    required this.sourceId,
    this.coverUrl,
    this.updateTime,
  });

  final String id;
  final String animeId;
  final String title;
  final String? coverUrl;
  final int weekday;
  final String? updateTime;
  final String sourceId;
}
