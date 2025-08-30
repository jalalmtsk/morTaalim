// word_definition.dart

import '../LanguageManager.dart';

Map<AppLanguage, Map<String, String>> _pronunciationDictionary = {
  AppLanguage.en: {
    // Page 1
    'silly': 'ˈsɪli',
    'fox': 'fɑks',
    'dance': 'dæns',
    'rain': 'reɪn',
    'Flick': 'flɪk',

    // Page 2
    'invite': 'ɪnˈvaɪt',
    'friend': 'frɛnd',
    'bunny': 'ˈbʌni',
    'party': 'ˈpɑːrti',
    'Benny': 'ˈbɛni',

    // Page 3
    'forest': 'ˈfɔːrɪst',
    'rainbow': 'ˈreɪnˌboʊ',
    'adventures': 'ədˈvɛntʃərz',

    // Page 1
    'cheerful': 'ˈʧɪr.fəl',
    'squirrel': 'ˈskwɜːrəl',
    'pile': 'paɪl',
    'acorns': 'ˈeɪ.kɔrnz',
    'share': 'ʃɛr',
    'forest': 'ˈfɔːrɪst',

    // Page 2
    'wonderful': 'ˈwʌn.dər.fəl',
    'feast': 'fiːst',
    'oak': 'oʊk',

    // Page 3
    'happy': 'ˈhæpi',
    'thankful': 'ˈθæŋkfəl'
  },

  AppLanguage.fr: {
    // Page 1
    'rigolo': 'ʁi.ɡɔ.lo',
    'renard': 'ʁə.naʁ',
    'danser': 'dɑ̃.se',
    'pluie': 'plɥi',
    'Flick': 'flɪk',

    // Page 2
    'inviter': 'ɛ̃.vi.te',
    'ami': 'a.mi',
    'lapin': 'la.pɛ̃',
    'fête': 'fɛt',
    'Benny': 'ˈbɛni',

    // Page 3
    'forêt': 'fɔ.ʁɛ',
    'arc-en-ciel': 'aʁ.kɑ̃.sjɛl',
    'aventures': 'a.vɑ̃.tyʁ',

    // Page 1
    'joyeux': 'ʒwa.jø',
    "l'écureuil": "e.ky.ʁœj",
    'tas': 'ta',
    'glands': 'ɡlɑ̃',
    'partager': 'paʁ.ta.ʒe',
    'forêt': 'fɔ.ʁɛ',

    // Page 2
    'merveilleux': 'mɛʁ.vɛ.jø',
    'festin': 'fɛs.tɛ̃',
    'chêne': 'ʃɛn',

    // Page 3
    'heureux': 'ø.ʁø',
    'reconnaissant': 'ʁə.kɔ.nɛ.sɑ̃'
  },

  AppLanguage.ar: {
    // Page 1
    'ثعلب': 'tha‘lab',
    'مضحك': 'muḍḥik',
    'الرقص': 'ar-raqs',
    'المطر': 'al-maṭar',
    'فليك': 'Flīk',

    // Page 2
    'دعوة': 'da‘wah',
    'صديق': 'ṣadīq',
    'الأرنب': 'al-arnab',
    'حفلة': 'ḥaflah',
    'بيني': 'Bīnī',

    // Page 3
    'الغابة': 'al-ghābah',
    'قوس': 'qaws',
    'قزح': 'qazḥ',
    'مغامرات': 'mughāmarāt',

    // Page 1
    'مبتهج': 'mubtahij',
    'سنجاب': 'sanjab',
    'كومة': 'kumah',
    'البلوط': 'al-balut',
    'مشاركتها': 'mushaarakat-ha',
    'الغابة': 'al-ghabah',

    // Page 2
    'رائعة': 'ra’i‘ah',
    'بوليمة': 'buwlaymah',
    'شجرة': 'shajarah',

    // Page 3
    'سعادة': 'sa‘adah',
    'اعتزاز': 'i‘tizaz'
  },


  AppLanguage.ko: {
    // Page 1
    '어리석은': 'eo-ri-seok-eun',
    '여우': 'yeo-u',
    '춤추기를': 'chum-chu-gi-reul',
    '비를': 'bi-reul',
    'Flick이': 'Flick-i',

    // Page 2
    '초대하다': 'cho-dae-ha-da',
    '친구': 'chin-gu',
    '토끼': 'tok-ki',
    '파티': 'pa-ti',
    'Benny': 'Benny',

    // Page 3
    '숲': 'sup',
    '무지개': 'mu-ji-gae',
    '모험': 'mo-heom',

    // Page 1
    '행복한': 'haeng-bok-han',
    '다람쥐': 'da-ram-jwi',
    '더미': 'deo-mi',
    '도토리': 'do-to-ri',
    '나누다': 'na-nu-da',
    '숲': 'sup',

    // Page 2
    '멋진': 'meot-jin',
    '연회': 'yeon-hoe',
    '참나무': 'cham-na-mu',

    // Page 3
    '행복한': 'haeng-bok-han',
    '감사하는': 'gam-sa-ha-neun'
  },

  AppLanguage.es: {
    // Page 1
    'divertido': 'di-ver-ti-do',
    'zorro': 'zo-rro',
    'bailar': 'bai-lar',
    'lluvia': 'llu-via',
    'Flick': 'Flick',

    // Page 2
    'invitar': 'in-vi-tar',
    'amigo': 'a-mi-go',
    'conejo': 'co-ne-jo',
    'fiesta': 'fies-ta',
    'Benny': 'Benny',

    // Page 3
    'bosque': 'bos-que',
    'arcoíris': 'ar-co-í-ris',
    'aventuras': 'a-ven-tu-ras',

    // Page 1
    'alegre': 'a-le-gre',
    'ardilla': 'ar-di-ya',
    'montón': 'mon-ton',
    'bellotas': 'be-llo-tas',
    'compartir': 'com-par-tir',
    'bosque': 'bos-ke',

    // Page 2
    'maravilloso': 'ma-ra-vi-llo-so',
    'banquete': 'ban-ke-te',
    'roble': 'ro-ble',

    // Page 3
    'feliz': 'fe-liz',
    'agradecido': 'a-gra-de-ci-do'
  },


  AppLanguage.de: {
    // Page 1
    'lustiger': 'lus-ti-ger',
    'Fuchs': 'fuks',
    'tanzen': 'tan-tsen',
    'Regen': 're-gen',
    'Flick': 'Flick',

    // Page 2
    'einladen': 'ein-la-den',
    'Freund': 'froint',
    'Hase': 'ha-ze',
    'Party': 'par-tee',
    'Benny': 'Benny',

    // Page 3
    'Wald': 'valt',
    'Regenbogen': 're-gen-bo-gen',
    'Abenteuer': 'ab-en-toi-er',

    // Page 1
    'fröhliche': 'frøː-lɪçə',
    'Eichhörnchen': 'aɪç-hœrn-çən',
    'Haufen': 'haʊ-fən',
    'Eicheln': 'aɪ-çeln',
    'teilen': 'taɪ-lən',
    'Wald': 'valt',

    // Page 2
    'wunderbares': 'vʊn-dɐ-baː-rəs',
    'Festmahl': 'fɛst-maːl',
    'großen': 'ɡroː-sən',

    // Page 3
    'glücklich': 'ɡlʏklɪç',
    'dankbar': 'daŋk-bar'
  },


  AppLanguage.it: {
    // Page 1
    'buffa': 'bùf-fa',
    'volpe': 'vòl-pe',
    'ballare': 'bal-là-re',
    'pioggia': 'piòg-gia',
    'Flick': 'Flick',

    // Page 2
    'invitare': 'in-vi-tà-re',
    'amico': 'a-mì-co',
    'coniglio': 'co-nì-glio',
    'festa': 'fè-sta',
    'Benny': 'Benny',

    // Page 3
    'foresta': 'fo-rè-sta',
    'arcobaleno': 'ar-co-ba-lè-no',
    'avventure': 'av-ven-tù-re',

    // Page 1
    'gioioso': 'dʒoˈjoːzo',
    'scoiattolo': 'skwjatˈtoːlo',
    'mucchio': 'ˈmutːʃo',
    'ghiande': 'ˈɡjande',
    'condividere': 'kon.diˈvi.de.re',
    'foresta': 'foˈrɛsta',

    // Page 2
    'meraviglioso': 'mera.viʎˈʎoːzo',
    'banchetto': 'banˈketːto',
    'quercia': 'ˈkwɛrʧa',

    // Page 3
    'felice': 'feˈlitʃe',
    'grato': 'ˈɡraːto'
  },


  AppLanguage.ru: {
    // Page 1
    'глупый': 'glupyj',
    'лис': 'lis',
    'танцевать': 'tantsyevat’',
    'дождем': 'dozh-dem',
    'Флик': 'Flik',

    // Page 2
    'друг': 'druk',
    'пригласить': 'priglasit’',
    'кролик': 'krolik',
    'вечеринка': 'vecherinka',
    'Бенни': 'Benny',

    // Page 3
    'лес': 'les',
    'радуга': 'raduga',
    'приключения': 'priklyucheniya',

    // Page 1
    'радостный': 'ra-dost-nyy',
    'белка': 'byel-ka',
    'куча': 'ku-cha',
    'желуди': 'zhe-lu-di',
    'делиться': 'de-lit-sya',
    'лес': 'les',

    // Page 2
    'чудесный': 'chu-des-nyy',
    'пир': 'pir',
    'дуб': 'dub',

    // Page 3
    'счастливый': 'shchas-li-vyy',
    'благодарный': 'bla-go-dar-nyy'
  },


  AppLanguage.amazigh: {
    // Page 1
    'ⴼⵍⵉⴽ': 'Flick',
    'ⴰⵎⵔⴰⵙⵏ': 'amrasn',

    // Page 2
    'ⴱⴰⵏⵏⵢ': 'Banny',
    'ⴰⵡⴰⵙ': 'awas',

    // Page 3
    'ⴰⵙⴷⴰⵍ': 'asdal',
    'ⴰⵔⴰⴷⵉ': 'aradi',
    'ⵢⴰⵎⵓ': 'yamu',

    // Page 1
    'ⵢⴰⴷⵓⴳ': 'ya-dug',
    'ⴰⵎⵓⴽ': 'a-muk',
    'ⵣⴰⵢⴰⵏ': 'za-yan',
    'ⴰⵎⴰⵣⴰⵔ': 'a-ma-zar',
    'ⵉⴷⴷⴰⵎ': 'id-dam',
    'ⴰⵙⴷⴰⵍ': 'as-dal',

    // Page 2
    'ⴰⵎⵓⵙⵙⴰⵍ': 'a-mus-sal',
    'ⴷⴰⴷⵓⵔ': 'da-dur',
    'ⴰⵙⴷⴰⵍ': 'as-dal',

    // Page 3
    'ⵢⴰⵎⵙ': 'ya-ms',
    'ⵢⵉⵙⵙ': 'yi-ss'
  },

  AppLanguage.zh: {
    // Page 1
    '傻': 'shǎ',
    '狐狸': 'húli',
    '跳舞': 'tiàowǔ',
    '雨中': 'yǔ zhōng',
    'Flick': 'Flick',

    // Page 2
    '邀请': 'yāoqǐng',
    '朋友': 'péngyǒu',
    '兔子': 'tùzi',
    '派对': 'pàiduì',
    'Benny': 'Benny',

    // Page 3
    '森林': 'sēnlín',
    '彩虹': 'cǎihóng',
    '冒险': 'màoxiǎn',

    // Page 1
    '开心': 'kāi xīn',
    '松鼠': 'sōng shǔ',
    '堆': 'duī',
    '橡果': 'xiàng guǒ',
    '分享': 'fēn xiǎng',
    '森林': 'sēn lín',

    // Page 2
    '精彩': 'jīng cǎi',
    '盛宴': 'shèng yàn',
    '橡树': 'xiàng shù',

    // Page 3
    '快乐': 'kuài lè',
    '感激': 'gǎn jī'
  }


};

String getPronunciationFor(String word, AppLanguage language) {
  final cleanedWord = word.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  if (_pronunciationDictionary[language]?.containsKey(cleanedWord) == true) {
    return _pronunciationDictionary[language]![cleanedWord]!;
  } else {
    return "Pronunciation not found";
  }
}
