import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ThemeManager.dart';

class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Theme"),
        backgroundColor: themeManager.currentTheme.primaryColor,
      ),
      body: ListView.builder(
        itemCount: themeManager.themes.length,
        itemBuilder: (context, index) {
          final theme = themeManager.themes[index];
          final isSelected = index == themeManager.selectedIndex;

          return GestureDetector(
            onTap: () {
              themeManager.setTheme(index);
            },
            child: Card(
              margin: EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              elevation: isSelected ? 8 : 2,
              shadowColor: theme.boxShadow.color,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadius)),
                    child: Image.asset(theme.bannerImage, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  ListTile(
                    title: Text(theme.name, style: TextStyle(color: theme.textColor)),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: theme.primaryColor)
                        : Icon(Icons.circle_outlined, color: theme.textColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
