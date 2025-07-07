// lib/games/Quiz_Game/questions_data.dart

import 'question_model.dart';
import 'ModeSelectorPage.dart'; // for QuizLanguage enum

final Map<QuizLanguage, List<Question>> questionsByLanguage = {
  QuizLanguage.english: [
    Question('🌤️ What color is the sky?', ['Blue', 'Green', 'Red', 'Yellow'], 0),
    Question('🕷️ How many legs does a spider have?', ['6', '8', '10', '4'], 1),
    Question('🐶 Which animal barks?', ['Cat', 'Cow', 'Dog', 'Bird'], 2),
    Question('🧮 What is 2 + 2?', ['3', '4', '5'], 1),
    Question('🍌 Which one is a fruit?', ['Carrot', 'Banana', 'Potato', 'Onion'], 1),
    Question('🐶 Which one is an animal?', ['Car', 'Dog', 'Table', 'Chair'], 1),
    Question('🌈 What color is the sky?', ['Green', 'Blue', 'Red', 'Yellow'], 1),
    Question('🚗 Which one can fly?', ['Car', 'Boat', 'Airplane', 'Bike'], 2),
    Question('🍎 Which one is red?', ['Banana', 'Apple', 'Grape', 'Orange'], 1),
    Question('🌻 Which one is a flower?', ['Rose', 'Tree', 'Grass', 'Rock'], 0),
    Question('🐸 Which one lives in water?', ['Dog', 'Frog', 'Cat', 'Horse'], 1),
    Question('🍪 Which one is a sweet treat?', ['Bread', 'Cookie', 'Rice', 'Potato'], 1),
    Question('🎵 Which one is a musical instrument?', ['Piano', 'Book', 'Chair', 'Pen'], 0),
    Question('⚽ What do you use to play soccer?', ['Ball', 'Bat', 'Glove', 'Racket'], 0),
    Question('🌟 Which one shines in the night sky?', ['Moon', 'Sun', 'Cloud', 'Tree'], 0),
    // ... add the rest of English questions here
  ],
  QuizLanguage.french: [
    Question('🌤️ Quelle est la couleur du ciel ?', ['Bleu', 'Vert', 'Rouge', 'Jaune'], 0),
    Question('🕷️ Combien de pattes a une araignée ?', ['6', '8', '10', '4'], 1),
    Question('🐶 Quel animal aboie ?', ['Chat', 'Vache', 'Chien', 'Oiseau'], 2),
    Question('🧮 Combien font 2 + 2 ?', ['3', '4', '5'], 1),
    Question('🍌 Lequel est un fruit ?', ['Carotte', 'Banane', 'Pomme de terre', 'Oignon'], 1),
    Question('🐶 Lequel est un animal ?', ['Voiture', 'Chien', 'Table', 'Chaise'], 1),
    Question('🌈 Quelle est la couleur du ciel ?', ['Vert', 'Bleu', 'Rouge', 'Jaune'], 1),
    Question('🚗 Lequel peut voler ?', ['Voiture', 'Bateau', 'Avion', 'Vélo'], 2),
    Question('🍎 Lequel est rouge ?', ['Banane', 'Pomme', 'Raisin', 'Orange'], 1),
    Question('🌻 Lequel est une fleur ?', ['Rose', 'Arbre', 'Herbe', 'Roche'], 0),
    Question('🐸 Lequel vit dans l’eau ?', ['Chien', 'Grenouille', 'Chat', 'Cheval'], 1),
    Question('🍪 Lequel est une douceur ?', ['Pain', 'Cookie', 'Riz', 'Pomme de terre'], 1),
    Question('🎵 Lequel est un instrument de musique ?', ['Piano', 'Livre', 'Chaise', 'Stylo'], 0),
    Question('⚽ Qu’utilisez-vous pour jouer au football ?', ['Balle', 'Batte', 'Gant', 'Raquette'], 0),
    Question('🌟 Lequel brille dans le ciel nocturne ?', ['Lune', 'Soleil', 'Nuage', 'Arbre'], 0),
    // ... add the rest of French questions here
  ],
  QuizLanguage.arabic: [
    Question('🌤️ ما لون السماء؟', ['أزرق', 'أخضر', 'أحمر', 'أصفر'], 0),
    Question('🕷️ كم عدد أرجل العنكبوت؟', ['6', '8', '10', '4'], 1),
    Question('🐶 أي حيوان ينبح؟', ['قط', 'بقرة', 'كلب', 'عصفور'], 2),
    Question('🧮 كم يساوي 2 + 2؟', ['3', '4', '5'], 1),
    Question('🍌 أيهم فاكهة؟', ['جزرة', 'موز', 'بطاطا', 'بصل'], 1),
    Question('🐶 أيهم حيوان؟', ['سيارة', 'كلب', 'طاولة', 'كرسي'], 1),
    Question('🌈 ما لون السماء؟', ['أخضر', 'أزرق', 'أحمر', 'أصفر'], 1),
    Question('🚗 أيهم يستطيع الطيران؟', ['سيارة', 'قارب', 'طائرة', 'دراجة'], 2),
    Question('🍎 أيهما أحمر؟', ['موز', 'تفاح', 'عنب', 'برتقال'], 1),
    Question('🌻 أيهما زهرة؟', ['وردة', 'شجرة', 'عشب', 'صخرة'], 0),
    Question('🐸 أيهما يعيش في الماء؟', ['كلب', 'ضفدع', 'قط', 'حصان'], 1),
    Question('🍪 أيهما حلوى؟', ['خبز', 'كوكي', 'أرز', 'بطاطا'], 1),
    Question('🎵 أيهما آلة موسيقية؟', ['بيانو', 'كتاب', 'كرسي', 'قلم'], 0),
    Question('⚽ ماذا تستخدم للعب كرة القدم؟', ['كرة', 'مضرب', 'قفاز', 'مضرب تنس'], 0),
    Question('🌟 أيهما يلمع في السماء ليلاً؟', ['قمر', 'شمس', 'سحاب', 'شجرة'], 0),
    // ... add the rest of Arabic questions here
  ],
};
