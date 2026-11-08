import 'dart:math';

final _random = Random.secure();

/// A new entry or device id: 16 random bytes as hex. Random, not a counter,
/// so two devices never hand out the same id.
String generateId() => [
  for (var i = 0; i < 16; i++)
    _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
].join();
