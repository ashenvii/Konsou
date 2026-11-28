/// A count with thousands commas.
String formatCount(int count) {
  final digits = '$count';
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// "1 title", "3 titles", "1,200 users". Only for words that take an s.
String formatCountOf(int count, String word) =>
    count == 1 ? '1 $word' : '${formatCount(count)} ${word}s';
