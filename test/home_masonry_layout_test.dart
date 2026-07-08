import 'package:ani_destiny/features/anime/domain/entities/anime.dart';
import 'package:ani_destiny/features/home/presentation/pages/home_page.dart';
import 'package:ani_destiny/features/home/presentation/widgets/anime_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('home masonry layout', () {
    test('uses stable responsive column counts', () {
      expect(homeMasonryColumnCountForWidth(360), 2);
      expect(homeMasonryColumnCountForWidth(719), 2);
      expect(homeMasonryColumnCountForWidth(720), 3);
      expect(homeMasonryColumnCountForWidth(1024), 4);
      expect(homeMasonryColumnCountForWidth(1360), 5);
      expect(homeMasonryColumnCountForWidth(1680), 6);
    });

    test('uses a deterministic tile rhythm', () {
      expect(homeAnimeTileAspectRatio(0), 1.18);
      expect(homeAnimeTileAspectRatio(2), 0.62);
      expect(homeAnimeTileAspectRatio(7), 0.68);
      expect(homeAnimeTileAspectRatio(8), 1.18);
    });

    testWidgets('compact card keeps title and hides empty-description copy',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildCard(
          const Anime(
            id: 'anime-1',
            title: 'Compact show',
            tags: ['Adventure'],
            status: 'EP 01',
          ),
          onTap: () => tapped = true,
        ),
      );

      expect(find.text('Compact show'), findsOneWidget);
      expect(find.text('EP 01'), findsOneWidget);
      expect(find.text('Adventure'), findsNothing);
      expect(find.text('No description'), findsNothing);
      expect(find.text('暂无简介'), findsNothing);

      await tester.tap(find.text('Compact show'));
      expect(tapped, isTrue);
    });

    testWidgets('long titles stay inside a narrow tile', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          const Anime(
            id: 'anime-2',
            title: 'A very very very long anime title that should not overflow',
          ),
          width: 142,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('A very very very long anime title that should not overflow'),
        findsOneWidget,
      );
    });
  });
}

Widget _buildCard(
  Anime anime, {
  VoidCallback? onTap,
  double width = 180,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: AnimeCard(
            anime: anime,
            imageAspectRatio: 0.72,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}
