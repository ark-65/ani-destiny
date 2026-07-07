import 'package:ani_destiny/features/source/data/services/persistent_source_health_service.dart';
import 'package:ani_destiny/features/source/domain/entities/source_health.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('recordFailure increments failureCount and updates status thresholds',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = PersistentSourceHealthService(
      preferences: await SharedPreferences.getInstance(),
      sourceIds: const ['sakura'],
    );

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'home',
      error: StateError('temporary issue'),
    );
    expect(service.getHealth('sakura').failureCount, 1);
    expect(service.getHealth('sakura').status, SourceHealthStatus.healthy);

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'home',
      error: StateError('temporary issue'),
    );
    expect(service.getHealth('sakura').failureCount, 2);
    expect(service.getHealth('sakura').status, SourceHealthStatus.degraded);

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'home',
      error: StateError('temporary issue'),
    );
    expect(service.getHealth('sakura').failureCount, 3);
    expect(service.getHealth('sakura').status, SourceHealthStatus.unavailable);
    expect(service.shouldFallback('sakura'), isTrue);
  });

  test('recordSuccess resets failureCount and clears last error', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PersistentSourceHealthService(
      preferences: await SharedPreferences.getInstance(),
      sourceIds: const ['sakura'],
    );

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'detail',
      error: Exception('broken'),
    );
    service.recordSuccess(sourceId: 'sakura', operation: 'detail');

    final health = service.getHealth('sakura');
    expect(health.failureCount, 0);
    expect(health.status, SourceHealthStatus.healthy);
    expect(health.lastErrorMessage, isNull);
  });

  test('reset health clears failure count', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PersistentSourceHealthService(
      preferences: await SharedPreferences.getInstance(),
      sourceIds: const ['sakura'],
    );

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'search',
      error: Exception('broken'),
    );
    service.reset('sakura');

    expect(service.getHealth('sakura').failureCount, 0);
    expect(service.getHealth('sakura').status, SourceHealthStatus.healthy);
  });

  test('persisted health reloads from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = PersistentSourceHealthService(
      preferences: preferences,
      sourceIds: const ['sakura'],
    );

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'play_sources',
      error: Exception('https://example.test/watch?token=secret'),
    );

    final reloaded = PersistentSourceHealthService(
      preferences: preferences,
      sourceIds: const ['sakura'],
    );

    final health = reloaded.getHealth('sakura');
    expect(health.failureCount, 1);
    expect(health.lastErrorMessage, isNot(contains('token=secret')));
  });

  test('recordFailure stores a sanitized source failure summary', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PersistentSourceHealthService(
      preferences: await SharedPreferences.getInstance(),
      sourceIds: const ['sakura'],
    );

    service.recordFailure(
      sourceId: 'sakura',
      operation: 'detail',
      error: Exception(
        '<html><body>token=secret</body></html> '
        '/Users/ark/Downloads/AniDestiny/debug.log',
      ),
    );

    final message = service.getHealth('sakura').lastErrorMessage!;
    expect(message, 'HTML document omitted');
    expect(message, isNot(contains('token=secret')));
    expect(message, isNot(contains('/Users/ark')));
  });
}
