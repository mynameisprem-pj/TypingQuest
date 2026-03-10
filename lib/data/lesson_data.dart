// ── Lesson System Data ────────────────────────────────────────────────────
// Courses → Lessons → Exercises
// Each exercise drills specific keys with increasing difficulty.

class LessonExercise {
  final String title;
  final String text;
  final String hint; // short tip shown during exercise

  const LessonExercise({
    required this.title,
    required this.text,
    required this.hint,
  });
}

class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String keys; // keys introduced in this lesson e.g. "A S D F"
  final List<LessonExercise> exercises;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.keys,
    required this.exercises,
  });
}

class LessonCourse {
  final String id;
  final String title;
  final String description;
  final String icon;
  final List<Lesson> lessons;

  const LessonCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.lessons,
  });
}

// ── All Courses ────────────────────────────────────────────────────────────
class LessonData {
  static const List<LessonCourse> courses = [
    _homeRowCourse,
    _topRowCourse,
    _bottomRowCourse,
    _numbersCourse,
    _symbolsCourse,
    _speedDrillsCourse,
  ];

  static LessonCourse? getCourse(String id) {
    try { return courses.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  static Lesson? getLesson(String courseId, String lessonId) {
    final course = getCourse(courseId);
    if (course == null) return null;
    try { return course.lessons.firstWhere((l) => l.id == lessonId); } catch (_) { return null; }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 1: HOME ROW MASTERY
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _homeRowCourse = LessonCourse(
  id: 'home_row',
  title: 'Home Row Mastery',
  description: 'The foundation of typing. Master A S D F J K L and never look at the keyboard again.',
  icon: '🏠',
  lessons: [
    Lesson(
      id: 'left_home',
      title: 'Left Hand: A S D F',
      subtitle: 'Pinky, Ring, Middle, Index fingers',
      keys: 'A S D F',
      exercises: [
        LessonExercise(
          title: 'Meet the keys',
          text: 'a a a s s s d d d f f f',
          hint: 'Place your left fingers on A S D F. Type slowly.',
        ),
        LessonExercise(
          title: 'Mix it up',
          text: 'as as sd sd df df fa fa',
          hint: 'Keep your fingers resting on home row between keystrokes.',
        ),
        LessonExercise(
          title: 'Simple words',
          text: 'add dad fad sad ask flask',
          hint: 'Real words! Keep eyes on screen, not keyboard.',
        ),
        LessonExercise(
          title: 'Speed drill',
          text: 'as sad fad add ask dad fads flask salads falls',
          hint: 'Go as fast as feels comfortable. Accuracy first!',
        ),
      ],
    ),
    Lesson(
      id: 'right_home',
      title: 'Right Hand: J K L ;',
      subtitle: 'Index, Middle, Ring, Pinky fingers',
      keys: 'J K L ;',
      exercises: [
        LessonExercise(
          title: 'Meet the keys',
          text: 'j j j k k k l l l ; ; ;',
          hint: 'Place your right fingers on J K L ;. Type slowly.',
        ),
        LessonExercise(
          title: 'Mix it up',
          text: 'jk jk kl kl lj lj jl jl',
          hint: 'Right hand stays still — only fingers move to their keys.',
        ),
        LessonExercise(
          title: 'Simple words',
          text: 'jell kill lull skill fill ill',
          hint: 'Keep your wrist relaxed and flat above the keyboard.',
        ),
        LessonExercise(
          title: 'Speed drill',
          text: 'jk kl lj jl jkl lkj skill fill kill jell',
          hint: 'Push a little faster this time. You know these keys!',
        ),
      ],
    ),
    Lesson(
      id: 'both_home',
      title: 'Both Hands Together',
      subtitle: 'Full home row: A S D F J K L',
      keys: 'A S D F J K L',
      exercises: [
        LessonExercise(
          title: 'Warm up',
          text: 'fjfj dkdk slsl ajaj fkfk dlsl',
          hint: 'F and J are the anchor keys — they have bumps you can feel.',
        ),
        LessonExercise(
          title: 'Real words',
          text: 'fall lads ask jail skill flask salad',
          hint: 'Both hands working together now. Stay relaxed.',
        ),
        LessonExercise(
          title: 'Sentences',
          text: 'a lad asks a dad for a flask',
          hint: 'Use your thumb for the spacebar. Do not look down!',
        ),
        LessonExercise(
          title: 'Final drill',
          text: 'dad falls ask a lad add salad flask skills all fall',
          hint: 'This is your home row foundation. Feel the keys!',
        ),
      ],
    ),
    Lesson(
      id: 'home_with_e_i',
      title: 'Add E and I',
      subtitle: 'Your index fingers reach up',
      keys: 'E I',
      exercises: [
        LessonExercise(
          title: 'Reach for E',
          text: 'de de ed ed ded ede fee see',
          hint: 'Middle finger of LEFT hand reaches UP one row for E.',
        ),
        LessonExercise(
          title: 'Reach for I',
          text: 'ki ki ik ik kik iki ill sill',
          hint: 'Middle finger of RIGHT hand reaches UP one row for I.',
        ),
        LessonExercise(
          title: 'E and I together',
          text: 'like side feel file life isle',
          hint: 'Return fingers to home row after every keystroke.',
        ),
        LessonExercise(
          title: 'Sentences',
          text: 'i feel like a skilled filer',
          hint: 'E and I are two of the most common letters in English.',
        ),
      ],
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 2: TOP ROW
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _topRowCourse = LessonCourse(
  id: 'top_row',
  title: 'Top Row Takeover',
  description: 'Q W E R T Y U I O P — master the top row and unlock the full alphabet.',
  icon: '⬆️',
  lessons: [
    Lesson(
      id: 'left_top',
      title: 'Left Top: Q W E R T',
      subtitle: 'Pinky to index finger, top row',
      keys: 'Q W E R T',
      exercises: [
        LessonExercise(
          title: 'Q and W',
          text: 'qq ww qw wq qqw wwq qwq wqw',
          hint: 'Pinky reaches up for Q, Ring finger for W.',
        ),
        LessonExercise(
          title: 'E and R',
          text: 'er re ere rere free tree deer',
          hint: 'Middle finger for E, Index finger for R.',
        ),
        LessonExercise(
          title: 'Add T',
          text: 'tr rt tt trt rtt tree treat street',
          hint: 'Index finger stretches LEFT slightly to reach T.',
        ),
        LessonExercise(
          title: 'All left top',
          text: 'write questrew tree water sweet',
          hint: 'Return to home row between words. Do not hover.',
        ),
        LessonExercise(
          title: 'Sentences',
          text: 'we write sweet words at the desk',
          hint: 'Great job! You are building real typing speed now.',
        ),
      ],
    ),
    Lesson(
      id: 'right_top',
      title: 'Right Top: Y U I O P',
      subtitle: 'Index to pinky, top row',
      keys: 'Y U I O P',
      exercises: [
        LessonExercise(
          title: 'Y and U',
          text: 'yu uy yuy uyu yuu uuy you your',
          hint: 'Y: Index stretches RIGHT. U: Index goes straight up.',
        ),
        LessonExercise(
          title: 'I and O',
          text: 'io oi ioi oio oil oil join foil',
          hint: 'I: Middle finger up. O: Ring finger up.',
        ),
        LessonExercise(
          title: 'Add P',
          text: 'op po pp pop top stop drip drop',
          hint: 'Pinky reaches up for P. Keep your wrist still.',
        ),
        LessonExercise(
          title: 'All right top',
          text: 'your type print purple output',
          hint: 'Five new keys — keep calm and type steadily.',
        ),
        LessonExercise(
          title: 'Sentences',
          text: 'you type your output pretty well',
          hint: 'Top row is now yours. Excellent progress!',
        ),
      ],
    ),
    Lesson(
      id: 'full_top',
      title: 'Full Top Row',
      subtitle: 'Q through P — the QWERTY row',
      keys: 'Q W E R T Y U I O P',
      exercises: [
        LessonExercise(
          title: 'The classic sentence',
          text: 'the quick brown fox jumps',
          hint: 'One of the most famous typing practice sentences.',
        ),
        LessonExercise(
          title: 'Common words',
          text: 'write quiet pretty power quite tower',
          hint: 'You know all these letters now. Trust your fingers.',
        ),
        LessonExercise(
          title: 'Speed drill',
          text: 'type your text with power and write proper output',
          hint: 'Push your speed a little. Aim for no errors first.',
        ),
        LessonExercise(
          title: 'Final challenge',
          text: 'we write quotes properly to improve our typing power',
          hint: 'Top row mastered! Bottom row is next.',
        ),
      ],
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 3: BOTTOM ROW
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _bottomRowCourse = LessonCourse(
  id: 'bottom_row',
  title: 'Bottom Row Complete',
  description: 'Z X C V B N M and punctuation. Complete your keyboard mastery.',
  icon: '⬇️',
  lessons: [
    Lesson(
      id: 'left_bottom',
      title: 'Left Bottom: Z X C V B',
      subtitle: 'Pinky to index, bottom row',
      keys: 'Z X C V B',
      exercises: [
        LessonExercise(
          title: 'Z and X',
          text: 'zz xx zx xz zxz xzx zinc fix',
          hint: 'Z: Pinky reaches down. X: Ring finger reaches down.',
        ),
        LessonExercise(
          title: 'C and V',
          text: 'cv vc cvv vcc cave vice voice',
          hint: 'C: Middle finger down. V: Index finger down.',
        ),
        LessonExercise(
          title: 'Add B',
          text: 'bv vb bb bbb brave verb below',
          hint: 'B: Index finger stretches RIGHT along bottom row.',
        ),
        LessonExercise(
          title: 'All together',
          text: 'brave cave zero fix verb black',
          hint: 'Bottom row is tricky — keep your fingers close to home row.',
        ),
      ],
    ),
    Lesson(
      id: 'right_bottom',
      title: 'Right Bottom: N M , . /',
      subtitle: 'Index to pinky, bottom row',
      keys: 'N M , . /',
      exercises: [
        LessonExercise(
          title: 'N and M',
          text: 'nm mn nmn mnm name main mine',
          hint: 'N: Index stretches LEFT. M: Index goes straight down.',
        ),
        LessonExercise(
          title: 'Comma and Period',
          text: 'one, two, three. stop. go, run.',
          hint: 'Comma: Middle finger. Period: Ring finger. Very common!',
        ),
        LessonExercise(
          title: 'Sentences with punctuation',
          text: 'run, jump, swim. work hard. be kind.',
          hint: 'Punctuation is part of typing. Practice it seriously.',
        ),
        LessonExercise(
          title: 'Full bottom row',
          text: 'mix zinc, brave men. fix the cave below.',
          hint: 'All bottom row keys — you have done it!',
        ),
      ],
    ),
    Lesson(
      id: 'full_alphabet',
      title: 'Full Alphabet',
      subtitle: 'All 26 letters flowing together',
      keys: 'All 26 letters',
      exercises: [
        LessonExercise(
          title: 'The pangram',
          text: 'the quick brown fox jumps over the lazy dog',
          hint: 'This sentence uses every letter of the alphabet!',
        ),
        LessonExercise(
          title: 'Another pangram',
          text: 'pack my box with five dozen liquor jugs',
          hint: 'Another sentence with all 26 letters. Type it twice.',
        ),
        LessonExercise(
          title: 'Common words',
          text: 'zone brave quick vex jump cloth fog why',
          hint: 'Letters from all three rows mixed together.',
        ),
        LessonExercise(
          title: 'Final sentence',
          text: 'amazing typing skills develop with practice every single day',
          hint: 'You now know every key on the keyboard. Incredible!',
        ),
      ],
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 4: NUMBERS ROW
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _numbersCourse = LessonCourse(
  id: 'numbers',
  title: 'Numbers & Numerals',
  description: 'Type numbers without looking. Essential for coding, math, and data entry.',
  icon: '🔢',
  lessons: [
    Lesson(
      id: 'left_numbers',
      title: 'Left Numbers: 1 2 3 4 5',
      subtitle: 'Top row, left side numbers',
      keys: '1 2 3 4 5',
      exercises: [
        LessonExercise(
          title: '1 and 2',
          text: '1 2 1 2 11 22 12 21 121 212',
          hint: '1: Pinky reaches to top. 2: Ring finger to top.',
        ),
        LessonExercise(
          title: '3 and 4',
          text: '3 4 3 4 33 44 34 43 343 434',
          hint: '3: Middle finger up. 4: Index finger up.',
        ),
        LessonExercise(
          title: 'Add 5',
          text: '5 55 555 15 25 35 45 54 53 52 51',
          hint: '5: Index finger stretches up-left.',
        ),
        LessonExercise(
          title: 'Number words',
          text: 'room 12, class 4, floor 3, desk 25, seat 31',
          hint: 'Numbers in real context. This is how they are used!',
        ),
      ],
    ),
    Lesson(
      id: 'right_numbers',
      title: 'Right Numbers: 6 7 8 9 0',
      subtitle: 'Top row, right side numbers',
      keys: '6 7 8 9 0',
      exercises: [
        LessonExercise(
          title: '6 and 7',
          text: '6 7 6 7 66 77 67 76 676 767',
          hint: '6: Right index stretches up-left. 7: Right index up.',
        ),
        LessonExercise(
          title: '8 and 9',
          text: '8 9 8 9 88 99 89 98 898 989',
          hint: '8: Middle finger up. 9: Ring finger up.',
        ),
        LessonExercise(
          title: 'Add 0',
          text: '0 00 000 10 20 30 100 200 300',
          hint: '0: Pinky reaches to top right.',
        ),
        LessonExercise(
          title: 'All numbers',
          text: '1234 5678 90 100 2024 8765 4321 0987',
          hint: 'Numbers from both hands together. You are doing great!',
        ),
      ],
    ),
    Lesson(
      id: 'numbers_in_text',
      title: 'Numbers in Real Text',
      subtitle: 'Mixing letters and numbers',
      keys: '0-9 with letters',
      exercises: [
        LessonExercise(
          title: 'Addresses and dates',
          text: 'class 8, room 12, year 2024, grade 90',
          hint: 'Numbers appear in real documents all the time.',
        ),
        LessonExercise(
          title: 'Computer context',
          text: 'port 8765, ip 192, pixel 1080, level 42',
          hint: 'In computers, numbers are everywhere. Practice them well.',
        ),
        LessonExercise(
          title: 'Math sentences',
          text: '12 plus 34 equals 46, not 56 or 78',
          hint: 'Mix numbers with letters smoothly without pausing.',
        ),
        LessonExercise(
          title: 'Final challenge',
          text: 'on 2024, 8 students scored above 90 in class 7b',
          hint: 'Real-world number usage. You have mastered numbers!',
        ),
      ],
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 5: SYMBOLS & PUNCTUATION
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _symbolsCourse = LessonCourse(
  id: 'symbols',
  title: 'Symbols & Punctuation',
  description: 'Commas, periods, colons, brackets, and more. Professional typing uses them all.',
  icon: '!@#',
  lessons: [
    Lesson(
      id: 'basic_punctuation',
      title: 'Basic Punctuation',
      subtitle: '. , ; : ? !',
      keys: '. , ; : ? !',
      exercises: [
        LessonExercise(
          title: 'Period and Comma',
          text: 'hello, world. run, jump, fly. stop, look.',
          hint: 'These are the two most common punctuation marks.',
        ),
        LessonExercise(
          title: 'Question and Exclamation',
          text: 'what? who? why! how! when? where!',
          hint: 'Shift + / for ?. Shift + 1 for !. Use right pinky for shift.',
        ),
        LessonExercise(
          title: 'Colon and Semicolon',
          text: 'note: item one; item two; item three.',
          hint: 'Colon: after a list intro. Semicolon: between related ideas.',
        ),
        LessonExercise(
          title: 'All together',
          text: 'ready? yes! type: fast, accurate; always improve.',
          hint: 'Real punctuation makes real sentences. Great work!',
        ),
      ],
    ),
    Lesson(
      id: 'shift_symbols',
      title: 'Shift Key Symbols',
      subtitle: r'@ # $ % & * ( ) _ +',
      keys: r'@ # $ % & *',
      exercises: [
        LessonExercise(
          title: 'At and Hash',
          text: '@ @ # # @name #tag @school #nepal',
          hint: 'Shift+2 for @. Shift+3 for #. Hold shift, tap the key.',
        ),
        LessonExercise(
          title: 'Dollar and Percent',
          text: '\$ \$ % % \$100 50% \$200 75% price',
          hint: 'Shift+4 for \$. Shift+5 for %. Common in math and finance.',
        ),
        LessonExercise(
          title: 'Brackets',
          text: '(hello) (world) (type) (fast) (win)',
          hint: 'Shift+9 for (. Shift+0 for ). Pinky and ring finger.',
        ),
        LessonExercise(
          title: 'Programming symbols',
          text: 'print("hello") // output: "world" x = 100%',
          hint: 'These symbols are used every day in programming!',
        ),
      ],
    ),
    Lesson(
      id: 'coding_symbols',
      title: 'Coding Symbols',
      subtitle: '{ } [ ] < > = + - _ /',
      keys: '{ } [ ] < > = + -',
      exercises: [
        LessonExercise(
          title: 'Curly braces',
          text: '{} {{}} {name} {value} {key: value}',
          hint: 'Shift+[ for {. Shift+] for }. Used in every programming language.',
        ),
        LessonExercise(
          title: 'Square brackets',
          text: '[] [[]] [0] [1] [index] [array]',
          hint: 'Left bracket is to the right of P. No shift needed.',
        ),
        LessonExercise(
          title: 'Equals and operators',
          text: 'x = 5, y = 10, z = x + y',
          hint: 'Equals sign is very common in code and math.',
        ),
        LessonExercise(
          title: 'Real code line',
          text: 'int x = 100; if (x > 50) { print(x); }',
          hint: 'This is real code! Typing code requires all symbols.',
        ),
      ],
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// COURSE 6: SPEED DRILLS
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _speedDrillsCourse = LessonCourse(
  id: 'speed_drills',
  title: 'Speed Drills',
  description: 'Push your WPM to the limit. These drills are designed to make you faster.',
  icon: '⚡',
  lessons: [
    Lesson(
      id: 'common_words',
      title: 'Top 100 Common Words',
      subtitle: 'The words you type most in life',
      keys: 'All keys',
      exercises: [
        LessonExercise(
          title: 'Top 20 words',
          text: 'the and to a of in is it you that',
          hint: 'These 10 words make up 25% of all text. Know them cold.',
        ),
        LessonExercise(
          title: 'Next 20 words',
          text: 'he was for on are with as his they at',
          hint: 'Push for speed here. You know all these letters.',
        ),
        LessonExercise(
          title: 'Action words',
          text: 'run type write read learn grow think help find make',
          hint: 'Common verbs. These appear in almost every sentence.',
        ),
        LessonExercise(
          title: 'Speed run',
          text: 'the quick type is the best type you can make every day',
          hint: 'Full speed! Count errors and try to beat your WPM.',
        ),
      ],
    ),
    Lesson(
      id: 'word_bursts',
      title: 'Word Bursts',
      subtitle: 'Short explosive typing drills',
      keys: 'All keys',
      exercises: [
        LessonExercise(
          title: 'Short words burst',
          text: 'go do so no we be me he she the and but for',
          hint: 'Tiny words. Go as fast as possible. Each word is 2-3 keys.',
        ),
        LessonExercise(
          title: 'Double letters',
          text: 'soon feel tall add egg inn off all book good',
          hint: 'Double letters trip people up. Press each one cleanly.',
        ),
        LessonExercise(
          title: 'Long words',
          text: 'information communication understanding development important',
          hint: 'Slow down and be accurate. Long words need concentration.',
        ),
        LessonExercise(
          title: 'Mixed burst',
          text: 'we need to understand the important information now',
          hint: 'Short and long words together. Find your rhythm.',
        ),
      ],
    ),
    Lesson(
      id: 'accuracy_focus',
      title: 'Accuracy Training',
      subtitle: 'Zero errors. Every key counts.',
      keys: 'All keys',
      exercises: [
        LessonExercise(
          title: 'Capital letters',
          text: 'Nepal India China Russia France Japan Korea Brazil',
          hint: 'Left Shift for right-hand letters. Right Shift for left-hand.',
        ),
        LessonExercise(
          title: 'Numbers in sentences',
          text: 'there are 26 letters and 10 digits in 36 total keys',
          hint: 'Switch between letters and numbers without pausing.',
        ),
        LessonExercise(
          title: 'Full punctuation',
          text: 'Hello, my name is Ram. I am 14 years old. I study in Class 8.',
          hint: 'Real sentence with capitals, commas, and periods.',
        ),
        LessonExercise(
          title: 'Ultimate accuracy test',
          text: 'In 2024, 8 students from Class 7B achieved over 90% accuracy in TypingQuest!',
          hint: 'Numbers, symbols, capitals, punctuation — the works!',
        ),
      ],
    ),
    Lesson(
      id: 'speed_records',
      title: 'Record Breaker',
      subtitle: 'Push your absolute maximum speed',
      keys: 'All keys',
      exercises: [
        LessonExercise(
          title: 'Warm up sprint',
          text: 'type fast and keep your fingers on the home row at all times',
          hint: 'Nice and fast. This is your warm-up for the real drills.',
        ),
        LessonExercise(
          title: 'Sprint 1',
          text: 'the sun rises in the east and sets in the west every single day',
          hint: 'All common words. Push for maximum WPM with no errors.',
        ),
        LessonExercise(
          title: 'Sprint 2',
          text: 'practice every morning and your typing speed will double in one month',
          hint: 'Longer sentence. Maintain your speed to the very last word.',
        ),
        LessonExercise(
          title: 'Ultimate speed test',
          text: 'a good typist can type over sixty words per minute with perfect accuracy through daily practice and focused effort',
          hint: 'This is your personal record attempt. Type as fast as you can!',
        ),
      ],
    ),
  ],
);