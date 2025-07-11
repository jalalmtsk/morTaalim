import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider.dart';

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RoomProvider>(context);
    return ListView(
      children: provider.ownedItems.map((item) {
        return ListTile(
          leading: Image.asset(item.assetPath, width: 40),
          title: Text(item.name),
          trailing: ElevatedButton(
            onPressed: () => provider.buyItem(item),
            child: Text("Buy ${item.price}⭐"),
          ),
        );
      }).toList(),
    );
  }
}
