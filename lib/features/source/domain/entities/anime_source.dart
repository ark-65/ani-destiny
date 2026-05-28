class AnimeSource {
  const AnimeSource({
    required this.id,
    required this.name,
    required this.enabled,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final bool enabled;
}
