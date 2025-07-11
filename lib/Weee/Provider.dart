import 'package:flutter/material.dart';

import 'RoomItem.dart';

class RoomProvider with ChangeNotifier {
  List<RoomItem> _items = [];
  int _currency = 100;

  List<RoomItem> get ownedItems => _items.where((i) => i.isOwned).toList();
  int get currency => _currency;

  void buyItem(RoomItem item) {
    if (_currency >= item.price) {
      _currency -= item.price;
      item.isOwned = true;
      notifyListeners();
    }
  }

  void updateItemPosition(String id, int x, int y) {
    final item = _items.firstWhere((i) => i.id == id);
    item.posX = x;
    item.posY = y;
    notifyListeners();
  }

  void loadDefaultItems() {
    _items = [
      RoomItem(id: 'chair1', name: 'Chair', assetPath: 'assets/chair.png', type: ItemType.furniture, price: 10),
      RoomItem(id: 'poster1', name: 'Poster', assetPath: 'assets/poster.png', type: ItemType.poster, price: 5),
      // Add more items
    ];
  }
}
