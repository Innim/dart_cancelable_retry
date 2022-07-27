import 'dart:async';
import 'dart:math' as math;

import 'package:async/async.dart';

final _rnd = math.Random();

class CancelableRetry<T> {
  final FutureOr<T> Function() request;
  final FutureOr<bool> Function(T) retryIf;
  //final FutureOr<bool> Function(Exception)? retryIfException;
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

  Future<void> cancel() async {
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
