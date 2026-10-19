import 'dart:math';
import 'dart:ui';

/// Data for Alpha Draw: the languages, their letters and the stroke paths
/// used to show the stroke order.
///
/// Stroke paths use a 100 × 100 letter box:
///   y = 10 top line, y = 45 middle line, y = 80 base line, y = 100 descender.
/// Commands: `M x y` move, `L x y` line,
/// `A cx cy rx ry startDeg sweepDeg` elliptical arc (0° = right, positive = clockwise).

const String adDir = 'assets/images/UI/KidScene/';

class AdLetter {
  final String char;
  final String name; // shown under the board
  final String? word; // example word in the target language
  final String? emoji; // picture for the example word
  final String? speak; // what text-to-speech should say for the letter
  const AdLetter(this.char, this.name, [this.word, this.emoji, this.speak]);
}

class AdLanguage {
  final String code; // matches ExperienceManager.unlockLanguage codes
  final String native;
  final Map<String, String> names; // in the app's UI language
  final String tile;
  final double tileAspect; // height / width
  final String tts;
  final int cost; // 0 = free
  final bool hasCase;
  final bool rtl;
  final String connector; // "A comme avion"
  final List<AdLetter> letters;
  const AdLanguage({
    required this.code,
    required this.native,
    required this.names,
    required this.tile,
    required this.tileAspect,
    required this.tts,
    required this.letters,
    this.cost = 0,
    this.hasCase = false,
    this.rtl = false,
    this.connector = '—',
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Languages
// ─────────────────────────────────────────────────────────────────────────

const _fr = [
  AdLetter('A', 'A', 'avion', '✈️'), AdLetter('B', 'B', 'ballon', '🎈'), AdLetter('C', 'C', 'chat', '🐱'),
  AdLetter('D', 'D', 'dauphin', '🐬'), AdLetter('E', 'E', 'éléphant', '🐘'), AdLetter('F', 'F', 'fleur', '🌸'),
  AdLetter('G', 'G', 'girafe', '🦒'), AdLetter('H', 'H', 'hibou', '🦉'), AdLetter('I', 'I', 'île', '🏝️'),
  AdLetter('J', 'J', 'jus', '🧃'), AdLetter('K', 'K', 'koala', '🐨'), AdLetter('L', 'L', 'lion', '🦁'),
  AdLetter('M', 'M', 'maison', '🏠'), AdLetter('N', 'N', 'nuage', '☁️'), AdLetter('O', 'O', 'orange', '🍊'),
  AdLetter('P', 'P', 'poisson', '🐟'), AdLetter('Q', 'Q', 'quille', '🎳'), AdLetter('R', 'R', 'robot', '🤖'),
  AdLetter('S', 'S', 'soleil', '☀️'), AdLetter('T', 'T', 'tortue', '🐢'), AdLetter('U', 'U', 'usine', '🏭'),
  AdLetter('V', 'V', 'vélo', '🚲'), AdLetter('W', 'W', 'wagon', '🚃'), AdLetter('X', 'X', 'xylophone', '🎶'),
  AdLetter('Y', 'Y', 'yoyo', '🪀'), AdLetter('Z', 'Z', 'zèbre', '🦓'),
];

const _en = [
  AdLetter('A', 'A', 'Airplane', '✈️'), AdLetter('B', 'B', 'Ball', '⚽'), AdLetter('C', 'C', 'Cat', '🐱'),
  AdLetter('D', 'D', 'Dog', '🐶'), AdLetter('E', 'E', 'Egg', '🥚'), AdLetter('F', 'F', 'Fish', '🐟'),
  AdLetter('G', 'G', 'Grapes', '🍇'), AdLetter('H', 'H', 'Hat', '🎩'), AdLetter('I', 'I', 'Ice cream', '🍦'),
  AdLetter('J', 'J', 'Juice', '🧃'), AdLetter('K', 'K', 'Kite', '🪁'), AdLetter('L', 'L', 'Lion', '🦁'),
  AdLetter('M', 'M', 'Moon', '🌙'), AdLetter('N', 'N', 'Nest', '🪺'), AdLetter('O', 'O', 'Owl', '🦉'),
  AdLetter('P', 'P', 'Pig', '🐷'), AdLetter('Q', 'Q', 'Queen', '👑'), AdLetter('R', 'R', 'Rabbit', '🐰'),
  AdLetter('S', 'S', 'Sun', '☀️'), AdLetter('T', 'T', 'Tiger', '🐯'), AdLetter('U', 'U', 'Umbrella', '☂️'),
  AdLetter('V', 'V', 'Van', '🚐'), AdLetter('W', 'W', 'Whale', '🐋'), AdLetter('X', 'X', 'Xylophone', '🎶'),
  AdLetter('Y', 'Y', 'Yo-yo', '🪀'), AdLetter('Z', 'Z', 'Zebra', '🦓'),
];

const _ar = [
  AdLetter('ا', 'Alif', 'أسد', '🦁', 'ألف'), AdLetter('ب', 'Ba', 'بطة', '🦆', 'باء'),
  AdLetter('ت', 'Ta', 'تفاحة', '🍎', 'تاء'), AdLetter('ث', 'Tha', 'ثعلب', '🦊', 'ثاء'),
  AdLetter('ج', 'Jim', 'جمل', '🐫', 'جيم'), AdLetter('ح', 'Ha', 'حصان', '🐴', 'حاء'),
  AdLetter('خ', 'Kha', 'خروف', '🐑', 'خاء'), AdLetter('د', 'Dal', 'دب', '🐻', 'دال'),
  AdLetter('ذ', 'Dhal', 'ذرة', '🌽', 'ذال'), AdLetter('ر', 'Ra', 'ريشة', '🪶', 'راء'),
  AdLetter('ز', 'Zay', 'زرافة', '🦒', 'زاي'), AdLetter('س', 'Sin', 'سمكة', '🐟', 'سين'),
  AdLetter('ش', 'Shin', 'شمس', '☀️', 'شين'), AdLetter('ص', 'Sad', 'صقر', '🦅', 'صاد'),
  AdLetter('ض', 'Dad', 'ضفدع', '🐸', 'ضاد'), AdLetter('ط', 'Ṭa', 'طائرة', '✈️', 'طاء'),
  AdLetter('ظ', 'Ẓa', 'ظرف', '✉️', 'ظاء'), AdLetter('ع', 'Ayn', 'عنب', '🍇', 'عين'),
  AdLetter('غ', 'Ghayn', 'غيمة', '☁️', 'غين'), AdLetter('ف', 'Fa', 'فيل', '🐘', 'فاء'),
  AdLetter('ق', 'Qaf', 'قطة', '🐱', 'قاف'), AdLetter('ك', 'Kaf', 'كتاب', '📖', 'كاف'),
  AdLetter('ل', 'Lam', 'ليمون', '🍋', 'لام'), AdLetter('م', 'Mim', 'موز', '🍌', 'ميم'),
  AdLetter('ن', 'Nun', 'نحلة', '🐝', 'نون'), AdLetter('ه', 'Ha', 'هدية', '🎁', 'هاء'),
  AdLetter('و', 'Waw', 'وردة', '🌹', 'واو'), AdLetter('ي', 'Ya', 'يد', '✋', 'ياء'),
];

// IRCAM Neo-Tifinagh alphabet.
const _zgh = [
  AdLetter('ⴰ', 'ya'), AdLetter('ⴱ', 'yab'), AdLetter('ⴳ', 'yag'), AdLetter('ⴷ', 'yad'), AdLetter('ⴹ', 'yaḍ'),
  AdLetter('ⴻ', 'yey'), AdLetter('ⴼ', 'yaf'), AdLetter('ⴽ', 'yak'), AdLetter('ⵀ', 'yah'), AdLetter('ⵃ', 'yaḥ'),
  AdLetter('ⵄ', 'yaɛ'), AdLetter('ⵅ', 'yax'), AdLetter('ⵇ', 'yaq'), AdLetter('ⵉ', 'yi'), AdLetter('ⵊ', 'yaj'),
  AdLetter('ⵍ', 'yal'), AdLetter('ⵎ', 'yam'), AdLetter('ⵏ', 'yan'), AdLetter('ⵓ', 'yu'), AdLetter('ⵔ', 'yar'),
  AdLetter('ⵕ', 'yaṛ'), AdLetter('ⵖ', 'yaɣ'), AdLetter('ⵙ', 'yas'), AdLetter('ⵚ', 'yaṣ'), AdLetter('ⵛ', 'yac'),
  AdLetter('ⵜ', 'yat'), AdLetter('ⵟ', 'yaṭ'), AdLetter('ⵡ', 'yaw'), AdLetter('ⵢ', 'yay'), AdLetter('ⵣ', 'yaz'),
  AdLetter('ⵥ', 'yaẓ'),
];

const _ru = [
  AdLetter('А', 'А', 'арбуз', '🍉'), AdLetter('Б', 'Бэ', 'банан', '🍌'), AdLetter('В', 'Вэ', 'волк', '🐺'),
  AdLetter('Г', 'Гэ', 'гриб', '🍄'), AdLetter('Д', 'Дэ', 'дом', '🏠'), AdLetter('Е', 'Е', 'ель', '🌲'),
  AdLetter('Ё', 'Ё', 'ёж', '🦔'), AdLetter('Ж', 'Жэ', 'жираф', '🦒'), AdLetter('З', 'Зэ', 'зонт', '☂️'),
  AdLetter('И', 'И', 'индюк', '🦃'), AdLetter('Й', 'Й', 'йогурт', '🥛'), AdLetter('К', 'Ка', 'кот', '🐱'),
  AdLetter('Л', 'Эль', 'лиса', '🦊'), AdLetter('М', 'Эм', 'мяч', '⚽'), AdLetter('Н', 'Эн', 'нос', '👃'),
  AdLetter('О', 'О', 'облако', '☁️'), AdLetter('П', 'Пэ', 'пингвин', '🐧'), AdLetter('Р', 'Эр', 'рыба', '🐟'),
  AdLetter('С', 'Эс', 'солнце', '☀️'), AdLetter('Т', 'Тэ', 'тигр', '🐯'), AdLetter('У', 'У', 'утка', '🦆'),
  AdLetter('Ф', 'Эф', 'флаг', '🚩'), AdLetter('Х', 'Ха', 'хлеб', '🍞'), AdLetter('Ц', 'Цэ', 'цветок', '🌸'),
  AdLetter('Ч', 'Чэ', 'часы', '⌚'), AdLetter('Ш', 'Ша', 'шар', '🎈'), AdLetter('Щ', 'Ща', 'щенок', '🐶'),
  AdLetter('Ъ', 'Твёрдый знак', 'объятие', '🤗'), AdLetter('Ы', 'Ы', 'сыр', '🧀'),
  AdLetter('Ь', 'Мягкий знак', 'соль', '🧂'), AdLetter('Э', 'Э', 'эскимо', '🍦'),
  AdLetter('Ю', 'Ю', 'юла', '🪀'), AdLetter('Я', 'Я', 'яблоко', '🍎'),
];

const _el = [
  AdLetter('Α', 'Alfa', 'αστέρι', '⭐', 'άλφα'), AdLetter('Β', 'Vita', 'βάρκα', '⛵', 'βήτα'),
  AdLetter('Γ', 'Gamma', 'γάτα', '🐱', 'γάμμα'), AdLetter('Δ', 'Delta', 'δέντρο', '🌳', 'δέλτα'),
  AdLetter('Ε', 'Epsilon', 'ελέφαντας', '🐘', 'έψιλον'), AdLetter('Ζ', 'Zita', 'ζέβρα', '🦓', 'ζήτα'),
  AdLetter('Η', 'Ita', 'ήλιος', '☀️', 'ήτα'), AdLetter('Θ', 'Thita', 'θάλασσα', '🌊', 'θήτα'),
  AdLetter('Ι', 'Giota', 'ιγκουάνα', '🦎', 'γιώτα'), AdLetter('Κ', 'Kappa', 'καρδιά', '❤️', 'κάπα'),
  AdLetter('Λ', 'Lamda', 'λεμόνι', '🍋', 'λάμδα'), AdLetter('Μ', 'Mi', 'μήλο', '🍎', 'μι'),
  AdLetter('Ν', 'Ni', 'νερό', '💧', 'νι'), AdLetter('Ξ', 'Xi', 'ξύλο', '🪵', 'ξι'),
  AdLetter('Ο', 'Omikron', 'ομπρέλα', '☂️', 'όμικρον'), AdLetter('Π', 'Pi', 'πάπια', '🦆', 'πι'),
  AdLetter('Ρ', 'Ro', 'ρολόι', '⏰', 'ρο'), AdLetter('Σ', 'Sigma', 'σπίτι', '🏠', 'σίγμα'),
  AdLetter('Τ', 'Taf', 'τίγρης', '🐯', 'ταυ'), AdLetter('Υ', 'Ypsilon', 'ύπνος', '😴', 'ύψιλον'),
  AdLetter('Φ', 'Fi', 'φεγγάρι', '🌙', 'φι'), AdLetter('Χ', 'Chi', 'χιόνι', '❄️', 'χι'),
  AdLetter('Ψ', 'Psi', 'ψάρι', '🐟', 'ψι'), AdLetter('Ω', 'Omega', 'ωκεανός', '🌊', 'ωμέγα'),
];

const _ja = [
  AdLetter('あ', 'a', 'あめ', '🍬'), AdLetter('い', 'i', 'いぬ', '🐶'), AdLetter('う', 'u', 'うみ', '🌊'),
  AdLetter('え', 'e', 'えんぴつ', '✏️'), AdLetter('お', 'o', 'おちゃ', '🍵'),
  AdLetter('か', 'ka', 'かさ', '☂️'), AdLetter('き', 'ki', 'きつね', '🦊'), AdLetter('く', 'ku', 'くるま', '🚗'),
  AdLetter('け', 'ke', 'けーき', '🍰'), AdLetter('こ', 'ko', 'こあら', '🐨'),
  AdLetter('さ', 'sa', 'さかな', '🐟'), AdLetter('し', 'shi', 'しか', '🦌'), AdLetter('す', 'su', 'すいか', '🍉'),
  AdLetter('せ', 'se', 'せみ'), AdLetter('そ', 'so', 'そら', '☁️'),
  AdLetter('た', 'ta', 'たまご', '🥚'), AdLetter('ち', 'chi', 'ちず', '🗺️'), AdLetter('つ', 'tsu', 'つき', '🌙'),
  AdLetter('て', 'te', 'てがみ', '✉️'), AdLetter('と', 'to', 'とけい', '⏰'),
  AdLetter('な', 'na', 'なす', '🍆'), AdLetter('に', 'ni', 'にんじん', '🥕'), AdLetter('ぬ', 'nu', 'ぬいぐるみ', '🧸'),
  AdLetter('ね', 'ne', 'ねこ', '🐱'), AdLetter('の', 'no', 'のり'),
  AdLetter('は', 'ha', 'はな', '🌸'), AdLetter('ひ', 'hi', 'ひこうき', '✈️'), AdLetter('ふ', 'fu', 'ふね', '🚢'),
  AdLetter('へ', 'he', 'へび', '🐍'), AdLetter('ほ', 'ho', 'ほし', '⭐'),
  AdLetter('ま', 'ma', 'まど', '🪟'), AdLetter('み', 'mi', 'みかん', '🍊'), AdLetter('む', 'mu', 'むし', '🐛'),
  AdLetter('め', 'me', 'めがね', '👓'), AdLetter('も', 'mo', 'もも', '🍑'),
  AdLetter('や', 'ya', 'やま', '⛰️'), AdLetter('ゆ', 'yu', 'ゆき', '❄️'), AdLetter('よ', 'yo', 'よる', '🌃'),
  AdLetter('ら', 'ra', 'らいおん', '🦁'), AdLetter('り', 'ri', 'りんご', '🍎'), AdLetter('る', 'ru', 'るす'),
  AdLetter('れ', 're', 'れもん', '🍋'), AdLetter('ろ', 'ro', 'ろうそく', '🕯️'),
  AdLetter('わ', 'wa', 'わに', '🐊'), AdLetter('を', 'wo'), AdLetter('ん', 'n'),
];

const _ko = [
  AdLetter('ㄱ', 'giyeok', '가방', '🎒', '기역'), AdLetter('ㄴ', 'nieun', '나무', '🌳', '니은'),
  AdLetter('ㄷ', 'digeut', '달', '🌙', '디귿'), AdLetter('ㄹ', 'rieul', '라면', '🍜', '리을'),
  AdLetter('ㅁ', 'mieum', '물', '💧', '미음'), AdLetter('ㅂ', 'bieup', '바다', '🌊', '비읍'),
  AdLetter('ㅅ', 'siot', '사과', '🍎', '시옷'), AdLetter('ㅇ', 'ieung', '아이', '🧒', '이응'),
  AdLetter('ㅈ', 'jieut', '자전거', '🚲', '지읒'), AdLetter('ㅊ', 'chieut', '치마', '👗', '치읓'),
  AdLetter('ㅋ', 'kieuk', '코', '👃', '키읔'), AdLetter('ㅌ', 'tieut', '토끼', '🐰', '티읕'),
  AdLetter('ㅍ', 'pieup', '피자', '🍕', '피읖'), AdLetter('ㅎ', 'hieut', '하늘', '☁️', '히읗'),
  AdLetter('ㅏ', 'a', '아기', '👶', '아'), AdLetter('ㅑ', 'ya', '야구', '⚾', '야'),
  AdLetter('ㅓ', 'eo', '어머니', '👩', '어'), AdLetter('ㅕ', 'yeo', '여우', '🦊', '여'),
  AdLetter('ㅗ', 'o', '오리', '🦆', '오'), AdLetter('ㅛ', 'yo', '요리', '🍳', '요'),
  AdLetter('ㅜ', 'u', '우유', '🥛', '우'), AdLetter('ㅠ', 'yu', '유리', '🪟', '유'),
  AdLetter('ㅡ', 'eu', null, null, '으'), AdLetter('ㅣ', 'i', '이', '🦷', '이'),
];

const _zh = [
  AdLetter('一', 'yī', '一', '1️⃣'), AdLetter('二', 'èr', '二', '2️⃣'), AdLetter('三', 'sān', '三', '3️⃣'),
  AdLetter('十', 'shí', '十', '🔟'), AdLetter('人', 'rén', '人', '🧍'), AdLetter('口', 'kǒu', '口', '👄'),
  AdLetter('大', 'dà', '大', '🐘'), AdLetter('小', 'xiǎo', '小', '🐜'), AdLetter('日', 'rì', '日', '☀️'),
  AdLetter('月', 'yuè', '月', '🌙'), AdLetter('山', 'shān', '山', '⛰️'), AdLetter('水', 'shuǐ', '水', '💧'),
  AdLetter('火', 'huǒ', '火', '🔥'), AdLetter('木', 'mù', '木', '🌳'),
];

const List<AdLanguage> adLanguages = [
  AdLanguage(
      code: 'arabic', native: 'العربية', names: {'fr': 'Arabe', 'en': 'Arabic', 'ar': 'العربية', 'de': 'Arabisch'},
      tile: '${adDir}ad_tile_ar.webp', tileAspect: 0.9598, tts: 'ar-SA', rtl: true, connector: 'مثل', letters: _ar),
  AdLanguage(
      code: 'french', native: 'Français', names: {'fr': 'Français', 'en': 'French', 'ar': 'الفرنسية', 'de': 'Französisch'},
      tile: '${adDir}ad_tile_fr.webp', tileAspect: 0.9188, tts: 'fr-FR', hasCase: true, connector: 'comme', letters: _fr),
  AdLanguage(
      code: 'amazigh', native: 'ⵜⴰⵎⴰⵣⵉⵖⵜ', names: {'fr': 'Amazigh', 'en': 'Amazigh', 'ar': 'الأمازيغية', 'de': 'Amazigh'},
      tile: '${adDir}ad_tile_zgh.webp', tileAspect: 0.9476, tts: 'fr-FR', letters: _zgh),
  AdLanguage(
      code: 'russian', native: 'Русский', names: {'fr': 'Russe', 'en': 'Russian', 'ar': 'الروسية', 'de': 'Russisch'},
      tile: '${adDir}ad_tile_ru.webp', tileAspect: 0.9437, tts: 'ru-RU', cost: 20, hasCase: true, letters: _ru),
  AdLanguage(
      code: 'japanese', native: '日本語', names: {'fr': 'Japonais', 'en': 'Japanese', 'ar': 'اليابانية', 'de': 'Japanisch'},
      tile: '${adDir}ad_tile_ja.webp', tileAspect: 0.952, tts: 'ja-JP', cost: 25, letters: _ja),
  AdLanguage(
      code: 'english', native: 'English', names: {'fr': 'Anglais', 'en': 'English', 'ar': 'الإنجليزية', 'de': 'Englisch'},
      tile: '${adDir}ad_tile_en.webp', tileAspect: 0.9478, tts: 'en-US', hasCase: true, connector: 'is for', letters: _en),
  AdLanguage(
      code: 'greek', native: 'Ελληνικά', names: {'fr': 'Grec', 'en': 'Greek', 'ar': 'اليونانية', 'de': 'Griechisch'},
      tile: '${adDir}ad_tile_greek.webp', tileAspect: 0.7937, tts: 'el-GR', cost: 25, hasCase: true, letters: _el),
  AdLanguage(
      code: 'chinese', native: '中文', names: {'fr': 'Chinois', 'en': 'Chinese', 'ar': 'الصينية', 'de': 'Chinesisch'},
      tile: '${adDir}ad_tile_chinese.webp', tileAspect: 0.7817, tts: 'zh-CN', cost: 35, letters: _zh),
  AdLanguage(
      code: 'korean', native: '한국어', names: {'fr': 'Coréen', 'en': 'Korean', 'ar': 'الكورية', 'de': 'Koreanisch'},
      tile: '${adDir}ad_tile_korean.webp', tileAspect: 0.7897, tts: 'ko-KR', cost: 30, letters: _ko),
];

AdLanguage adLanguage(String code) => adLanguages.firstWhere((l) => l.code == code, orElse: () => adLanguages[1]);

// ─────────────────────────────────────────────────────────────────────────
// Stroke paths
// ─────────────────────────────────────────────────────────────────────────

const Map<String, List<String>> _strokes = {
  // Latin uppercase
  'A': ['M50 10 L22 80', 'M50 10 L78 80', 'M33 52 L67 52'],
  'B': ['M28 10 L28 80', 'M28 10 L50 10 A50 27.5 17.5 17.5 -90 180 L28 45', 'M28 45 L53 45 A53 62.5 17.5 17.5 -90 180 L28 80'],
  'C': ['A55 45 30 35 -40 -280'],
  'D': ['M28 10 L28 80', 'M28 10 L43 10 A43 45 30 35 -90 180 L28 80'],
  'E': ['M30 10 L30 80', 'M30 10 L72 10', 'M30 45 L66 45', 'M30 80 L72 80'],
  'F': ['M30 10 L30 80', 'M30 10 L72 10', 'M30 45 L64 45'],
  'G': ['A54 45 30 35 -40 -310', 'M62 49 L84 49'],
  'H': ['M28 10 L28 80', 'M72 10 L72 80', 'M28 45 L72 45'],
  'I': ['M50 10 L50 80'],
  'J': ['M65 10 L65 60 A47 60 18 20 0 180'],
  'K': ['M30 10 L30 80', 'M72 10 L30 52', 'M44 39 L74 80'],
  'L': ['M32 10 L32 80 L72 80'],
  'M': ['M22 10 L22 80', 'M22 10 L50 58 L78 10 L78 80'],
  'N': ['M26 10 L26 80', 'M26 10 L74 80', 'M74 80 L74 10'],
  'O': ['A50 45 30 35 -90 -360'],
  'P': ['M30 10 L30 80', 'M30 10 L52 10 A52 28 18 18 -90 180 L30 46'],
  'Q': ['A50 45 30 35 -90 -360', 'M58 62 L80 84'],
  'R': ['M30 10 L30 80', 'M30 10 L52 10 A52 28 18 18 -90 180 L30 46', 'M48 46 L74 80'],
  'S': ['A50 27.5 21 17.5 -30 -240 A50 62.5 23 17.5 -90 240'],
  'T': ['M24 10 L76 10', 'M50 10 L50 80'],
  'U': ['M28 10 L28 58 A50 58 22 22 180 -180 L72 10'],
  'V': ['M22 10 L50 80 L78 10'],
  'W': ['M14 10 L32 80 L50 30 L68 80 L86 10'],
  'X': ['M26 10 L74 80', 'M74 10 L26 80'],
  'Y': ['M26 10 L50 45', 'M74 10 L50 45 L50 80'],
  'Z': ['M26 10 L74 10 L26 80 L74 80'],
  // Latin lowercase
  'a': ['A50 62.5 18 17.5 -20 -340', 'M68 45 L68 80'],
  'b': ['M32 10 L32 80', 'A50 62.5 18 17.5 180 360'],
  'c': ['A52 62.5 19 17.5 -40 -280'],
  'd': ['A50 62.5 18 17.5 -20 -340', 'M68 10 L68 80'],
  'e': ['M32 62.5 L70 62.5 A51 62.5 19 17.5 0 -320'],
  'f': ['A62 24 12 12 -30 -150 L50 80', 'M36 45 L66 45'],
  'g': ['A50 62.5 18 17.5 -20 -340', 'M68 45 L68 88 A52 88 16 12 0 160'],
  'h': ['M32 10 L32 80', 'M32 60 A50 60 18 15 180 180 L68 80'],
  'i': ['M50 45 L50 80', 'M50 29 L50 30'],
  'j': ['M56 45 L56 88 A44 88 12 12 0 160', 'M56 29 L56 30'],
  'k': ['M32 10 L32 80', 'M66 45 L32 66', 'M44 59 L68 80'],
  'l': ['M50 10 L50 80'],
  'm': ['M26 45 L26 80', 'M26 58 A38 58 12 13 180 180 L50 80', 'M50 58 A62 58 12 13 180 180 L74 80'],
  'n': ['M32 45 L32 80', 'M32 60 A50 60 18 15 180 180 L68 80'],
  'o': ['A50 62.5 19 17.5 -90 -360'],
  'p': ['M32 45 L32 100', 'A50 62.5 18 17.5 180 360'],
  'q': ['A50 62.5 18 17.5 -20 -340', 'M68 45 L68 100'],
  'r': ['M36 45 L36 80', 'M36 62 A52 62 16 15 180 140'],
  's': ['A50 53.75 16 8.75 -30 -240 A50 71.25 18 8.75 -90 240'],
  't': ['M48 18 L48 72 A58 72 10 8 180 -150', 'M36 45 L64 45'],
  'u': ['M32 45 L32 64 A50 64 18 16 180 -180 L68 45', 'M68 45 L68 80'],
  'v': ['M28 45 L50 80 L72 45'],
  'w': ['M18 45 L32 80 L50 55 L68 80 L82 45'],
  'x': ['M30 45 L70 80', 'M70 45 L30 80'],
  'y': ['M28 45 L50 80', 'M72 45 L50 80 L38 100'],
  'z': ['M30 45 L70 45 L30 80 L70 80'],
  // Cyrillic / Greek shapes that Latin does not have
  'Г': ['M30 10 L30 80', 'M30 10 L72 10'],
  'П': ['M28 10 L28 80', 'M28 10 L72 10 L72 80'],
  'И': ['M28 10 L28 80', 'M28 80 L72 10', 'M72 10 L72 80'],
  'Ш': ['M20 10 L20 80', 'M50 10 L50 80', 'M80 10 L80 80', 'M20 80 L80 80'],
  'Я': ['M70 10 L70 80', 'M70 10 L48 10 A48 28 18 18 -90 -180 L70 46', 'M52 46 L26 80'],
  'Λ': ['M50 10 L22 80', 'M50 10 L78 80'],
  'Δ': ['M50 10 L20 80 L80 80 L50 10'],
  // Arabic
  'ا': ['M50 12 L50 80'],
  // Korean
  'ㄱ': ['M28 20 L70 20 L70 82'],
  'ㄴ': ['M30 18 L30 80 L74 80'],
  'ㄷ': ['M30 20 L70 20', 'M30 20 L30 80 L72 80'],
  'ㄹ': ['M28 18 L70 18 L70 46 L30 46 L30 80 L72 80'],
  'ㅁ': ['M30 20 L30 80', 'M30 20 L70 20 L70 80', 'M30 80 L70 80'],
  'ㅂ': ['M30 15 L30 82', 'M70 15 L70 82', 'M30 48 L70 48', 'M30 82 L70 82'],
  'ㅅ': ['M50 15 L22 80', 'M48 45 L78 80'],
  'ㅇ': ['A50 48 28 30 -90 -360'],
  'ㅈ': ['M28 22 L72 22 L30 82', 'M52 50 L76 82'],
  'ㅋ': ['M28 20 L70 20 L70 82', 'M30 50 L68 50'],
  'ㅌ': ['M30 20 L72 20', 'M30 50 L70 50', 'M30 20 L30 80 L72 80'],
  'ㅍ': ['M22 20 L78 20', 'M38 20 L38 78', 'M62 20 L62 78', 'M18 78 L82 78'],
  'ㅏ': ['M45 10 L45 85', 'M45 48 L68 48'],
  'ㅓ': ['M32 48 L55 48', 'M55 10 L55 85'],
  'ㅗ': ['M50 30 L50 60', 'M15 60 L85 60'],
  'ㅜ': ['M15 40 L85 40', 'M50 40 L50 75'],
  'ㅡ': ['M15 50 L85 50'],
  'ㅣ': ['M50 10 L50 85'],
  // Chinese
  '一': ['M15 50 L85 50'],
  '二': ['M28 30 L72 30', 'M15 72 L85 72'],
  '三': ['M26 22 L74 22', 'M32 48 L68 48', 'M15 78 L85 78'],
  '十': ['M15 48 L85 48', 'M50 12 L50 88'],
  '人': ['M50 12 L22 80', 'M50 40 L80 80'],
  '口': ['M28 22 L28 78', 'M28 22 L72 22 L72 78', 'M28 78 L72 78'],
  '大': ['M20 38 L80 38', 'M50 12 L50 38 L20 82', 'M50 40 L82 82'],
  '日': ['M30 12 L30 84', 'M30 12 L70 12 L70 84', 'M30 48 L70 48', 'M30 84 L70 84'],
  '山': ['M50 10 L50 78', 'M22 35 L22 78 L78 78', 'M78 35 L78 78'],
  '小': ['M50 10 L50 74 L42 68', 'M32 32 L18 64', 'M68 32 L82 64'],
  '木': ['M18 38 L82 38', 'M50 10 L50 88', 'M50 40 L20 74', 'M50 40 L80 74'],
};

/// Cyrillic and Greek letters drawn exactly like a Latin one.
const Map<String, String> _same = {
  'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T', 'Х': 'X',
  'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'х': 'x', 'у': 'y',
  'Α': 'A', 'Β': 'B', 'Ε': 'E', 'Ζ': 'Z', 'Η': 'H', 'Ι': 'I', 'Κ': 'K', 'Μ': 'M', 'Ν': 'N', 'Ο': 'O', 'Ρ': 'P',
  'Τ': 'T', 'Υ': 'Y', 'Χ': 'X', 'Γ': 'Г', 'Π': 'П', 'ο': 'o',
};

final Map<String, List<List<Offset>>> _cache = {};

/// The strokes of [char] as polylines in the 100 × 100 letter box,
/// or null when only the font shape is available.
List<List<Offset>>? adStrokes(String char) {
  final key = _same[char] ?? char;
  final src = _strokes[key];
  if (src == null) return null;
  return _cache.putIfAbsent(key, () => [for (final s in src) _parse(s)]);
}

/// Lowercase letters sit between the middle and base lines.
bool adIsSmall(String char) => char != char.toUpperCase() && char.toLowerCase() == char;

List<Offset> _parse(String s) {
  final t = s.split(RegExp(r'\s+'));
  final out = <Offset>[];
  var i = 0;
  double n() => double.parse(t[i++]);
  while (i < t.length) {
    final tok = t[i++];
    final c = tok[0];
    if (tok.length > 1) {
      i--;
      t[i] = tok.substring(1);
    }
    switch (c) {
      case 'M':
      case 'L':
        out.add(Offset(n(), n()));
      case 'A':
        final cx = n(), cy = n(), rx = n(), ry = n(), a0 = n(), sw = n();
        final steps = max(6, (sw.abs() / 8).round());
        for (int k = 0; k <= steps; k++) {
          final a = (a0 + sw * k / steps) * pi / 180;
          out.add(Offset(cx + rx * cos(a), cy + ry * sin(a)));
        }
    }
  }
  return out;
}
