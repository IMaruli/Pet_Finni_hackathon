final class GameCoins {
  const GameCoins(this.value) : assert(value >= 0);

  static const zero = GameCoins(0);

  final int value;

  GameCoins operator +(GameCoins other) => GameCoins(value + other.value);

  GameCoins operator -(GameCoins other) {
    final next = value - other.value;
    if (next < 0) {
      throw ArgumentError.value(other.value, 'other', 'result would be negative');
    }
    return GameCoins(next);
  }

  bool operator <=(GameCoins other) => value <= other.value;
  bool operator >=(GameCoins other) => value >= other.value;

  @override
  bool operator ==(Object other) => other is GameCoins && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'GameCoins($value)';
}
