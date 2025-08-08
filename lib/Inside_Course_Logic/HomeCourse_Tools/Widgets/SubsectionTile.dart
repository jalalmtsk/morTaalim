import 'package:flutter/material.dart';

/// Subsection tile used in bottom sheet
class SubsectionTile extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;
  const SubsectionTile({Key? key, required this.title, required this.description, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.play_arrow), backgroundColor: Colors.orangeAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
