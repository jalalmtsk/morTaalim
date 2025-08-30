import '../LanguageManager.dart';

/// Multilingual dictionary: language -> word -> definition
final Map<AppLanguage, Map<String, String>> wordDefinitionsByLang = {


  AppLanguage.en: {
    //->FIRST STORY
    //1111111111111111111111111111111111111111111111111111111111111
    // Page 1
    'silly': 'Funny in a playful way.',
    'fox': 'A small wild animal with a bushy tail.',
    'dance': 'To move your body to music.',
    'rain': 'Water falling from the sky as drops.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    'invite': 'To ask someone to join an event or activity.',
    'friend': 'A person you like and trust.',
    'bunny': 'A small, soft animal that hops.',
    'party': 'A joyful gathering with fun and activities.',
    'Benny': 'Flick\'s best friend, a playful bunny.',

    // Page 3
    'forest': 'A large area covered with trees.',
    'rainbow': 'A colorful arc in the sky after rain.',
    'adventures': 'Exciting experiences or journeys.',

    //->SECOND STORY
    //222222222222222222222222222222222222222222222222222222222222222

    //-> SUNNY STORY
    // Page 1
    'cheerful': 'Feeling or showing happiness and optimism.',
    'squirrel': 'A small rodent with a bushy tail that climbs trees.',
    'pile': 'A large amount of things placed on top of each other.',
    'acorns': 'Nuts from an oak tree.',
    'share': 'To give part of something to others.',
    'forest': 'A large area covered with trees.',

    // Page 2
    'wonderful': 'Extremely good or pleasant.',
    'feast': 'A large meal with plenty of food.',
    'oak': 'A type of large tree with acorns.',

    // Page 3
    'thankful': 'Feeling or showing gratitude.',
    'happy': 'Feeling pleasure or contentment.',


    //-> THIRD STORY
    //3333333333333333333333333333333333333333333333333333333333333

    // Page 1
    'deep': 'Far below the surface.',
    'sea': 'A large body of salt water.',
    'sleepy': 'Feeling ready to sleep or rest.',
    'narwhal': 'A whale with a long spiral tusk.',
    'nap': 'A short period of sleep.',
    'jellyfish': 'A soft sea creature with tentacles.',
    'Nina': 'A sleepy narwhal who loves naps.',

    // Page 2
    'turtle': 'A reptile with a shell that swims in the sea.',
    'swimming': 'Moving through water by using body parts.',
    'fast': 'Moving quickly.',
    'surfboard': 'A board used for riding waves in the ocean.',

    // Page 3
    'quiet': 'Making little or no noise.',
    'rock': 'A large solid piece of stone.',
    'surprise': 'Something unexpected.',
    'octopus': 'A sea creature with eight arms.',
    'hug': 'To hold someone tightly with your arms.',
  },

  AppLanguage.fr: {
    // Page 1
    'rigolo': 'Funny in a playful way.',
    'renard': 'A small wild animal with a bushy tail.',
    'danser': 'To move your body to music.',
    'pluie': 'Water falling from the sky as drops.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    'inviter': 'To ask someone to join an event or activity.',
    'ami': 'Friend; a person you like and trust.',
    'lapin': 'Bunny; a small, soft animal that hops.',
    'fête': 'Party; a joyful gathering with fun and activities.',
    'Benny': 'Flick\'s best friend, a playful bunny.',

    // Page 3
    'forêt': 'Forest; a large area covered with trees.',
    'arc-en-ciel': 'Rainbow; a colorful arc in the sky after rain.',
    'aventures': 'Adventures; exciting experiences or journeys.',


    //->HISTOIRE DE SUNNY
    // Page 1
    'joyeux': 'Feeling or showing happiness. / شعور أو إظهار السعادة.',
    'écureuil': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    'tas': 'A pile of things. / كومة من الأشياء.',
    'glands': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    'partager': 'To give part to others. / إعطاء جزء للآخرين.',
    'forêt': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    'merveilleux': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    'festin': 'A large meal. / وجبة كبيرة.',
    'chêne': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    'heureux': 'Feeling happy. / الشعور بالسعادة.',
    'reconnaissant': 'Feeling grateful. / الشعور بالامتنان.',

    //->FIRST STORY
    // Page 1
    'narval': 'Narwhal / حوت نرجوال: Une baleine avec une longue défense en spirale.',
    'endormie': 'Sleepy / كسول: Qui a sommeil ou prêt à faire une sieste.',
    'sieste': 'Nap / قيلولة: Un court sommeil pendant la journée.',
    'méduse': 'Jellyfish / قنديل البحر: Un animal marin mou avec des tentacules urticants.',
    'Nina': 'Nina / نينا: Le personnage principal qui aime dormir.',

    // Page 2
    'tortue': 'Turtle / سلحفاة: Un animal lent avec une carapace dure.',
    'nager': 'Swimming / سباحة: Se déplacer dans l’eau.',
    'vite': 'Fast / سريع: Se déplacer rapidement.',
    'rapide': 'Speedy / سريع: Très rapide.',

    // Page 3
    'rocher': 'Rock / صخرة: Un morceau de pierre dur et solide.',
    'poulpe': 'Octopus / أخطبوط: Un animal marin avec huit bras.',
    'tranquille': 'Quiet / هادئ: Sans bruit ni agitation.',
    'SURPRISE': 'SURPRISE / مفاجأة: Quelque chose d’inattendu ou étonnant.'
  },


  AppLanguage.ar: {
    // Page 1
    'ثعلب': 'Fox; a small wild animal with a bushy tail.',
    'مضحك': 'Funny; amusing in a playful way.',
    'الرقص': 'Dance; to move rhythmically to music.',
    'المطر': 'Rain; water falling from the sky.',
    'فليك': 'A funny fox who loves dancing.',

    // Page 2
    'دعوة': 'Invitation; asking someone to join.',
    'صديق': 'Friend; a person you like and trust.',
    'الأرنب': 'Bunny; a small animal that hops.',
    'حفلة': 'Party; a joyful gathering.',
    'بيني': 'Flick\'s friend, a playful bunny.',

    // Page 3
    'الغابة': 'Forest; a large area covered with trees.',
    'قوس': 'Arc; part of a rainbow.',
    'قزح': 'Rainbow; colorful arc in the sky.',
    'مغامرات': 'Adventures; exciting experiences or journeys.',

    //->قصة ساني
    // Page 1
    'السنجاب': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    'المبتهج': 'Feeling happy or cheerful. / شعور بالسعادة أو البهجة.',
    'كومة': 'A pile of things. / كومة من الأشياء.',
    'البلوط': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    'مشاركتها': 'To share with others. / المشاركة مع الآخرين.',
    'الغابة': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    'رائعة': 'Extremely good or pleasant. / رائعة أو ممتعة للغاية.',
    'بوليمة': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    'شجرة': 'A large plant with a trunk and branches. / نبات كبير ذو جذع وفروع.',

    // Page 3
    'سعادة': 'Feeling happy. / الشعور بالسعادة.',
    'اعتزاز': 'Feeling grateful or proud. / الشعور بالامتنان أو الفخر.',

    // Page 1
    'أخيرًا': 'Finally; في النهاية.',
    'نينا': 'Nina; اسم الشخصية الرئيسية.',
    'وجدت': 'Found; وجدت شيئًا.',
    'مكانًا': 'Place; مكان هادئ أو محدد.',
    'هادئًا': 'Quiet; هادئ وخالٍ من الضوضاء.',
    'على': 'On; فوق شيء ما.',
    'صخرة': 'Rock; كتلة صلبة من الحجر.',

    // Page 2
    'لكن': 'But; تعبير يستخدم للمعارضة أو المفاجأة.',
    'مفاجأة': 'Surprise; شيء غير متوقع.',
    'كان': 'Was; شكل من أشكال الفعل الماضي.',
    'أخطبوطًا': 'Octopus; حيوان بحري ثماني الأرجل.',
    'نائمًا': 'Sleeping; في حالة النوم.',

    // Extras if needed
    'الصخور': 'Rocks; جمع صخرة.',
    'البحر': 'Sea; مسطح مائي كبير يحتوي على ماء مالح.',

    //->FIRST STORY
    // Page 1
    'نرجوال': 'Narwhal / حوت بحاجب طويل يشبه القرن.',
    'كسول': 'Sleepy / يشعر بالنعاس أو يحب النوم.',
    'قيلولة': 'Nap / نوم قصير خلال النهار.',
    'قنديل البحر': 'Jellyfish / حيوان بحري لين له مجسات لاذعة.',
    'نينا': 'Nina / الشخصية الرئيسية التي تحب النوم.',

    // Page 2
    'سلحفاة': 'Turtle / حيوان بطيء له صدفة صلبة.',
    'تسبح': 'Swimming / التحرك في الماء.',
    'بسرعة': 'Fast / التحرك بسرعة.',
    'سريع': 'Speedy / سريع جدًا.',

    // Page 3
    'صخرة': 'Rock / قطعة صلبة من الحجر.',
    'أخطبوط': 'Octopus / حيوان بحري له ثمانية أذرع.',
    'هادئ': 'Quiet / بدون ضوضاء أو توتر.',
    'مفاجأة': 'SURPRISE / شيء غير متوقع أو مدهش.'

  },

  AppLanguage.de: {
    // Page 1
    'lustiger': 'Funny; amusing in a playful way.',
    'Fuchs': 'Fox; a small wild animal with a bushy tail.',
    'tanzen': 'To move your body to music.',
    'Regen': 'Rain; water falling from the sky.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    'einladen': 'To invite someone to an event or activity.',
    'Freund': 'Friend; a person you like and trust.',
    'Hase': 'Bunny; a small, hopping animal.',
    'Party': 'Party; joyful gathering.',
    'Benny': 'Flick\'s best friend, a playful bunny.',

    // Page 3
    'Wald': 'Forest; a large area covered with trees.',
    'Regenbogen': 'Rainbow; colorful arc in the sky.',
    'Abenteuer': 'Adventures; exciting experiences or journeys.',
  },

  AppLanguage.es: {
    // Page 1
    'divertido': 'Funny in a playful way.',
    'zorro': 'A small wild animal with a bushy tail.',
    'bailar': 'To move your body to music.',
    'lluvia': 'Water falling from the sky as drops.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    'invitar': 'To ask someone to join an event or activity.',
    'amigo': 'Friend; a person you like and trust.',
    'conejo': 'Bunny; a small, hopping animal.',
    'fiesta': 'Party; joyful gathering.',
    'Benny': 'Flick\'s best friend, a playful bunny.',

    // Page 3
    'bosque': 'Forest; a large area covered with trees.',
    'arcoíris': 'Rainbow; colorful arc in the sky.',
    'aventuras': 'Adventures; exciting experiences or journeys.',

    //->SUNNY GESCHICHTE
    // Page 1
    'fröhliche': 'Feeling happy or cheerful. / الشعور بالسعادة أو البهجة.',
    'Eichhörnchen': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    'Haufen': 'A pile of things. / كومة من الأشياء.',
    'Eicheln': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    'teilen': 'To share with others. / المشاركة مع الآخرين.',
    'Wald': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    'wunderbares': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    'Festmahl': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    'Eiche': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    'glücklich': 'Feeling happy. / الشعور بالسعادة.',
    'dankbar': 'Feeling grateful. / الشعور بالامتنان.'
  },

  AppLanguage.amazigh: {
    // Page 1
    'ⴼⵍⵉⴽ': 'A funny fox who loves dancing.',
    'ⴰⵎⵔⴰⵙⵏ': 'Rain; water falling from the sky.',

    // Page 2
    'ⴱⴰⵏⵏⵢ': 'Bunny; Flick\'s playful friend.',
    'ⴰⵡⴰⵙ': 'Invite; to ask someone to join.',

    // Page 3
    'ⴰⵙⴷⴰⵍ': 'Forest; a large area with trees.',
    'ⴰⵔⴰⴷⵉ': 'Rainbow; colorful arc in the sky.',
    'ⵢⴰⵎⵓ': 'Adventures; exciting experiences or journeys.',

    //->STORY OF SUNNY
    // Page 1
    'ⵢⴰⴷⵓⴳ': 'Feeling happy or cheerful. / شعور بالسعادة أو البهجة.',
    'ⴰⵎⵓⴽ': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    'ⴰⵣⵓⴳ': 'A pile of things. / كومة من الأشياء.',
    'ⴰⴷⵓ': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    'ⵉⴷⴷⴰⵎ': 'To share with others. / المشاركة مع الآخرين.',
    'ⴰⵙⴷⴰⵍ': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    'ⴰⵎⵓⵙⵙⴰⵍ': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    'ⵏⴰⴷⵓⵔ': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    'ⴰⵔⴰⴷⵉ': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    'ⵢⵉⵙⵙ': 'Feeling happy. / الشعور بالسعادة.',
    'ⵢⴰⵎⵙ': 'Feeling grateful. / الشعور بالامتنان.'
  },

  AppLanguage.ru: {
    // Page 1
    'глупый': 'Funny or silly in a playful way.',
    'лис': 'Fox; a small wild animal with a bushy tail.',
    'танцевать': 'To move your body to music.',
    'дождем': 'Rain; water falling from the sky.',
    'Флик': 'A funny fox who loves dancing.',

    // Page 2
    'друг': 'Friend; a person you like and trust.',
    'пригласить': 'To invite someone to join an event.',
    'кролик': 'Bunny; a small hopping animal.',
    'вечеринка': 'Party; joyful gathering.',
    'Бенни': 'Flick\'s playful friend, a bunny.',

    // Page 3
    'лес': 'Forest; a large area covered with trees.',
    'радуга': 'Rainbow; colorful arc in the sky.',
    'приключения': 'Adventures; exciting experiences or journeys.',

    //->ИСТОРИЯ О SUNNY
    // Page 1
    'Санни': 'The name of the cheerful squirrel. / اسم السنجاب المبتهج.',
    'счастливым': 'Feeling happy or joyful. / الشعور بالسعادة أو البهجة.',
    'куча': 'A pile of things. / كومة من الأشياء.',
    'друзей': 'Friends; people you like and trust. / أصدقاء؛ أشخاص تحبهم وتثق بهم.',

    // Page 2
    'вкусный': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    'пир': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    'дуб': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    'благодарным': 'Feeling grateful. / الشعور بالامتنان.'
  },

  AppLanguage.it: {
    // Page 1
    'buffa': 'Funny in a playful way.',
    'volpe': 'Fox; a small wild animal with a bushy tail.',
    'ballare': 'To move your body to music.',
    'pioggia': 'Rain; water falling from the sky.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    'invitare': 'To ask someone to join an event or activity.',
    'amico': 'Friend; a person you like and trust.',
    'coniglio': 'Bunny; a small hopping animal.',
    'festa': 'Party; joyful gathering.',
    'Benny': 'Flick\'s playful friend, a bunny.',

    // Page 3
    'arcobaleno': 'Rainbow; colorful arc in the sky.',
    'avventure': 'Adventures; exciting experiences or journeys.',

    //->STORIA DI SUNNY
    // Page 1
    'felice': 'Feeling happy or cheerful. / شعور بالسعادة أو البهجة.',
    'scoiattolo': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    'mucchio': 'A pile of things. / كومة من الأشياء.',
    'ghiande': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    'condividere': 'To share with others. / المشاركة مع الآخرين.',
    'foresta': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    'meraviglioso': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    'banchetto': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    'quercia': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    'grato': 'Feeling grateful. / الشعور بالامتنان.'
  },

  AppLanguage.zh: {
    // Page 1
    '傻': 'Silly; funny in a playful way.',
    '狐狸': 'Fox; a small wild animal with a bushy tail.',
    '跳舞': 'To move your body to music.',
    '雨中': 'In the rain; water falling from the sky.',
    'Flick': 'A funny fox who loves dancing.',

    // Page 2
    '邀请': 'Invite; ask someone to join.',
    '朋友': 'Friend; a person you like and trust.',
    '兔子': 'Bunny; a small hopping animal.',
    '派对': 'Party; joyful gathering.',
    'Benny': 'Flick\'s playful friend, a bunny.',

    // Page 3
    '森林': 'Forest; a large area covered with trees.',
    '彩虹': 'Rainbow; colorful arc in the sky.',
    '冒险': 'Adventures; exciting experiences or journeys.',

    //->阳光松鼠的故事
    // Page 1
    '开心': 'Feeling happy or cheerful. / شعور بالسعادة أو البهجة.',
    '松鼠': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    '一堆': 'A pile of things. / كومة من الأشياء.',
    '橡树果': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    '分享': 'To share with others. / المشاركة مع الآخرين.',
    '森林': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    '美妙': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    '盛宴': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    '橡树': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    '开心': 'Feeling happy. / الشعور بالسعادة.',
    '感恩': 'Feeling grateful. / الشعور بالامتنان.'
  },

  AppLanguage.ko: {
    // Page 1
    '어리석은': 'Silly; funny in a playful way.',
    '여우': 'Fox; a small wild animal with a bushy tail.',
    '춤추기를': 'To move your body to music.',
    '비를': 'Rain; water falling from the sky.',
    'Flick이': 'A funny fox who loves dancing.',

    // Page 2
    '초대하다': 'Invite; ask someone to join.',
    '친구': 'Friend; a person you like and trust.',
    '토끼': 'Bunny; a small hopping animal.',
    '파티': 'Party; joyful gathering.',
    'Benny': 'Flick\'s playful friend, a bunny.',

    // Page 3
    '숲': 'Forest; a large area covered with trees.',
    '무지개': 'Rainbow; colorful arc in the sky.',
    '모험': 'Adventures; exciting experiences or journeys.',

    //->써니 이야기
    // Page 1
    '행복한': 'Feeling happy or cheerful. / شعور بالسعادة أو البهجة.',
    '다람쥐': 'A small rodent with a bushy tail. / قارض صغير ذو ذيل كثيف.',
    '더미': 'A pile of things. / كومة من الأشياء.',
    '도토리': 'Nuts from an oak tree. / ثمار شجرة البلوط.',
    '나누다': 'To share with others. / المشاركة مع الآخرين.',
    '숲': 'A large area with trees. / مساحة كبيرة مغطاة بالأشجار.',

    // Page 2
    '멋진': 'Extremely good or pleasant. / رائع أو ممتع للغاية.',
    '연회': 'A large meal or feast. / وجبة كبيرة أو مأدبة.',
    '참나무': 'A large tree with acorns. / شجرة كبيرة تنتج البلوط.',

    // Page 3
    '행복한': 'Feeling happy. / الشعور بالسعادة.',
    '감사하는': 'Feeling grateful. / الشعور بالامتنان.'
  },


};

/// Get definition for a word in a selected language
String getDefinitionFor(String word, AppLanguage lang) {
  final definitions = wordDefinitionsByLang[lang] ?? {};
  return definitions[word] ??
      'No definition found.';
}
