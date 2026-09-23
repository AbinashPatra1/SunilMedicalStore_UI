import 'package:flutter/services.dart';

const _channel = MethodChannel('com.sunilmedical.store/beep');

/// Plays a short confirmation beep — used when a barcode scan succeeds.
/// Best effort: never throws (e.g. on platforms/tests without the channel).
Future<void> playScanBeep() async {
  try {
    await _channel.invokeMethod<void>('beep');
  } catch (_) {
    // A missing beep isn't worth surfacing.
  }
}
