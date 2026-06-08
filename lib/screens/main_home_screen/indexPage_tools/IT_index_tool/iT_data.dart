// it_courses_data.dart
import 'package:flutter/material.dart';

final List<Map<String, dynamic>> itCourses = [

  // ══════════════════════════════════════════
  //  TIER 1 — GRADE 1–2  (Free, beginner)
  // ══════════════════════════════════════════
  {
    'title': 'itWhatIsComputer',
    'icon': Icons.computer_outlined,
    'routeName': 'IT_WhatIsComputer',
    'image': 'assets/images/GridImages/It_Grid/whatComputer_grid.png',
    'locked': false,
    'cost': 0,
    'grade': '1–2',
    'tag': 'hardware',
    // Exercise: tap-to-identify pictures of a computer, tablet, phone, TV
    // Question: "Which one is a computer?" → 4 image choices
  },
  {
    'title': 'itComputerParts',
    'icon': Icons.keyboard_outlined,
    'routeName': 'IT_ComputerParts',
    'image': 'assets/images/GridImages/It_Grid/computerParts_grid.png',
    'locked': false,
    'cost': 0,
    'grade': '1–2',
    'tag': 'hardware',
    // Exercise: labelling game — drag the name onto the part
    // Parts: monitor, keyboard, mouse, CPU tower, speaker
  },
  {
    'title': 'itMousePractice',
    'icon': Icons.mouse_outlined,
    'routeName': 'IT_MousePractice',
    'image': 'assets/images/GridImages/It_Grid/mousePractise_grid.png',
    'locked': false,
    'cost': 0,
    'grade': '1–2',
    'tag': 'hardware',
    // Exercise: tap/click moving targets (simulates mouse control)
    // Stars awarded by accuracy & speed
  },
  {
    'title': 'itInputOutput',
    'icon': Icons.swap_horiz,
    'routeName': 'IT_InputOutput',
    'image': 'assets/images/GridImages/It_Grid/inputOutput_grid.png',
    'locked': false,
    'cost': 0,
    'grade': '1–2',
    'tag': 'hardware',
    // Exercise: sort cards into INPUT or OUTPUT bucket
    // Cards: keyboard, monitor, printer, microphone, speaker, mouse
  },

  // ══════════════════════════════════════════
  //  TIER 2 — GRADE 2–3  (Low cost)
  // ══════════════════════════════════════════
  /*
  {
    'title': 'itInternetBasics',
    'icon': Icons.public_outlined,
    'routeName': 'IT_InternetBasics',
    'image': 'assets/images/IT/internet.png',
    'locked': true,
    'cost': 10,
    'grade': '2–3',
    'tag': 'internet',
    // Exercise: true/false quiz — "The internet needs wifi or cables: TRUE/FALSE?"
    // + drag: match website icon to its purpose (YouTube→videos, Google→search)
  },
  {
    'title': 'itOnlineSafety',
    'icon': Icons.shield_outlined,
    'routeName': 'IT_OnlineSafety',
    'image': 'assets/images/IT/safety.png',
    'locked': true,
    'cost': 10,
    'grade': '2–3',
    'tag': 'safety',
    // Exercise: scenario cards — "A stranger asks your address online. What do you do?"
    // 3 choices: Tell them / Ask a parent / Ignore
    // Safe/Unsafe badge shown after answer
  },
  {
    'title': 'itFileFolders',
    'icon': Icons.folder_outlined,
    'routeName': 'IT_FileFolders',
    'image': 'assets/images/IT/folders.png',
    'locked': true,
    'cost': 15,
    'grade': '2–3',
    'tag': 'files',
    // Exercise: virtual file explorer — drag files into the correct folder
    // Folders: Photos / Music / Documents / Videos
    // Files: dog.jpg, song.mp3, report.docx, movie.mp4 etc.
  },
  {
    'title': 'itTypingFingers',
    'icon': Icons.text_fields_outlined,
    'routeName': 'IT_TypingFingers',
    'image': 'assets/images/IT/typing.png',
    'locked': true,
    'cost': 15,
    'grade': '2–3',
    'tag': 'typing',
    // Exercise: on-screen keyboard highlight shows which finger to use
    // Kid taps the highlighted key before it changes
    // Home row (ASDF JKL;) first, then full keyboard progressively
  },

  // ══════════════════════════════════════════
  //  TIER 3 — GRADE 3–4  (Medium cost)
  // ══════════════════════════════════════════
  {
    'title': 'itWhatIsAlgorithm',
    'icon': Icons.account_tree_outlined,
    'routeName': 'IT_Algorithm',
    'image': 'assets/images/IT/algorithm.png',
    'locked': true,
    'cost': 20,
    'grade': '3–4',
    'tag': 'coding',
    // Exercise: put scrambled steps in the right order
    // Scenario: "Making a sandwich" → steps shown as cards, drag to sort
    // Then coding version: "Print 1 to 5" → sort the pseudocode blocks
  },
  {
    'title': 'itLoopsConditions',
    'icon': Icons.loop_outlined,
    'routeName': 'IT_LoopsConditions',
    'image': 'assets/images/IT/loops.png',
    'locked': true,
    'cost': 20,
    'grade': '3–4',
    'tag': 'coding',
    // Exercise: visual block coding (Scratch-style cards)
    // "Repeat 3 times: move forward" → animate a robot on screen
    // IF condition: "If door is locked → use key, ELSE → walk in"
  },
  {
    'title': 'itPasswordSafety',
    'icon': Icons.lock_outlined,
    'routeName': 'IT_PasswordSafety',
    'image': 'assets/images/IT/password.png',
    'locked': true,
    'cost': 20,
    'grade': '3–4',
    'tag': 'safety',
    // Exercise: rate passwords as Weak / Medium / Strong
    // "abc" → Weak, "Abc123!" → Strong
    // Tips shown after each rating: length, symbols, uppercase
  },
  {
    'title': 'itFileTypes',
    'icon': Icons.insert_drive_file_outlined,
    'routeName': 'IT_FileTypes',
    'image': 'assets/images/IT/filetypes.png',
    'locked': true,
    'cost': 25,
    'grade': '3–4',
    'tag': 'files',
    // Exercise: match extension to file type
    // .jpg → Image, .mp3 → Audio, .exe → Program, .pdf → Document
    // Quiz + drag-and-drop
  },

  // ══════════════════════════════════════════
  //  TIER 4 — GRADE 4–5  (Higher cost)
  // ══════════════════════════════════════════
  {
    'title': 'itBinaryNumbers',
    'icon': Icons.looks_two_outlined,
    'routeName': 'IT_BinaryNumbers',
    'image': 'assets/images/IT/binary.png',
    'locked': false,
    'cost': 30,
    'grade': '4–5',
    'tag': 'binary',
    // Exercise: flip bit switches (0/1 toggle buttons) to match a decimal
    // Start: convert 5 → binary (0101). Visual bulb: ON=1, OFF=0
    // Progression: 4-bit → 8-bit numbers
  },
  {
    'title': 'itHowInternetWorks',
    'icon': Icons.lan_outlined,
    'routeName': 'IT_HowInternet',
    'image': 'assets/images/IT/network.png',
    'locked': true,
    'cost': 30,
    'grade': '4–5',
    'tag': 'internet',
    // Exercise: animated packet journey — drag data "packets" from
    // your device → router → server → website
    // Quiz: "What does IP stand for?" 4 choices
  },
  {
    'title': 'itScratchCoding',
    'icon': Icons.code_outlined,
    'routeName': 'IT_ScratchCoding',
    'image': 'assets/images/IT/scratch.png',
    'locked': true,
    'cost': 35,
    'grade': '4–5',
    'tag': 'coding',
    // Exercise: Scratch-style drag-and-drop block coding
    // Challenges: make sprite move, loop a dance, if-key-pressed jump
    // 5 mini-challenges with XP reward each
  },
  {
    'title': 'itCyberThreats',
    'icon': Icons.bug_report_outlined,
    'routeName': 'IT_CyberThreats',
    'image': 'assets/images/IT/cyber.png',
    'locked': true,
    'cost': 35,
    'grade': '4–5',
    'tag': 'safety',
    // Exercise: spot-the-phishing email game
    // Fake email shown → circle suspicious elements (wrong sender, bad link)
    // Types covered: virus, phishing, spam, malware
  },

  // ══════════════════════════════════════════
  //  TIER 5 — GRADE 5–6  (Advanced)
  // ══════════════════════════════════════════
  {
    'title': 'itIntroToPython',
    'icon': Icons.terminal_outlined,
    'routeName': 'IT_IntroPython',
    'image': 'assets/images/IT/python.png',
    'locked': true,
    'cost': 50,
    'grade': '5–6',
    'tag': 'coding',
    // Exercise: fill-in-the-blank Python code
    // print("Hello ___") → type "World"
    // x = 5 + ___ → tap correct number from choices
    // Mini challenges: variables, print, simple if/else
  },
  {
    'title': 'itDataAndDatabases',
    'icon': Icons.storage_outlined,
    'routeName': 'IT_Databases',
    'image': 'assets/images/IT/database.png',
    'locked': true,
    'cost': 50,
    'grade': '5–6',
    'tag': 'data',
    // Exercise: build a mini database — add/remove student records
    // Concepts: rows, columns, fields, search/filter
    // Quiz: "What is a primary key?" 4 choices
  },
  {
    'title': 'itHtmlBasics',
    'icon': Icons.html_outlined,
    'routeName': 'IT_HtmlBasics',
    'image': 'assets/images/IT/html.png',
    'locked': true,
    'cost': 60,
    'grade': '5–6',
    'tag': 'coding',
    // Exercise: live HTML editor (simple)
    // Pre-filled template with blanks: <h1>___</h1> → type title
    // See rendered output update in real time on the right side
    // Tags covered: h1, p, b, img, a, ul/li
  },
  {
    'title': 'itAiAndRobots',
    'icon': Icons.smart_toy_outlined,
    'routeName': 'IT_AiRobots',
    'image': 'assets/images/IT/ai.png',
    'locked': true,
    'cost': 60,
    'grade': '5–6',
    'tag': 'ai',
    // Exercise: train a simple image classifier — drag dog/cat images
    // into training buckets, then test it on new images
    // Quiz: "What is machine learning?" + real-life AI examples
  },

   */
];