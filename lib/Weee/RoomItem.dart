enum ItemType { furniture, wall, poster, pet }

class RoomItem {
  final String id;
  final String name;
  final String assetPath;
  final ItemType type;
  final int price;
  bool isOwned;
  int posX;
  int posY;

  RoomItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.type,
    required this.price,
    this.isOwned = false,
    this.posX = 0,
    this.posY = 0,
  });
}
