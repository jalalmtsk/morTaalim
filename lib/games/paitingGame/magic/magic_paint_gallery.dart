import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/KidScene/kid_scene.dart';
import 'magic_paint_data.dart';
import 'magic_paint_widgets.dart';

/// Mes créations: "Mon petit musée".
class MpGalleryTab extends StatefulWidget {
  final double scale;
  final Animation<double> idle;
  final void Function(String key) onSound;
  final void Function(MpCreation c) onOpen;
  final VoidCallback onNew; // "Nouvelle création" card
  final VoidCallback onCreateDrawing;
  const MpGalleryTab({
    super.key,
    required this.scale,
    required this.idle,
    required this.onSound,
    required this.onOpen,
    required this.onNew,
    required this.onCreateDrawing,
  });

  @override
  State<MpGalleryTab> createState() => MpGalleryTabState();
}

class MpGalleryTabState extends State<MpGalleryTab> {
  List<MpCreation> _all = [];
  final Map<String, File> _files = {};
  int _filter = 0; // 0 all, 1 in progress, 2 done
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final all = await MpStore.list();
    for (final c in all) {
      _files[c.id] = await MpStore.imageFile(c.id);
    }
    if (!mounted) return;
    setState(() {
      _all = all;
      _loaded = true;
    });
  }

  List<MpCreation> get _shown => _filter == 0 ? _all : _all.where((c) => _filter == 2 ? c.done : !c.done).toList();

  Future<void> _menu(MpCreation c) async {
    widget.onSound('clickButton');
    final act = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: mpCard(1, radius: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(c.title, style: mpTitle(19, color: mpPurple)),
            const SizedBox(height: 6),
            for (final it in [
              ('open', Icons.brush_rounded, mpText(context, 'continue')),
              ('rename', Icons.edit_rounded, mpText(context, 'rename')),
              ('share', Icons.share_rounded, mpText(context, 'share')),
              ('delete', Icons.delete_rounded, mpText(context, 'delete')),
            ])
              ListTile(
                leading: Icon(it.$2, color: it.$1 == 'delete' ? const Color(0xFFE5273F) : mpPurple),
                title: Text(it.$3, style: mpTitle(17, color: it.$1 == 'delete' ? const Color(0xFFE5273F) : mpInk)),
                onTap: () => Navigator.of(ctx).pop(it.$1),
              ),
          ]),
        ),
      ),
    );
    if (!mounted || act == null) return;
    switch (act) {
      case 'open':
        widget.onOpen(c);
        break;
      case 'rename':
        final ctrl = TextEditingController(text: c.title);
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => KidDialog(
            title: mpText(context, 'rename'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 24,
              textAlign: TextAlign.center,
              style: mpTitle(20),
              decoration: InputDecoration(hintText: mpText(context, 'nameHint'), counterText: ''),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            actions: [
              KidButton(label: mpText(context, 'ok'), onPressed: () => Navigator.of(ctx).pop(ctrl.text), width: 180, height: 52, showArrow: false),
            ],
          ),
        );
        if (name != null && name.trim().isNotEmpty) {
          c.title = name.trim();
          await MpStore.update(c);
          await reload();
        }
        break;
      case 'share':
        final f = _files[c.id];
        if (f != null && await f.exists()) {
          await Share.shareXFiles([XFile(f.path)], text: '🎨 ${c.title}');
        }
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => KidDialog(
            title: mpText(context, 'deleteAsk'),
            actions: [
              KidButton(label: mpText(context, 'delete'), onPressed: () => Navigator.of(ctx).pop(true), width: 200, height: 52, showArrow: false),
              const SizedBox(height: 8),
              KidOutlineButton(label: mpText(context, 'cancel'), onTap: () => Navigator.of(ctx).pop(false)),
            ],
          ),
        );
        if (ok == true) {
          await MpStore.delete(c.id);
          await reload();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final items = _shown;
    return Stack(clipBehavior: Clip.none, children: [
      Column(children: [
        MpBanner(scale: s, title: mpText(context, 'museum'), subtitle: mpText(context, 'museumSub'), height: 76),
        Expanded(
          child: Transform.translate(
            offset: Offset(0, -8 * s),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 6 * s),
              padding: EdgeInsets.fromLTRB(8 * s, 14 * s, 8 * s, 0),
              decoration: BoxDecoration(
                color: mpCream.withOpacity(0.92),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s), bottom: Radius.circular(18 * s)),
                border: Border.all(color: Colors.white, width: 2.5 * s),
              ),
              child: Column(children: [
                _filters(s),
                SizedBox(height: 8 * s),
                Expanded(
                  child: !_loaded
                      ? const Center(child: CircularProgressIndicator(color: mpPurple))
                      : GridView.builder(
                          padding: EdgeInsets.only(bottom: 90 * s),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10 * s,
                            crossAxisSpacing: 10 * s,
                            childAspectRatio: 0.93,
                          ),
                          itemCount: items.length + 1,
                          itemBuilder: (_, i) => i == items.length ? _newCard(s, items.isEmpty) : _card(s, items[i]),
                        ),
                ),
              ]),
            ),
          ),
        ),
        SizedBox(height: 2 * s),
        Padding(
          padding: EdgeInsetsDirectional.only(end: 70 * s),
          child: MpOrangeButton(
            scale: s,
            label: mpText(context, 'createDrawing'),
            icon: Image.asset(mpImgBrushPlus),
            onTap: () {
              widget.onSound('clickButton');
              widget.onCreateDrawing();
            },
          ),
        ),
      ]),
      PositionedDirectional(
        end: -12 * s,
        bottom: -10 * s,
        child: IgnorePointer(
          child: MpRobotTalk(scale: s, image: mpImgRobotGallery, text: mpText(context, 'talent'), idle: widget.idle, height: 120),
        ),
      ),
    ]);
  }

  Widget _filters(double s) {
    final labels = [mpText(context, 'all'), mpText(context, 'inProgress'), mpText(context, 'doneMany')];
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) SizedBox(width: 8 * s),
        Expanded(
          child: KidPressable(
            onTap: () {
              widget.onSound('clickButton');
              setState(() => _filter = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 38 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20 * s),
                gradient: _filter == i ? const LinearGradient(colors: [Color(0xFF45E3F5), Color(0xFF12B5D4)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                color: _filter == i ? null : const Color(0xFFFBF0DC),
                border: Border.all(color: _filter == i ? const Color(0xFFB8F6FF) : Colors.white, width: 2 * s),
                boxShadow: [if (_filter == i) BoxShadow(color: mpCyan.withOpacity(0.55), blurRadius: 10 * s)],
              ),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(labels[i], style: mpTitle(16 * s, color: _filter == i ? Colors.white : mpInk))),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _status(double s, bool done) {
    return Container(
      height: 28 * s,
      padding: EdgeInsetsDirectional.fromSTEB(3 * s, 0, 10 * s, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * s),
        gradient: LinearGradient(
          colors: done ? const [Color(0xFFB8F27A), Color(0xFF7CD94A)] : const [Color(0xFFFFE27A), Color(0xFFFFC23C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 22 * s,
          height: 22 * s,
          decoration: BoxDecoration(shape: BoxShape.circle, color: done ? const Color(0xFF1E9E3A) : Colors.transparent),
          child: Icon(done ? Icons.check_rounded : Icons.edit_rounded, size: 16 * s, color: done ? Colors.white : const Color(0xFF7A3E00)),
        ),
        SizedBox(width: 4 * s),
        Text(mpText(context, done ? 'done' : 'inProgress'), style: mpTitle(13.5 * s, color: done ? const Color(0xFF14531F) : const Color(0xFF6A3500))),
      ]),
    );
  }

  Widget _card(double s, MpCreation c) {
    final f = _files[c.id];
    return KidPressable(
      onTap: () => widget.onOpen(c),
      pressedScale: 0.96,
      child: Container(
        padding: EdgeInsets.all(7 * s),
        decoration: mpCard(s, radius: 20, fill: Colors.white),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14 * s),
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: f == null
                    ? null
                    : Image.file(f, fit: BoxFit.cover, key: ValueKey('${c.id}_${c.updated}'), errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          ),
          SizedBox(height: 4 * s),
          Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: mpTitle(15 * s)),
          SizedBox(height: 3 * s),
          Row(children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: _status(s, c.done))),
            const Spacer(),
            if (!c.done)
              KidPressable(
                onTap: () => widget.onOpen(c),
                child: Container(
                  height: 28 * s,
                  padding: EdgeInsets.symmetric(horizontal: 10 * s),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 * s),
                    gradient: const LinearGradient(colors: [Color(0xFFFFB63D), Color(0xFFFF7A10)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(mpText(context, 'continue'), style: mpTitle(13 * s, color: Colors.white))),
                ),
              ),
            SizedBox(width: 4 * s),
            MpRoundButton(size: 30 * s, onTap: () => _menu(c), child: Icon(Icons.more_horiz_rounded, color: mpPurple, size: 20 * s)),
          ]),
        ]),
      ),
    );
  }

  Widget _newCard(double s, bool empty) {
    return KidPressable(
      onTap: () {
        widget.onSound('clickButton');
        widget.onNew();
      },
      pressedScale: 0.96,
      child: Container(
        padding: EdgeInsets.all(6 * s),
        decoration: mpCard(s, radius: 20, fill: const Color(0xFFFFFBF2)),
        child: Column(children: [
          Expanded(child: Image.asset(mpImgNewCard, fit: BoxFit.contain)),
          SizedBox(height: 4 * s),
          FittedBox(fit: BoxFit.scaleDown, child: Text(mpText(context, 'newCreation'), textAlign: TextAlign.center, style: mpTitle(16 * s, color: mpPurple))),
          if (empty)
            Text(mpText(context, 'emptyMuseum'), textAlign: TextAlign.center, maxLines: 3, style: kidBodyStyle(10.5 * s, color: mpInk, weight: FontWeight.w600)),
          SizedBox(height: 4 * s),
        ]),
      ),
    );
  }
}
