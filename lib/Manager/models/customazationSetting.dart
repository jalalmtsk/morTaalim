import 'package:shared_preferences/shared_preferences.dart';

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
  })  : unlockedAvatars = unlockedAvatars ??
      [
        "🐱",
        "🐻",
        'assets/images/AvatarImage/OnlyAvatar/Avatar1.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar2.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar3.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar4.png',
      ],
        selectedAvatar = selectedAvatar ??
            'assets/images/AvatarImage/OnlyAvatar/Avatar1.png',
        unlockedBanners = unlockedBanners ??
            [
              'assets/images/Banners/CuteBr/Banner1.png',
              'assets/images/Banners/CuteBr/Banner2.png',
              'assets/images/Banners/CuteBr/Banner3.png',
            ],
        selectedBannerImage = selectedBannerImage ??
            'assets/images/Banners/CuteBr/Banner3.png',
        unlockedAvatarFrames = unlockedAvatarFrames ?? [],
        selectedAvatarFrame = selectedAvatarFrame ?? '';

  factory CustomizationSettings.fromPrefs(SharedPreferences prefs) {
    return CustomizationSettings(
      unlockedAvatars: prefs.getStringList('unlockedAvatars') ??
          ["🐱", "🐻",
        'assets/images/AvatarImage/OnlyAvatar/Avatar1.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar2.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar3.png',
        'assets/images/AvatarImage/OnlyAvatar/Avatar4.png',],
      selectedAvatar:
      prefs.getString('selectedAvatar') ?? 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png',
      unlockedBanners: prefs.getStringList('unlockedBanners') ??
          [
            'assets/images/Banners/CuteBr/Banner1.png',
            'assets/images/Banners/CuteBr/Banner2.png',
            'assets/images/Banners/CuteBr/Banner3.png',
          ],
      selectedBannerImage:
      prefs.getString('selectedBannerImage') ?? 'assets/images/Banners/CuteBr/Banner3.png',
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
    unlockedAvatars = List<String>.from(data["unlockedAvatars"] ?? unlockedAvatars);
    selectedAvatar = data["selectedAvatar"] ?? selectedAvatar;
    unlockedBanners = List<String>.from(data["unlockedBanners"] ?? unlockedBanners);
    selectedBannerImage = data["selectedBannerImage"] ?? selectedBannerImage;
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
