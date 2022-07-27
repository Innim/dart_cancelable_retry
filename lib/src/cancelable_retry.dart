import 'dart:async';
import 'dart:math' as math;

import 'package:async/async.dart';

final _rnd = math.Random();

/// Utility for wrapping an asynchronous function
/// in automatic retry logic with ability to cancel it.
///
/// Allows to automatically retry request on some condition.
/// Retry logic implemented with exponential back-off,
/// useful when making requests over network.
/// If you don't need to continue retry - you can cancel retry.
/// In such case last result will be returned.
class CancelableRetry<T> {
  final FutureOr<T> Function() request;
  final FutureOr<bool> Function(T) retryIf;
  final Duration delayFactor;
  final Duration maxDelay;
  final int maxAttempts;
  final double randomizationFactor;

  CancelableOperation? _delay;
  bool _running = false;

  CancelableRetry(
    this.request, {
    required this.retryIf,
    this.delayFactor = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 30),
    this.maxAttempts = 8,
    this.randomizationFactor = 0.25,
  });

  /// Runs request and returns result.
  ///
  /// Will be finished when:
  /// - request returns result, which not satisfies [retryIf] condition, or
  /// - [cancel] is called, or
  /// - [maxAttempts] is reached.
  Future<T> run() async {
    if (_running) throw StateError('Already running');
    _running = true;

    var attempts = 0;
    T res;

    // ignore: literal_only_boolean_expressions
    while (true) {
      res = await request();
      if (attempts < maxAttempts && await retryIf(res)) {
        attempts++;

        final delay = _delay = CancelableOperation<void>.fromFuture(
            Future<void>.delayed(_getDelay(attempts)));
        await delay.valueOrCancellation();
        _delay = null;
        if (delay.isCanceled) break;
      } else {
        break;
      }
    }

    _running = false;
    return res;
  }

  /// Cancels retries.
  ///
  /// In such case last result will be returned from [run].
  Future<void> cancel() async {
    // TODO: mark for cancellation if request is running
    await _delay?.cancel();
  }

  Duration _getDelay(int attempt) {
    assert(attempt > 0);

    final rndFactor = 1 + randomizationFactor * (_rnd.nextDouble() * 2 - 1);

    // prevent overflows
    final exp = math.min(attempt, 31);
    final delay = delayFactor * math.pow(2.0, exp) * rndFactor;
    return delay < maxDelay ? delay : maxDelay;
  }
}
