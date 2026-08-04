import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final timeServiceProvider = Provider<TimeService>((ref) {
  return TimeService();
});

class TimeService {
  DateTime now() => DateTime.now();
  
  Stream<DateTime> get timeStream {
    return Stream.periodic(const Duration(seconds: 1), (_) => now());
  }
  
  Stream<int> createCountdownStream(int seconds) {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      final remaining = seconds - count - 1;
      return remaining >= 0 ? remaining : 0;
    }).take(seconds + 1);
  }
}

// Rest Timer Controller
final restTimerControllerProvider = StateNotifierProvider.autoDispose
    .family<RestTimerController, RestTimerState, int>((ref, initialSeconds) {
  return RestTimerController(initialSeconds);
});

class RestTimerState {
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;

  const RestTimerState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.isCompleted,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class RestTimerController extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerController(int initialSeconds)
      : super(RestTimerState(
          remainingSeconds: initialSeconds,
          isRunning: false,
          isCompleted: false,
        ));

  void start() {
    if (state.isRunning || state.isCompleted) return;
    
    state = state.copyWith(isRunning: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        _complete();
        return;
      }
      
      state = state.copyWith(
        remainingSeconds: state.remainingSeconds - 1,
      );
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (!state.isRunning && !state.isCompleted) {
      start();
    }
  }

  void skip() {
    _complete();
  }

  void reset(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      isRunning: false,
      isCompleted: false,
    );
  }

  void _complete() {
    _timer?.cancel();
    state = state.copyWith(
      remainingSeconds: 0,
      isRunning: false,
      isCompleted: true,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
