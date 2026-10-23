// Texts of the Arabic games (always in Arabic). Looked up by m1T().

const Map<String, String> arS = {
  'arabic_mathTitle': 'اللغة العربية', 'arabic_grade': 'السنة الأولى ابتدائي', 'arabic_homeSay': 'أهلًا! هيا نتعلم ونلعب مع الحروف والكلمات',
  'arabic_learnPlaying': 'أتعلم وألعب مع واكي', 'arabic_mapTitle': 'مغامرتي مع العربية', 'arabic_bravo': 'أحسنت! أنت تتقدم', 'arabic_bravoTop': 'رائع! أحسنت يا بطل',
  'ar_wait_listen': 'اضغط على مكبر الصوت لتسمع أولًا', 'ar_tap_speaker': 'اضغط على مكبر الصوت لتسمع',
  'ar_dict': 'معجمي المصور', 'ar_dict_later': 'أكتشفها لاحقًا', 'ar_dict_count': 'تعلمت {n} كلمات من {t}', 'ar_dict_listen': 'أستمع إلى الكلمة',
  'ar_dict_play': 'ألعب بهذه الكلمة', 'ar_dict_more': 'أواصل مغامرتي', 'ar_cat_animals': 'الحيوانات', 'ar_cat_school': 'المدرسة', 'ar_cat_home': 'البيت',
  'ar_dict_say': 'كلمات أتعلمها وأعود إليها',

  // حديقة الحروف
  'letters_t1': 'حديقة', 'letters_t2': 'الحروف', 'letters_tag': 'أتعرف الحروف وأميزها', 'letters_home': 'أتعرف الحروف وأميزها', 'letters_short': 'الحروف',
  'letters_tip': 'انتبه إلى النقاط فوق الحروف وتحتها', 'letters_m0': 'أتعرف', 'letters_m1': 'أبحث', 'letters_m2': 'المتشابهة',
  'letters_r0': 'ا — ذ', 'letters_r1': 'ر — ع', 'letters_r2': 'غ — ي',
  'letters_h1': 'استمع إلى اسم الحرف', 'letters_h2': 'المس الحرف الصحيح', 'letters_h3': 'انتبه إلى شكل الحرف ونقاطه',
  'letters_c1': 'تعرفت الحروف', 'letters_c2': 'بحثت عن الحروف', 'letters_c3': 'ميزت النقاط',
  'letters_badge0': 'صديق الحروف', 'letters_badge1': 'مستكشف الحروف', 'letters_badge2': 'بطل الحروف',
  'al_letter': 'حرف', 'al_q_find': 'أين حرف ال{n}؟', 'al_q_all': 'جد كل حروف ال{n}', 'al_twins': 'أي حرف يشبه هذا الحرف تمامًا؟', 'al_yes': 'نعم! هذا حرف ال',
  'al_rev_shape': 'شكل الحرف', 'al_rev_twins': 'النقاط تغير الحرف', 'al_help_shape': 'استمع جيدًا ثم انظر إلى شكل الحرف', 'al_help_dots': 'عد النقاط وانظر أين هي: فوق أم تحت؟',

  // أسمع وأكتشف
  'sounds_t1': 'أسمع', 'sounds_t2': 'وأكتشف', 'sounds_tag': 'أميز أصوات الحروف', 'sounds_home': 'أميز أصوات الحروف', 'sounds_short': 'الأصوات',
  'sounds_tip': 'استمع جيدًا إلى أول صوت في الكلمة', 'sounds_m0': 'أستمع', 'sounds_m1': 'أول صوت', 'sounds_m2': 'نفس الصوت',
  'sounds_r0': 'الحيوانات', 'sounds_r1': 'المدرسة والبيت', 'sounds_r2': 'كل الكلمات',
  'sounds_h1': 'اضغط على مكبر الصوت', 'sounds_h2': 'استمع إلى الكلمة جيدًا', 'sounds_h3': 'اختر الصورة أو الحرف الصحيح',
  'sounds_c1': 'استمعت جيدًا', 'sounds_c2': 'ميزت الأصوات', 'sounds_c3': 'تعلمت كلمات جديدة',
  'sounds_badge0': 'الأذن الذكية', 'sounds_badge1': 'محقق الأصوات', 'sounds_badge2': 'بطل الأصوات',
  'as_q_listen': 'استمع ثم اختر الصورة', 'as_q_first': 'بأي حرف تبدأ هذه الكلمة؟', 'as_q_same': 'جد كل الصور التي تبدأ بصوت ال{n}', 'as_same_v': 'كلمات تبدأ بحرف ال',
  'as_starts': 'تبدأ بحرف ال', 'as_rev_listen': 'الاستماع إلى الكلمة', 'as_rev_first': 'أول صوت في الكلمة', 'as_rev_same': 'الكلمات التي تبدأ بنفس الصوت',
  'as_help_listen': 'استمع مرة أخرى ثم انظر إلى الصور', 'as_help_first': 'قل الكلمة ببطء: ما أول صوت تسمعه؟', 'as_help_same': 'قل اسم كل صورة واسمع أول صوت',

  // قطار الحركات
  'harakat_t1': 'قطار', 'harakat_t2': 'الحركات', 'harakat_tag': 'أتعلم الفتحة والضمة والكسرة', 'harakat_home': 'أتعلم الفتحة والضمة والكسرة', 'harakat_short': 'الحركات',
  'harakat_tip': 'الفتحة فوق، والكسرة تحت، والضمة واو صغيرة', 'harakat_m0': 'أسمع', 'harakat_m1': 'أركّب', 'harakat_m2': 'أقرأ',
  'harakat_r0': 'ب ت ن م', 'harakat_r1': 'د ر س ش', 'harakat_r2': 'ك ق ع ج',
  'harakat_h1': 'استمع إلى صوت الحرف', 'harakat_h2': 'اسحب الحركة إلى الحرف', 'harakat_h3': 'اقرأ الحرف مع حركته',
  'harakat_c1': 'سمعت الحركات', 'harakat_c2': 'ركبت الحركات', 'harakat_c3': 'قرأت الحروف',
  'harakat_badge0': 'راكب القطار', 'harakat_badge1': 'سائق الحركات', 'harakat_badge2': 'قائد القطار',
  'ah_q_listen': 'استمع ثم اختر العربة الصحيحة', 'ah_q_build': 'اسحب الحركة ليقول الحرف: {s}', 'ah_q_read': 'ما اسم الحركة على هذا الحرف؟',
  'ah_n_fatha': 'فَتْحَة', 'ah_n_damma': 'ضَمَّة', 'ah_n_kasra': 'كَسْرَة',
  'ah_rev_fatha': 'الفتحة فوق الحرف وصوتها: آ', 'ah_rev_damma': 'الضمة فوق الحرف وصوتها: أو', 'ah_rev_kasra': 'الكسرة تحت الحرف وصوتها: إي',
  'ah_help_fatha': 'الفتحة خط صغير فوق الحرف', 'ah_help_damma': 'الضمة مثل واو صغيرة فوق الحرف', 'ah_help_kasra': 'الكسرة خط صغير تحت الحرف',

  // كلمتي وصورتي
  'words_t1': 'كلمتي', 'words_t2': 'وصورتي', 'words_tag': 'أصل الكلمة بالصورة', 'words_home': 'أصل الكلمة بالصورة', 'words_short': 'الكلمات',
  'words_tip': 'كلمات جديدة أكتشفها كل يوم', 'words_m0': 'أصل', 'words_m1': 'أقرأ', 'words_m2': 'أستمع',
  'words_r0': 'الحيوانات', 'words_r1': 'المدرسة', 'words_r2': 'البيت',
  'words_h1': 'انظر إلى الصورة', 'words_h2': 'اقرأ الكلمة أو استمع إليها', 'words_h3': 'صل الكلمة بصورتها',
  'words_c1': 'قرأت الكلمات', 'words_c2': 'وصلت الكلمات بالصور', 'words_c3': 'تعلمت كلمات جديدة',
  'words_badge0': 'قارئ صغير', 'words_badge1': 'مستكشف الكلمات', 'words_badge2': 'بطل الكلمات',
  'aw_q_match': 'اسحب الكلمة إلى صورتها', 'aw_q_read': 'اقرأ الكلمة واختر صورتها', 'aw_q_listen': 'استمع ثم اختر الكلمة',
  'aw_this': 'هذا', 'aw_rev': 'قراءة الكلمات', 'aw_help': 'اقرأ الكلمة حرفًا حرفًا', 'aw_help_drag': 'اقرأ الكلمات ثم اسحب الصحيحة إلى الصورة',

  // جملتي الأولى
  'sentences_t1': 'جملتي', 'sentences_t2': 'الأولى', 'sentences_tag': 'أرتب الكلمات وأفهم الجملة', 'sentences_home': 'أرتب كلمات جملة بسيطة',
  'sentences_short': 'الجمل', 'sentences_tip': 'لكل صورة جملة تحكي عنها', 'sentences_m0': 'أستمع', 'sentences_m1': 'أرتّب', 'sentences_m2': 'أفهم',
  'sentences_r0': '٣ كلمات', 'sentences_r1': '٤ كلمات', 'sentences_r2': 'تحديات صغيرة',
  'sentences_h1': 'استمع إلى الجملة', 'sentences_h2': 'ابدأ من اليمين', 'sentences_h3': 'رتب الكلمات لتكوين جملة',
  'sentences_c1': 'استمعت إلى الجمل', 'sentences_c2': 'رتبت الكلمات', 'sentences_c3': 'فهمت الجمل',
  'sentences_badge0': 'كاتب صغير', 'sentences_badge1': 'صانع الجمل', 'sentences_badge2': 'بطل الجمل',
  'ase_q_listen': 'استمع ثم رتب الكلمات', 'ase_q_order': 'رتب الكلمات لتكوين جملة', 'ase_q_understand': 'أي جملة تحكي عن الصورة؟',
  'ase_rev_order': 'ترتيب كلمات الجملة', 'ase_rev_understand': 'فهم الجملة', 'ase_help_first': 'ابدأ من اليمين: من يقوم بالعمل؟',
  'ase_help_next': 'ما الكلمة التي تأتي بعدها؟', 'ase_help_understand': 'انظر إلى الصورة ثم اقرأ كل جملة', 'ase_placed': '{n} من {t} كلمات',
};
