import 'package:flutter/material.dart';

import 'kid_scene.dart';

/// Form pieces in the illustrated onboarding style:
/// white pill fields with a purple outline, a divider, and a chevron.

class KidFieldLabel extends StatelessWidget {
  final String text;
  final String? tag;
  final double size;

  const KidFieldLabel(this.text, {super.key, this.tag, this.size = 17});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 6),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (tag != null)
            TextSpan(
              text: ' $tag',
              style: kidBodyStyle(size * 0.82, color: KidColors.inkSoft, weight: FontWeight.w500),
            ),
        ]),
        style: kidBodyStyle(size, color: KidColors.ink, weight: FontWeight.w700),
      ),
    );
  }
}

class KidSelectField extends StatelessWidget {
  final Widget? leading;
  final String? value;
  final String hint;
  final VoidCallback? onTap;
  final double height;

  const KidSelectField({
    super.key,
    this.leading,
    required this.value,
    required this.hint,
    required this.onTap,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final has = value != null && value!.isNotEmpty;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: KidPressable(
        onTap: onTap,
        pressedScale: 0.98,
        semanticLabel: has ? value : hint,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: h,
          padding: EdgeInsets.symmetric(horizontal: h * 0.28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(h * 0.42),
            border: Border.all(
                color: has ? KidColors.purple : const Color(0xFFC7B2F6), width: has ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                color: KidColors.purple.withOpacity(has ? 0.22 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: h * 0.52, height: h * 0.52, child: Center(child: leading)),
                SizedBox(width: h * 0.18),
                Container(
                    width: 3,
                    height: h * 0.42,
                    decoration: BoxDecoration(
                        color: KidColors.purple.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(2))),
                SizedBox(width: h * 0.18),
              ],
              Expanded(
                child: Text(
                  has ? value! : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kidBodyStyle(
                    h * 0.29,
                    color: has ? KidColors.purpleDeep : const Color(0xFFA996D6),
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: h * 0.1),
              Image.asset(KidAssets.icChevron,
                  width: h * 0.22, height: h * 0.15, color: KidColors.purple),
            ],
          ),
        ),
      ),
    );
  }
}

/// Underlined small link ("Skip for now").
class KidLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double size;

  const KidLink({super.key, required this.text, required this.onTap, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          text,
          style: kidBodyStyle(size, color: KidColors.purpleDeep, weight: FontWeight.w600).copyWith(
            decoration: TextDecoration.underline,
            decorationColor: KidColors.purpleDeep,
            decorationThickness: 1.6,
          ),
        ),
      ),
    );
  }
}

/// Cream rounded bottom sheet frame with a drag handle and title.
class KidSheetFrame extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxHeightFactor;

  const KidSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.maxHeightFactor = 0.78,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * maxHeightFactor),
        decoration: const BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: KidColors.lavender, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                    color: KidColors.lavender, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: kidBodyStyle(21, color: KidColors.ink, weight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable row in a sheet.
class KidOptionTile extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const KidOptionTile({
    super.key,
    required this.label,
    this.subLabel,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: KidPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? KidColors.purpleLight : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? KidColors.purple : const Color(0xFFE6DDF7),
                width: selected ? 2.5 : 1.5),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: kidBodyStyle(17, color: KidColors.ink, weight: FontWeight.w700)),
                    if (subLabel != null)
                      Text(subLabel!,
                          style: kidBodyStyle(13, color: KidColors.muted, weight: FontWeight.w500)),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: const Icon(Icons.check_circle_rounded, color: KidColors.purple, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple list picker in a cream sheet. Returns the chosen value.
Future<T?> showKidOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) label,
  T? selected,
  Widget Function(T)? leading,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => KidSheetFrame(
      title: title,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 14),
        children: [
          for (final o in options)
            KidOptionTile(
              label: label(o),
              leading: leading?.call(o),
              selected: o == selected,
              onTap: () => Navigator.of(ctx).pop(o),
            ),
        ],
      ),
    ),
  );
}
