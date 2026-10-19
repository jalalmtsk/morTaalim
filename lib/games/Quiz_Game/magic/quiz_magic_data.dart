import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ModeSelectorPage.dart';
import '../Questions.dart';
import '../question_model.dart';

part 'quiz_magic_keys.dart';

// ── assets ─────────────────────────────────────────────────────────────────

const String qmDir = 'assets/images/UI/KidScene/';
const String qmImgBg = '${qmDir}it_page_bg.webp';
const String qmImgBack = '${qmDir}qz_back.webp';
const String qmImgGear = '${qmDir}qz_gear.webp';
const String qmImgTitle = '${qmDir}qz_title.webp';
const String qmImgStar = '${qmDir}qz_star.webp';
const String qmImgStarEmpty = '${qmDir}qz_star_empty.webp';
const String qmImgBigStar = '${qmDir}qz_big_star.webp';
const String qmImgBubble = '${qmDir}qz_bubble.webp';
const String qmImgSpeaker = '${qmDir}qz_speaker.webp';
const String qmImgLetter = '${qmDir}qz_letter.webp';
const String qmImgBadgeOk = '${qmDir}qz_badge_ok.webp';
const String qmImgBadgeX = '${qmDir}qz_badge_x.webp';
const String qmImgBigCheck = '${qmDir}qz_big_check.webp';
const String qmImgPaw = '${qmDir}qz_paw.webp';
const String qmImgBadge = '${qmDir}qz_badge.webp';
const String qmImgRobotPeek = '${qmDir}qz_robot_peek.webp';
const String qmImgRobotStand = '${qmDir}qz_robot_stand.webp';
const String qmImgWinScene = '${qmDir}qz_win_scene.webp';
const String qmImgRetryDuo = '${qmDir}qz_retry_duo.webp';
const String qmImgRetryGround = '${qmDir}qz_retry_ground.webp';
const String qmImgHome = '${qmDir}qz_home.webp';
const String qmImgBook = '${qmDir}qz_book.webp';
const String qmImgRefresh = '${qmDir}qz_refresh.webp';
const String qmImgBush1 = '${qmDir}qz_bush1.webp';
const String qmImgBush2 = '${qmDir}qz_bush2.webp';
const String qmImgFlowers = '${qmDir}qz_flowers_r.webp';
const String qmImgLeaves1 = '${qmDir}qz_leaves1.webp';
const String qmImgLeaves2 = '${qmDir}qz_leaves2.webp';
const String qmImgWoodSign = '${qmDir}qz_wood_sign.webp';

const String qmImgRobotLens = '${qmDir}qm_robot_lens.webp';
const String qmImgRobotPoint = '${qmDir}qm_robot_point.webp';
const String qmImgCheck = '${qmDir}qm_check.webp';
const String qmImgLvlEasy = '${qmDir}qm_lvl_easy.webp';
const String qmImgLvlMid = '${qmDir}qm_lvl_mid.webp';
const String qmImgLvlHard = '${qmDir}qm_lvl_hard.webp';
const String qmImgPersonBlue = '${qmDir}qm_person_blue.webp';
const String qmImgPersonPink = '${qmDir}qm_person_pink.webp';
const String qmImgHandsTablet = '${qmDir}qm_hands_tablet.webp';
const String qmImgWinnerPodium = '${qmDir}qm_winner_podium.webp';
const String qmImgTrophy = '${qmDir}qm_trophy.webp';
const String qmImgCrown = '${qmDir}qm_crown.webp';
const String qmImgRibbon = '${qmDir}qm_ribbon.webp';
const String qmImgVs = '${qmDir}qm_vs.webp';
const String qmImgTwoPlayers = '${qmDir}qm_two_players.webp';
const String qmImgAvRobot = '${qmDir}qm_av_robot.webp';

const List<String> qmAllImages = [
  qmImgRobotLens, qmImgRobotPoint, qmImgCheck, qmImgLvlEasy, qmImgLvlMid, qmImgLvlHard, qmImgPersonBlue,
  qmImgPersonPink, qmImgHandsTablet, qmImgWinnerPodium, qmImgTrophy, qmImgCrown, qmImgRibbon, qmImgVs,
  qmImgTwoPlayers, qmImgAvRobot,
  qmImgBg, qmImgBack, qmImgGear, qmImgTitle, qmImgStar, qmImgStarEmpty, qmImgBigStar, qmImgBubble,
  qmImgSpeaker, qmImgLetter, qmImgBadgeOk, qmImgBadgeX, qmImgBigCheck, qmImgPaw, qmImgBadge,
  qmImgRobotPeek, qmImgRobotStand, qmImgWinScene, qmImgRetryDuo, qmImgRetryGround, qmImgHome,
  qmImgBook, qmImgRefresh, qmImgBush1, qmImgBush2, qmImgFlowers, qmImgLeaves1, qmImgLeaves2, qmImgWoodSign,
];

/// Answer pictures: drop `quiz_<key>.webp` files into assets/images/quiz/
/// (names come from quiz_answer_images.csv). Answers without a picture yet
/// show a big word card instead, so new batches appear without code changes.
const String qmAnswerDir = 'assets/images/quiz/';
String qmAnswerAsset(String key) => '${qmAnswerDir}quiz_$key.webp';

class QmAssets {
  static Set<String> _have = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      _have = m.listAssets().where((a) => a.startsWith(qmAnswerDir)).toSet();
    } catch (_) {
      _have = {};
    }
    _loaded = true;
  }

  static bool has(String? key) => key != null && _have.contains(qmAnswerAsset(key));
}

// ── languages & texts ──────────────────────────────────────────────────────

String qmLang(QuizLanguage l) {
  switch (l) {
    case QuizLanguage.english:
      return 'en';
    case QuizLanguage.arabic:
      return 'ar';
    case QuizLanguage.deutch:
      return 'de';
    case QuizLanguage.spanish:
      return 'es';
    case QuizLanguage.amazigh:
      return 'amazigh';
    case QuizLanguage.french:
      return 'fr';
  }
}

/// UI language: Amazigh questions keep French interface texts.
String qmUiLang(QuizLanguage l) {
  final c = qmLang(l);
  return c == 'amazigh' ? 'fr' : c;
}

const Map<String, Map<String, String>> _qmUi = {
  'title': {'fr': 'Quiz magique', 'en': 'Magic quiz', 'ar': 'الاختبار السحري', 'de': 'Zauberquiz', 'es': 'Quiz mágico'},
  'question': {'fr': 'Question', 'en': 'Question', 'ar': 'سؤال', 'de': 'Frage', 'es': 'Pregunta'},
  'correct': {'fr': 'Bonne réponse !', 'en': 'Correct!', 'ar': 'إجابة صحيحة!', 'de': 'Richtig!', 'es': '¡Correcto!'},
  'wrong': {'fr': 'Pas tout à fait !', 'en': 'Not quite!', 'ar': 'ليس تماماً!', 'de': 'Nicht ganz!', 'es': '¡Casi!'},
  'correctLine': {
    'fr': 'Bravo, c’est bien « {a} » !',
    'en': 'Well done, it’s “{a}”!',
    'ar': 'أحسنت، إنها «{a}»!',
    'de': 'Super, es ist „{a}“!',
    'es': '¡Muy bien, es «{a}»!',
  },
  'wrongLine': {
    'fr': 'La bonne réponse est « {a} ».',
    'en': 'The right answer is “{a}”.',
    'ar': 'الإجابة الصحيحة هي «{a}».',
    'de': 'Die richtige Antwort ist „{a}“.',
    'es': 'La respuesta correcta es «{a}».',
  },
  'continue': {'fr': 'Continuer', 'en': 'Continue', 'ar': 'متابعة', 'de': 'Weiter', 'es': 'Continuar'},
  'bravo': {'fr': 'Bravo !', 'en': 'Great!', 'ar': 'أحسنت!', 'de': 'Super!', 'es': '¡Bravo!'},
  'learn': {'fr': 'On apprend ensemble !', 'en': 'Let’s learn together!', 'ar': 'نتعلم معاً!', 'de': 'Wir lernen zusammen!', 'es': '¡Aprendemos juntos!'},
  'yourTurn': {'fr': 'À toi !', 'en': 'Your turn!', 'ar': 'دورك!', 'de': 'Du bist dran!', 'es': '¡Tu turno!'},
  'winTitle': {'fr': 'Défi réussi !', 'en': 'Challenge won!', 'ar': 'تحدٍّ ناجح!', 'de': 'Geschafft!', 'es': '¡Reto superado!'},
  'winSub': {'fr': 'Bravo, petit explorateur !', 'en': 'Well done, little explorer!', 'ar': 'أحسنت أيها المستكشف الصغير!', 'de': 'Toll, kleiner Entdecker!', 'es': '¡Bravo, pequeño explorador!'},
  'retryTitle': {'fr': 'On réessaie ?', 'en': 'Try again?', 'ar': 'نحاول مجدداً؟', 'de': 'Nochmal?', 'es': '¿Otra vez?'},
  'retrySub': {'fr': 'Chaque essai te fait progresser !', 'en': 'Every try helps you grow!', 'ar': 'كل محاولة تجعلك أفضل!', 'de': 'Jeder Versuch macht dich besser!', 'es': '¡Cada intento te hace mejorar!'},
  'goodAnswers': {'fr': 'Bonnes réponses', 'en': 'Correct answers', 'ar': 'إجابات صحيحة', 'de': 'Richtige Antworten', 'es': 'Respuestas correctas'},
  'practice': {'fr': 'Encore un peu d’entraînement !', 'en': 'A little more practice!', 'ar': 'القليل من التدريب بعد!', 'de': 'Noch ein bisschen üben!', 'es': '¡Un poco más de práctica!'},
  'rewards': {'fr': 'Récompenses', 'en': 'Rewards', 'ar': 'المكافآت', 'de': 'Belohnungen', 'es': 'Recompensas'},
  'badge': {'fr': 'Badge obtenu', 'en': 'Badge earned', 'ar': 'شارة جديدة', 'de': 'Neues Abzeichen', 'es': 'Insignia ganada'},
  'review': {'fr': 'Revoir mes réponses', 'en': 'Review my answers', 'ar': 'مراجعة إجاباتي', 'de': 'Antworten ansehen', 'es': 'Revisar mis respuestas'},
  'menu': {'fr': 'Menu des quiz', 'en': 'Quiz menu', 'ar': 'قائمة الاختبارات', 'de': 'Quiz-Menü', 'es': 'Menú de quiz'},
  'retry': {'fr': 'Réessayer', 'en': 'Try again', 'ar': 'أعد المحاولة', 'de': 'Nochmal', 'es': 'Reintentar'},
  'tipTitle': {'fr': 'Pour progresser', 'en': 'To get better', 'ar': 'لتتحسّن', 'de': 'So wirst du besser', 'es': 'Para mejorar'},
  'tipText': {
    'fr': 'Revois les réponses, puis retente le défi.',
    'en': 'Look at the answers, then try the challenge again.',
    'ar': 'راجع الإجابات، ثم أعد التحدي.',
    'de': 'Schau dir die Antworten an und versuch es nochmal.',
    'es': 'Revisa las respuestas y vuelve a intentarlo.',
  },
  'yourAnswer': {'fr': 'Ta réponse', 'en': 'Your answer', 'ar': 'إجابتك', 'de': 'Deine Antwort', 'es': 'Tu respuesta'},
  'rightAnswer': {'fr': 'Bonne réponse', 'en': 'Right answer', 'ar': 'الإجابة الصحيحة', 'de': 'Richtige Antwort', 'es': 'Respuesta correcta'},
  'settings': {'fr': 'Réglages', 'en': 'Settings', 'ar': 'الإعدادات', 'de': 'Einstellungen', 'es': 'Ajustes'},
  'voice': {'fr': 'Lire les questions à voix haute', 'en': 'Read questions aloud', 'ar': 'قراءة الأسئلة بصوت عالٍ', 'de': 'Fragen vorlesen', 'es': 'Leer las preguntas en voz alta'},
  'ok': {'fr': 'OK', 'en': 'OK', 'ar': 'حسناً', 'de': 'OK', 'es': 'OK'},
  'ready': {'fr': 'Je suis prêt !', 'en': 'I\'m ready!', 'ar': 'أنا مستعد!', 'de': 'Ich bin bereit!', 'es': '¡Estoy listo!'},
  'passTo': {'fr': 'Passe l’appareil à {a}', 'en': 'Pass the device to {a}', 'ar': 'مرّر الجهاز إلى {a}', 'de': 'Gib das Gerät an {a}', 'es': 'Pasa el dispositivo a {a}'},
  'getReady': {'fr': 'Prépare-toi !', 'en': 'Get ready!', 'ar': 'استعد!', 'de': 'Mach dich bereit!', 'es': '¡Prepárate!'},
  'robotTurn': {'fr': 'Au tour du robot !', 'en': 'The robot\'s turn!', 'ar': 'دور الروبوت!', 'de': 'Der Roboter ist dran!', 'es': '¡Turno del robot!'},
  'tapToStart': {'fr': 'Touche l’écran pour commencer', 'en': 'Tap the screen to start', 'ar': 'المس الشاشة للبدء', 'de': 'Tippe zum Starten', 'es': 'Toca la pantalla para empezar'},
  'yourTurnTag': {'fr': 'À toi !', 'en': 'Your turn!', 'ar': 'دورك!', 'de': 'Du!', 'es': '¡Tú!'},
  'hint': {'fr': 'Indice', 'en': 'Hint', 'ar': 'تلميح', 'de': 'Tipp', 'es': 'Pista'},
  'great': {'fr': 'Super !', 'en': 'Super!', 'ar': 'رائع!', 'de': 'Klasse!', 'es': '¡Genial!'},
  'champion': {'fr': 'Champion !', 'en': 'Champion!', 'ar': 'بطل!', 'de': 'Champion!', 'es': '¡Campeón!'},
  'onFire': {'fr': 'En feu !', 'en': 'On fire!', 'ar': 'مشتعل!', 'de': 'Volle Fahrt!', 'es': '¡Imparable!'},
  'genius': {'fr': 'Génie !', 'en': 'Genius!', 'ar': 'عبقري!', 'de': 'Genie!', 'es': '¡Genio!'},
  'streakN': {'fr': 'Série x{a}', 'en': 'Streak x{a}', 'ar': 'سلسلة x{a}', 'de': 'Serie x{a}', 'es': 'Racha x{a}'},
  'bestStreak': {'fr': 'Meilleure série : {a}', 'en': 'Best streak: {a}', 'ar': 'أفضل سلسلة: {a}', 'de': 'Beste Serie: {a}', 'es': 'Mejor racha: {a}'},
  'tryHint': {'fr': 'Besoin d’aide ? Touche Indice !', 'en': 'Need help? Tap Hint!', 'ar': 'تحتاج مساعدة؟ المس تلميح!', 'de': 'Hilfe? Tippe auf Tipp!', 'es': '¿Ayuda? ¡Toca Pista!'},
  'solo': {'fr': 'Solo', 'en': 'Solo', 'ar': 'فردي', 'de': 'Solo', 'es': 'Solo'},
  'duel': {'fr': 'Duel à 2', 'en': 'Duel for 2', 'ar': 'تحدٍّ لاثنين', 'de': 'Duell zu zweit', 'es': 'Duelo a 2'},
  'chooseOpponent': {'fr': 'Choisis ton adversaire', 'en': 'Choose your opponent', 'ar': 'اختر منافسك', 'de': 'Wähle deinen Gegner', 'es': 'Elige a tu rival'},
  'friend': {'fr': 'Un ami', 'en': 'A friend', 'ar': 'صديق', 'de': 'Ein Freund', 'es': 'Un amigo'},
  'friendSub': {'fr': 'Sur le même écran', 'en': 'On the same screen', 'ar': 'على نفس الشاشة', 'de': 'Am selben Bildschirm', 'es': 'En la misma pantalla'},
  'robot': {'fr': 'Un robot', 'en': 'A robot', 'ar': 'روبوت', 'de': 'Ein Roboter', 'es': 'Un robot'},
  'robotSub': {'fr': 'Contre l’ordinateur', 'en': 'Against the computer', 'ar': 'ضد الحاسوب', 'de': 'Gegen den Computer', 'es': 'Contra el ordenador'},
  'robotLevel': {'fr': 'Niveau du robot', 'en': 'Robot level', 'ar': 'مستوى الروبوت', 'de': 'Roboter-Level', 'es': 'Nivel del robot'},
  'easy': {'fr': 'Facile', 'en': 'Easy', 'ar': 'سهل', 'de': 'Leicht', 'es': 'Fácil'},
  'medium': {'fr': 'Moyen', 'en': 'Medium', 'ar': 'متوسط', 'de': 'Mittel', 'es': 'Medio'},
  'hard': {'fr': 'Difficile', 'en': 'Hard', 'ar': 'صعب', 'de': 'Schwer', 'es': 'Difícil'},
  'chooseTheme': {'fr': 'Choisis ton thème', 'en': 'Choose your theme', 'ar': 'اختر موضوعك', 'de': 'Wähle dein Thema', 'es': 'Elige tu tema'},
  'you': {'fr': 'Toi', 'en': 'You', 'ar': 'أنت', 'de': 'Du', 'es': 'Tú'},
  'robotName': {'fr': 'Robot', 'en': 'Robot', 'ar': 'الروبوت', 'de': 'Roboter', 'es': 'Robot'},
  'questionsN': {'fr': '{a} questions', 'en': '{a} questions', 'ar': '{a} أسئلة', 'de': '{a} Fragen', 'es': '{a} preguntas'},
  'startDuel': {'fr': 'Lancer le duel', 'en': 'Start the duel', 'ar': 'ابدأ التحدي', 'de': 'Duell starten', 'es': 'Empezar el duelo'},
  'startQuiz': {'fr': 'Lancer le quiz', 'en': 'Start the quiz', 'ar': 'ابدأ الاختبار', 'de': 'Quiz starten', 'es': 'Empezar el quiz'},
  'turnHint': {'fr': 'À tour de rôle, chacun sa réponse !', 'en': 'Take turns, one answer each!', 'ar': 'بالتناوب، لكلٍّ إجابته!', 'de': 'Abwechselnd, jeder eine Antwort!', 'es': '¡Por turnos, cada uno su respuesta!'},
  'soloHint': {'fr': 'Trouve un maximum de bonnes réponses !', 'en': 'Find as many right answers as you can!', 'ar': 'اعثر على أكبر عدد من الإجابات الصحيحة!', 'de': 'Finde so viele richtige Antworten wie möglich!', 'es': '¡Encuentra todas las respuestas que puedas!'},
  'playWithFriend': {'fr': 'Jouer avec un ami', 'en': 'Play with a friend', 'ar': 'العب مع صديق', 'de': 'Mit einem Freund spielen', 'es': 'Jugar con un amigo'},
  'sameScreen': {'fr': 'À deux, sur le même écran !', 'en': 'Two players, one screen!', 'ar': 'اثنان على نفس الشاشة!', 'de': 'Zu zweit an einem Bildschirm!', 'es': '¡Dos jugadores, una pantalla!'},
  'player': {'fr': 'Joueur {a}', 'en': 'Player {a}', 'ar': 'اللاعب {a}', 'de': 'Spieler {a}', 'es': 'Jugador {a}'},
  'firstName': {'fr': 'Prénom', 'en': 'Name', 'ar': 'الاسم', 'de': 'Vorname', 'es': 'Nombre'},
  'chooseAvatar': {'fr': 'Choisis ton avatar', 'en': 'Choose your avatar', 'ar': 'اختر صورتك', 'de': 'Wähle deinen Avatar', 'es': 'Elige tu avatar'},
  'theDuel': {'fr': 'Le duel', 'en': 'The duel', 'ar': 'التحدي', 'de': 'Das Duell', 'es': 'El duelo'},
  'roundsInfo': {'fr': '{a} tours · {b} par joueur', 'en': '{a} rounds · {b} each', 'ar': '{a} جولات · {b} لكل لاعب', 'de': '{a} Runden · {b} pro Spieler', 'es': '{a} rondas · {b} por jugador'},
  'eachTurn': {'fr': 'Chacun son tour !', 'en': 'Each in turn!', 'ar': 'كلٌّ في دوره!', 'de': 'Jeder ist mal dran!', 'es': '¡Cada uno a su turno!'},
  'passDevice': {'fr': 'Passe l’appareil à ton ami après ta réponse.', 'en': 'Pass the device to your friend after your answer.', 'ar': 'مرّر الجهاز لصديقك بعد إجابتك.', 'de': 'Gib das Gerät nach deiner Antwort weiter.', 'es': 'Pasa el dispositivo a tu amigo después de responder.'},
  'onePoint': {'fr': 'Une bonne réponse = 1 point', 'en': 'One right answer = 1 point', 'ar': 'إجابة صحيحة = نقطة واحدة', 'de': 'Richtige Antwort = 1 Punkt', 'es': 'Respuesta correcta = 1 punto'},
  'duel1v1': {'fr': 'Duel 1 vs 1', 'en': 'Duel 1 vs 1', 'ar': 'تحدٍّ 1 ضد 1', 'de': 'Duell 1 gegen 1', 'es': 'Duelo 1 vs 1'},
  'round': {'fr': 'Tour', 'en': 'Round', 'ar': 'الجولة', 'de': 'Runde', 'es': 'Ronda'},
  'yourTurnName': {'fr': 'À toi de jouer, {a} !', 'en': 'Your turn, {a}!', 'ar': 'دورك يا {a}!', 'de': 'Du bist dran, {a}!', 'es': '¡Te toca, {a}!'},
  'robotThinking': {'fr': 'Le robot réfléchit…', 'en': 'The robot is thinking…', 'ar': 'الروبوت يفكر…', 'de': 'Der Roboter denkt nach…', 'es': 'El robot está pensando…'},
  'validate': {'fr': 'Valider', 'en': 'Check', 'ar': 'تأكيد', 'de': 'Prüfen', 'es': 'Validar'},
  'pickAnswer': {'fr': 'Choisis une réponse', 'en': 'Pick an answer', 'ar': 'اختر إجابة', 'de': 'Wähle eine Antwort', 'es': 'Elige una respuesta'},
  'pts': {'fr': 'pts', 'en': 'pts', 'ar': 'نقاط', 'de': 'Pkt', 'es': 'pts'},
  'pt': {'fr': 'pt', 'en': 'pt', 'ar': 'نقطة', 'de': 'Pkt', 'es': 'pt'},
  'pointFor': {'fr': '+1 pour {a} !', 'en': '+1 for {a}!', 'ar': '+1 لـ{a}!', 'de': '+1 für {a}!', 'es': '¡+1 para {a}!'},
  'nextTurn': {'fr': 'Au tour de {a}', 'en': '{a}’s turn', 'ar': 'دور {a}', 'de': '{a} ist dran', 'es': 'Turno de {a}'},
  'seeResults': {'fr': 'Voir le résultat', 'en': 'See the result', 'ar': 'عرض النتيجة', 'de': 'Ergebnis ansehen', 'es': 'Ver el resultado'},
  'bravoName': {'fr': 'Bravo {a} !', 'en': 'Well done {a}!', 'ar': 'أحسنت يا {a}!', 'de': 'Bravo {a}!', 'es': '¡Bravo {a}!'},
  'youWinDuel': {'fr': 'Tu remportes le duel !', 'en': 'You win the duel!', 'ar': 'لقد فزت بالتحدي!', 'de': 'Du gewinnst das Duell!', 'es': '¡Ganas el duelo!'},
  'robotWins': {'fr': 'Le robot gagne !', 'en': 'The robot wins!', 'ar': 'الروبوت فاز!', 'de': 'Der Roboter gewinnt!', 'es': '¡Gana el robot!'},
  'robotWinsSub': {'fr': 'Retente ta chance !', 'en': 'Try again!', 'ar': 'حاول مرة أخرى!', 'de': 'Versuch es nochmal!', 'es': '¡Inténtalo otra vez!'},
  'tie': {'fr': 'Égalité !', 'en': 'It’s a tie!', 'ar': 'تعادل!', 'de': 'Unentschieden!', 'es': '¡Empate!'},
  'tieSub': {'fr': 'Vous êtes aussi forts l’un que l’autre !', 'en': 'You’re just as strong as each other!', 'ar': 'أنتما بنفس القوة!', 'de': 'Ihr seid gleich stark!', 'es': '¡Sois igual de fuertes!'},
  'finalScore': {'fr': 'Score final', 'en': 'Final score', 'ar': 'النتيجة النهائية', 'de': 'Endstand', 'es': 'Resultado final'},
  'winner': {'fr': 'Vainqueur', 'en': 'Winner', 'ar': 'الفائز', 'de': 'Sieger', 'es': 'Ganador'},
  'bothBravo': {'fr': 'Bravo à vous deux !', 'en': 'Well done, both of you!', 'ar': 'أحسنتما كلاكما!', 'de': 'Toll gemacht, ihr beiden!', 'es': '¡Bravo a los dos!'},
  'together': {'fr': 'Ensemble, vous avez trouvé {a} bonnes réponses.', 'en': 'Together you found {a} right answers.', 'ar': 'معاً وجدتما {a} إجابات صحيحة.', 'de': 'Zusammen habt ihr {a} richtige Antworten gefunden.', 'es': 'Juntos encontrasteis {a} respuestas correctas.'},
  'youFound': {'fr': 'Tu as trouvé {a} bonnes réponses.', 'en': 'You found {a} right answers.', 'ar': 'وجدت {a} إجابات صحيحة.', 'de': 'Du hast {a} richtige Antworten gefunden.', 'es': 'Encontraste {a} respuestas correctas.'},
  'rematch': {'fr': 'Revanche', 'en': 'Rematch', 'ar': 'مباراة العودة', 'de': 'Revanche', 'es': 'Revancha'},
  'reviewAll': {'fr': 'Revoir les réponses', 'en': 'Review the answers', 'ar': 'مراجعة الإجابات', 'de': 'Antworten ansehen', 'es': 'Revisar las respuestas'},
  'language': {'fr': 'Langue du quiz', 'en': 'Quiz language', 'ar': 'لغة الاختبار', 'de': 'Quiz-Sprache', 'es': 'Idioma del quiz'},
};

String qmText(String lang, String key, {String? a, String? b}) {
  final m = _qmUi[key];
  if (m == null) return key;
  var t = m[lang] ?? m['fr']!;
  if (a != null) t = t.replaceAll('{a}', a);
  if (b != null) t = t.replaceAll('{b}', b);
  return t;
}

List<String> qmLetters(String lang) => lang == 'ar' ? const ['أ', 'ب', 'ج', 'د'] : const ['A', 'B', 'C', 'D'];

// ── categories ─────────────────────────────────────────────────────────────

class QmCategory {
  final String id;
  final String emoji;
  final Map<String, String> name;
  final Map<String, String> badge;
  const QmCategory(this.id, this.emoji, this.name, this.badge);
}

const List<QmCategory> qmCategories = [
  QmCategory('animals', '🐾', {'fr': 'Les animaux', 'en': 'Animals', 'ar': 'الحيوانات', 'de': 'Tiere', 'es': 'Animales'},
      {'fr': 'Expert des animaux', 'en': 'Animal expert', 'ar': 'خبير الحيوانات', 'de': 'Tierprofi', 'es': 'Experto en animales'}),
  QmCategory('food', '🍎', {'fr': 'Les aliments', 'en': 'Food', 'ar': 'الطعام', 'de': 'Essen', 'es': 'Comida'},
      {'fr': 'Expert des aliments', 'en': 'Food expert', 'ar': 'خبير الطعام', 'de': 'Essensprofi', 'es': 'Experto en comida'}),
  QmCategory('nature', '🌿', {'fr': 'La nature', 'en': 'Nature', 'ar': 'الطبيعة', 'de': 'Natur', 'es': 'Naturaleza'},
      {'fr': 'Expert de la nature', 'en': 'Nature expert', 'ar': 'خبير الطبيعة', 'de': 'Naturprofi', 'es': 'Experto en naturaleza'}),
  QmCategory('objects', '🧸', {'fr': 'Les objets', 'en': 'Objects', 'ar': 'الأشياء', 'de': 'Dinge', 'es': 'Objetos'},
      {'fr': 'Expert des objets', 'en': 'Object expert', 'ar': 'خبير الأشياء', 'de': 'Dingeprofi', 'es': 'Experto en objetos'}),
  QmCategory('vehicles', '🚗', {'fr': 'Les véhicules', 'en': 'Vehicles', 'ar': 'المركبات', 'de': 'Fahrzeuge', 'es': 'Vehículos'},
      {'fr': 'Expert des véhicules', 'en': 'Vehicle expert', 'ar': 'خبير المركبات', 'de': 'Fahrzeugprofi', 'es': 'Experto en vehículos'}),
  QmCategory('places', '🏠', {'fr': 'Les lieux', 'en': 'Places', 'ar': 'الأماكن', 'de': 'Orte', 'es': 'Lugares'},
      {'fr': 'Expert des lieux', 'en': 'Places expert', 'ar': 'خبير الأماكن', 'de': 'Ortsprofi', 'es': 'Experto en lugares'}),
  QmCategory('colors', '🎨', {'fr': 'Les couleurs', 'en': 'Colors', 'ar': 'الألوان', 'de': 'Farben', 'es': 'Colores'},
      {'fr': 'Expert des couleurs', 'en': 'Color expert', 'ar': 'خبير الألوان', 'de': 'Farbenprofi', 'es': 'Experto en colores'}),
  QmCategory('time', '🎉', {'fr': 'La vie de tous les jours', 'en': 'Everyday life', 'ar': 'الحياة اليومية', 'de': 'Alltag', 'es': 'Vida diaria'},
      {'fr': 'Expert du quotidien', 'en': 'Everyday expert', 'ar': 'خبير الحياة اليومية', 'de': 'Alltagsprofi', 'es': 'Experto del día a día'}),
  QmCategory('general', '💡', {'fr': 'Culture générale', 'en': 'General knowledge', 'ar': 'ثقافة عامة', 'de': 'Allgemeinwissen', 'es': 'Cultura general'},
      {'fr': 'Petit génie', 'en': 'Little genius', 'ar': 'العبقري الصغير', 'de': 'Kleines Genie', 'es': 'Pequeño genio'}),
];

QmCategory qmCategory(String id) => qmCategories.firstWhere((c) => c.id == id, orElse: () => qmCategories.last);

String qmCatName(QmCategory c, String lang) => c.name[lang] ?? c.name['fr']!;
String qmBadgeName(QmCategory c, String lang) => c.badge[lang] ?? c.badge['fr']!;

// ── colours drawn as swatches ──────────────────────────────────────────────

const Map<String, Color> qmSwatches = {
  'color_blue': Color(0xFF3D8BFF),
  'color_green': Color(0xFF3CC85A),
  'color_red': Color(0xFFFF4D4D),
  'color_yellow': Color(0xFFFFD21A),
  'color_white': Color(0xFFFFFFFF),
};

// ── answer → picture key ───────────────────────────────────────────────────

String? qmKeyFor(String text, String lang) {
  final t = text.trim().toLowerCase();
  return _qmLangOverride['$lang|$t'] ?? _qmAnswerKey[t];
}

bool qmIsNumber(String s) => RegExp(r'^\s*-?\d+\s*$').hasMatch(s);

// ── a round of questions ───────────────────────────────────────────────────

class QmItem {
  final Question question; // options already shuffled
  final List<String?> keys; // picture key per option (null = word card)
  final String category;
  int? picked;

  QmItem(this.question, this.keys, this.category);

  bool get answered => picked != null;
  bool get correct => picked == question.correctIndex;
  String get answerText => question.options[question.correctIndex];
  String? get answerKey => keys[question.correctIndex];
}

const Set<String> _qmSpaceKeys = {
  'sun', 'moon', 'star', 'sunlight', 'earth_planet', 'mars', 'venus', 'jupiter', 'rainbow', 'cloud',
};

/// Theme of an item (by its correct answer).
String qmThemeOf(QmItem it) {
  final k = it.answerKey;
  if (k != null && _qmSpaceKeys.contains(k)) return 'space';
  switch (it.category) {
    case 'animals':
      return 'animals';
    case 'food':
      return 'food';
    case 'nature':
      return 'nature';
    case 'objects':
    case 'vehicles':
    case 'places':
    case 'time':
    case 'colors':
      return 'daily';
  }
  return 'surprise';
}

/// Builds [count] random questions for [theme] ('surprise' = everything).
/// When a theme has fewer questions than [count] the round is topped up with
/// other questions. [choices] keeps at most that many options (2, 3 or 4).
List<QmItem> qmBuildRound(QuizLanguage lang, {int count = 10, String theme = 'surprise', int choices = 4}) {
  final code = qmLang(lang);
  final source = List<Question>.from(questionsByLanguage[lang] ?? const <Question>[]);
  // Amazigh answers are written in Tifinagh; their order follows the Spanish
  // question with the same id, so pictures are borrowed from there.
  final twins = <int, Question>{
    if (lang == QuizLanguage.amazigh)
      for (final q in questionsByLanguage[QuizLanguage.spanish] ?? const <Question>[]) q.id: q,
  };
  final rnd = Random();
  final all = <QmItem>[];
  for (final q in source) {
    final twin = twins[q.id];
    final useTwin = twin != null && twin.options.length == q.options.length && twin.correctIndex == q.correctIndex;
    final keys = <String?>[
      for (var i = 0; i < q.options.length; i++)
        useTwin ? qmKeyFor(twin!.options[i], 'es') : qmKeyFor(q.options[i], code),
    ];
    // keep the right answer plus random wrong ones
    final wrong = [for (var i = 0; i < q.options.length; i++) if (i != q.correctIndex) i]..shuffle(rnd);
    final keep = <int>[q.correctIndex, ...wrong.take(max(1, min(choices, q.options.length) - 1))];
    keep.shuffle(rnd);
    final opts = [for (final i in keep) q.options[i]];
    final k2 = [for (final i in keep) keys[i]];
    final cKey = keys[q.correctIndex];
    final cat = cKey == null ? 'general' : (_qmKeyCategory[cKey] ?? 'general');
    all.add(QmItem(Question(q.id, q.questionText, opts, keep.indexOf(q.correctIndex)), k2, cat));
  }
  all.shuffle(rnd);
  if (theme == 'surprise') return all.take(count).toList();
  final picked = all.where((i) => qmThemeOf(i) == theme).take(count).toList();
  if (picked.length < count) {
    final rest = all.where((i) => !picked.contains(i)).toList()
      ..sort((a, b) => (a.category == 'general' ? 1 : 0) - (b.category == 'general' ? 1 : 0));
    picked.addAll(rest.take(count - picked.length));
    picked.shuffle(rnd);
  }
  return picked;
}

/// Stars earned so far (thresholds at 30 %, 60 % and 90 % of the round).
int qmStars(int good, int total) {
  if (total == 0) return 0;
  final r = good / total;
  return r >= 0.9 ? 3 : (r >= 0.6 ? 2 : (r >= 0.3 ? 1 : 0));
}

bool qmPassed(int good, int total) => total > 0 && good / total >= 0.6;

// ── themes (quiz menu) ─────────────────────────────────────────────────────

class QmTheme {
  final String id;
  final String category; // category used for the pill icon
  final Map<String, String> name;
  const QmTheme(this.id, this.category, this.name);
  String get image => '${qmDir}qm_theme_$id.webp';
}

const List<QmTheme> qmThemes = [
  QmTheme('animals', 'animals', {'fr': 'Les animaux', 'en': 'Animals', 'ar': 'الحيوانات', 'de': 'Tiere', 'es': 'Animales'}),
  QmTheme('food', 'food', {'fr': 'Les aliments', 'en': 'Food', 'ar': 'الطعام', 'de': 'Essen', 'es': 'Comida'}),
  QmTheme('nature', 'nature', {'fr': 'La nature', 'en': 'Nature', 'ar': 'الطبيعة', 'de': 'Natur', 'es': 'Naturaleza'}),
  QmTheme('daily', 'time', {'fr': 'Le quotidien', 'en': 'Everyday life', 'ar': 'الحياة اليومية', 'de': 'Alltag', 'es': 'Vida diaria'}),
  QmTheme('space', 'space', {'fr': 'L’espace', 'en': 'Space', 'ar': 'الفضاء', 'de': 'Weltall', 'es': 'El espacio'}),
  QmTheme('surprise', 'general', {'fr': 'Quiz surprise', 'en': 'Surprise quiz', 'ar': 'اختبار مفاجئ', 'de': 'Überraschungsquiz', 'es': 'Quiz sorpresa'}),
];

QmTheme qmTheme(String id) => qmThemes.firstWhere((t) => t.id == id, orElse: () => qmThemes.last);
String qmThemeName(QmTheme t, String lang) => t.name[lang] ?? t.name['fr']!;

/// Category shown for a theme (space has its own rocket icon).
QmCategory qmThemeCategory(QmTheme t) {
  if (t.id == 'space') {
    return const QmCategory('space', '🚀', {'fr': 'L’espace', 'en': 'Space', 'ar': 'الفضاء', 'de': 'Weltall', 'es': 'El espacio'},
        {'fr': 'Expert de l’espace', 'en': 'Space expert', 'ar': 'خبير الفضاء', 'de': 'Weltraumprofi', 'es': 'Experto del espacio'});
  }
  if (t.id == 'daily') {
    return QmCategory('daily', '⏰', t.name, const {'fr': 'Expert du quotidien', 'en': 'Everyday expert', 'ar': 'خبير الحياة اليومية', 'de': 'Alltagsprofi', 'es': 'Experto del día a día'});
  }
  if (t.id == 'surprise') {
    return QmCategory('surprise', '🎁', t.name, const {'fr': 'Petit génie', 'en': 'Little genius', 'ar': 'العبقري الصغير', 'de': 'Kleines Genie', 'es': 'Pequeño genio'});
  }
  return qmCategory(t.category);
}

// ── avatars & levels ───────────────────────────────────────────────────────

const List<String> qmAvatars = ['boy', 'girl', 'fox', 'panda', 'astro', 'cat'];
String qmAvatarAsset(String id) => id == 'robot' ? qmImgAvRobot : '${qmDir}qm_av_$id.webp';

/// 0 = easy, 1 = medium, 2 = hard.
const List<String> qmLevelKeys = ['easy', 'medium', 'hard'];
const List<String> qmLevelIcons = [qmImgLvlEasy, qmImgLvlMid, qmImgLvlHard];

/// Chance that the robot answers right, per level.
const List<double> qmRobotSkill = [0.45, 0.68, 0.88];

/// Number of answer choices in a friend duel, per level.
const List<int> qmFriendChoices = [4, 4, 4];

class QmPlayer {
  final String name;
  final String avatar; // id in [qmAvatars] or 'robot'
  final bool robot;
  const QmPlayer(this.name, this.avatar, {this.robot = false});
}

QuizLanguage qmLanguageFromCode(String? code) {
  switch (code) {
    case 'en':
      return QuizLanguage.english;
    case 'ar':
      return QuizLanguage.arabic;
    case 'de':
      return QuizLanguage.deutch;
    case 'es':
      return QuizLanguage.spanish;
    case 'amazigh':
    case 'zgh':
    case 'tzm':
      return QuizLanguage.amazigh;
  }
  return QuizLanguage.french;
}

const Map<QuizLanguage, String> qmLanguageNames = {
  QuizLanguage.french: 'Français',
  QuizLanguage.english: 'English',
  QuizLanguage.arabic: 'العربية',
  QuizLanguage.deutch: 'Deutsch',
  QuizLanguage.spanish: 'Español',
  QuizLanguage.amazigh: 'ⵜⴰⵎⴰⵣⵉⵖⵜ',
};

// ── saved choices ──────────────────────────────────────────────────────────

class QmPrefs {
  static SharedPreferences? _p;
  static Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  static Future<void> init() async {
    await _prefs;
  }

  static bool get voice => _p?.getBool('qm_voice') ?? true;
  static set voice(bool v) => _p?.setBool('qm_voice', v);

  static String? get language => _p?.getString('qm_lang');
  static set language(String? v) => v == null ? _p?.remove('qm_lang') : _p?.setString('qm_lang', v);

  static String get theme => _p?.getString('qm_theme') ?? 'animals';
  static set theme(String v) => _p?.setString('qm_theme', v);

  static bool get duel => _p?.getBool('qm_duel') ?? false;
  static set duel(bool v) => _p?.setBool('qm_duel', v);

  static bool get vsRobot => _p?.getBool('qm_vs_robot') ?? true;
  static set vsRobot(bool v) => _p?.setBool('qm_vs_robot', v);

  static int get robotLevel => _p?.getInt('qm_robot_level') ?? 0;
  static set robotLevel(int v) => _p?.setInt('qm_robot_level', v);

  static int get friendLevel => _p?.getInt('qm_friend_level') ?? 0;
  static set friendLevel(int v) => _p?.setInt('qm_friend_level', v);

  static String name(int player) => _p?.getString('qm_p${player}_name') ?? '';
  static void setName(int player, String v) => _p?.setString('qm_p${player}_name', v);

  static String avatar(int player) => _p?.getString('qm_p${player}_av') ?? (player == 1 ? 'boy' : 'girl');
  static void setAvatar(int player, String v) => _p?.setString('qm_p${player}_av', v);
}
