import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide useWhiteForeground;
import 'package:flutter/rendering.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:mortaalim/games/paitingGame/singleDrawing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import 'model_logic_page.dart';

class DrawingApp extends StatefulWidget {
  @override
  _DrawingAppState createState() => _DrawingAppState();
}

class _DrawingAppState extends State<DrawingApp> {


  List<SavedDrawing> savedDrawings = [];
  int _currentIndex = 0; // 0 = Draw, 1 = Gallery

  // Variables to preserve current drawing state
  List<DrawPoint?> currentPoints = [];
  Color currentColor = Colors.black;
  double currentStrokeWidth = 6.0;
  bool currentIsErasing = false;
  Duration currentElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSavedDrawings();
  }

  Future<Directory> get _appDir async {
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _loadSavedDrawings() async {
    final dir = await _appDir;
    final metaFile = File('${dir.path}/drawings_metadata.json');

    if (!await metaFile.exists()) {
      // No saved drawings yet
      return;
    }

    final metaJson = await metaFile.readAsString();
    final List<dynamic> metaList = jsonDecode(metaJson);

    List<SavedDrawing> loadedDrawings = [];

    for (var item in metaList) {
      final String fileName = item['fileName'];
      final int drawDurationMs = item['drawDurationMs'];
      final String savedAtStr = item['savedAt'];

      final imageFile = File('${dir.path}/$fileName');

      if (await imageFile.exists()) {
        final imageBytes = await imageFile.readAsBytes();

        loadedDrawings.add(SavedDrawing(
          imageData: imageBytes,
          drawDuration: Duration(milliseconds: drawDurationMs),
          savedAt: DateTime.parse(savedAtStr),
        ));
      }
    }

    setState(() {
      savedDrawings = loadedDrawings;
    });
  }

  Future<void> _saveDrawingToDisk(SavedDrawing drawing) async {
    final dir = await _appDir;

    // Unique filename based on timestamp
    final fileName = 'drawing_${drawing.savedAt.millisecondsSinceEpoch}.png';
    final imageFile = File('${dir.path}/$fileName');

    await imageFile.writeAsBytes(drawing.imageData);

    // Save metadata
    final metaFile = File('${dir.path}/drawings_metadata.json');
    List<dynamic> metaList = [];

    if (await metaFile.exists()) {
      final metaJson = await metaFile.readAsString();
      metaList = jsonDecode(metaJson);
    }

    metaList.add({
      'fileName': fileName,
      'drawDurationMs': drawing.drawDuration.inMilliseconds,
      'savedAt': drawing.savedAt.toIso8601String(),
    });

    await metaFile.writeAsString(jsonEncode(metaList));
  }

  Future<void> _deleteDrawingFromDisk(int index) async {
    final dir = await _appDir;
    final metaFile = File('${dir.path}/drawings_metadata.json');

    if (!await metaFile.exists()) return;

    final metaJson = await metaFile.readAsString();
    List<dynamic> metaList = jsonDecode(metaJson);

    if (index < 0 || index >= metaList.length) return;

    final item = metaList[index];
    final fileName = item['fileName'];
    final imageFile = File('${dir.path}/$fileName');

    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    metaList.removeAt(index);

    await metaFile.writeAsString(jsonEncode(metaList));
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? SingleDrawingPage(
        initialPoints: currentPoints,
        initialColor: currentColor,
        initialStrokeWidth: currentStrokeWidth,
        initialIsErasing: currentIsErasing,
        initialElapsed: currentElapsed,
        onSave: (drawing) async {
          await _saveDrawingToDisk(drawing);
          setState(() {
            savedDrawings.add(drawing);
            // Clear current drawing state after saving
            currentPoints = [];
            currentElapsed = Duration.zero;
            currentIsErasing = false;
            currentColor = Colors.black;
            currentStrokeWidth = 6.0;

            _currentIndex = 1; // switch to gallery after save
          });
        },
        onChanged: (points, color, strokeWidth, isErasing, elapsed) {
          // Save current drawing state when it changes
          currentPoints = points;
          currentColor = color;
          currentStrokeWidth = strokeWidth;
          currentIsErasing = isErasing;
          currentElapsed = elapsed;
        },
      )
          : GalleryPage(
        savedDrawings: savedDrawings,
        onDelete: (index) async {
          await _deleteDrawingFromDisk(index);
          setState(() {
            savedDrawings.removeAt(index);
          });
        },
        onBack: () => setState(() => _currentIndex = 0),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.format_paint), label: "Draw"),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: "Gallery"),
        ],
      ),

    );
  }
}

class GalleryPage extends StatelessWidget {
  final List<SavedDrawing> savedDrawings;
  final Function(int) onDelete;
  final VoidCallback onBack;

  GalleryPage({required this.savedDrawings, required this.onDelete, required this.onBack});

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy - hh:mm a').format(dt);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🖼️ Gallery', style: TextStyle(fontFamily: 'Comic Sans MS', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: savedDrawings.isEmpty
          ? Center(
        child: Text(
          'No drawings saved yet!\nCreate some awesome art!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontFamily: 'Comic Sans MS'),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: savedDrawings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final drawing = savedDrawings[index];
            return Stack(
              children: [
                GestureDetector(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    shadowColor: Colors.deepPurpleAccent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.memory(drawing.imageData, fit: BoxFit.cover),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.85),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time: ${_formatDuration(drawing.drawDuration)}',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Comic Sans MS'),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatDate(drawing.savedAt),
                                style: TextStyle(color: Colors.white70, fontFamily: 'Comic Sans MS', fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: Icon(Icons.delete_forever, color: Colors.redAccent),
                    onPressed: () {
                      _confirmDelete(context, index);
                    },
                    tooltip: 'Delete Drawing',
                  ),
                ),

              ],
            );
          },
        ),
      ),


    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Drawing?', style: TextStyle(fontFamily: 'Comic Sans MS')),
        content: Text('Are you sure you want to delete this drawing?', style: TextStyle(fontFamily: 'Comic Sans MS')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
              onPressed: () {
                onDelete(index);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

