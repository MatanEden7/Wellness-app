import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/services/time_service.dart';

/// Coverage for [RestTimerController]: the workout-session rest timer's
/// start/pause/resume/skip/reset state machine. Had zero test coverage --
/// it's a StateNotifier with a real `Timer.periodic`, so nothing exercised
/// it outside of actually running a workout session on a simulator.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  RestTimerController controller(int seconds) =>
      container.read(restTimerControllerProvider(seconds).notifier);

  test('starts at the given duration, not running, not completed', () {
    final state = container.read(restTimerControllerProvider(90));
    expect(state.remainingSeconds, 90);
    expect(state.isRunning, isFalse);
    expect(state.isCompleted, isFalse);
  });

  test('start() marks the timer running', () {
    final c = controller(90);
    c.start();
    expect(container.read(restTimerControllerProvider(90)).isRunning, isTrue);
  });

  test('start() is a no-op if already running or already completed', () {
    final c = controller(90);
    c.start();
    c.start(); // second call should not throw or reset anything
    expect(container.read(restTimerControllerProvider(90)).isRunning, isTrue);

    c.skip(); // now completed
    c.start(); // must not un-complete it
    expect(container.read(restTimerControllerProvider(90)).isCompleted, isTrue);
  });

  test('pause() stops the timer without completing it', () {
    final c = controller(90);
    c.start();
    c.pause();
    final state = container.read(restTimerControllerProvider(90));
    expect(state.isRunning, isFalse);
    expect(state.isCompleted, isFalse);
  });

  test('resume() restarts a paused timer but not a completed one', () {
    final c = controller(90);
    c.start();
    c.pause();
    c.resume();
    expect(container.read(restTimerControllerProvider(90)).isRunning, isTrue);

    c.skip();
    c.resume(); // completed -- resume must not revive it
    final state = container.read(restTimerControllerProvider(90));
    expect(state.isRunning, isFalse);
    expect(state.isCompleted, isTrue);
  });

  test('skip() completes immediately and zeroes the remaining time', () {
    final c = controller(90);
    c.start();
    c.skip();
    final state = container.read(restTimerControllerProvider(90));
    expect(state.isCompleted, isTrue);
    expect(state.remainingSeconds, 0);
    expect(state.isRunning, isFalse);
  });

  test('reset() restores the initial duration and clears running/completed', () {
    final c = controller(90);
    c.start();
    c.skip();
    c.reset(60);
    final state = container.read(restTimerControllerProvider(90));
    expect(state.remainingSeconds, 60);
    expect(state.isRunning, isFalse);
    expect(state.isCompleted, isFalse);
  });

  test('the timer actually ticks down once a second while running', () async {
    // .autoDispose providers tear themselves (and their Timer) down once
    // nothing is listening -- a bare container.read() doesn't hold it alive
    // long enough for a real Timer.periodic tick to land, so keep a
    // subscription open for the duration of the wait.
    final sub = container.listen(restTimerControllerProvider(3), (_, __) {});
    addTearDown(sub.close);
    container.read(restTimerControllerProvider(3).notifier).start();

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(sub.read().remainingSeconds, 2);
  });

  test('reaching zero while running completes the timer on its own', () async {
    final sub = container.listen(restTimerControllerProvider(1), (_, __) {});
    addTearDown(sub.close);
    container.read(restTimerControllerProvider(1).notifier).start();

    await Future<void>.delayed(const Duration(milliseconds: 2200));
    final state = sub.read();
    expect(state.isCompleted, isTrue);
    expect(state.remainingSeconds, 0);
  });
}
