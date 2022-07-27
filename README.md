# cancelable_retry

[![pub package](https://img.shields.io/pub/v/cancelable_retry)](https://pub.dartlang.org/packages/cancelable_retry)
![Analyze & Test](https://github.com/Innim/dart_cancelable_retry/actions/workflows/dart.yml/badge.svg?branch=main)
[![innim lint](https://img.shields.io/badge/style-innim_lint-40c4ff.svg)](https://pub.dev/packages/innim_lint)

Utility for wrapping an asynchronous function in automatic retry logic with ability to cancel it.

## Features

Allows to automatically retry request on some condition. Retry logic implemented with exponential back-off, useful when making requests over network.
If you don't need to continue retry - you can cancel retry. In such case last result will be returned.

## Getting started

To use this plugin, add `cancelable_retry` as a [dependency in your pubspec.yaml file](https://flutter.dev/platform-plugins/).

## Usage

Create instance of `CancelableRetry` and call `run()`:

```dart
import 'package:cancelable_retry/cancelable_retry.dart';

final request = CancelableRetry(
    // Provide request function
    () => doSomeRequest(),
    // Set conditions for retry
    retryIf: (result) => result == "retry",
    // Optional:
    // - Define max retry attempts
    maxAttempts: 8,
    // - Define max delay between retries
    maxDelay: const Duration(seconds: 30),
    // - Tune delay between retries
    delayFactor: const Duration(milliseconds: 200),
    randomizationFactor: 0.25,
  );

// Run request
final res = await request.run();
```

If you want to cancel retries, just call `cancel()`:

```dart
await request.cancel();
```