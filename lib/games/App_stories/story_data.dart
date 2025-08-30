import 'LanguageManager.dart';
import 'Stories.dart';
import 'story_page_data.dart';

final List<Story> stories = [


  Story(
    title: 'Flick the Dancing Fox',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/TheDancingFox_cover.png',
    pages: [
      // FIRST PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['Once', 'upon', 'a', 'time,', 'there', 'was', 'a', 'silly', 'fox', 'named', 'Flick,', 'who', 'loved', 'to', 'dance', 'in', 'the', 'rain.'],
          AppLanguage.fr: ['Il', 'était', 'une', 'fois,', 'un', 'renard', 'rigolo', 'nommé', 'Flick', 'aimait', 'danser', 'sous', 'la', 'pluie.'],
          AppLanguage.ar: ['في', 'زمانٍ', 'ماضٍ،', 'كان', 'هناك', 'ثعلب', 'مضحك', 'اسمه', 'فليك،', 'يحب', 'الرقص', 'تحت', 'المطر.'],
          AppLanguage.de: ['Es', 'war', 'ein', 'Mal,', 'da', 'lebte', 'ein', 'lustiger', 'Fuchs', 'namens', 'Flick,', 'der', 'es', 'liebte,', 'im', 'Regen', 'zu', 'tanzen.'],
          AppLanguage.es: ['Érase', 'una', 'vez,', 'había', 'un', 'zorro', 'divertido', 'llamado', 'Flick,', 'que', 'amaba', 'bailar', 'bajo', 'la', 'lluvia.'],
          AppLanguage.amazigh: ['ⴰⵏⵏ', 'ⴰⵡⴰⵙ,', 'ⴰⵎⵣⴰⵢ', 'ⵏ', 'ⵡⵉⵣⴰⵍ,', 'ⴰⵏⴰⵙ', 'ⴼⵍⵉⴽ', 'ⵢⵉⵏ', 'ⴰⵎⵔⴰⵙ', 'ⴰⵣⴰⵡⵉⵍ'],
          AppLanguage.ru: ['Жил', 'был', 'забавный', 'лис', 'по', 'имени', 'Флик,', 'который', 'обожал', 'танцевать', 'под', 'дождем.'],
          AppLanguage.it: ['C\'era', 'una', 'volta', 'un', 'furbo', 'e', 'buffo', 'volpe', 'chiamata', 'Flick,', 'che', 'amava', 'ballare', 'sotto', 'la', 'pioggia.'],
          AppLanguage.zh: ['从前，', '有一只', '可爱又傻', '的', '狐狸', '叫', 'Flick，', '它', '喜欢', '在', '雨中', '跳舞。'],
          AppLanguage.ko: ['옛날에', '어리석지만', '귀여운', '여우', 'Flick이', '살고 있었어요,', '그는', '비를', '맞으며', '춤추는', '것을', '좋아했어요.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxDancingOnRain_Story.png',
        characterName: 'Flick',
        funnyLine: 'Oops! He slipped and did a funny twirl!',
      ),

      // SECOND PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['Flick', 'decided', 'to', 'invite', 'his', 'best', 'friend,', 'Benny', 'the', 'bunny,', 'to', 'join', 'the', 'rain', 'dance', 'party.'],
          AppLanguage.fr: ['Flick', 'décida', 'd\'inviter', 'son', 'meilleur', 'ami,', 'Benny', 'le', 'lapin,', 'à', 'rejoindre', 'la', 'fête', 'de', 'danse', 'sous', 'la', 'pluie.'],
          AppLanguage.ar: ['قرر', 'فليك', 'دعوة', 'أفضل', 'صديقه،', 'بيني', 'الأرنب،', 'للانضمام', 'إلى', 'حفلة', 'الرقص', 'في', 'المطر.'],
          AppLanguage.de: ['Flick', 'beschloss', 'seinen', 'besten', 'Freund,', 'Benny', 'den', 'Hasen,', 'einzuladen,', 'an', 'der', 'Regen-Tanzparty', 'teilzunehmen.'],
          AppLanguage.es: ['Flick', 'decidió', 'invitar', 'a', 'su', 'mejor', 'amigo,', 'Benny', 'el', 'conejo,', 'para', 'unirse', 'a', 'la', 'fiesta', 'de', 'baile', 'bajo', 'la', 'lluvia.'],
          AppLanguage.amazigh: ['Flick', 'yesɛeḍ', 'ad', 'yeswaṛ', 'asek', 'amiḍu,', 'Benny', 'aneγ', 'aḍu', 'ad', 'yeddu', 'i', 'tafukt', 'n', 'tixsiwin.'],
          AppLanguage.ru: ['Флик', 'решил', 'пригласить', 'своего', 'лучшего', 'друга,', 'Бенни', 'кролика,', 'чтобы', 'он', 'присоединился', 'к', 'вечеринке', 'под', 'дождем.'],
          AppLanguage.it: ['Flick', 'decise', 'di', 'invitare', 'il', 'suo', 'migliore', 'amico,', 'Benny', 'il', 'coniglio,', 'a', 'partecipare', 'alla', 'festa', 'di', 'danza', 'sotto', 'la', 'pioggia.'],
          AppLanguage.zh: ['Flick', '决定', '邀请', '他', '最好的', '朋友', 'Benny', '兔子', '加入', '雨中', '舞会。'],
          AppLanguage.ko: ['Flick', '결정했어요', '그의', '가장', '친한', '친구', 'Benny', '토끼를', '초대해', '비', '속에서', '춤추는', '파티에', '참가하게.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxDancingWithFriends_Story.png',
        characterName: 'Benny',
        funnyLine: 'Benny tried to hop but ended up splashing mud everywhere!',
      ),

      // THIRD PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['Together,', 'they', 'danced', 'and', 'laughed,', 'making', 'the', 'forest', 'a', 'happier', 'place.', 'Suddenly,', 'a', 'rainbow', 'appeared,', 'and', 'Flick', 'wished', 'for', 'more', 'adventures.'],
          AppLanguage.fr: ['Ensemble,', 'ils', 'dansèrent', 'et', 'rirent,', 'rendant', 'la', 'forêt', 'encore', 'plus', 'joyeuse.', 'Soudain,', 'un', 'arc-en-ciel', 'apparut,', 'et', 'Flick', 'souhaita', 'vivre', 'plus', 'd\'aventures.'],
          AppLanguage.ar: ['معًا،', 'رقصوا', 'وضحكوا،', 'مما', 'جعل', 'الغابة', 'مكانًا', 'أكثر', 'سعادة.', 'فجأة،', 'ظهر', 'قوس', 'قزح،', 'وتمنى', 'فليك', 'مزيدًا', 'من', 'المغامرات.'],
          AppLanguage.de: ['Zusammen', 'tanzten', 'sie', 'und', 'lachten,', 'wodurch', 'der', 'Wald', 'zu', 'einem', 'glücklicheren', 'Ort', 'wurde.', 'Plötzlich', 'erschien', 'ein', 'Regenbogen,', 'und', 'Flick', 'wünschte', 'sich', 'mehr', 'Abenteuer.'],
          AppLanguage.es: ['Juntos,', 'bailaron', 'y', 'rieron,', 'haciendo', 'del', 'bosque', 'un', 'lugar', 'más', 'feliz.', 'De repente,', 'apareció', 'un', 'arcoíris,', 'y', 'Flick', 'pidió', 'tener', 'más', 'aventuras.'],
          AppLanguage.amazigh: ['ⴰⵎⴰⵏⴰ,', 'ⵢⴰⵎⴰⵙ', 'ⵢⴰⴷⵓ', 'ⴷ', 'ⵉⵙⴰⵔ,', 'ⵏⴰ', 'ⴰⵙⴷⴰⵍ', 'ⴰⵔⴰⴷⵉ', 'ⴷ', 'ⵢⴰⵏⵓ', 'ⵓⵙⴽⵉⵏ', 'ⴷ', 'ⴰⵎⴰⵢⵏⵉⵏ'],
          AppLanguage.ru: ['Вместе', 'они', 'танцевали', 'и', 'смеялись,', 'делая', 'лес', 'более', 'счастливым', 'местом.', 'Вдруг', 'появилась', 'радуга,', 'и', 'Флик', 'пожелал', 'больше', 'приключений.'],
          AppLanguage.it: ['Insieme,', 'ballarono', 'e', 'risero,', 'rendendo', 'la', 'foresta', 'un', 'luogo', 'ancora', 'più', 'felice.', 'All\'improvviso,', 'apparve', 'un', 'arcobaleno,', 'e', 'Flick', 'desiderò', 'vivere', 'altre', 'avventure.'],
          AppLanguage.zh: ['一起，', '他们', '跳舞', '并', '欢笑，', '让', '森林', '变得', '更加', '快乐。', '突然，', '一条', '彩虹', '出现了，', 'Flick', '许下了', '更多', '冒险', '的愿望。'],
          AppLanguage.ko: ['함께,', '그들은', '춤추고', '웃으며', '숲을', '더욱', '행복한', '곳으로', '만들었어요.', '갑자기,', '무지개가', '나타났고,', 'Flick은', '더', '많은', '모험을', '바랐어요.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/FoxMud_Story.png',
        characterName: 'Flick & Benny',
        funnyLine: 'Rainbow magic made Benny\'s ears glow bright pink!',
      ),
    ],
  ),


  /// SECOND STORYY   EN
  Story(
    title: 'Sunny the Squirrel',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/SunnyTheSquirrel_cover.png',
    pages: [
      // FIRST PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['Sunny', 'the', 'cheerful', 'squirrel', 'found', 'a', 'big', 'pile', 'of', 'acorns', 'and', 'decided', 'to', 'share', 'them', 'with', 'his', 'friends', 'in', 'the', 'forest.'],
          AppLanguage.fr: ['Sunny', 'l\'écureuil', 'joyeux', 'découvrit', 'un', 'grand', 'tas', 'de', 'glands', 'et', 'décida', 'de', 'les', 'partager', 'avec', 'ses', 'amis', 'dans', 'la', 'forêt.'],
          AppLanguage.ar: ['ساني', 'السنجاب', 'المبهج', 'عثر', 'على', 'كومة', 'كبيرة', 'من', 'البلوط', 'وقرر', 'أن', 'يشاركها', 'مع', 'أصدقائه', 'في', 'الغابة.'],
          AppLanguage.de: ['Sunny', 'das', 'fröhliche', 'Eichhörnchen', 'fand', 'einen', 'großen', 'Haufen', 'Eicheln', 'und', 'beschloss', 'diese', 'mit', 'seinen', 'Freunden', 'im', 'Wald', 'zu', 'teilen.'],
          AppLanguage.es: ['Sunny', 'la', 'ardilla', 'alegre', 'encontró', 'un', 'gran', 'montón', 'de', 'bellotas', 'y', 'decidió', 'compartirlas', 'con', 'sus', 'amigos', 'en', 'el', 'bosque.'],
          AppLanguage.amazigh: ['Sunny', 'yufa', 'asek', 'amehraz', 'n', 'tagawsa', 'ameqqran', 'sy', 'inaḍen', 'u', 'ifassen', 'iwet', 'ad', 'yebdu', 'd', 'imeḍdukal', 's', 'taɣult.'],
          AppLanguage.ru: ['Санни,', 'веселая', 'белка,', 'нашла', 'большую', 'кучу', 'желудей', 'и', 'решила', 'поделиться', 'ими', 'со', 'своими', 'друзьями', 'в', 'лесу.'],
          AppLanguage.it: ['Sunny', 'lo', 'scoiattolo', 'allegro', 'trovò', 'un', 'grande', 'mucchio', 'di', 'ghiande', 'e', 'decise', 'di', 'condividerle', 'con', 'i', 'suoi', 'amici', 'nella', 'foresta.'],
          AppLanguage.zh: ['Sunny', '这只', '开朗的', '松鼠', '发现了', '一大堆', '橡子', '并且', '决定', '和', '他的', '朋友们', '分享', '在', '森林里。'],
          AppLanguage.ko: ['활발한', '다람쥐', 'Sunny는', '큰', '도토리', '더미를', '발견하고', '숲속', '친구들과', '함께', '나누기로', '결정했어요.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelEating_Story.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny accidentally buried one acorn in his own hat!',
      ),

      // SECOND PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['Sunny', 'and', 'his', 'friends', 'had', 'a', 'wonderful', 'feast', 'under', 'the', 'big', 'oak', 'tree.'],
          AppLanguage.fr: ['Sunny', 'et', 'ses', 'amis', 'ont', 'eu', 'un', 'festin', 'merveilleux', 'sous', 'le', 'grand', 'chêne.'],
          AppLanguage.ar: ['ساني', 'وأصدقاؤه', 'استمتعوا', 'بوليمة', 'رائعة', 'تحت', 'شجرة', 'البلوط', 'الكبيرة.'],
          AppLanguage.de: ['Sunny', 'und', 'seine', 'Freunde', 'hatten', 'ein', 'wunderbares', 'Festmahl', 'unter', 'der', 'großen', 'Eiche.'],
          AppLanguage.es: ['Sunny', 'y', 'sus', 'amigos', 'tuvieron', 'un', 'banquete', 'maravilloso', 'bajo', 'el', 'gran', 'roble.'],
          AppLanguage.amazigh: ['Sunny', 'ⴷ', 'ⴰⵎⵓⵙⵙⴰⵍ', 'ⵢⵉⵙⵙ', 'ⴰⴷⵓ', 'ⵉⴷⴷⴰⵎ', 'ⵓⵏⵏ', 'ⴰⴷⵓ', 'ⵏ', 'ⴰⵙⴷⴰⵍ', 'ⴷ', 'ⴰⴷⵓⵔ'],
          AppLanguage.ru: ['Санни', 'и', 'его', 'друзья', 'устроили', 'замечательный', 'пир', 'под', 'большим', 'дубом.'],
          AppLanguage.it: ['Sunny', 'e', 'i', 'suoi', 'amici', 'fecero', 'un', 'meraviglioso', 'banchetto', 'sotto', 'la', 'grande', 'quercia.'],
          AppLanguage.zh: ['Sunny', '和', '他的', '朋友们', '在', '大橡树下', '举行了', '一场', '精彩的', '盛宴。'],
          AppLanguage.ko: ['Sunny와', '친구들은', '큰', '참나무', '아래에서', '멋진', '잔치를', '열었어요.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelHappyWithFriends_Story.png',
        characterName: 'Sunny & Friends',
        funnyLine: 'They laughed so much the acorns almost rolled away!',
      ),

      // THIRD PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['At', 'the', 'end', 'of', 'the', 'day,', 'Sunny', 'felt', 'happy', 'and', 'thankful', 'for', 'his', 'friends.'],
          AppLanguage.fr: ['À', 'la', 'fin', 'de', 'la', 'journée,', 'Sunny', 'se', 'sentit', 'heureux', 'et', 'reconnaissant', 'envers', 'ses', 'amis.'],
          AppLanguage.ar: ['في', 'نهاية', 'اليوم،', 'شعر', 'ساني', 'بالسعادة', 'والامتنان', 'لأصدقائه.'],
          AppLanguage.de: ['Am', 'Ende', 'des', 'Tages', 'fühlte', 'Sunny', 'sich', 'glücklich', 'und', 'dankbar', 'für', 'seine', 'Freunde.'],
          AppLanguage.es: ['Al', 'final', 'del', 'día,', 'Sunny', 'se', 'sintió', 'feliz', 'y', 'agradecido', 'por', 'sus', 'amigos.'],
          AppLanguage.amazigh: ['ⴰⵏⴰⵎⴰ', 'ⴷ', 'ⴰⵙⴷⴰⵍ', 'ⴷ', 'ⵏⴰ', 'ⴷⵓⵔ', 'Sunny', 'ⵢⵉⵙⵙ', 'ⵢⴰⵎⵙ', 'ⵏⴰ', 'ⴰⵏⵏ', 'ⴰⵎⵓ', 'ⵢⴰⵎⵙ'],
          AppLanguage.it: ['Alla', 'fine', 'della', 'giornata,', 'Sunny', 'si', 'sentì', 'felice', 'e', 'grato', 'per', 'i', 'suoi', 'amici.'],
          AppLanguage.ru: ['В', 'конце', 'дня', 'Санни', 'чувствовал', 'себя', 'счастливым', 'и', 'благодарным', 'своим', 'друзьям.'],
          AppLanguage.zh: ['在', '一天', '结束时，', 'Sunny', '感到', '快乐', '并且', '感激', '他的', '朋友们。'],
          AppLanguage.ko: ['하루가', '끝날', '무렵,', 'Sunny는', '행복하고', '친구들에게', '감사함을', '느꼈어요.'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/SquirrelSharing_Story.png',
        characterName: 'Sunny',
        funnyLine: 'Sunny\'s tail was fluffier than ever!',
      ),
    ],
  ),

  /// THIRD STORY EN /////

  Story(
    title: 'Nina the Sleepy Narwhal',
    thumbnail: 'assets/images/StoriesImages/StoriesCovers/NinaTheNarwhale_cover.png',
    pages: [
      // FIRST PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['In', 'the', 'deep', 'blue', 'sea,', 'lived', 'a', 'sleepy', 'narwhal', 'named', 'Nina.', 'She', 'loved', 'to', 'nap', 'everywhere—even', 'on', 'top', 'of', 'a', 'jellyfish!'],
          AppLanguage.fr: ['Dans', 'la', 'mer', 'bleue', 'profonde,', 'vivait', 'une', 'narval', 'endormie', 'nommée', 'Nina.', 'Elle', 'aimait', 'faire', 'la', 'sieste', 'partout—même', 'sur', 'le', 'dos', 'd\'une', 'méduse!'],
          AppLanguage.ar: ['في', 'البحر', 'الأزرق', 'العميق،', 'عاشت', 'حوت', 'نرجوال', 'الكسول', 'اسمه', 'نينا.', 'كانت', 'تحب', 'القيلولة', 'في', 'كل', 'مكان—حتى', 'فوق', 'قنديل', 'البحر!'],
          AppLanguage.de: ['Im', 'tiefen', 'blauen', 'Meer,', 'lebte', 'ein', 'schläfriger', 'Narwal', 'namens', 'Nina.', 'Sie', 'liebte', 'es,', 'überall', 'ein', 'Nickerchen', 'zu', 'machen—sogar', 'auf', 'einer', 'Qualle!'],
          AppLanguage.es: ['En', 'el', 'profundo', 'mar', 'azul,', 'vivía', 'una', 'narval', 'somnolienta', 'llamada', 'Nina.', 'Le', 'encantaba', 'dormitar', 'por', 'todas', 'partes—¡incluso', 'sobre', 'una', 'medusa!'],
          AppLanguage.amazigh: ['ⴰⵏⴰⵎⴰ', 'ⴷ', 'ⴰⵣⵓⵙ', 'ⵉⵎⵙⵙⵓⵏ,', 'ⵢⵉⵎⴰⵙ', 'ⴰⵏ', 'ⴰⵎⴰⵣⴰⵔ', 'ⴰⵏⵏⴰⵏ', 'ⵏⵉⵏⴰ.', 'ⵢⴰⵎⴰ', 'ⴷ', 'ⴰⵎⵙⵙⴰ', 'ⵢⵉⴷⵓ', 'ⵢⵉⵏ', 'ⴰⴷⵓ', 'ⵉⴷⴷⴰⵎ', 'ⴰⵏ', 'ⵢⵉⵙⵙⵓⵏ', 'ⴰⵎⵙⵙⴰ'],
          AppLanguage.it: ['Nel', 'profondo', 'mare', 'blu,', 'viveva', 'un', 'sonnolento', 'narvalo', 'di', 'nome', 'Nina.', 'Le', 'piaceva', 'fare', 'un', 'pisolino', 'ovunque—persino', 'sopra', 'una', 'medusa!'],
          AppLanguage.ru: ['В', 'глубоком', 'синем', 'море', 'жила', 'сонная', 'нарвалиха', 'по имени', 'Нина.', 'Она', 'любила', 'вздремнуть', 'везде—даже', 'наверху', 'медузы!'],
          AppLanguage.zh: ['在', '深蓝色', '的', '大海里，', '住着', '一只', '困倦的', '独角鲸', '名叫', 'Nina。', '她', '喜欢', '到处', '打盹——甚至', '在', '水母', '上面！'],
          AppLanguage.ko: ['깊고', '푸른', '바다에,', '잠꾸러기', '일각고래', 'Nina가', '살고', '있었어요.', '그녀는', '어디서든', '낮잠', '자는', '것을', '좋아했어요—심지어', '해파리', '위에서도요!'],
        },

        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaAndJellyFish_Story.png',
        characterName: 'Nina',
        funnyLine: 'Zzz... *BOING!* The jellyfish bounced her like a trampoline!',
      ),


      // SECOND PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['One', 'day,', 'Nina', 'tried', 'to', 'nap', 'on', 'a', 'sea', 'turtle,', 'but', 'it', 'started', 'swimming', 'fast!', 'Wheee!'],
          AppLanguage.fr: ['Un', 'jour,', 'Nina', 'a', 'essayé', 'de', 'faire', 'la', 'sieste', 'sur', 'une', 'tortue', 'de', 'mer,', 'mais', 'elle', 'a', 'commencé', 'à', 'nager', 'vite!', 'Wheee!'],
          AppLanguage.ar: ['في', 'يومٍ', 'ما،', 'حاولت', 'نينا', 'القيلولة', 'على', 'سلحفاة', 'بحرية،', 'لكن', 'بدأت', 'تسبح', 'بسرعة!', 'وييي!'],
          AppLanguage.de: ['Eines', 'Tages,', 'versuchte', 'Nina,', 'auf', 'einer', 'Meeresschildkröte', 'ein', 'Nickerchen', 'zu', 'machen,', 'aber', 'sie', 'begann', 'schnell', 'zu', 'schwimmen!', 'Wheee!'],
          AppLanguage.es: ['Un', 'día,', 'Nina', 'intentó', 'dormitar', 'sobre', 'una', 'tortuga', 'marina,', 'pero', 'empezó', 'a', 'nadar', 'rápido!', '¡Wheee!'],
          AppLanguage.amazigh: ['ⴰⵙⴷⴰⵍ', 'ⴷⵓⵔ,', 'Nina', 'ⴰⵎⵙⵙⴰ', 'ⴷ', 'ⴰⵎⵙⵙⴰ', 'ⴰⵏ', 'ⴰⵣⵓⵙ', 'ⴰⵏ', 'ⴰⵎⵙⵙⵓⵏ,', 'ⴷ', 'ⴰⵙⵙⴰ', 'ⵉⴷⴷⴰⵎ', 'ⴷ', 'ⴰⵎⵙⵙⴰ', 'Wheee!'],
          AppLanguage.it: ['Un', 'giorno,', 'Nina', 'ha', 'provato', 'a', 'fare', 'un', 'pisolino', 'su', 'una', 'tartaruga', 'marina,', 'ma', 'questa', 'ha', 'iniziato', 'a', 'nuotare', 'velocemente!', 'Wheee!'],
          AppLanguage.ru: ['Однажды', 'Нина', 'попробовала', 'вздремнуть', 'на', 'морской', 'черепахе,', 'но', 'она', 'начала', 'быстро', 'плавать!', 'Уиии!'],
          AppLanguage.zh: ['有一天，', 'Nina', '试着', '在', '一只', '海龟', '上', '打盹，', '但是', '它', '开始', '快速', '游泳！', '呼——！'],
          AppLanguage.ko: ['어느', '날,', 'Nina는', '바다거북', '위에서', '낮잠을', '자려', '했어요,', '하지만', '거북이가', '갑자기', '빠르게', '헤엄치기', '시작했어요!', '위이이!'],
        },
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaScreaming_Story.png',
        characterName: 'Speedy Turtle',
        funnyLine: 'Nina yelled, "I’m not a surfboard!" as she zoomed across the waves!',
      ),

      // THIRD PAGE
      StoryPageData(
        wordsByLang: {
          AppLanguage.en: ['At', 'last,', 'Nina', 'found', 'a', 'quiet', 'spot', 'on', 'a', 'rock.', 'But—SURPRISE!—it', 'was', 'a', 'sleeping', 'octopus!'],
          AppLanguage.fr: ['Enfin,', 'Nina', 'trouva', 'un', 'endroit', 'tranquille', 'sur', 'un', 'rocher.', 'Mais—SURPRISE!—c\'était', 'un', 'poulpe', 'endormi!'],
          AppLanguage.ar: ['أخيرًا،', 'وجدت', 'نينا', 'مكانًا', 'هادئًا', 'على', 'صخرة.', 'لكن—مفاجأة!—كان', 'أخطبوطًا', 'نائمًا!'],
          AppLanguage.de: ['Schließlich', 'fand', 'Nina', 'einen', 'ruhigen', 'Platz', 'auf', 'einem', 'Felsen.', 'Aber—ÜBERRASCHUNG!—es', 'war', 'ein', 'schlafender', 'Oktopus!'],
          AppLanguage.es: ['Al', 'final,', 'Nina', 'encontró', 'un', 'lugar', 'tranquilo', 'sobre', 'una', 'roca.', '¡Pero—SORPRESA!—era', 'un', 'pulpo', 'durmiendo!'],
          AppLanguage.amazigh: ['ⴰⵙⴷⴰⵍ,', 'Nina', 'ⴰⵎⵙⵙⴰ', 'ⴰⵏ', 'ⴰⵣⵓⵙ', 'ⵏⴰⴷ', 'ⴷ', 'ⴰⵎⵙⵙⵓⵏ', 'ⴰⵏ', 'ⴰⵎⵙⵙⴰ.', 'ⴷ—SURPRISE!—ⴰⵙ', 'ⴰⵏ', 'ⵓⴽⵜⵓⴱⵓⵙ', 'ⴰⵎⵙⵙⴰ'],
          AppLanguage.it: ['Alla', 'fine,', 'Nina', 'trovò', 'un', 'posto', 'tranquillo', 'su', 'una', 'roccia.', 'Ma—SORPRESA!—era', 'un', 'polpo', 'addormentato!'],
          AppLanguage.ru: ['Наконец', 'Нина', 'нашла', 'тихое', 'место', 'на', 'камне.', 'Но—СЮРПРИЗ!—это', 'был', 'спящий', 'осьминог!'],
          AppLanguage.zh: ['最后，', 'Nina', '找到', '了', '一块', '安静的', '岩石。', '但是——惊喜！——那是', '一只', '睡着的', '章鱼！'],
          AppLanguage.ko: ['마침내,', 'Nina는', '조용한', '바위', '위에서', '쉴', '자리를', '찾았어요.', '하지만—깜짝!—그건', '잠든', '문어였어요!'],
        },
        imageUrl: 'assets/images/StoriesImages/InsideStoriesImages/NinaAndOctopus_Story.png',
        characterName: 'Ollie the Octopus',
        funnyLine: 'Ollie woke up, gave her a hug with all 8 arms, and said, "Best nap ever!"',
      ),


    ],
  ),
];
