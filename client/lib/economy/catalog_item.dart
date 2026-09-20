import 'game_coins.dart';

enum ItemKind { need, want }

final class CatalogItem {
  const CatalogItem({required this.id, required this.kind, required this.price});
  final String id;
  final ItemKind kind;
  final GameCoins price;
}
