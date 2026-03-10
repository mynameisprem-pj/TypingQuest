# TypingQuest 🎯⌨️

> A fun, gamified typing trainer built for students. 
TypingQuest teaches keyboard skills through structured lessons, timed practice, LAN multiplayer races, and action-packed typing games — all in one app.

---

## ✨ Features

### 🎓 Solo Practice
- **300 levels** across 3 difficulties — Beginner, Intermediate, Master
- Each level has a **fixed time limit** — finish before the clock runs out
- Real-time WPM, accuracy, and countdown timer
- ⭐ Star rating system (1–3 stars) based on speed and accuracy
- Virtual keyboard with **finger color hints** for beginners
- Progress saved per student profile

### 📚 Structured Lessons
- 6 courses covering home row, top row, bottom row, numbers, symbols, and speed
- Step-by-step finger placement guidance with hand diagrams
- Lesson progress tracked separately from solo practice

### ⏱️ Timed Challenge
- Type as much as possible in **1, 2, or 5 minutes**
- WPM graph showing your speed over time
- Personal best tracking per difficulty

### 🖊️ Custom Text
- Paste any text and practice typing it
- Great for typing homework, notes, or paragraphs from textbooks

### 🌐 LAN Race *(School Network)*
- Multiplayer typing race over your school's local network
- **Host** picks text and game mode:
  - **Finish Race** — first to complete the full text wins
  - **Timed Battle** — most words typed in the time limit wins
- Live standings and progress bars for all players
- Supports up to 10 players simultaneously

### 🎮 Learn With Fun — Game Hub
Two fully playable games with more coming soon:

| Game | Description | Status |
|---|---|---|
| 🚀 Space Shooter | Type words to fire lasers and destroy alien invaders. Combo multipliers + boss waves every 10 kills | ✅ Available |
| 🧟 Zombie Survival | Defend your base from zombie hordes across 3 lanes. Power-ups: FREEZE all zombies, BOMB clears the screen | ✅ Available |
| 🏎️ Car Race | Type to accelerate and beat AI opponents | 🔜 Coming Soon |
| 🐟 Deep Sea Diver | Type words to collect treasure and scare sharks | 🔜 Coming Soon |
| ⚔️ Typing Knight | Turn-based RPG — type to attack and defend | 🔜 Coming Soon |

### 👤 Student Profiles
- Multiple profiles on one device — perfect for shared school computers
- Each profile has its own name, class, avatar, progress and high scores
- Switch profiles without losing any data

### 🏆 Achievements
- 20+ achievements for speed, accuracy, streaks, and consistency
- Toast notifications when you unlock one mid-session

### 📊 Stats
- WPM history graph
- Best WPM, total words typed, total time practiced
- Average accuracy across all sessions

---

## 🖼️ Screenshots

> *(Add your screenshots here after deploying)*

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Platforms | Windows Desktop, Web |
| Storage | `shared_preferences` |
| Fonts | Google Fonts (Poppins + Inter) |
| Audio | `audioplayers` |
| Graphics | Custom `CustomPainter` (no game engine) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) — stable channel
- Dart SDK ≥ 3.0.0
- For Windows builds: Visual Studio 2022 with **Desktop development with C++**

### Run Locally

```bash
# Clone the repository
git clone https://github.com/mynameisprem-pj/typingquest.git
cd typingquest

# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on Chrome (web)
flutter run -d chrome
```

### Build for Release

```bash
# Windows
flutter build windows --release

# Web (for deployment)
flutter build web --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point + service init
├── theme/
│   └── app_theme.dart           # Colors, typography, shared styles
├── data/
│   ├── typing_content.dart      # All 300 level texts + time limits
│   └── lesson_data.dart         # Lesson course content
├── models/
│   └── game_models.dart         # Difficulty, LevelResult, LanPlayer etc.
├── services/
│   ├── profile_service.dart     # Multi-profile management
│   ├── progress_service.dart    # Solo level progress + stars
│   ├── stats_service.dart       # WPM history + totals
│   ├── achievements_service.dart
│   ├── lesson_progress_service.dart
│   ├── lan_service.dart         # TCP socket LAN multiplayer
│   └── sound_service.dart       # Key click + effect sounds
├── widgets/
│   ├── virtual_keyboard.dart    # On-screen keyboard with highlights
│   ├── virtual_hands.dart       # Animated hand/finger diagrams
│   ├── wpm_graph.dart           # Line chart for WPM history
│   └── achievement_toast.dart   # Slide-in achievement notification
└── screens/
    ├── home/
    │   ├── home_screen.dart     # Dashboard + navigation drawer
    │   └── falling_words_game.dart
    ├── solo/                    # Difficulty → Level select → Typing
    ├── lessons/                 # Course list → Lesson viewer
    ├── timed/                   # Timed challenge screen
    ├── custom/                  # Custom text practice
    ├── lan/                     # Host, Join, Race screens
    ├── fun/
    │   ├── fun_hub_screen.dart  # Game selection hub
    │   ├── space_shooter_game.dart
    │   └── zombie_survival_game.dart
    ├── stats/
    ├── achievements/
    └── profile/
```

---

## 🎮 How the Games Work

### Space Shooter
- Aliens fall from the top of the screen, each carrying a word
- Type the **first letter** to lock on and rotate your ship toward it
- Each correct letter fires a bullet — **finish the word** to destroy the alien
- Every 10 kills triggers a **Boss Wave** — type a full sentence to defeat it
- Chain kills for Combo Multipliers: 5× kill = 2× points, 10× kill = 3× points
- 3 difficulties: Cadet (short words), Pilot (medium), Commander (long words)

### Zombie Survival
- Zombies walk left across **3 lanes** toward your base
- Type their word to fire bullets — each letter = one bullet
- Special zombie types: **Fast** (runs), **Tank** (slow but tough words)
- Power-ups: **❄ Freeze** zombie (type "freeze") freezes all zombies for 4 seconds
- **💣 Bomb** zombie (type "bomb") clears all normal zombies instantly
- Survive endless waves — each wave is faster and denser

---

## 🏫 About This Project

The project was developed entirely in Flutter/Dart with no external game engines — all game graphics are drawn using Flutter's `CustomPainter` API.

---

## 📄 License

This project is open source and free to use for educational purposes.

---

## 🙏 Acknowledgements

- Built with [Flutter](https://flutter.dev)
- Fonts by [Google Fonts](https://fonts.google.com)
