class DanmakuSettings {
  const DanmakuSettings({
    required this.enabled,
    required this.opacity,
    required this.fontSize,
    required this.speed,
  });

  const DanmakuSettings.defaults()
      : enabled = true,
        opacity = 0.82,
        fontSize = 16,
        speed = 1;

  final bool enabled;
  final double opacity;
  final double fontSize;
  final double speed;

  DanmakuSettings copyWith({
    bool? enabled,
    double? opacity,
    double? fontSize,
    double? speed,
  }) {
    return DanmakuSettings(
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      speed: speed ?? this.speed,
    );
  }
}
