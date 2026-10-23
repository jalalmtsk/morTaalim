// Texts of the French course. The course is always shown in French
// (the world has lang 'fr'); a few shared keys also exist in English/Arabic.

const Map<String, Map<String, String>> frS = {
  'fr': {
    'soonSay': 'Ce jeu arrive très bientôt !',
    // world
    'french_mathTitle': 'Français',
    'french_grade': '1re année primaire',
    'french_homeSay': 'Choisis un jeu : écoute, découvre et joue !',
    'french_learnPlaying': 'Écoute, découvre et joue !',
    'french_mapTitle': 'Mon aventure en français',
    'french_bravo': 'Bravo, tu progresses en français !',
    'french_bravoTop': 'Parfait, petit lecteur !',
    'fr_wait_listen': 'Touche d\'abord le haut-parleur pour écouter !',
    'fr_tap_speaker': 'Touche le haut-parleur pour écouter.',

    // 1 · La forêt des lettres
    'lettres_t1': 'La forêt', 'lettres_t2': 'des lettres', 'lettres_home': 'Reconnais les lettres',
    'lettres_tag': 'Chaque lettre ouvre une aventure !', 'lettres_short': 'Lettres', 'lettres_tip': 'Observe, écoute et découvre les lettres !',
    'lettres_m0': 'Je reconnais', 'lettres_m1': 'Majuscule et minuscule', 'lettres_m2': 'Le début du mot',
    'lettres_r0': 'A à H', 'lettres_r1': 'I à Q', 'lettres_r2': 'R à Z',
    'lettres_h1': 'Écoute le nom de la lettre.', 'lettres_h2': 'Regarde bien sa forme.', 'lettres_h3': 'Touche la bonne lettre !',
    'lettres_c1': 'J\'ai écouté les lettres', 'lettres_c2': 'J\'ai reconnu les formes', 'lettres_c3': 'J\'ai trouvé le début des mots',
    'lettres_badge0': 'Petit explorateur', 'lettres_badge1': 'Ami des lettres', 'lettres_badge2': 'Roi de l\'alphabet',
    'fl_letter': 'la lettre {l}', 'fl_q_find': 'Écoute et touche la bonne lettre !', 'fl_q_case': 'Trouve la petite lettre de {l} !',
    'fl_q_first': 'Par quelle lettre commence ce mot ?', 'fl_rev_name': 'Le nom des lettres', 'fl_help_listen': 'Réécoute le nom de la lettre.',
    'fl_rev_case': 'Majuscules et minuscules', 'fl_help_case': 'Regarde bien : la petite lettre a souvent une autre forme.',
    'fl_rev_first': 'La première lettre d\'un mot', 'fl_help_first': 'Dis le mot doucement : quelle lettre entends-tu au début ?',
    'fl_yes': 'Oui ! C\'est la lettre {l}.', 'fl_yes_case': 'Bravo ! Grand {l}, petit {l}.', 'fl_yes_first': '{w} commence par la lettre {l} !',

    // 2 · Le détective des sons
    'sons_t1': 'Le détective', 'sons_t2': 'des sons', 'sons_home': 'Écoute et trouve le son',
    'sons_tag': 'Ouvre grand tes oreilles !', 'sons_short': 'Sons', 'sons_tip': 'Écoute les mots, repère les sons !',
    'sons_m0': 'J\'écoute', 'sons_m1': 'Le premier son', 'sons_m2': 'Même son',
    'sons_r0': 'Les animaux', 'sons_r1': 'École et maison', 'sons_r2': 'Défi',
    'sons_h1': 'Touche le haut-parleur et écoute.', 'sons_h2': 'Cherche le son au début du mot.', 'sons_h3': 'Trouve toutes les images !',
    'sons_c1': 'J\'ai bien écouté', 'sons_c2': 'J\'ai trouvé le premier son', 'sons_c3': 'J\'ai mené l\'enquête',
    'sons_badge0': 'Petite oreille', 'sons_badge1': 'Détective', 'sons_badge2': 'Super détective',
    'fs_same_v': 'Trouve les mots qui commencent comme {w}.', 'fs_q_listen': 'Écoute le mot et touche son image.',
    'fs_q_first': 'Quel son entends-tu au début du mot ?', 'fs_q_same': 'Trouve les images qui commencent par « {s} », comme {w} !',
    'fs_rev_listen': 'Écouter un mot', 'fs_help_listen': 'Réécoute bien le mot.', 'fs_rev_first': 'Le premier son d\'un mot',
    'fs_help_first': 'Dis le mot lentement et écoute le début.', 'fs_rev_same': 'Les mots qui commencent pareil',
    'fs_help_same': 'Dis chaque mot à voix haute : commence-t-il pareil ?', 'fs_yes_first': '{w} commence par « {s} » !',

    // 3 · Le train des syllabes
    'syllabes_t1': 'Le train', 'syllabes_t2': 'des syllabes', 'syllabes_home': 'Assemble des syllabes simples',
    'syllabes_tag': 'Assemble les syllabes, découvre les mots !', 'syllabes_short': 'Syllabes', 'syllabes_tip': 'Un wagon, une syllabe !',
    'syllabes_m0': 'J\'écoute', 'syllabes_m1': 'J\'assemble', 'syllabes_m2': 'Je lis',
    'syllabes_r0': 'm · l · r', 'syllabes_r1': 'p · t · s · n', 'syllabes_r2': 'Défi',
    'syllabes_h1': 'Écoute la syllabe.', 'syllabes_h2': 'Glisse la voyelle dans le wagon.', 'syllabes_h3': 'Lis les wagons et trouve l\'image !',
    'syllabes_c1': 'J\'ai écouté les syllabes', 'syllabes_c2': 'J\'ai assemblé des sons', 'syllabes_c3': 'J\'ai lu des mots',
    'syllabes_badge0': 'Petit passager', 'syllabes_badge1': 'Chef de gare', 'syllabes_badge2': 'Conducteur de train',
    'fy_q_listen': 'Écoute et trouve la bonne syllabe.', 'fy_q_build': 'Fais « {s} » : glisse la bonne voyelle dans le wagon !',
    'fy_q_read': 'Lis les wagons : quel est ce mot ?', 'fy_rev_listen': 'Reconnaître une syllabe', 'fy_help_listen': 'Réécoute la syllabe.',
    'fy_rev_build': 'Assembler une consonne et une voyelle', 'fy_help_build': 'Écoute bien la fin de la syllabe.',
    'fy_rev_read': 'Lire un mot syllabe par syllabe', 'fy_help_read': 'Lis un wagon après l\'autre.', 'fy_yes_build': '{c} et {v}, ça fait « {s} » !',

    // 4 · Les mots en images
    'mots_t1': 'Les mots', 'mots_t2': 'en images', 'mots_home': 'Associe un mot à son image',
    'mots_tag': 'Lis le mot ou écoute-le !', 'mots_short': 'Mots', 'mots_tip': 'Des mots à écouter et à retrouver !',
    'mots_m0': 'Je place', 'mots_m1': 'Je lis', 'mots_m2': 'J\'écoute',
    'mots_r0': 'Les animaux', 'mots_r1': 'L\'école', 'mots_r2': 'La maison',
    'mots_h1': 'Regarde les images.', 'mots_h2': 'Glisse chaque mot sous la bonne image.', 'mots_h3': 'Vérifie : tout est bien placé ?',
    'mots_c1': 'J\'ai lu des mots', 'mots_c2': 'J\'ai associé mots et images', 'mots_c3': 'J\'ai rempli mon imagier',
    'mots_badge0': 'Petit lecteur', 'mots_badge1': 'Explorateur des mots', 'mots_badge2': 'Champion des mots',
    'fw_q_match': 'Place chaque mot sous la bonne image.', 'fw_q_read': 'Lis le mot et touche son image.', 'fw_q_listen': 'Écoute et touche le bon mot.',
    'fw_rev': 'Lire un mot', 'fw_help_match': 'Glisse le mot sous son image, comme ça !', 'fw_help': 'Lis le mot lettre par lettre.',
    'fw_all': 'Bravo ! Tous les mots sont à leur place !', 'fw_what': 'Choisis d\'abord un mot en bas !', 'fw_placed': '{n} / 3 mots placés',

    // 5 · Ma première phrase
    'phrases_t1': 'Ma première', 'phrases_t2': 'phrase', 'phrases_home': 'Remets les mots dans l\'ordre',
    'phrases_tag': 'Des mots qui racontent une histoire !', 'phrases_short': 'Phrases', 'phrases_tip': 'Une image pour comprendre, des mots pour raconter !',
    'phrases_m0': 'J\'écoute', 'phrases_m1': 'Je mets en ordre', 'phrases_m2': 'Je comprends',
    'phrases_r0': '3 mots', 'phrases_r1': '4 à 5 mots', 'phrases_r2': 'Petits défis',
    'phrases_h1': 'Écoute la phrase.', 'phrases_h2': 'Déplace les mots dans l\'ordre.', 'phrases_h3': 'Vérifie avec l\'image !',
    'phrases_c1': 'J\'ai écouté la phrase', 'phrases_c2': 'J\'ai mis les mots en ordre', 'phrases_c3': 'J\'ai compris l\'image',
    'phrases_badge0': 'Petit conteur', 'phrases_badge1': 'Bâtisseur de phrases', 'phrases_badge2': 'Grand lecteur',
    'fp_q_listen': 'Écoute la phrase, puis remets les mots dans l\'ordre.', 'fp_q_order': 'Remets les mots dans l\'ordre.',
    'fp_q_understand': 'Quelle phrase va avec l\'image ?', 'fp_rev_understand': 'Comprendre une phrase', 'fp_help_understand': 'Qui voit-on ? Que fait-il ?',
    'fp_rev_order': 'L\'ordre des mots', 'fp_help_first': 'Une phrase commence par une majuscule !', 'fp_help_next': 'Quel mot vient ensuite ? Regarde l\'image.',
    'fp_placed': '{n} / {t} mots placés',

    // Mon imagier magique
    'fi_title': 'Mon imagier magique', 'fi_say': 'Des mots à écouter et à retrouver !', 'fi_cat_animals': 'Animaux', 'fi_cat_school': 'École',
    'fi_cat_home': 'Maison', 'fi_count': '{n} mots découverts sur {t}', 'fi_continue': 'Continuer mon aventure', 'fi_later': 'À découvrir',
    'fi_listen': 'Écouter le mot', 'fi_replay': 'Rejouer avec ce mot',
  },
  'en': {'soonSay': 'This game is coming very soon!'},
  'ar': {'soonSay': 'هذه اللعبة قادمة قريبًا جدًا!'},
};
