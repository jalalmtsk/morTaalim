import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_catalog.dart';
import 'banner_catalog.dart';

class CustomizationSettings {
  // Avatars
  List<String> unlockedAvatars;
  String selectedAvatar;

  // Banners
  List<String> unlockedBanners;
  String selectedBannerImage;

  // Avatar frames
  List<String> unlockedAvatarFrames;
  String selectedAvatarFrame;

  CustomizationSettings({
    List<String>? unlockedAvatars,
    String? selectedAvatar,
    List<String>? unlockedBanners,
    String? selectedBannerImage,
    List<String>? unlockedAvatarFrames,
    String? selectedAvatarFrame,
  })  : unlockedAvatars = AvatarCatalog.sanitizeUnlocked(unlockedAvatars),
        selectedAvatar = AvatarCatalog.resolve(selectedAvatar),
        unlockedBanners = BannerCatalog.sanitizeUnlocked(unlockedBanners),
        selectedBannerImage = BannerCatalog.resolve(selectedBannerImage),
        unlockedAvatarFrames = unlockedAvatarFrames ?? [],
        selectedAvatarFrame = selectedAvatarFrame ?? '';

  factory CustomizationSettings.fromPrefs(SharedPreferences prefs) {
    return CustomizationSettings(
      unlockedAvatars: prefs.getStringList('unlockedAvatars'),
      selectedAvatar:
      prefs.getString('selectedAvatar'),
      unlockedBanners: prefs.getStringList('unlockedBanners'),
      selectedBannerImage:
      prefs.getString('selectedBannerImage'),
      unlockedAvatarFrames:
      prefs.getStringList('unlockedAvatarFrames') ?? [],
      selectedAvatarFrame: prefs.getString('selectedAvatarFrame') ?? '',
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setStringList('unlockedAvatars', unlockedAvatars);
    await prefs.setString('selectedAvatar', selectedAvatar);
    await prefs.setStringList('unlockedBanners', unlockedBanners);
    await prefs.setString('selectedBannerImage', selectedBannerImage);
    await prefs.setStringList('unlockedAvatarFrames', unlockedAvatarFrames);
    await prefs.setString('selectedAvatarFrame', selectedAvatarFrame);
  }

  Map<String, dynamic> toMap() => {
    "unlockedAvatars": unlockedAvatars,
    "selectedAvatar": selectedAvatar,
    "unlockedBanners": unlockedBanners,
    "selectedBannerImage": selectedBannerImage,
    "unlockedAvatarFrames": unlockedAvatarFrames,
    "selectedAvatarFrame": selectedAvatarFrame,
  };

  void loadFromMap(Map<String, dynamic> data) {
    unlockedAvatars = AvatarCatalog.sanitizeUnlocked(
        List<String>.from(data["unlockedAvatars"] ?? unlockedAvatars));
    selectedAvatar = AvatarCatalog.resolve(data["selectedAvatar"] ?? selectedAvatar);
    unlockedBanners = BannerCatalog.sanitizeUnlocked(
        List<String>.from(data["unlockedBanners"] ?? unlockedBanners));
    selectedBannerImage = BannerCatalog.resolve(data["selectedBannerImage"] ?? selectedBannerImage);
    unlockedAvatarFrames = List<String>.from(data["unlockedAvatarFrames"] ?? unlockedAvatarFrames);
    selectedAvatarFrame = data["selectedAvatarFrame"] ?? selectedAvatarFrame;
  }

  // Utility methods for unlocking/selecting

  bool unlockAvatar(String avatar) {
    if (!unlockedAvatars.contains(avatar)) {
      unlockedAvatars.add(avatar);
      return true;
    }
    return false;
  }

  bool selectAvatar(String avatar) {
    if (unlockedAvatars.contains(avatar)) {
      selectedAvatar = avatar;
      return true;
    }
    return false;
  }

  bool unlockBanner(String banner) {
    if (!unlockedBanners.contains(banner)) {
      unlockedBanners.add(banner);
      return true;
    }
    return false;
  }

  bool selectBanner(String banner) {
    if (unlockedBanners.contains(banner)) {
      selectedBannerImage = banner;
      return true;
    }
    return false;
  }

  bool unlockAvatarFrame(String frame) {
    if (!unlockedAvatarFrames.contains(frame)) {
      unlockedAvatarFrames.add(frame);
      return true;
    }
    return false;
  }

  bool selectAvatarFrame(String frame) {
    if (unlockedAvatarFrames.contains(frame)) {
      selectedAvatarFrame = frame;
      return true;
    }
    return false;
  }
}
