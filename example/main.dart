// ignore_for_file: avoid_print

import 'package:async/async.dart';
import 'package:cancelable_retry/cancelable_retry.dart';

var _num = 0;

Future<void> main() async {
  // Create CancelableRetry
  final request = CancelableRetry<Result<String>>(
    _request,
    retryIf: (r) => r.isError && r.asError!.error == 'retry',
  );

  // Execute request
  final res = await request.run();

  // Print result
  print(res.isValue
      ? 'Result: ${res.asValue!.value}'
      : 'Error: ${res.asError!.error}');
}

// Request function
Future<Result<String>> _request() async {
  _num++;
  print('Request #$_num');
  await Future<void>.delayed(const Duration(milliseconds: 100));
  if (_num < 3) {
    return Result.error('retry');
  } else {
    return Result.value('success');
  }
}
