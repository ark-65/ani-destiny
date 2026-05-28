import 'package:ani_destiny/features/anime/data/models/anime_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AnimeModel maps to Anime entity', () {
    const model = AnimeModel(
      id: 'mock-id',
      title: 'Mock Title',
      coverUrl: 'https://example.test/cover.jpg',
      tags: ['Adventure'],
      sourceId: 'mock',
      rating: 8.5,
      year: 2026,
      status: 'Updating',
    );

    final entity = model.toEntity();

    expect(entity.id, 'mock-id');
    expect(entity.title, 'Mock Title');
    expect(entity.tags, ['Adventure']);
    expect(entity.sourceId, 'mock');
  });
}
