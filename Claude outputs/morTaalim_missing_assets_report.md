# morTaalim — Missing Assets Audit & Icon Generation Prompts

Scanned all 939 files under `assets/` against every `assets/...` string referenced in `lib/` (Dart source). Of ~660 unique paths referenced in code, **111 do not resolve to a real file**. After checking each one by hand against the actual folder structure, they split into three real categories below. Dynamic paths built from variables (e.g. `assets/audios/piano_notes/$note.mp3`, the SugarSmash candy colors, the MemoryFlip tile sets, the Puzzle images) were checked against their folders and are all fine — false positives from the scan, not listed here.

---

## 1. Path bugs — fix in code, no new assets needed

These images already exist in the project; the Dart code just points at the wrong path. Fixing these is a 2-minute find-and-replace, not an asset problem.

| Referenced (broken) path | Used in | Real file that already exists |
|---|---|---|
| `assets/images/AvatarImage/Avatar2.png` | `IT_index_tool/iT_grid.dart:160,467` | `assets/images/AvatarImage/OnlyAvatar/Avatar2.png` |
| `assets/images/PetImages/17.png` | `Pet/pet_home_page.dart:254` | `assets/images/PetImages/DragonPet/17.png` |
| `assets/images/PetImages/18.png` | `Pet/pet_home_page.dart:255` | `assets/images/PetImages/DragonPet/18.png` |
| `assets/images/PetImages/19.png` | `Pet/pet_home_page.dart:256` | `assets/images/PetImages/DragonPet/19.png` |
| `assets/images/PetImages/20.png` | `Pet/pet_home_page.dart:257` | `assets/images/PetImages/DragonPet/20.png` |
| `assets/images/PractiseImage/house.jpg` | `primaire2Page/.../1_primaire_French_Practise.dart:31` | almost certainly `assets/images/PractiseImage/maison.jpg` (same word, French vocab set) |

**Fix:** in each file above, prepend the missing subfolder (`OnlyAvatar/`, `DragonPet/`) to the path, and swap `house.jpg` → `maison.jpg` (or rename the file if you'd rather keep the English name — just pick one and make code and file agree).

---

## 2. Missing audio (not images — out of scope for the icon prompts below, listed for completeness)

40 audio files are referenced but don't exist. These need voice recording or TTS, not image generation:

- **French vocabulary pronunciation** (images already exist in `PractiseImage/`, audio doesn't): `arbre, avion, banane, bateau, chaussure, ecole, fleur, livre, lune, oiseau, papillon, poisson, robe, soleil` → expected at `assets/audio/*.mp3`
- **Animal sounds**: `cat, cow, dog, duck, horse, sheep` → expected at `assets/audios/animals/*.mp3`
- **Arabic letters**: `alif, baa, jeem, taa` → expected at `assets/audios/arabic_letters/*.mp3`
- **Islamic terms**: `hajj, ramadan, salat, shahada, zakat` → expected at `assets/audios/*.mp3`
- **Sound effects / UI**: `PopButton_SB.mp3`, `XPWin.mp3`, `victory2_SFX.mp3`
- **Soundtrack**: `SakuraGirlYay_BcG, SakuraGirl_bkG, arcade-beat, happy, piano` → `assets/audios/sound_track/*.mp3`
- **Object sounds**: `balloon, book, coin, elephant, feather, leaf, rock, wrong` → `assets/sounds/*.mp3` (note: this whole `assets/sounds/` folder doesn't exist — everything else lives under `assets/audios/`, so this looks like another path-naming inconsistency worth standardizing)

---

## 3. Genuinely missing images — need to be created

These have no matching file anywhere in the project. Grouped below into icon-grid batches you can hand to an AI image generator (Midjourney, DALL·E, Ideogram, etc.), generate as one grid image, then crop into individual files.

### Style brief (applies to every prompt below)
Flat vector cartoon / kawaii style, matching a colorful kids' educational app (Duolingo-esque): bold clean outlines, rounded shapes, soft pastel-to-bright color palette, simple friendly faces where applicable, centered subject with generous padding, **plain solid white background** (for easy cropping/knockout), no text or watermarks, consistent lighting (flat, no harsh shadows), consistent stroke weight across the whole set.

---

### Batch A — IT / Computer Science course icons (16 icons)
Used in `IT_index_tool/iT_data.dart` for the "Découverte de l'informatique" course tiles. This entire `assets/images/IT/` folder doesn't exist — needed from scratch.

**Files needed:** `internet.png, safety.png, folders.png, typing.png, algorithm.png, loops.png, password.png, filetypes.png, binary.png, network.png, scratch.png, cyber.png, python.png, database.png, html.png, ai.png`

**Prompt (generate as a 4×4 grid, then crop each cell to its own square PNG):**
> A 4x4 grid of 16 flat vector cartoon icons for a kids' computer-science app, one concept per cell, each icon centered on its own white square with thin light-gray divider lines between cells: (1) internet — a cute globe with wifi signal waves, (2) online safety — a friendly shield with a padlock, (3) folders — a smiling yellow file folder, (4) typing — a keyboard with a cursor blinking, (5) algorithm — a flowchart with rounded arrows, (6) loops — a circular arrow repeating, (7) password — a padlock with dots, (8) file types — a stack of colorful file icons, (9) binary numbers — a chip with 0s and 1s, (10) computer network — three connected computer nodes, (11) Scratch coding — colorful jigsaw-puzzle code blocks, (12) cybersecurity — a shield with a bug crossed out, (13) Python — a cute snake mascot coiled around a laptop, (14) database — a stack of cylinder disks, (15) HTML/web — a browser window with code brackets </>, (16) artificial intelligence — a friendly cartoon robot head with a lightbulb. Bold clean outlines, rounded shapes, bright pastel colors, flat design, no gradients, no text labels, no shadows, consistent style across all 16 icons.

---

### Batch B — Arabic alphabet vocabulary images (4 images)
Used in `PractiseGames/ArabicExercice/ArabicLetters.dart` — each Arabic letter is paired with a word and an illustration.

**Files needed:** `asad.png` (أسد / lion), `duck.png` (بطة / duck), `apple.png` (تفاح / apple), `camel.png` (جمل / camel)

**Prompt (2×2 grid):**
> A 2x2 grid of 4 flat vector cartoon icons for a kids' Arabic-alphabet learning app, one per cell on a white background with thin divider lines: (1) a cute friendly lion sitting, (2) a cute cartoon duck, (3) a shiny red apple with a leaf, (4) a friendly cartoon camel standing. Bold outlines, rounded kawaii style, bright flat colors, centered composition, no text, no shadows, consistent art style across all 4.

*(Note: `duck.png` here can double as the duck image needed in Batch C below — same subject, reuse the crop instead of generating twice.)*

---

### Batch C — Animal sounds game images (5 new + 1 reused from Batch B)
Used in `PractiseGames/ScienceExercice/AnimalSounds.dart`.

**Files needed:** `dog.png, cat.png, cow.png, sheep.png, horse.png` (+ `duck.png` from Batch B)

**Prompt (2×3 grid):**
> A 2x3 grid of 5 flat vector cartoon farm-animal icons for a kids' app, one per cell on a white background with thin divider lines: (1) a happy cartoon dog sitting, (2) a cute cartoon cat sitting, (3) a friendly cartoon cow standing, (4) a fluffy cartoon sheep, (5) a cute cartoon horse standing. Bold clean outlines, rounded kawaii style, bright flat pastel colors, centered, no text, no shadows, consistent style across all icons and matching the same art style as a lion/duck/apple/camel set already made for this app.

---

### Batch D — Science quiz images (5 icons)
Used in `PractiseGames/ScienceExercice/ScienceQuizz.dart`.

**Files needed:** `water_state.png, oxygen.png, sun.png, helium_balloon.png, ice.png`

**Prompt (grid, e.g. 2×3 with one empty cell or 1×5 row):**
> A row of 5 flat vector cartoon science icons for a kids' science-quiz app, one per cell on a white background with thin divider lines: (1) the three states of water — ice cube, water droplet and steam cloud arranged together, (2) an oxygen molecule — two friendly cartoon-faced blue spheres connected, (3) a smiling cartoon sun with rays, (4) a red helium balloon floating with a string, (5) a cartoon ice cube with a sparkle. Bold outlines, rounded kawaii style, bright flat colors, centered, no text, no shadows, consistent style across all 5.

---

### Batch E — Misc single icons (3 icons, can be generated together in one small grid)
- `islamic_icon.png` — used in `PractiseGames/IslamExercice/PillarOfIslam.dart` (icon representing the 5 Pillars of Islam)
- `waki_avatar.png` — the chatbot's mascot avatar, used in `widgets/AIChatbot/ChatBotScreen.dart` (the bot is called "Waki" — check `WakiBrain/` folder for personality context before generating so the mascot design matches the bot's tone)
- `bg_QuizzGame` already exists twice (`.jpg` and `.png`) so is not included here

**Prompt (1×2 grid):**
> A row of 2 flat vector cartoon icons on a white background with a thin divider line: (1) an Islamic geometric star/mosque-silhouette icon in a friendly rounded flat style suitable for a kids' education app teaching the Pillars of Islam, gold and teal color palette, (2) a cute friendly cartoon robot/mascot character named "Waki" for a kids' chatbot — round-headed, big expressive eyes, small antenna, warm smile, sitting or waving pose. Bold outlines, rounded kawaii style, bright flat colors, no text, no shadows.

---

### Batch F — Time-of-day icons for the drag-and-drop exercise (3 icons)
Used in `ExericeWidgets_Tools_Widgets/Drag_Drop_Tool_Widget/DragAndDropPage.dart`. **Note:** in the code these are currently named `logo_black.png` (mapped to "morning"), `logo_white.png` ("noon"), and `red.jpg` ("evening") — those look like placeholder/copy-paste names left over from testing, not intentional filenames. Recommend renaming to something readable like `morning.png` / `noon.png` / `evening.png` once you generate them (and updating the 3 lines in that file to match).

**Prompt (1×3 grid):**
> A row of 3 flat vector cartoon icons for a kids' app showing times of day, one per cell on a white background with thin divider lines: (1) morning — a cartoon sun rising behind rolling hills with a light orange sky, (2) noon — a bright cartoon sun high in a blue sky with a few clouds, (3) evening — a cartoon sunset with an orange-pink sky and a crescent moon peeking. Bold outlines, rounded kawaii style, bright flat colors, centered, no text, no shadows, consistent style across all 3.

---

### Batch G — App theme background banners (5 large images)
Used in `Themes/AppTheme.dart` as the full-screen background for each selectable app theme. These are backgrounds, not icons — generate each as a standalone portrait image (e.g. 1080×1920) rather than a grid cell, since they'll be viewed full-screen, not cropped from a sheet.

**Files needed:** `assets/banners/ocean.png, sunset.png, forest.png, purple.png, dark.png`

**Prompts (one per image):**
> "Ocean" theme: a soft flat-vector illustrated background of a calm cartoon ocean scene — gentle waves, a few fluffy clouds, warm sunlight, pastel blue-and-teal palette, no characters, no text, safe empty space in the center-top for UI overlay, portrait orientation.

> "Sunset" theme: a flat-vector illustrated background of a dreamy sunset sky — gradient from pink to orange to purple, soft silhouette hills at the bottom, a few birds, pastel warm palette, no text, portrait orientation.

> "Forest" theme: a flat-vector illustrated background of a cheerful cartoon forest — soft green trees, dappled sunlight, a gentle path, pastel green palette, no characters, no text, portrait orientation.

> "Purple" theme: a flat-vector illustrated background with a dreamy purple/lavender gradient sky, soft stars or bokeh light dots, gentle rolling clouds, pastel purple-violet palette, no text, portrait orientation.

> "Dark" theme: a flat-vector illustrated dark-mode background — deep navy/charcoal gradient sky with soft glowing stars and a crescent moon, cozy and calm, no harsh contrast, no text, portrait orientation.

---

### Optional / lower priority — Batch H: playing-card deck
`lib/TestingBeforeProdcution/CardConcept.dart` and `Hezz2Game.dart` reference a full `assets/images/cards/` deck (`{suit}_{rank}.png` for all 52 cards, plus `backCard.png`) that doesn't exist at all. These files live under `TestingBeforeProdcution/`, which reads as work-in-progress/experimental code, not a shipped screen — confirm whether this card game is actually going into the app before spending generation budget on a full 53-image deck. If it is, that's its own dedicated batch (a 13×4 grid per suit is the practical way to generate + crop it) — happy to write that prompt separately once you confirm the feature is live.

---

## Suggested next step
Once you generate each grid image, crop it into the individual files named above and drop them into the exact folders listed (create `assets/images/IT/` and `assets/banners/` — they don't exist yet). Everything else already has its target folder. After adding the files, also apply the 6 path fixes in Section 1 — those need a code edit either way, generated images won't fix them.
