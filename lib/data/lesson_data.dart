// ── Lesson System Data ────────────────────────────────────────────────────
//
// STRUCTURE
//   LessonCourse  →  List<Lesson>  →  List<LessonExercise>
//
// PEDAGOGICAL PATTERN (5 exercises per lesson, always in this order)
//   Exercise 1 — Isolation   : Each new key repeated alone to build muscle memory.
//   Exercise 2 — Alternation : New keys paired and interleaved to train transitions.
//   Exercise 3 — Real words  : Short real words using only keys covered so far.
//   Exercise 4 — Phrases     : Meaningful multi-word phrases for flow practice.
//   Exercise 5 — Sentence    : A complete timed sentence; the lesson's speed goal.
//
// COURSES (6 total)
//   1. home_row      — A S D F G H J K L ;  +  E I
//   2. top_row       — Q W R T Y U O P  +  Capital letters
//   3. bottom_row    — Z X C V B N M , . /  +  Full alphabet
//   4. numbers       — 1 2 3 4 5 6 7 8 9 0
//   5. symbols       — Punctuation, shift symbols, coding symbols
//   6. speed_drills  — Common words, bursts, accuracy, record attempts

class LessonExercise {
  final String title;
  final String text;
  final String hint;

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
  final String keys; // keys introduced in this lesson
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

// ── Public API ─────────────────────────────────────────────────────────────
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
    try {
      return courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Lesson? getLesson(String courseId, String lessonId) {
    final course = getCourse(courseId);
    if (course == null) return null;
    try {
      return course.lessons.firstWhere((l) => l.id == lessonId);
    } catch (_) {
      return null;
    }
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 1 — HOME ROW MASTERY
// Keys introduced across 6 lessons: A S D F  |  J K L ;  |  G H  |  E I
// Goal: touch-type the full home row without looking at the keyboard.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _homeRowCourse = LessonCourse(
  id: 'home_row',
  title: 'Home Row Mastery',
  description:
      'Every great typist starts here. Master A S D F G H J K L and build '
      'the muscle memory that makes all other keys easier.',
  icon: '🏠',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'left_home',
      title: 'Left Hand: A S D F',
      subtitle: 'Pinky · Ring · Middle · Index — your left anchor keys',
      keys: 'A S D F',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'a a a a s s s s d d d d f f f f',
          hint: 'Rest your left fingers on A S D F. Press each key with the '
              'correct finger only — pinky on A, ring on S, middle on D, index on F.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'as sa sd ds df fd fa af asdf fdsa',
          hint: 'Keep all four fingers resting on home row at all times. '
              'Only the finger pressing a key should move.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'add dad fad sad ask ads dads fads flask',
          hint: 'These are real English words typed with A S D F alone. '
              'Eyes on the screen — do not look at your fingers.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'a sad dad asks a fad flask salads',
          hint: 'Use your thumb to press the spacebar after every word. '
              'Return to home row immediately after each space.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'a flask falls as dad adds salad and asks a lad',
          hint: 'Your first full sentence on A S D F. Aim for zero errors '
              'before you try to go faster.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'right_home',
      title: 'Right Hand: J K L ;',
      subtitle: 'Index · Middle · Ring · Pinky — your right anchor keys',
      keys: 'J K L ;',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'j j j j k k k k l l l l ; ; ; ;',
          hint: 'Rest your right fingers on J K L ;. The J key has a small '
              'bump so you can always find home row by touch.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'jk kj kl lk lj jl j;l ;lk jkl; ;lkj',
          hint: 'Your right wrist stays still and flat. Only individual '
              'fingers reach each key.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'jill kill fill lull skill skull ill',
          hint: 'Right-hand-only words. Stay relaxed — tension slows you down '
              'and causes mistakes.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'jill kills skills; lull ill lads; kill skill',
          hint: 'Notice the semicolons. Your right pinky handles ; just like '
              'your left pinky handles A.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'jill has skill; she fills jars; kill ill skills',
          hint: 'Push for a smooth, even rhythm. Every key should sound '
              'the same — like a steady ticking clock.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'both_home',
      title: 'Both Hands Together',
      subtitle: 'Full home row: A S D F — J K L ;',
      keys: 'A S D F J K L ;',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Anchor Check',
          text: 'f j f j f j d k d k s l s l a ; a ;',
          hint: 'F and J are anchor keys — feel their bumps. This drill '
              'trains your hands to find home position instantly.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Hand Alternation',
          text: 'fj jf dk kd sl ls a; ;a fjdk dksl slaj',
          hint: 'Let your hands alternate naturally. Good typists keep '
              'a steady flow between left and right.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'fall flask lads jails ask salad skill',
          hint: 'Both hands contribute to each word now. Coordinate them '
              'without favouring one side.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'a lad asks; jill falls; dad salads; skill falls',
          hint: 'The semicolons give you a brief pause between phrases. '
              'Use that moment to reset your posture.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'dad falls as jill asks a lad for salad and flask skills',
          hint: 'Your home row foundation is complete. This sentence uses '
              'only A S D F J K L — type it perfectly.',
        ),
      ],
    ),

    // ── Lesson 4 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'add_g_h',
      title: 'Add G and H',
      subtitle: 'Index fingers stretch inward to the centre keys',
      keys: 'G H',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'f g f g f g f g j h j h j h j h',
          hint: 'G: left index finger stretches one key to the right. '
              'H: right index finger stretches one key to the left. '
              'Return to F and J after every G and H keystroke.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'gh hg ghg hgh fgh jhg fghj jhgf',
          hint: 'G and H sit right beside each other. Your index fingers '
              'meet in the middle of the keyboard here.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'glad gash hash lash gala hall glad shall',
          hint: 'G and H unlock dozens of common words. Type each one '
              'cleanly before moving to the next.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'glad hall; gash slash; shall fall; has glad skill',
          hint: 'The G and H stretches should feel natural now. '
              'Trust your index fingers to find those keys.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'jill has glad skills and shall flash a glad hall gash',
          hint: 'Full home row plus G and H. This is eight of the most '
              'important keys on the entire keyboard.',
        ),
      ],
    ),

    // ── Lesson 5 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'add_e_i',
      title: 'Add E and I',
      subtitle: 'Middle fingers reach up one row',
      keys: 'E I',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'd e d e d e d e k i k i k i k i',
          hint: 'E: left middle finger reaches straight up from D. '
              'I: right middle finger reaches straight up from K. '
              'Snap back to D and K immediately after each press.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'ei ie eie iei dei eki dek eki dei',
          hint: 'E and I are two of the three most common vowels in English. '
              'Getting them right will feel like a huge unlock.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'feel file life like idle side idea seek field',
          hint: 'Real words with E and I. Notice how many more words '
              'are now possible with just these two new keys.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'i feel like a skilled filer; side fields; ideas slide',
          hint: 'Your first proper sentences with vowels. Read ahead '
              'one word while typing the current one.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'i like the idea of skill; she feels glad; life is ideal',
          hint: 'E and I are among the most typed letters in English. '
              'Mastering them will boost your speed dramatically.',
        ),
      ],
    ),

    // ── Lesson 6 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'home_mastery',
      title: 'Home Row Mastery Review',
      subtitle: 'Consolidate everything: A S D F G H J K L ; E I',
      keys: 'A S D F G H J K L ; E I',
      exercises: [

        // Ex 1 — Isolation (finger warm-up)
        LessonExercise(
          title: 'Finger Warm-Up',
          text: 'a s d f g h j k l f d s a j k l h g f',
          hint: 'The classic home-row warm-up. Every finger touches every '
              'key once. Feel where each key sits before you begin.',
        ),

        // Ex 2 — Alternation (pattern drill)
        LessonExercise(
          title: 'Pattern Drill',
          text: 'ag sh di fj gk hl ej fia ghi jkl',
          hint: 'Cross-hand patterns force both hands to coordinate. '
              'Keep your pace even — do not rush any transition.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Word Bank',
          text: 'jailed skilled fields gladly shielded ideally',
          hint: 'Six long words using only your home-row keys. '
              'Break each word into syllables if it helps: ja-iled, field-s.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Phrase Flow',
          text: 'she shields jails; glide fields ideally; skilled ideas alike',
          hint: 'Aim for no pauses between words. Let your fingers flow '
              'from one word directly into the next.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Mastery Sentence',
          text: 'skilled ideas glide ahead; she fields jails gladly like a shield',
          hint: 'This is the hardest home-row sentence in the course. '
              'Accuracy first, speed second. You have earned this.',
        ),
      ],
    ),
  ],
);


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 2 — TOP ROW TAKEOVER
// Keys introduced across 4 lessons: Q W R T  |  Y U O P  |  Full top  |  Shift
// Goal: full QWERTY top row + capital letters using the shift key.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _topRowCourse = LessonCourse(
  id: 'top_row',
  title: 'Top Row Takeover',
  description:
      'Q W E R T Y U I O P — master the top row and unlock the full '
      'alphabet. Capital letters included.',
  icon: '⬆️',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'left_top',
      title: 'Left Top: Q W R T',
      subtitle: 'Pinky · Ring · Index · Index-stretch — left top row',
      keys: 'Q W R T',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'q q q q w w w w r r r r t t t t',
          hint: 'Q: left pinky reaches up. W: left ring reaches up. '
              'R: left index reaches up. T: left index stretches right then up. '
              'Return to A S D F after every keystroke.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'qw wq wr rw rt tr qt tq qwrt trwq',
          hint: 'Four fingers on four keys. Feel the row above home row — '
              'it is only one reach away.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'word wrist quest rest write dirt tried',
          hint: 'Q W R T give us some powerful consonants. Notice how '
              'your left hand does most of the work in these words.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'write a word; try rest; quest for skill; wrist dirt',
          hint: 'Reach up to the top row and snap back to home row '
              'between each word. Do not leave fingers raised.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'try to write a tidy word list; rest after a task',
          hint: 'Left top row plus everything you know from home row. '
              'Keep a steady rhythm from first key to last.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'right_top',
      title: 'Right Top: Y U O P',
      subtitle: 'Index-stretch · Index · Ring · Pinky — right top row',
      keys: 'Y U O P',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'j y j y j y u u u u l o l o p p p p',
          hint: 'Y: right index stretches left then up. U: right index goes up. '
              'O: right ring reaches up. P: right pinky reaches up. '
              'Snap back to J K L after each keystroke.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'yu uy uo ou op po py yp yuop pou',
          hint: 'Y and U share the right index finger. Give yourself a '
              'split second to move between them deliberately.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'your pour loop upon youth polo pulp',
          hint: 'Y U O P together with home row letters make many common '
              'English words. Type each one with calm confidence.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'your pool; loop upon youth; pull up output; pour oil',
          hint: 'O and U together appear in many everyday words. '
              'Your right hand handles both with ease now.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'you pull your youth up to pour oil upon the pool loop',
          hint: 'All four right top row keys working together. '
              'This sentence loads P and O heavily — stay smooth.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'full_top',
      title: 'Full Top Row',
      subtitle: 'Q W E R T Y U I O P — the complete QWERTY row',
      keys: 'Q W E R T Y U I O P',
      exercises: [

        // Ex 1 — Isolation (row sweep)
        LessonExercise(
          title: 'Row Sweep',
          text: 'q w e r t y u i o p p o i u y t r e w q',
          hint: 'Type the top row left to right, then right to left. '
              'This trains your fingers to find every key from memory.',
        ),

        // Ex 2 — Alternation (cross-row pairs)
        LessonExercise(
          title: 'Cross-Row Pairs',
          text: 'qp wo ei ru ty yt ur ie ow pq',
          hint: 'Each pair uses one key from each end of the top row, '
              'pressing toward the centre. A classic coordination drill.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Top-Row Words',
          text: 'type write power quiet pretty tower output',
          hint: 'These words use only the top row. Notice how your '
              'fingers flow across the row without dipping back down.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Phrase Flow',
          text: 'write your output quietly; power your type; pretty work',
          hint: 'Read one word ahead while typing the current one. '
              'Your eyes should always be slightly in front of your fingers.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'we write pretty words to power your quiet output every week',
          hint: 'Full top row plus home row letters. This is a proud milestone — '
              'you now have two complete keyboard rows under your fingers.',
        ),
      ],
    ),

    // ── Lesson 4 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'capital_letters',
      title: 'Capital Letters',
      subtitle: 'Left Shift for right-hand keys · Right Shift for left-hand keys',
      keys: 'Shift',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Shift Practice',
          text: 'Aa Ss Dd Ff Jj Kk Ll Ee Ii Oo Pp',
          hint: 'To capitalise a RIGHT-hand letter: hold LEFT Shift. '
              'To capitalise a LEFT-hand letter: hold RIGHT Shift. '
              'Never use the wrong shift — it breaks your finger position.',
        ),

        // Ex 2 — Alternation (proper nouns)
        LessonExercise(
          title: 'Names Drill',
          text: 'Ali Sara Deepa Kiran Jaya Priya Sunil',
          hint: 'Every name starts with a capital. Release Shift '
              'completely before typing the rest of the name.',
        ),

        // Ex 3 — Real words (sentence starts)
        LessonExercise(
          title: 'Sentence Starts',
          text: 'The dog is kind. She runs fast. He is tall.',
          hint: 'Capital letter at the start of every sentence. '
              'Pair it with a period at the end to build the habit.',
        ),

        // Ex 4 — Phrases (mixed case)
        LessonExercise(
          title: 'Proper Phrases',
          text: 'I study at School. Nepal is great. Life is short.',
          hint: '"I" is always capitalised in English. '
              'Check every capital — use the correct shift key each time.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'Jill studies at a great school in Kathmandu. She works hard.',
          hint: 'Capitals, periods, and a comma — professional typing. '
              'This is the standard you should aim for in all written work.',
        ),
      ],
    ),
  ],
);


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 3 — BOTTOM ROW COMPLETE
// Keys introduced across 3 lessons: Z X C V B  |  N M , . /  |  Full alphabet
// Goal: complete all 26 letters and basic punctuation.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _bottomRowCourse = LessonCourse(
  id: 'bottom_row',
  title: 'Bottom Row Complete',
  description:
      'Z X C V B N M and punctuation. Finish all 26 letters and become '
      'a complete typist.',
  icon: '⬇️',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'left_bottom',
      title: 'Left Bottom: Z X C V B',
      subtitle: 'Pinky · Ring · Middle · Index · Index-stretch',
      keys: 'Z X C V B',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'z z z z x x x x c c c c v v v v b b b b',
          hint: 'Z: left pinky reaches down. X: left ring reaches down. '
              'C: left middle reaches down. V: left index reaches down. '
              'B: left index stretches right along the bottom row.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'zx xz xc cx cv vc vb bv zxcv bvcxz',
          hint: 'The bottom row is a longer reach than the top row. '
              'Keep your wrists low and let your fingers curl downward.',
        ),

        // Ex 3 — Real words
        LessonExercise(
          title: 'Real Words',
          text: 'cave zinc verb vice brave black blaze',
          hint: 'Bottom-row letters combined with home and top row. '
              'Take your time — accuracy on these new keys matters most.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'brave cave; zinc verb vice; black blaze carve',
          hint: 'V appears in many words but can be tricky at first. '
              'Make sure your index finger curls all the way down.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'brave vixens carved zinc blades above the black cave',
          hint: 'Left bottom row fully integrated. If B feels unstable, '
              'practise "fBf fBf" ten times: index out and back.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'right_bottom',
      title: 'Right Bottom: N M , . /',
      subtitle: 'Index · Index · Middle · Ring · Pinky',
      keys: 'N M , . /',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: 'j n j n j n m m m m , , , , . . . . / / /',
          hint: 'N: right index stretches left-down. M: right index goes down. '
              'Comma: right middle down. Period: right ring down. '
              '/: right pinky all the way down-right.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: 'nm mn nm,. ,./  n,m. m.n, jnm,.',
          hint: 'Comma and period are among the most common keys you will '
              'ever press. Practice them deliberately.',
        ),

        // Ex 3 — Real words with punctuation
        LessonExercise(
          title: 'Words and Marks',
          text: 'name, moon, mine. noon. man, men. main.',
          hint: 'Every word ends with a comma or period. '
              'Do not pause before the punctuation — it is part of the word.',
        ),

        // Ex 4 — Phrases
        LessonExercise(
          title: 'Short Phrases',
          text: 'run, jump, swim. come in, sit down. name it, find it.',
          hint: 'Real-world punctuation rhythm. A comma creates a short '
              'pause in speech — feel that pause in your typing too.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'come in, name it, find it. make it, mine it, done.',
          hint: 'Commas and periods flowing naturally. '
              'If / is new and unfamiliar, practise it separately: / / / /.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'full_alphabet',
      title: 'Full Alphabet',
      subtitle: 'All 26 letters — three rows working together',
      keys: 'All 26 letters',
      exercises: [

        // Ex 1 — Isolation (alphabet in order)
        LessonExercise(
          title: 'Alphabet Run',
          text: 'a b c d e f g h i j k l m n o p q r s t u v w x y z',
          hint: 'Type the entire alphabet in order. This is your benchmark. '
              'Notice which letters feel uncertain — those are your targets.',
        ),

        // Ex 2 — Alternation (classic pangrams)
        LessonExercise(
          title: 'Pangram Pair',
          text: 'the quick brown fox jumps over the lazy dog',
          hint: 'This sentence contains every letter of the alphabet at least once. '
              'It has been used to test typewriters for over 100 years.',
        ),

        // Ex 3 — Real words (alphabet variety)
        LessonExercise(
          title: 'Letter Variety',
          text: 'zone brave quick extra vex jump cloth fog why quiz',
          hint: 'Letters from all three rows mixed together. '
              'Find your weaker letters and give them extra attention.',
        ),

        // Ex 4 — Phrases (second pangram)
        LessonExercise(
          title: 'Second Pangram',
          text: 'pack my box with five dozen liquor jugs.',
          hint: 'Another all-26-letter sentence. Notice how X, Z, Q, and J '
              'are always rare — they appear in pangrams by necessity.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Full Alphabet Drill',
          text: 'amazing typing skills develop quickly with brave, focused practice every day.',
          hint: 'You now know every key on the keyboard. This sentence '
              'marks the end of alphabet learning. Everything from here builds speed.',
        ),
      ],
    ),
  ],
);


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 4 — NUMBERS & NUMERALS
// Keys introduced across 3 lessons: 1 2 3 4 5  |  6 7 8 9 0  |  Mixed
// Goal: reach the number row without looking, and mix numbers into text.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _numbersCourse = LessonCourse(
  id: 'numbers',
  title: 'Numbers and Numerals',
  description:
      'Type numbers without looking. Essential for data entry, coding, '
      'mathematics, and any professional work.',
  icon: '🔢',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'left_numbers',
      title: 'Left Numbers: 1 2 3 4 5',
      subtitle: 'Pinky · Ring · Middle · Index · Index-stretch',
      keys: '1 2 3 4 5',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: '1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5',
          hint: '1: left pinky stretches to the very top. '
              '2: left ring reaches up. 3: left middle up. '
              '4: left index up. 5: left index stretches up-right. '
              'Return to home row after every number.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: '12 21 23 32 34 43 45 54 15 51 123 321 12345',
          hint: 'Numbers in sequence are easier than random order. '
              'These drills build the sequence memory first.',
        ),

        // Ex 3 — Real numbers
        LessonExercise(
          title: 'Real Numbers',
          text: '12 345 1234 5432 1 2 3 4 5 55 44 33 22 11',
          hint: 'Multi-digit numbers require you to hold your position '
              'in the number row across several keystrokes.',
        ),

        // Ex 4 — Numbers in context
        LessonExercise(
          title: 'Numbers in Context',
          text: 'class 4, desk 12, floor 3, seat 25, grade 5',
          hint: 'Numbers in real-world context. Switch cleanly between '
              'letters and numbers without hesitating at the number row.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'i scored 45 in test 3 and 21 in quiz 4 last week',
          hint: 'Left-hand numbers woven into a full sentence. '
              'Keep your eyes on the screen, not the number row.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'right_numbers',
      title: 'Right Numbers: 6 7 8 9 0',
      subtitle: 'Index-stretch · Index · Middle · Ring · Pinky',
      keys: '6 7 8 9 0',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Key Isolation',
          text: '6 6 6 6 7 7 7 7 8 8 8 8 9 9 9 9 0 0 0 0',
          hint: '6: right index stretches up-left. 7: right index goes up. '
              '8: right middle reaches up. 9: right ring reaches up. '
              '0: right pinky stretches to the far top-right.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Key Alternation',
          text: '67 76 78 87 89 98 90 09 60 06 678 876 67890',
          hint: '6 and 7 share the right index finger. '
              'Give yourself a moment to reposition between them.',
        ),

        // Ex 3 — Real numbers
        LessonExercise(
          title: 'Real Numbers',
          text: '70 80 90 100 700 800 900 1000 678 9870',
          hint: '0 is the hardest right-hand number to reach. '
              'If it feels uncertain, practise ";0;0;0" twenty times.',
        ),

        // Ex 4 — Numbers in context
        LessonExercise(
          title: 'Numbers in Context',
          text: 'port 8080, year 2019, score 97, page 106, row 70',
          hint: 'Real computing and real-life numbers. '
              'Notice how 8080 and 2019 cross between left and right hands.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'in 2008 and 2019, some schools had 700 to 900 students',
          hint: 'Right-hand numbers in a full sentence. '
              'Both hands must share the number row across this sentence.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'numbers_in_text',
      title: 'Numbers in Real Text',
      subtitle: 'Fluent switching between letters and digits',
      keys: '0–9 in context',
      exercises: [

        // Ex 1 — Isolation (full number row sweep)
        LessonExercise(
          title: 'Full Row Sweep',
          text: '1 2 3 4 5 6 7 8 9 0 0 9 8 7 6 5 4 3 2 1',
          hint: 'Type the full number row left to right, then right to left. '
              'This is the number-row equivalent of the alphabet run.',
        ),

        // Ex 2 — Alternation (common number patterns)
        LessonExercise(
          title: 'Common Patterns',
          text: '100 200 500 1000 2024 1080 360 90 50 25 10',
          hint: 'These are numbers that appear constantly in real life. '
              'Train your fingers to reach them automatically.',
        ),

        // Ex 3 — Mixed letter and number words
        LessonExercise(
          title: 'Letter-Number Mix',
          text: 'class 8b, room 12a, level 7, ip 192, pixel 1080',
          hint: 'In coding and data work, letters and numbers alternate '
              'constantly. The transition must be seamless.',
        ),

        // Ex 4 — Phrases with all numbers
        LessonExercise(
          title: 'Number-Rich Phrases',
          text: 'marks: 78, 85, 90; rank: 3 of 120; year: 2024',
          hint: 'Numbers with punctuation. The colon comes before the value; '
              'semicolons separate multiple items in a list.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Final Number Sentence',
          text: 'in 2024, class 7b had 38 students, with 9 scoring above 90',
          hint: 'All ten digits and every letter you know. '
              'If any number causes a pause, make a note and drill it tonight.',
        ),
      ],
    ),
  ],
);


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 5 — SYMBOLS AND PUNCTUATION
// Keys introduced across 3 lessons: . , ; : ? !  |  @ # $ % ( )  |  { } [ ] = +
// Goal: type all common symbols fluently without hunting for the key.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _symbolsCourse = LessonCourse(
  id: 'symbols',
  title: 'Symbols and Punctuation',
  description:
      'Commas, periods, colons, brackets, and more. Professional and '
      'programming work requires every symbol.',
  icon: '!@#',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'basic_punctuation',
      title: 'Basic Punctuation',
      subtitle: '. , ; : ? ! — the six most common symbols',
      keys: '. , ; : ? !',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Mark Isolation',
          text: '. . . . , , , , ; ; ; ; : : : : ? ? ? ! !',
          hint: 'Period and comma: right middle and ring reach down. '
              'Semicolon: right pinky on home row. Colon: Shift + ;. '
              'Question mark: Shift + /. Exclamation: Shift + 1.',
        ),

        // Ex 2 — Alternation
        LessonExercise(
          title: 'Mark Pairs',
          text: '., ., ,. ,. ;: :; ?! !? .,;:?!',
          hint: 'Switch between punctuation marks cleanly. '
              'Each mark has exactly one correct finger — commit to it.',
        ),

        // Ex 3 — Real sentences
        LessonExercise(
          title: 'Sentences with Marks',
          text: 'hello, world. stop, look. run! who? why? go!',
          hint: 'Punctuation is part of the sentence, not an afterthought. '
              'Do not slow down before a comma or period.',
        ),

        // Ex 4 — Phrases with colons and semicolons
        LessonExercise(
          title: 'Colons and Semicolons',
          text: 'note: item one; item two; done. result: pass; fail.',
          hint: 'Colon introduces a list or explanation. '
              'Semicolon joins two related but independent ideas.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'ready? yes! type fast, accurately; result: great work.',
          hint: 'All six basic punctuation marks in one sentence. '
              'If any mark causes a slowdown, return to Ex 1 for that mark.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'shift_symbols',
      title: 'Shift Symbols',
      subtitle: r'@ # $ % & * ( ) — eight common shift symbols',
      keys: r'@ # $ % & * ( )',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Symbol Isolation',
          text: '@ @ # # \$ \$ % % & & * * ( ( ) )',
          hint: '@: Shift+2. #: Shift+3. \$: Shift+4. %: Shift+5. '
              '&: Shift+7. *: Shift+8. (: Shift+9. ): Shift+0. '
              'Left Shift for right-hand keys; right Shift for left-hand keys.',
        ),

        // Ex 2 — Alternation (symbol pairs)
        LessonExercise(
          title: 'Symbol Pairs',
          text: '@# #@ \$% %\$ &* *& () )( @\$& #%*',
          hint: 'Hold Shift with one hand, tap the number with the other. '
              'Never use the same hand for both Shift and the key.',
        ),

        // Ex 3 — Real-world symbols
        LessonExercise(
          title: 'Real-World Use',
          text: '@school #nepal \$100 50% (grade) save & share',
          hint: 'These symbols appear in email addresses, social media, '
              'finance, and everyday documents. They are not optional.',
        ),

        // Ex 4 — Phrases with symbols
        LessonExercise(
          title: 'Symbol Phrases',
          text: 'email @user; cost \$50 (50%); score * 100; save & run',
          hint: 'Smooth symbol integration in real phrases. '
              'Aim for no pause before or after any symbol.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Sentence Drill',
          text: 'send 50% to @admin & pay \$100 (discount: 20%) for class #7',
          hint: 'Six different shift symbols in one sentence. '
              'This is the level of fluency you need for real work.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'coding_symbols',
      title: 'Coding Symbols',
      subtitle: '{ } [ ] < > = + - _ — essential for programming',
      keys: '{ } [ ] = + - _',
      exercises: [

        // Ex 1 — Isolation
        LessonExercise(
          title: 'Symbol Isolation',
          text: '[ ] [ ] { } { } = = + + - - _ _',
          hint: '[: right pinky (no shift). ]: right pinky right (no shift). '
              '{: Shift+[. }: Shift+]. =: right pinky row. '
              '+: Shift+=. -: right pinky. _: Shift+-.',
        ),

        // Ex 2 — Alternation (bracket pairs)
        LessonExercise(
          title: 'Bracket Pairs',
          text: '[] {} [] {} [{}] {[]} () [] {}',
          hint: 'Brackets always come in pairs in code. '
              'Practise opening and closing each type without looking.',
        ),

        // Ex 3 — Simple code fragments
        LessonExercise(
          title: 'Code Fragments',
          text: 'x = 5 y = x + 10 name = "ali" list = []',
          hint: 'Equals and plus are among the most typed symbols in code. '
              'Make them feel as natural as a letter key.',
        ),

        // Ex 4 — Longer code phrases
        LessonExercise(
          title: 'Code Phrases',
          text: 'score = score + 1; if (x > 0) { total = total - 1; }',
          hint: 'A real line of code with five different symbols. '
              'Read the whole line first, then type it in one smooth motion.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Code Line Drill',
          text: 'int x = 100; if (x > 50) { x = x - 25; } // result: 75',
          hint: 'A complete logical code statement. Every symbol here '
              'appears in real programs. This is professional-level typing.',
        ),
      ],
    ),
  ],
);


// ═══════════════════════════════════════════════════════════════════════════
// COURSE 6 — SPEED DRILLS
// Lessons: Common words · Word bursts · Accuracy focus · Record breaker
// Goal: push WPM with accuracy using real-world text patterns.
// ═══════════════════════════════════════════════════════════════════════════
const LessonCourse _speedDrillsCourse = LessonCourse(
  id: 'speed_drills',
  title: 'Speed Drills',
  description:
      'Push your WPM without sacrificing accuracy. Each lesson targets '
      'a different barrier: common words, flow, precision, and raw speed.',
  icon: '⚡',
  lessons: [

    // ── Lesson 1 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'common_words',
      title: 'Top Common Words',
      subtitle: 'The words you type in 80% of every sentence',
      keys: 'All keys',
      exercises: [

        // Ex 1 — Isolation (highest-frequency words)
        LessonExercise(
          title: 'Top 10 Words',
          text: 'the and to a of in is it you that',
          hint: 'These 10 words make up roughly 25% of all written English. '
              'You should type each one without any conscious thought.',
        ),

        // Ex 2 — Alternation (next 10 words)
        LessonExercise(
          title: 'Next 10 Words',
          text: 'he was for on are with as his they at',
          hint: 'Learn these cold. Together with the first 10, these 20 words '
              'appear in nearly every paragraph you will ever type.',
        ),

        // Ex 3 — Real phrases (common verb set)
        LessonExercise(
          title: 'Common Verbs',
          text: 'run type write read learn grow think find help make',
          hint: 'High-frequency action words. Push for smooth, even rhythm '
              'with no hesitation between words.',
        ),

        // Ex 4 — Phrases (combined common words)
        LessonExercise(
          title: 'Common Phrases',
          text: 'you can do it; make it work; find the way; learn and grow',
          hint: 'Phrases built entirely from top-frequency words. '
              'If you type these fast, you type fast in general.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Speed Sentence',
          text: 'the best way to learn to type fast is to type the right words every day',
          hint: 'All high-frequency words. Count your WPM. '
              'Repeat this drill three times and watch your score improve.',
        ),
      ],
    ),

    // ── Lesson 2 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'word_bursts',
      title: 'Word Bursts',
      subtitle: 'Short explosive drills targeting specific patterns',
      keys: 'All keys',
      exercises: [

        // Ex 1 — Isolation (1–3 letter words)
        LessonExercise(
          title: 'Tiny Word Burst',
          text: 'go do so no we be me he she the and but for it is',
          hint: 'Short words at full speed. Every word is 2–3 keystrokes. '
              'You should feel like you are pressing keys non-stop.',
        ),

        // Ex 2 — Alternation (double letters)
        LessonExercise(
          title: 'Double Letter Drill',
          text: 'soon feel tall add egg inn off all book good loop',
          hint: 'Double letters catch typists off guard. '
              'Press each one firmly — do not merge them into one keystroke.',
        ),

        // Ex 3 — Real words (long words)
        LessonExercise(
          title: 'Long Word Challenge',
          text: 'information communication understanding development keyboard',
          hint: 'Slow down and be accurate. Long words are typed in chunks: '
              'in-for-ma-tion. Break them mentally, not physically.',
        ),

        // Ex 4 — Phrases (alternating short and long)
        LessonExercise(
          title: 'Mixed Burst',
          text: 'we need to understand the important information presented now',
          hint: 'Short and long words alternating. Find a rhythm that carries '
              'you through the long words without a hesitation dip.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Burst Sentence',
          text: 'good communication and understanding help all of us feel and work better',
          hint: 'Your target is zero errors at your personal maximum speed. '
              'Errors cost more time than slowness does. Stay accurate.',
        ),
      ],
    ),

    // ── Lesson 3 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'accuracy_focus',
      title: 'Accuracy Training',
      subtitle: 'Zero errors. Every keystroke matters.',
      keys: 'All keys',
      exercises: [

        // Ex 1 — Isolation (capital letters)
        LessonExercise(
          title: 'Capitals Drill',
          text: 'Nepal India China Russia France Japan Korea Brazil Canada',
          hint: 'Every word is capitalised. Use the correct Shift key each time. '
              'Left Shift for right-hand first letters; Right Shift for left-hand.',
        ),

        // Ex 2 — Alternation (numbers in sentences)
        LessonExercise(
          title: 'Number Integration',
          text: 'there are 26 letters, 10 digits, and 36 total main keys',
          hint: 'Switch between letters and numbers without any pause '
              'or hesitation. The letter-to-number transition is a skill.',
        ),

        // Ex 3 — Real sentences (full punctuation)
        LessonExercise(
          title: 'Punctuated Sentences',
          text: 'Hello, my name is Ram. I am 14 years old. I study in Class 8.',
          hint: 'Capitals, commas, and periods. This is real, professional prose. '
              'Read the sentence once before you type it.',
        ),

        // Ex 4 — Phrases (mixed content)
        LessonExercise(
          title: 'Mixed Content',
          text: 'Room 12, Floor 3: 8 students scored 90% or above last year.',
          hint: 'Numbers, symbols, capitals, and punctuation together. '
              'This is the standard you need for any office or exam situation.',
        ),

        // Ex 5 — Sentence drill
        LessonExercise(
          title: 'Accuracy Challenge',
          text: 'In 2024, 8 students from Class 7B achieved over 90% accuracy in TypingQuest!',
          hint: 'Every character type in one sentence. Count your errors carefully. '
              'Achieving zero errors here is the true accuracy milestone.',
        ),
      ],
    ),

    // ── Lesson 4 ──────────────────────────────────────────────────────────
    Lesson(
      id: 'record_breaker',
      title: 'Record Breaker',
      subtitle: 'Push your absolute maximum speed — this is your personal best attempt',
      keys: 'All keys',
      exercises: [

        // Ex 1 — Isolation (warm-up sprint)
        LessonExercise(
          title: 'Warm-Up Sprint',
          text: 'type fast and keep your fingers close to the home row at all times',
          hint: 'A clean, familiar sentence to warm your fingers. '
              'Shake out any tension first. Breathe, then type.',
        ),

        // Ex 2 — Alternation (balanced sentence)
        LessonExercise(
          title: 'Sprint One',
          text: 'the sun rises in the east and sets in the west every single day',
          hint: 'All common words, all home-row and top-row letters. '
              'Push for maximum WPM with zero errors. Count both.',
        ),

        // Ex 3 — Real sentence (motivation content)
        LessonExercise(
          title: 'Sprint Two',
          text: 'practice every morning and your typing speed will double in one month',
          hint: 'A longer sentence. Maintain your speed all the way to the period. '
              'Many typists slow at the end of sentences — do not.',
        ),

        // Ex 4 — Phrases (peak difficulty phrase)
        LessonExercise(
          title: 'Sprint Three',
          text: 'accurate and fast typing comes only through daily focused practice on real text',
          hint: 'Your personal best attempt. Forget your WPM score. '
              'Think only about smooth, even keystrokes from first to last.',
        ),

        // Ex 5 — Sentence drill (ultimate record attempt)
        LessonExercise(
          title: 'Record Attempt',
          text: 'a skilled typist reaches sixty words per minute with full accuracy through daily practice and deep focus',
          hint: 'This is your record attempt. Type it as fast as you possibly can '
              'with zero errors. Log your WPM and try to beat it every week.',
        ),
      ],
    ),
  ],
);