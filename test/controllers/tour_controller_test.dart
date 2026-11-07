import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgeek/controllers/tour_controller.dart';
import 'package:trackgeek/services/auth_service.dart';

void main() {
  final now = DateTime(2026, 11, 7);

  SessionUser userCreated(DateTime? createdAt) =>
      SessionUser(id: '1', name: 'n', email: 'e', createdAt: createdAt);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts for a new account and persists the stage', () async {
    final tour = TourController.instance;
    await tour.go(TourStage.done);
    SharedPreferences.setMockInitialValues({});
    await tour.go(TourStage.feed);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tour_stage'), 'feed');
  });

  test('startIfNew ignores old accounts and missing dates', () async {
    final tour = TourController.instance;
    await tour.go(TourStage.done);
    await tour.startIfNew(
      userCreated(now.subtract(const Duration(days: 30))),
      now: now,
    );
    expect(tour.stage, TourStage.done);
    await tour.startIfNew(userCreated(null), now: now);
    expect(tour.stage, TourStage.done);
  });
}
