/// Cities and towns of Morocco, grouped by the 12 administrative regions
/// (2015 division). Latin (French) spelling + Arabic name.
///
/// The Latin name is what gets saved in the profile, so it stays stable
/// whatever language the app is in.
class MaRegion {
  final String fr;
  final String ar;
  const MaRegion(this.fr, this.ar);
}

class MaCity {
  final String fr;
  final String ar;
  final int region;
  const MaCity(this.fr, this.ar, this.region);

  String display(String languageCode) => languageCode == 'ar' ? ar : fr;
}

const List<MaRegion> maRegions = [
  MaRegion('Tanger-Tétouan-Al Hoceïma', 'طنجة تطوان الحسيمة'), // 0
  MaRegion("L'Oriental", 'الشرق'), // 1
  MaRegion('Fès-Meknès', 'فاس مكناس'), // 2
  MaRegion('Rabat-Salé-Kénitra', 'الرباط سلا القنيطرة'), // 3
  MaRegion('Béni Mellal-Khénifra', 'بني ملال خنيفرة'), // 4
  MaRegion('Casablanca-Settat', 'الدار البيضاء سطات'), // 5
  MaRegion('Marrakech-Safi', 'مراكش آسفي'), // 6
  MaRegion('Drâa-Tafilalet', 'درعة تافيلالت'), // 7
  MaRegion('Souss-Massa', 'سوس ماسة'), // 8
  MaRegion('Guelmim-Oued Noun', 'كلميم واد نون'), // 9
  MaRegion('Laâyoune-Sakia El Hamra', 'العيون الساقية الحمراء'), // 10
  MaRegion('Dakhla-Oued Ed-Dahab', 'الداخلة وادي الذهب'), // 11
];

/// Shown as quick-pick chips at the top of the city sheet.
const List<String> maPopularCities = [
  'Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger', 'Agadir',
  'Meknès', 'Oujda', 'Kénitra', 'Tétouan', 'Laâyoune', 'Dakhla',
];

const List<MaCity> maCities = [
  // 0 — Tanger-Tétouan-Al Hoceïma
  MaCity('Tanger', 'طنجة', 0),
  MaCity('Tétouan', 'تطوان', 0),
  MaCity('Al Hoceïma', 'الحسيمة', 0),
  MaCity('Larache', 'العرائش', 0),
  MaCity('Ksar El Kébir', 'القصر الكبير', 0),
  MaCity('Chefchaouen', 'شفشاون', 0),
  MaCity('Ouazzane', 'وزان', 0),
  MaCity('Asilah', 'أصيلة', 0),
  MaCity('Fnideq', 'الفنيدق', 0),
  MaCity("M'diq", 'المضيق', 0),
  MaCity('Martil', 'مرتيل', 0),
  MaCity('Imzouren', 'إمزورن', 0),
  MaCity('Targuist', 'تارجيست', 0),
  MaCity('Bni Bouayach', 'بني بوعياش', 0),
  MaCity('Oued Laou', 'واد لاو', 0),
  MaCity('Ksar Sghir', 'القصر الصغير', 0),
  MaCity('Jebha', 'الجبهة', 0),
  MaCity('Bab Taza', 'باب تازة', 0),
  MaCity('Gueznaia', 'اكزناية', 0),
  MaCity('Zinat', 'الزينات', 0),
  MaCity('Souk Tolba', 'سوق الطلبة', 0),

  // 1 — L'Oriental
  MaCity('Oujda', 'وجدة', 1),
  MaCity('Nador', 'الناظور', 1),
  MaCity('Berkane', 'بركان', 1),
  MaCity('Taourirt', 'تاوريرت', 1),
  MaCity('Guercif', 'جرسيف', 1),
  MaCity('Jerada', 'جرادة', 1),
  MaCity('Figuig', 'فجيج', 1),
  MaCity('Bouarfa', 'بوعرفة', 1),
  MaCity('Driouch', 'الدريوش', 1),
  MaCity('Zaïo', 'زايو', 1),
  MaCity('Selouane', 'سلوان', 1),
  MaCity('Al Aroui', 'العروي', 1),
  MaCity('Ben Taïeb', 'بن الطيب', 1),
  MaCity('Ahfir', 'أحفير', 1),
  MaCity('Saïdia', 'السعيدية', 1),
  MaCity('El Aïoun Sidi Mellouk', 'العيون سيدي ملوك', 1),
  MaCity('Bni Ansar', 'بني انصار', 1),
  MaCity('Midar', 'ميضار', 1),
  MaCity('Debdou', 'دبدو', 1),
  MaCity('Aïn Bni Mathar', 'عين بني مطهر', 1),
  MaCity('Touissit', 'تويسيت', 1),
  MaCity('Aklim', 'أكليم', 1),
  MaCity('Kariat Arekmane', 'قرية أركمان', 1),
  MaCity('Bni Drar', 'بني درار', 1),
  MaCity('Aïn Erreggada', 'عين الركادة', 1),
  MaCity('Tendrara', 'تندرارة', 1),

  // 2 — Fès-Meknès
  MaCity('Fès', 'فاس', 2),
  MaCity('Meknès', 'مكناس', 2),
  MaCity('Taza', 'تازة', 2),
  MaCity('Sefrou', 'صفرو', 2),
  MaCity('Ifrane', 'إفران', 2),
  MaCity('Azrou', 'أزرو', 2),
  MaCity('El Hajeb', 'الحاجب', 2),
  MaCity('Taounate', 'تاونات', 2),
  MaCity('Moulay Yacoub', 'مولاي يعقوب', 2),
  MaCity('Boulemane', 'بولمان', 2),
  MaCity('Missour', 'ميسور', 2),
  MaCity('Outat El Haj', 'أوطاط الحاج', 2),
  MaCity('Imouzzer Kandar', 'إيموزار كندر', 2),
  MaCity('El Menzel', 'المنزل', 2),
  MaCity('Bhalil', 'البهاليل', 2),
  MaCity('Tahla', 'تاهلة', 2),
  MaCity('Aïn Taoujdate', 'عين تاوجطات', 2),
  MaCity('Moulay Idriss Zerhoun', 'مولاي إدريس زرهون', 2),
  MaCity('Karia Ba Mohamed', 'قرية با محمد', 2),
  MaCity('Tissa', 'تيسة', 2),
  MaCity('Ghafsai', 'غفساي', 2),
  MaCity('Aknoul', 'أكنول', 2),
  MaCity('Oued Amlil', 'واد أمليل', 2),
  MaCity('Agourai', 'أكوراي', 2),
  MaCity('Boufakrane', 'بوفكران', 2),
  MaCity('Ribat El Kheir', 'رباط الخير', 2),
  MaCity('Imouzzer Marmoucha', 'إيموزار مرموشة', 2),
  MaCity('Sabaa Aiyoun', 'سبع عيون', 2),
  MaCity('Timahdite', 'تيمحضيت', 2),
  MaCity('Aïn Leuh', 'عين اللوح', 2),
  MaCity('Guigou', 'كيكو', 2),
  MaCity('Tainste', 'تايناست', 2),

  // 3 — Rabat-Salé-Kénitra
  MaCity('Rabat', 'الرباط', 3),
  MaCity('Salé', 'سلا', 3),
  MaCity('Kénitra', 'القنيطرة', 3),
  MaCity('Témara', 'تمارة', 3),
  MaCity('Skhirat', 'الصخيرات', 3),
  MaCity('Khémisset', 'الخميسات', 3),
  MaCity('Sidi Kacem', 'سيدي قاسم', 3),
  MaCity('Sidi Slimane', 'سيدي سليمان', 3),
  MaCity('Tiflet', 'تيفلت', 3),
  MaCity('Rommani', 'الرماني', 3),
  MaCity('Sidi Yahya El Gharb', 'سيدي يحيى الغرب', 3),
  MaCity('Mehdia', 'المهدية', 3),
  MaCity('Souk El Arbaa', 'سوق الأربعاء الغرب', 3),
  MaCity('Mechra Bel Ksiri', 'مشرع بلقصيري', 3),
  MaCity('Sidi Allal El Bahraoui', 'سيدي علال البحراوي', 3),
  MaCity('Aïn El Aouda', 'عين عودة', 3),
  MaCity('Harhoura', 'الهرهورة', 3),
  MaCity('Tamesna', 'تامسنا', 3),
  MaCity('Bouknadel', 'بوقنادل', 3),
  MaCity('Moulay Bousselham', 'مولاي بوسلهام', 3),
  MaCity('Dar Gueddari', 'دار الكداري', 3),
  MaCity('Sidi Taibi', 'سيدي الطيبي', 3),
  MaCity('Sidi Allal Tazi', 'سيدي علال التازي', 3),
  MaCity('Oulmès', 'والماس', 3),
  MaCity('Jorf El Melha', 'جرف الملحة', 3),
  MaCity('Had Kourt', 'حد كورت', 3),
  MaCity('Ain Johra', 'عين الجوهرة', 3),
  MaCity('Sidi Bouknadel', 'سيدي بوقنادل', 3),

  // 4 — Béni Mellal-Khénifra
  MaCity('Béni Mellal', 'بني ملال', 4),
  MaCity('Khouribga', 'خريبكة', 4),
  MaCity('Khénifra', 'خنيفرة', 4),
  MaCity('Fquih Ben Salah', 'الفقيه بن صالح', 4),
  MaCity('Azilal', 'أزيلال', 4),
  MaCity('Kasba Tadla', 'قصبة تادلة', 4),
  MaCity('Oued Zem', 'وادي زم', 4),
  MaCity('Souk Sebt Oulad Nemma', 'سوق السبت أولاد النمة', 4),
  MaCity('Bejaâd', 'أبي الجعد', 4),
  MaCity('Mrirt', 'مريرت', 4),
  MaCity('Demnate', 'دمنات', 4),
  MaCity('El Ksiba', 'القصيبة', 4),
  MaCity('Zaouiat Cheikh', 'زاوية الشيخ', 4),
  MaCity('Ouled Ayad', 'أولاد عياد', 4),
  MaCity('Boujniba', 'بوجنيبة', 4),
  MaCity('Hattane', 'حطان', 4),
  MaCity('Aguelmous', 'أكلموس', 4),
  MaCity('Lqbab', 'القباب', 4),
  MaCity('Bzou', 'بزو', 4),
  MaCity('Ouaouizeght', 'واويزغت', 4),
  MaCity('Tighassaline', 'تيغسالين', 4),
  MaCity('Dar Ould Zidouh', 'دار ولد زيدوح', 4),
  MaCity('Had Boumoussa', 'حد بوموسى', 4),
  MaCity('Beni Ayat', 'بني عياط', 4),
  MaCity('Afourer', 'أفورار', 4),
  MaCity('Foum Jamaa', 'فم الجمعة', 4),
  MaCity('Boulanouar', 'بولنوار', 4),

  // 5 — Casablanca-Settat
  MaCity('Casablanca', 'الدار البيضاء', 5),
  MaCity('Mohammédia', 'المحمدية', 5),
  MaCity('El Jadida', 'الجديدة', 5),
  MaCity('Settat', 'سطات', 5),
  MaCity('Berrechid', 'برشيد', 5),
  MaCity('Benslimane', 'بنسليمان', 5),
  MaCity('Sidi Bennour', 'سيدي بنور', 5),
  MaCity('Azemmour', 'أزمور', 5),
  MaCity('Bouskoura', 'بوسكورة', 5),
  MaCity('Nouaceur', 'النواصر', 5),
  MaCity('Médiouna', 'مديونة', 5),
  MaCity('Tit Mellil', 'تيط مليل', 5),
  MaCity('Dar Bouazza', 'دار بوعزة', 5),
  MaCity('Had Soualem', 'حد السوالم', 5),
  MaCity('Ben Ahmed', 'ابن أحمد', 5),
  MaCity('El Gara', 'الكارة', 5),
  MaCity('Bouznika', 'بوزنيقة', 5),
  MaCity('Lahraouyine', 'الهراويين', 5),
  MaCity('Deroua', 'الدروة', 5),
  MaCity('Oualidia', 'الوليدية', 5),
  MaCity('Zemamra', 'الزمامرة', 5),
  MaCity('Bir Jdid', 'البئر الجديد', 5),
  MaCity('Ouled Abbou', 'أولاد عبو', 5),
  MaCity('El Borouj', 'البروج', 5),
  MaCity('Oulad Said', 'أولاد سعيد', 5),
  MaCity('Sidi Smail', 'سيدي إسماعيل', 5),
  MaCity('Aïn Harrouda', 'عين حرودة', 5),
  MaCity('Bni Yakhlef', 'بني يخلف', 5),
  MaCity('Moulay Abdallah', 'مولاي عبد الله', 5),
  MaCity('Ouled Frej', 'أولاد فرج', 5),
  MaCity('Sidi Rahal Chatai', 'سيدي رحال الشاطئ', 5),
  MaCity('Loulad', 'لولاد', 5),
  MaCity('Sidi Hajjaj', 'سيدي حجاج', 5),
  MaCity('Ras El Ain', 'رأس العين', 5),

  // 6 — Marrakech-Safi
  MaCity('Marrakech', 'مراكش', 6),
  MaCity('Safi', 'آسفي', 6),
  MaCity('Essaouira', 'الصويرة', 6),
  MaCity('El Kelaâ des Sraghna', 'قلعة السراغنة', 6),
  MaCity('Youssoufia', 'اليوسفية', 6),
  MaCity('Ben Guerir', 'ابن جرير', 6),
  MaCity('Chichaoua', 'شيشاوة', 6),
  MaCity('Tahannaout', 'تحناوت', 6),
  MaCity('Amizmiz', 'أمزميز', 6),
  MaCity('Aït Ourir', 'أيت أورير', 6),
  MaCity('Tamansourt', 'تامنصورت', 6),
  MaCity('Jemaâ Shaim', 'جمعة سحيم', 6),
  MaCity('Sebt Gzoula', 'سبت كزولة', 6),
  MaCity('Chemaïa', 'الشماعية', 6),
  MaCity('Tamanar', 'تمنار', 6),
  MaCity('Imintanoute', 'إمنتانوت', 6),
  MaCity('Sidi Rahhal', 'سيدي رحال', 6),
  MaCity('Attaouia', 'العطاوية', 6),
  MaCity('Tamellalt', 'تملالت', 6),
  MaCity('Sid L\'Mokhtar', 'سيد المختار', 6),
  MaCity('Asni', 'أسني', 6),
  MaCity('Tameslouht', 'تامصلوحت', 6),
  MaCity('Lalla Takerkoust', 'لالة تكركوست', 6),
  MaCity('Sidi Bouzid', 'سيدي بوزيد', 6),
  MaCity('Had Draa', 'حد الدرا', 6),
  MaCity('Ounagha', 'أوناغة', 6),
  MaCity('Sidi Zouine', 'سيدي الزوين', 6),

  // 7 — Drâa-Tafilalet
  MaCity('Errachidia', 'الرشيدية', 7),
  MaCity('Ouarzazate', 'ورزازات', 7),
  MaCity('Zagora', 'زاكورة', 7),
  MaCity('Tinghir', 'تنغير', 7),
  MaCity('Midelt', 'ميدلت', 7),
  MaCity('Erfoud', 'أرفود', 7),
  MaCity('Rissani', 'الريصاني', 7),
  MaCity('Goulmima', 'كلميمة', 7),
  MaCity('Boumalne Dadès', 'بومالن دادس', 7),
  MaCity('Kelaât M\'Gouna', 'قلعة مكونة', 7),
  MaCity('Agdz', 'أكدز', 7),
  MaCity('Tazenakht', 'تازناخت', 7),
  MaCity('Er-Rich', 'الريش', 7),
  MaCity('Jorf', 'الجرف', 7),
  MaCity('Tinejdad', 'تنجداد', 7),
  MaCity('Alnif', 'ألنيف', 7),
  MaCity('Merzouga', 'مرزوكة', 7),
  MaCity('M\'Hamid El Ghizlane', 'امحاميد الغزلان', 7),
  MaCity('Tagounite', 'تاكونيت', 7),
  MaCity('Boudnib', 'بودنيب', 7),
  MaCity('Zaïda', 'زايدة', 7),
  MaCity('Imilchil', 'إملشيل', 7),
  MaCity('Skoura', 'سكورة', 7),
  MaCity('Aït Benhaddou', 'آيت بن حدو', 7),
  MaCity('Tamegroute', 'تامكروت', 7),
  MaCity('Aoufous', 'أوفوس', 7),

  // 8 — Souss-Massa
  MaCity('Agadir', 'أكادير', 8),
  MaCity('Inezgane', 'إنزكان', 8),
  MaCity('Aït Melloul', 'أيت ملول', 8),
  MaCity('Taroudant', 'تارودانت', 8),
  MaCity('Tiznit', 'تزنيت', 8),
  MaCity('Ouled Teïma', 'أولاد تايمة', 8),
  MaCity('Dcheira El Jihadia', 'الدشيرة الجهادية', 8),
  MaCity('Biougra', 'بيوكرى', 8),
  MaCity('Aït Baha', 'آيت باها', 8),
  MaCity('Tata', 'طاطا', 8),
  MaCity('Tafraout', 'تافراوت', 8),
  MaCity('Taliouine', 'تالوين', 8),
  MaCity('Massa', 'ماسة', 8),
  MaCity('Lqliâa', 'القليعة', 8),
  MaCity('Drarga', 'الدراركة', 8),
  MaCity('Temsia', 'التمسية', 8),
  MaCity('Aourir', 'أورير', 8),
  MaCity('Tamraght', 'تمراغت', 8),
  MaCity('Taghazout', 'تغازوت', 8),
  MaCity('Aoulouz', 'أولوز', 8),
  MaCity('Igherm', 'إغرم', 8),
  MaCity('Aït Iaaza', 'آيت إعزة', 8),
  MaCity('Sebt El Guerdane', 'سبت الكردان', 8),
  MaCity('Oulad Berhil', 'أولاد برحيل', 8),
  MaCity('Akka', 'أقا', 8),
  MaCity('Fam El Hisn', 'فم الحصن', 8),
  MaCity('Foum Zguid', 'فم زكيد', 8),
  MaCity('Belfaa', 'بلفاع', 8),
  MaCity('Anza', 'أنزا', 8),

  // 9 — Guelmim-Oued Noun
  MaCity('Guelmim', 'كلميم', 9),
  MaCity('Tan-Tan', 'طانطان', 9),
  MaCity('Sidi Ifni', 'سيدي إفني', 9),
  MaCity('Assa', 'أسا', 9),
  MaCity('Zag', 'الزاك', 9),
  MaCity('Bouizakarne', 'بويزكارن', 9),
  MaCity('El Ouatia', 'الوطية', 9),
  MaCity('Mirleft', 'ميرلفت', 9),
  MaCity('Taghjijt', 'تاغجيجت', 9),
  MaCity('Lakhsas', 'الأخصاص', 9),

  // 10 — Laâyoune-Sakia El Hamra
  MaCity('Laâyoune', 'العيون', 10),
  MaCity('Boujdour', 'بوجدور', 10),
  MaCity('Tarfaya', 'طرفاية', 10),
  MaCity('Es-Semara', 'السمارة', 10),
  MaCity('El Marsa', 'المرسى', 10),
  MaCity('Foum El Oued', 'فم الواد', 10),
  MaCity('Daoura', 'الدورة', 10),

  // 11 — Dakhla-Oued Ed-Dahab
  MaCity('Dakhla', 'الداخلة', 11),
  MaCity('Aousserd', 'أوسرد', 11),
  MaCity('Bir Gandouz', 'بئر كندوز', 11),
  MaCity('Bir Anzarane', 'بئر أنزران', 11),
  MaCity('Lagouira', 'لكويرة', 11),
];

/// Lower-case, accent- and hamza-insensitive key for search.
String maSearchKey(String s) {
  const map = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e',
    'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o',
    'ó': 'o', 'û': 'u', 'ù': 'u', 'ü': 'u', 'ú': 'u', "'": '', '-': ' ',
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ة': 'ه', 'ى': 'ي',
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(map[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Countries offered in the picker (Morocco first). Names in en/fr/ar;
/// other languages fall back to English.
class KidCountry {
  final String code; // ISO-3166 alpha-2
  final String en, fr, ar;
  const KidCountry(this.code, this.en, this.fr, this.ar);

  String display(String lang) {
    switch (lang) {
      case 'fr':
        return fr;
      case 'ar':
        return ar;
      case 'de':
        return _de[code] ?? en;
      case 'zgh':
        return code == 'MA' ? 'ⵍⵎⵖⵔⵉⴱ' : en;
      default:
        return en;
    }
  }

  /// Emoji flag from the ISO code.
  String get flag => String.fromCharCodes(
      code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  static const _de = {
    'MA': 'Marokko', 'DZ': 'Algerien', 'TN': 'Tunesien', 'EG': 'Ägypten',
    'FR': 'Frankreich', 'BE': 'Belgien', 'ES': 'Spanien', 'DE': 'Deutschland',
    'IT': 'Italien', 'NL': 'Niederlande', 'GB': 'Vereinigtes Königreich',
    'CA': 'Kanada', 'US': 'Vereinigte Staaten', 'SA': 'Saudi-Arabien',
    'AE': 'Vereinigte Arabische Emirate', 'QA': 'Katar', 'MR': 'Mauretanien',
    'SN': 'Senegal', 'CH': 'Schweiz', 'TR': 'Türkei', 'LY': 'Libyen',
    'PT': 'Portugal', 'SE': 'Schweden', 'KW': 'Kuwait',
  };
}

const List<KidCountry> kidCountries = [
  KidCountry('MA', 'Morocco', 'Maroc', 'المغرب'),
  KidCountry('DZ', 'Algeria', 'Algérie', 'الجزائر'),
  KidCountry('TN', 'Tunisia', 'Tunisie', 'تونس'),
  KidCountry('MR', 'Mauritania', 'Mauritanie', 'موريتانيا'),
  KidCountry('LY', 'Libya', 'Libye', 'ليبيا'),
  KidCountry('EG', 'Egypt', 'Égypte', 'مصر'),
  KidCountry('SN', 'Senegal', 'Sénégal', 'السنغال'),
  KidCountry('FR', 'France', 'France', 'فرنسا'),
  KidCountry('BE', 'Belgium', 'Belgique', 'بلجيكا'),
  KidCountry('ES', 'Spain', 'Espagne', 'إسبانيا'),
  KidCountry('DE', 'Germany', 'Allemagne', 'ألمانيا'),
  KidCountry('IT', 'Italy', 'Italie', 'إيطاليا'),
  KidCountry('NL', 'Netherlands', 'Pays-Bas', 'هولندا'),
  KidCountry('PT', 'Portugal', 'Portugal', 'البرتغال'),
  KidCountry('CH', 'Switzerland', 'Suisse', 'سويسرا'),
  KidCountry('SE', 'Sweden', 'Suède', 'السويد'),
  KidCountry('GB', 'United Kingdom', 'Royaume-Uni', 'المملكة المتحدة'),
  KidCountry('CA', 'Canada', 'Canada', 'كندا'),
  KidCountry('US', 'United States', 'États-Unis', 'الولايات المتحدة'),
  KidCountry('TR', 'Turkey', 'Turquie', 'تركيا'),
  KidCountry('SA', 'Saudi Arabia', 'Arabie saoudite', 'السعودية'),
  KidCountry('AE', 'United Arab Emirates', 'Émirats arabes unis', 'الإمارات'),
  KidCountry('QA', 'Qatar', 'Qatar', 'قطر'),
  KidCountry('KW', 'Kuwait', 'Koweït', 'الكويت'),
];

/// Finds a country from a stored value (any language or ISO code).
KidCountry? kidCountryFromStored(String stored) {
  final k = maSearchKey(stored);
  if (k.isEmpty) return null;
  for (final c in kidCountries) {
    if (k == c.code.toLowerCase() ||
        k == maSearchKey(c.en) ||
        k == maSearchKey(c.fr) ||
        k == maSearchKey(c.ar) ||
        k == maSearchKey(c.display('de')) ||
        (c.code == 'MA' && (k == 'maroc' || k == 'marokko' || k == 'ⵍⵎⵖⵔⵉⴱ'))) {
      return c;
    }
  }
  return null;
}

/// Finds a Moroccan city from a stored value (Latin or Arabic).
MaCity? maCityFromStored(String stored) {
  final k = maSearchKey(stored);
  if (k.isEmpty) return null;
  for (final c in maCities) {
    if (maSearchKey(c.fr) == k || maSearchKey(c.ar) == k) return c;
  }
  return null;
}
