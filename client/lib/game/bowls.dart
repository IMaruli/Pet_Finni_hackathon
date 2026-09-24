/// Миски у героя: полные, если нужное куплено (SA F-027).
final class Bowls {
  const Bowls({this.food = true, this.water = true});
  final bool food;
  final bool water;

  String get key => '$food$water';
}
