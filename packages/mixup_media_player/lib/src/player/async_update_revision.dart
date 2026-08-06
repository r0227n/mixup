import 'package:flutter/foundation.dart';

@internal
final class AsyncUpdateRevision {
  int _value = 0;

  int capture() => _value;

  void invalidate() => _value++;

  bool isCurrent(int revision) => revision == _value;
}
