import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'ThemeManager.dart';
import 'AppTheme.dart';

class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final current      = themeManager.currentTheme;

    return Scaffold(
      // Background uses the active theme's colour
      backgroundColor: current.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────
            _Header(theme: current),

            const SizedBox(height: 12),

            // ── Theme grid ────────────────────────────────────
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: themeManager.themes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) => _ThemeCard(
                  theme:      themeManager.themes[i],
                  isSelected: i == themeManager.selectedIndex,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    themeManager.setTheme(i);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final AppTheme theme;
  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [theme.boxShadow],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎨 Choose your theme!',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    shadows: [Shadow(color: Color(0x33000000), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make it yours ✨',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),

          // Active theme name pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              theme.name,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  THEME CARD
// ═══════════════════════════════════════════════════════════════
class _ThemeCard extends StatefulWidget {
  final AppTheme theme;
  final bool     isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) => _ctrl.reverse(),
      onTapCancel: ()  => _ctrl.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: t.backgroundColor,
            borderRadius: BorderRadius.circular(t.borderRadius),
            border: widget.isSelected
                ? Border.all(color: t.primaryColor, width: 3)
                : Border.all(color: t.primaryColor.withOpacity(0.20), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: t.boxShadow.color.withOpacity(
                    widget.isSelected ? 0.45 : 0.15),
                blurRadius: widget.isSelected ? 20 : 8,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Banner image ─────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(t.borderRadius),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      t.bannerImage,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
                        decoration: BoxDecoration(gradient: t.gradient),
                      ),
                    ),
                    // Gradient overlay on image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.30),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // Selected checkmark badge
                    if (widget.isSelected)
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: t.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: t.primaryColor.withOpacity(0.45),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom info row ──────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    // Colour swatches
                    Row(
                      children: [
                        _Swatch(t.primaryColor),
                        const SizedBox(width: 5),
                        _Swatch(t.accentColor),
                        const SizedBox(width: 5),
                        _Swatch(t.backgroundColor),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Theme name
                    Expanded(
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: t.textColor,
                        ),
                      ),
                    ),

                    // Active / inactive pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? t.primaryColor
                            : t.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isSelected ? '✓ Active' : 'Apply',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? Colors.white
                              : t.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Colour swatch dot ─────────────────────────────────────────
class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.35), blurRadius: 4),
      ],
    ),
  );
}