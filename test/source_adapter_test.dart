import 'package:ani_destiny/features/source/data/adapters/mock_anime_source_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MockAnimeSourceAdapter supports the first-version flow', () async {
    final adapter = MockAnimeSourceAdapter();

    final home = await adapter.getHomeRecommendations();
    expect(home, isNotEmpty);

    final search = await adapter.search('star');
    expect(search, isNotEmpty);

    final detail = await adapter.getAnimeDetail(home.first.id);
    expect(detail.episodes, isNotEmpty);

    final playSources = await adapter.getPlaySources(detail.episodes.first.id);
    expect(playSources.first.url, isNotEmpty);

    final schedule = await adapter.getSchedule();
    expect(schedule, isNotEmpty);
  });
}
