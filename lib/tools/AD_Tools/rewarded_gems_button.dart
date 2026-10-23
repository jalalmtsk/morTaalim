import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';

/// RewardedGemsButton — « Regarder une pub : +N gemmes »
/// Same Families rules as DoubleRewardButton: explicit tap, labelled
/// « Publicité », neutral style, greyed until an ad is ready, hidden when ads
/// are off or the daily cap is reached, one use per screen.
class RewardedGemsButton extends StatefulWidget {
  /// Gems given after the ad.
  final int gems;
  final double? width;
  final double height;

  const RewardedGemsButton({
    super.key,
    this.gems = 2,
    this.width,
    this.height = 46,
  });

  @override
  State<RewardedGemsButton> createState() => _RewardedGemsButtonState();
}

class _RewardedGemsButtonState extends State<RewardedGemsButton> {
  bool _ready = AdHelper.isRewardedAdReady;
  bool _busy = false;
  bool _done = false;
  bool _capReached = false;

  @override
  void initState() {
    super.initState();
    AdHelper.preloadRewardedAd(onLoaded: () {
      if (mounted) setState(() => _ready = true);
    });
    AdHelper.rewardedRemainingToday().then((left) {
      if (mounted && left <= 0) setState(() => _capReached = true);
    });
  }

  Future<void> _onTap() async {
    if (_busy || _done || !_ready) return;
    setState(() => _busy = true);
    final earned = await AdHelper.showRewardedAd(context);
    if (!mounted) return;
    if (earned) {
      Provider.of<ExperienceManager>(context, listen: false)
          .addGems(context, widget.gems);
    }
    setState(() {
      _busy = false;
      _done = earned;
      _ready = AdHelper.isRewardedAdReady;
    });
    if (!earned) {
      AdHelper.preloadRewardedAd(onLoaded: () {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsOn = context.select<ExperienceManager, bool>((x) => x.adsEnabled);
    if (widget.gems <= 0 || !adsOn || (_capReached && !_done)) {
      return const SizedBox.shrink();
    }

    final enabled = _ready && !_busy && !_done;
    final label = _done
        ? AdHelper.adText(context, 'gemsDone')
        : AdHelper.adText(context, 'gems').replaceAll('{n}', '${widget.gems}');

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: _done ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.height / 2),
          onTap: enabled ? _onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: _done ? const Color(0xFF66BB6A) : const Color(0xFFBDBDBD),
                width: 1.5,
              ),
            ),
            child: Opacity(
              opacity: enabled || _done ? 1 : 0.5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_done) ...[
                    // Étiquette « Publicité » obligatoire
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AdHelper.adText(context, 'adLabel'),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
                        )
                      : Icon(
                          _done ? Icons.check_circle_rounded : Icons.diamond_rounded,
                          size: 20,
                          color: _done ? const Color(0xFF43A047) : const Color(0xFF7B3FE4),
                        ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _done ? const Color(0xFF2E7D32) : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
