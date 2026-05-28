class PlaybackSpeed {
  const PlaybackSpeed({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  static const all = [
    PlaybackSpeed(label: '0.5x', value: 0.5),
    PlaybackSpeed(label: '0.75x', value: 0.75),
    PlaybackSpeed(label: '1.0x', value: 1),
    PlaybackSpeed(label: '1.25x', value: 1.25),
    PlaybackSpeed(label: '1.5x', value: 1.5),
    PlaybackSpeed(label: '2.0x', value: 2),
  ];
}
