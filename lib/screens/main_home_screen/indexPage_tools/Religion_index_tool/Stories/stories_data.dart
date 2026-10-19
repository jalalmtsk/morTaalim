import 'package:flutter/widgets.dart';

/// Religion → Stories. Each story has pages (illustration + paragraphs),
/// then a "what I remember" ending with values and a small challenge.
/// Text per language: fr (source), en, ar, de. Tamazight uses French.
class StoryPage {
  final String image;
  final Map<String, List<String>> text; // lang → paragraphs
  const StoryPage(this.image, this.text);
}

class StoryValue {
  final String image;
  final Map<String, String> label;
  const StoryValue(this.image, this.label);
}

class Story {
  final String id;
  final Map<String, String> title, subtitle, lesson, challenge;
  final String thumb;
  final List<StoryPage> pages;
  final List<StoryValue> values;
  final String endImage;
  const Story({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumb,
    required this.pages,
    required this.values,
    required this.lesson,
    required this.challenge,
    required this.endImage,
  });
  bool get available => pages.isNotEmpty;
}

String storyLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return (l == 'zgh' || !const ['fr', 'en', 'ar', 'de'].contains(l)) ? 'fr' : l;
}

String pick(Map<String, String> m, BuildContext c) => m[storyLang(c)] ?? m['fr'] ?? '';
List<String> pickList(Map<String, List<String>> m, BuildContext c) => m[storyLang(c)] ?? m['fr'] ?? const [];

const String _d = 'assets/images/UI/KidScene/';

final List<Story> allStories = [
  Story(
    id: 'jardin',
    title: {'fr': 'Le jardin du partage', 'en': 'The Sharing Garden', 'ar': 'حديقة المشاركة', 'de': 'Der Garten des Teilens'},
    subtitle: {
      'fr': 'Une histoire sur la générosité',
      'en': 'A story about generosity',
      'ar': 'قصة عن الكرم',
      'de': 'Eine Geschichte über Großzügigkeit',
    },
    thumb: '${_d}stories_thumb0.webp',
    endImage: '${_d}story_garden_end.webp',
    pages: [
      StoryPage('${_d}story_garden_end.webp', {
        'fr': [
          'Ce matin-là, le soleil brillait sur le grand jardin. Les pommiers étaient couverts de fruits rouges.',
          'Sami, sa sœur Lina et le petit Adam prirent un panier. « Bismillah, allons cueillir des pommes ! » dit Sami.',
        ],
        'en': [
          'That morning, the sun was shining on the big garden. The apple trees were full of red fruit.',
          'Sami, his sister Lina and little Adam took a basket. “Bismillah, let’s pick some apples!” said Sami.',
        ],
        'ar': [
          'في ذلك الصباح، كانت الشمس تشرق على الحديقة الكبيرة، وكانت أشجار التفاح مليئة بالثمار الحمراء.',
          'أخذ سامي وأخته لينا والصغير آدم سلة. قال سامي: «بسم الله، هيا نقطف التفاح!»',
        ],
        'de': [
          'An diesem Morgen schien die Sonne über dem großen Garten. Die Apfelbäume hingen voller roter Früchte.',
          'Sami, seine Schwester Lina und der kleine Adam nahmen einen Korb. „Bismillah, lasst uns Äpfel pflücken!“, sagte Sami.',
        ],
      }),
      StoryPage('${_d}story_garden_p2.webp', {
        'fr': [
          'Dans un joli jardin, Sami et Lina récoltaient des pommes. Leur panier était bien rempli !',
          'Près du portail, ils aperçurent Adam. « Viens avec nous ! » dit Lina en lui offrant une pomme.',
          'Sami sourit : partager rendait ce moment encore plus beau.',
        ],
        'en': [
          'In a pretty garden, Sami and Lina were picking apples. Their basket was nice and full!',
          'Near the gate, they saw Adam. “Come with us!” said Lina, offering him an apple.',
          'Sami smiled: sharing made this moment even more beautiful.',
        ],
        'ar': [
          'في حديقة جميلة، كان سامي ولينا يقطفان التفاح. امتلأت سلتهما!',
          'قرب البوابة رأيا آدم. قالت لينا وهي تقدم له تفاحة: «تعال معنا!»',
          'ابتسم سامي: المشاركة جعلت تلك اللحظة أجمل.',
        ],
        'de': [
          'In einem schönen Garten pflückten Sami und Lina Äpfel. Ihr Korb war gut gefüllt!',
          'Am Tor sahen sie Adam. „Komm mit uns!“, sagte Lina und reichte ihm einen Apfel.',
          'Sami lächelte: Teilen machte den Moment noch schöner.',
        ],
      }),
      StoryPage('${_d}story_garden_p3.webp', {
        'fr': [
          'Près du portail, une voisine regardait les pommes. Son panier était vide.',
          'Sami demanda doucement : « Veux-tu quelques pommes ? Nous en avons beaucoup ! »',
        ],
        'en': [
          'Near the gate, a neighbour was looking at the apples. Her basket was empty.',
          'Sami asked gently: “Would you like some apples? We have lots!”',
        ],
        'ar': [
          'قرب البوابة، كانت جارة تنظر إلى التفاح. كانت سلتها فارغة.',
          'سألها سامي بلطف: «هل تريدين بعض التفاح؟ لدينا الكثير!»',
        ],
        'de': [
          'Am Tor schaute eine Nachbarin auf die Äpfel. Ihr Korb war leer.',
          'Sami fragte freundlich: „Möchtest du ein paar Äpfel? Wir haben so viele!“',
        ],
      }),
      StoryPage('${_d}story_garden_p4.webp', {
        'fr': [
          'Lina choisit de belles pommes. Adam en ajouta une avec soin. « Merci, mes enfants ! » dit la voisine.',
          'En islam, la générosité et l’aide aux autres sont de belles valeurs.',
        ],
        'en': [
          'Lina chose some beautiful apples. Adam carefully added one more. “Thank you, children!” said the neighbour.',
          'In Islam, generosity and helping others are beautiful values.',
        ],
        'ar': [
          'اختارت لينا تفاحات جميلة، وأضاف آدم واحدة بعناية. قالت الجارة: «شكراً يا أبنائي!»',
          'في الإسلام، الكرم ومساعدة الآخرين قيم جميلة.',
        ],
        'de': [
          'Lina suchte schöne Äpfel aus. Adam legte vorsichtig noch einen dazu. „Danke, Kinder!“, sagte die Nachbarin.',
          'Im Islam sind Großzügigkeit und Hilfsbereitschaft schöne Werte.',
        ],
      }),
      StoryPage('${_d}story_garden_p5.webp', {
        'fr': [
          'Le panier était moins rempli, mais les enfants étaient heureux.',
          '« Il nous en reste pour le goûter ! » dit Sami.',
          'Lina sourit : « Et notre voisine pourra aussi se régaler. »',
        ],
        'en': [
          'The basket was less full, but the children were happy.',
          '“We still have some left for snack time!” said Sami.',
          'Lina smiled: “And our neighbour can enjoy them too.”',
        ],
        'ar': [
          'لم تعد السلة ممتلئة كما كانت، لكن الأطفال كانوا سعداء.',
          'قال سامي: «بقي لنا ما يكفي للُّمجة!»',
          'ابتسمت لينا: «وجارتنا أيضاً ستستمتع بها.»',
        ],
        'de': [
          'Der Korb war nicht mehr so voll, aber die Kinder waren glücklich.',
          '„Für den Nachmittag ist noch genug übrig!“, sagte Sami.',
          'Lina lächelte: „Und unsere Nachbarin kann sie auch genießen.“',
        ],
      }),
      StoryPage('${_d}story_garden_p6.webp', {
        'fr': [
          'Avant de rentrer, les enfants dirent : « Alhamdoulillah pour ces bons fruits ! »',
          'Sami avait compris : partager un bien, même petit, peut apporter beaucoup de joie.',
          'Depuis ce jour, ils pensèrent à leurs voisins à chaque récolte.',
        ],
        'en': [
          'Before going home, the children said: “Alhamdulillah for these good fruits!”',
          'Sami understood: sharing something, even something small, can bring a lot of joy.',
          'From that day on, they thought of their neighbours at every harvest.',
        ],
        'ar': [
          'قبل العودة إلى البيت، قال الأطفال: «الحمد لله على هذه الثمار الطيبة!»',
          'فهم سامي أن مشاركة شيء، ولو كان صغيراً، تجلب فرحاً كبيراً.',
          'ومنذ ذلك اليوم، صاروا يتذكرون جيرانهم في كل موسم قطاف.',
        ],
        'de': [
          'Bevor sie nach Hause gingen, sagten die Kinder: „Alhamdulillah für diese guten Früchte!“',
          'Sami hatte verstanden: Etwas zu teilen, auch wenn es klein ist, kann viel Freude bringen.',
          'Seit diesem Tag dachten sie bei jeder Ernte an ihre Nachbarn.',
        ],
      }),
    ],
    values: [
      StoryValue('${_d}story_value0.webp', {'fr': 'Partage', 'en': 'Sharing', 'ar': 'المشاركة', 'de': 'Teilen'}),
      StoryValue('${_d}story_value1.webp', {'fr': 'Entraide', 'en': 'Helping', 'ar': 'التعاون', 'de': 'Helfen'}),
      StoryValue('${_d}story_value2.webp', {'fr': 'Gratitude', 'en': 'Gratitude', 'ar': 'الشكر', 'de': 'Dankbarkeit'}),
    ],
    lesson: {
      'fr': 'Je peux partager et aider avec gentillesse.',
      'en': 'I can share and help with kindness.',
      'ar': 'أستطيع أن أشارك وأساعد بلطف.',
      'de': 'Ich kann freundlich teilen und helfen.',
    },
    challenge: {
      'fr': 'Aujourd’hui, je partage un fruit, un jouet ou un moment avec quelqu’un.',
      'en': 'Today, I share a fruit, a toy or a moment with someone.',
      'ar': 'اليوم، أشارك فاكهة أو لعبة أو لحظة مع أحد.',
      'de': 'Heute teile ich eine Frucht, ein Spielzeug oder einen Moment mit jemandem.',
    },
  ),
  // Coming soon: art is ready, text not written yet.
  Story(
    id: 'graine',
    title: {'fr': 'La petite graine', 'en': 'The Little Seed', 'ar': 'البذرة الصغيرة', 'de': 'Das kleine Samenkorn'},
    subtitle: const {},
    thumb: '${_d}stories_thumb1.webp',
    pages: const [],
    values: const [],
    lesson: const {},
    challenge: const {},
    endImage: '',
  ),
  Story(
    id: 'bonte',
    title: {'fr': 'Un geste de bonté', 'en': 'A Kind Gesture', 'ar': 'لفتة طيبة', 'de': 'Eine gute Tat'},
    subtitle: const {},
    thumb: '${_d}stories_thumb2.webp',
    pages: const [],
    values: const [],
    lesson: const {},
    challenge: const {},
    endImage: '',
  ),
  Story(
    id: 'promesse',
    title: {'fr': 'La promesse tenue', 'en': 'The Promise Kept', 'ar': 'الوعد المحفوظ', 'de': 'Das gehaltene Versprechen'},
    subtitle: const {},
    thumb: '${_d}stories_thumb3.webp',
    pages: const [],
    values: const [],
    lesson: const {},
    challenge: const {},
    endImage: '',
  ),
];

/// Small UI strings for the stories screens.
const Map<String, Map<String, String>> _ui = {
  'title': {'fr': 'Histoires', 'en': 'Stories', 'ar': 'قصص', 'de': 'Geschichten'},
  'heroTop': {'fr': 'Des histoires', 'en': 'Stories that', 'ar': 'قصص', 'de': 'Geschichten,'},
  'heroBottom': {'fr': 'qui inspirent', 'en': 'inspire', 'ar': 'مُلهِمة', 'de': 'die inspirieren'},
  'heroSub': {'fr': 'Écouter, découvrir et grandir', 'en': 'Listen, discover and grow', 'ar': 'استمع، اكتشف، وانمُ', 'de': 'Hören, entdecken, wachsen'},
  'continue': {'fr': 'Continuer mon histoire', 'en': 'Continue my story', 'ar': 'تابع قصتي', 'de': 'Meine Geschichte fortsetzen'},
  'start': {'fr': 'Commencer une histoire', 'en': 'Start a story', 'ar': 'ابدأ قصة', 'de': 'Eine Geschichte beginnen'},
  'all': {'fr': 'Toutes', 'en': 'All', 'ar': 'الكل', 'de': 'Alle'},
  'listen': {'fr': 'À écouter', 'en': 'To listen', 'ar': 'للاستماع', 'de': 'Zum Hören'},
  'favs': {'fr': 'Favoris', 'en': 'Favorites', 'ar': 'المفضلة', 'de': 'Favoriten'},
  'read': {'fr': 'Lire', 'en': 'Read', 'ar': 'اقرأ', 'de': 'Lesen'},
  'hear': {'fr': 'Écouter', 'en': 'Listen', 'ar': 'استمع', 'de': 'Hören'},
  'soon': {'fr': 'Bientôt', 'en': 'Soon', 'ar': 'قريباً', 'de': 'Bald'},
  'calm': {'fr': 'Un moment calme,\nune belle leçon', 'en': 'A calm moment,\na beautiful lesson', 'ar': 'لحظة هادئة،\nودرس جميل', 'de': 'Ein ruhiger Moment,\neine schöne Lektion'},
  'discover': {'fr': 'Découvrir une histoire', 'en': 'Discover a story', 'ar': 'اكتشف قصة', 'de': 'Geschichte entdecken'},
  'readWithMe': {'fr': 'Lire avec moi', 'en': 'Read with me', 'ar': 'اقرأ معي', 'de': 'Lies mit mir'},
  'page': {'fr': 'Page {n} / {t}', 'en': 'Page {n} / {t}', 'ar': 'الصفحة {n} / {t}', 'de': 'Seite {n} / {t}'},
  'next': {'fr': 'Suivant', 'en': 'Next', 'ar': 'التالي', 'de': 'Weiter'},
  'finish': {'fr': 'Terminer', 'en': 'Finish', 'ar': 'إنهاء', 'de': 'Fertig'},
  'bravo': {'fr': 'Bravo !', 'en': 'Well done!', 'ar': 'أحسنت!', 'de': 'Bravo!'},
  'done': {'fr': 'Histoire terminée', 'en': 'Story finished', 'ar': 'انتهت القصة', 'de': 'Geschichte beendet'},
  'remember': {'fr': 'Ce que je retiens', 'en': 'What I remember', 'ar': 'ما تعلّمته', 'de': 'Was ich mir merke'},
  'challenge': {'fr': 'Mon petit défi', 'en': 'My little challenge', 'ar': 'تحدّيّ الصغير', 'de': 'Meine kleine Aufgabe'},
  'reread': {'fr': 'Relire', 'en': 'Read again', 'ar': 'أعد القراءة', 'de': 'Nochmal lesen'},
  'more': {'fr': 'Autres histoires', 'en': 'More stories', 'ar': 'قصص أخرى', 'de': 'Mehr Geschichten'},
  'noFavs': {'fr': 'Touche ♡ pour garder une histoire ici', 'en': 'Tap ♡ to keep a story here', 'ar': 'اضغط ♡ لتحفظ قصة هنا', 'de': 'Tippe ♡, um eine Geschichte zu merken'},
  'soonMsg': {'fr': 'Cette histoire arrive bientôt !', 'en': 'This story is coming soon!', 'ar': 'هذه القصة قادمة قريباً!', 'de': 'Diese Geschichte kommt bald!'},
};

String storyUi(BuildContext c, String key, {Map<String, String> args = const {}}) {
  var s = _ui[key]?[storyLang(c)] ?? _ui[key]?['fr'] ?? key;
  args.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}
