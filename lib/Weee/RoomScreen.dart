// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class RoomMateApp extends StatelessWidget {
  const RoomMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoomProvider()..loadDefaultItems(),
      child: MaterialApp(
        title: 'RoomMate',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// models/item.dart
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

// providers/room_provider.dart


class RoomProvider with ChangeNotifier {
  List<RoomItem> _items = [];
  int _currency = 100;

  List<RoomItem> get ownedItems => _items.where((i) => i.isOwned).toList();
  List<RoomItem> get allItems => _items;
  int get currency => _currency;

  void buyItem(RoomItem item) {
    if (_currency >= item.price && !item.isOwned) {
      _currency -= item.price;
      item.isOwned = true;
      notifyListeners();
    }
  }

  void addCurrency(int amount) {
    _currency += amount;
    notifyListeners();
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
      RoomItem(id: 'pet1', name: 'Cat', assetPath: 'assets/cat.png', type: ItemType.pet, price: 15),
    ];
  }
}

// screens/home_screen.dart


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final screens = [ProfileScreen(), ShopScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Room'),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
        ],
      ),
    );
  }
}

// screens/profile_screen.dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("My Room")),
      body: Stack(
        children: [
          Container(color: Colors.lightBlue.shade50),
          RoomGrid(),
          Positioned(
            right: 10,
            top: 10,
            child: Chip(
              label: Text("⭐ ${provider.currency}"),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Shop")),
      body: ListView(
        children: provider.allItems.map((item) {
          return ListTile(
            leading: Image.asset(item.assetPath, width: 40),
            title: Text(item.name),
            subtitle: Text("${item.price} ⭐"),
            trailing: item.isOwned
                ? const Icon(Icons.check, color: Colors.green)
                : ElevatedButton(
              onPressed: () => provider.buyItem(item),
              child: const Text("Buy"),
            ),
          );
        }).toList(),
      ),
    );
  }
}



class RoomGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = Provider.of<RoomProvider>(context).ownedItems;
    return Stack(
      children: items.map((item) {
        return Positioned(
          left: item.posX.toDouble(),
          top: item.posY.toDouble(),
          child: Draggable(
            feedback: Image.asset(item.assetPath, width: 50),
            childWhenDragging: Container(),
            onDragEnd: (details) {
              Provider.of<RoomProvider>(context, listen: false)
                  .updateItemPosition(item.id, details.offset.dx.toInt(), details.offset.dy.toInt());
            },
            child: Image.asset(item.assetPath, width: 50),
          ),
        );
      }).toList(),
    );
  }
}