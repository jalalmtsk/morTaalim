Map<String, String> getAllDefinitions() {
  return {
    'Flick': 'A funny fox who loves dancing.',
    'bunny': 'A small, fluffy rabbit.',
    'forest': 'A large area covered with trees and animals.',
    'time' : "To Dance Baby",

    'Once': 'One time in the past. / Une fois / مرة واحدة',
    'upon': 'On or after. / Sur / عند',
    'a': 'One thing. / Un(e) / واحد',
    'time,': 'A moment or period. / Temps / وقت',
    'there': 'In that place. / Là-bas / هناك',
    'was': 'Past form of “is”. / Était / كان',
    'silly': 'Funny or a little crazy. / Bête / أحمق',
    'fox': 'A small wild animal with a bushy tail. / Renard / ثعلب',
    'named': 'Called or known as. / Appelé / اسمه',
    'Flick,': 'The name of a funny fox! / Flick (nom propre) / فليك',
    'who': 'The person or animal that does something. / Qui / الذي',
    'loved': 'Really liked something. / Aimait / أحب',
    'to': 'Shows direction or purpose. / À / إلى',
    'dance': 'Move to music. / Danser / يرقص',
    'in': 'Inside something. / Dans / في',
    'the': 'Used to point to something specific. / Le, la, les / ال',
    'rain.': 'Water falling from the sky. / Pluie / مطر',

    'decided': 'Made a choice. / Décidé / قرر',
    'invite': 'Ask someone to join. / Inviter / دعا',
    'his': 'Belongs to him. / Son / له',
    'best': 'The most awesome one! / Le meilleur / الأفضل',
    'friend,': 'Someone you like and trust. / Ami / صديق',
    'Benny': 'A bunny’s name! / Benny (nom propre) / بيني',
    'bunny,': 'A small, fluffy rabbit. / Lapin / أرنب',
    'join': 'Come together. / Rejoindre / انضم',
    'rain': 'Water falling from the sky. / Pluie / مطر',
    'party.': 'A fun gathering. / Fête / حفلة',

    'Together,': 'With each other. / Ensemble / معاً',
    'they': 'More than one person or animal. / Ils / هم',
    'danced': 'Moved to music in the past. / Ont dansé / رقصوا',
    'and': 'Also, plus. / Et / و',
    'laughed,': 'Made happy sounds. / Ont ri / ضحكوا',
    'making': 'Creating something. / Faisant / يصنعون',
    'happier': 'More joyful. / Plus heureux / أكثر سعادة',
    'place.': 'A location. / Endroit / مكان',
    'Suddenly,': 'All of a sudden. / Soudainement / فجأة',
    'rainbow': 'Colors in the sky after rain. / Arc-en-ciel / قوس قزح',
    'appeared,': 'Showed up. / Apparut / ظهر',
    'wished': 'Hoped for something. / Souhaité / تمنى',
    'for': 'Because of or to get. / Pour / من أجل',
    'more': 'A larger amount. / Plus / أكثر',
    'adventures.': 'Exciting journeys. / Aventures / مغامرات',

    'Oops!': 'A little mistake or surprise! / Oups! / أوه!',
    'He': 'A boy or male animal. / Il / هو',
    'slipped': 'Fell or lost balance. / A glissé / انزلق',
    'did': 'Performed an action. / A fait / فعل',
    'funny': 'Something that makes you laugh. / Drôle / مضحك',
    'twirl!': 'A spin around and around. / Tourbillon / دوران',

    'tried': 'Made an attempt. / A essayé / حاول',
    'hop': 'Jump like a bunny. / Sauter / يقفز',
    'ended': 'Finished or stopped. / A fini / انتهى',
    'splashing': 'Water flying around. / Éclaboussant / رشق',
    'mud': 'Wet dirt. / Boue / طين',
    'everywhere!': 'All places. / Partout / في كل مكان',

    'Rainbow': 'Colors in the sky after rain. / Arc-en-ciel / قوس قزح',
    'magic': 'Special, amazing power. / Magie / سحر',
    'made': 'Created or caused. / A fait / جعل',
    'ears': 'The parts on your head to hear. / Oreilles / آذان',
    'glow': 'Shine brightly. / Briller / يلمع',
    'bright': 'Very light and shiny. / Brillant / ساطع',
    'pink!': 'A color like light red. / Rose / وردي',


    // Add more...
  };
}

String getDefinitionFor(String word) {
  return getAllDefinitions()[word] ?? 'No definition found.';
}
