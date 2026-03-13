import '../models/game_models.dart';

class TypingContent {
  // Target WPM for each difficulty level
  static int targetWpm(Difficulty d, int level) {
    switch (d) {
      case Difficulty.beginner:
        return 10 + (level ~/ 10) * 3;
      case Difficulty.intermediate:
        return 25 + (level ~/ 10) * 5;
      case Difficulty.master:
        return 50 + (level ~/ 10) * 5;
    }
  }

  // Time limit: 1.2× the "expected" time at target WPM (generous window)
  // Clamped to 15–120 seconds so every level feels timed.
  static int timeLimitSeconds(Difficulty d, int level) {
    final text = getText(d, level);
    final wordCount = text.length / 5.0;
    final wpm = targetWpm(d, level).toDouble();
    final expectedSecs = (wordCount / wpm * 60).ceil();
    return (expectedSecs * 1.2).ceil().clamp(15, 120);
  }

  static String getText(Difficulty d, int level) {
    switch (d) {
      case Difficulty.beginner:
        return _beginnerLevels[level - 1];
      case Difficulty.intermediate:
        return _intermediateLevels[level - 1];
      case Difficulty.master:
        return _masterLevels[level - 1];
    }
  }

  // ── Beginner: 100 levels ──────────────────────────────────────────────
  // L1–10:   Home row keys only  (a s d f g h j k l)
  // L11–20:  Top row added       (q w e r t y u i o p)
  // L21–30:  Full keyboard       (z x c v b n m)
  // L31–40:  Simple 3–4-letter words
  // L41–50:  Common everyday words
  // L51–60:  Short familiar phrases
  // L61–70:  Simple sentences (no punctuation)
  // L71–80:  Sentences with commas
  // L81–90:  Complete sentences with full stops
  // L91–100: Longer sentences

  static const List<String> _beginnerLevels = [
    // Level 1–10: Home row keys only
    'a s d f',
    'j k l f',
    'a s d f j k l',
    'f d s a j k l f',
    'a d f s g h j k l',
    'ask sad fall had',
    'lad dad hall lass fall',
    'glad flask salad falls',
    'all fall glad ask a lass',
    'ask a lad all glad flask falls',

    // Level 11–20: Top row keys added
    'r t y u i',
    'q w e r t y',
    'say ray day try',
    'quit rate year duty',
    'fast type word stop',
    'great write your duty',
    'sweet treat street true',
    'try your best every day',
    'press the right key first',
    'write your words with great care',

    // Level 21–30: Full keyboard (bottom row added)
    'v b n m z x',
    'can van ban man',
    'back neck black zinc',
    'move come name next',
    'calm band zoom bench',
    'cave bank blame next move',
    'come back some brave calm',
    'next calm move zinc back',
    'bring some calm next move',
    'move back and come in now calm',

    // Level 31–40: Simple 3–4-letter words
    'cat dog run sit up',
    'big red box top cup',
    'hot sun day fun new',
    'old big one red bag',
    'cup top hat map sit',
    'mad sad bad glad run',
    'fog log hot dog jog',
    'bag tag rag nag flag',
    'cut but nut put rut',
    'sip dip tip lip rip',

    // Level 41–50: Common everyday words
    'book home work play day',
    'class read time more now',
    'food ball rain game run',
    'door open blue hand tree',
    'bird high fly sky wind',
    'look walk talk rest grow',
    'have give take make help',
    'good best nice kind warm',
    'here there that this then',
    'what when why will where',

    // Level 51–60: Short familiar phrases
    'the bright clear morning sky',
    'a long road leads far away',
    'fresh cool air in the morning',
    'work hard and do your best',
    'a kind word can help greatly',
    'reading books opens your mind wide',
    'keep trying until you reach your goal',
    'good things come with patience and work',
    'a clean desk helps you think clearly',
    'small steps each day lead to great things',

    // Level 61–70: Simple sentences (no punctuation)
    'i like to read books every day',
    'the sky is bright and very blue',
    'she has a neat and tidy desk',
    'we go to school every morning early',
    'he runs fast along the open road',
    'they eat rice and bread each day',
    'the dog loves to run in the park',
    'my friend and i love to play games',
    'the sun rises over the hills each morning',
    'i drink cold water when i feel thirsty',

    // Level 71–80: Sentences with commas
    'open the door, then step quietly inside',
    'write your full name, then sit down calmly',
    'eat your lunch, then drink a glass of water',
    'read the whole page, then close your book',
    'wash your hands well, then sit down to eat',
    'close the window gently, the wind is too cold',
    'pick up your pen, and start to write now',
    'look at the board closely, then copy the notes',
    'finish all your work first, then take a short rest',
    'stand up slowly, and walk carefully to the front',

    // Level 81–90: Complete sentences with full stops
    'The cat sat quietly on the warm mat.',
    'She opened her book and began to read it.',
    'He walked to school alone every single morning.',
    'The computer sits on the table by the window.',
    'We practise typing in the lab every school day.',
    'The teacher wrote the lesson neatly on the board.',
    'I finished all my homework well before dinner time.',
    'Open the right folder and find the correct file there.',
    'Press the enter key only when you are fully ready.',
    'Click the blue button that you can see on the screen.',

    // Level 91–100: Longer sentences
    'A computer is one of the most useful tools a student can learn to use well.',
    'Learning to type quickly and accurately is a skill that will help you every single day.',
    'The keyboard is made up of letters, numbers, punctuation marks, and special function keys.',
    'We can share our ideas, messages, and files with others quickly by using a computer.',
    'Please open the correct program on the computer and begin to type your answer carefully.',
    'She studied hard every evening and passed all of her important school examinations with high marks.',
    'The internet gives students the ability to find information on almost any subject they choose.',
    'A good typing speed will allow you to finish your school assignments much faster and with less effort.',
    'If you practise for just a little time every day, you will notice a big improvement in your speed.',
    'Typing is a skill that grows stronger and faster the more time and effort you put into practising it.',
  ];

  // ── Intermediate: 100 levels ──────────────────────────────────────────
  // L1–15:   Classic sayings and short sentences         (~10–25 words)
  // L16–30:  Longer educational single sentences         (~20–40 words)
  // L31–50:  Two-sentence educational pairs              (~30–55 words)
  // L51–70:  Short paragraphs                            (~50–70 words)
  // L71–85:  Medium paragraphs                           (~70–95 words)
  // L86–100: Long paragraphs                             (~90–115 words)

  static const List<String> _intermediateLevels = [
    // Level 1–15: Classic sayings and short sentences
    'The quick brown fox jumps over the lazy dog.',
    'Practice makes perfect in everything you choose to do.',
    'All that glitters is not always gold.',
    'Look before you leap into any decision.',
    'Actions speak much louder than words alone.',
    'A stitch in time will always save nine.',
    'The early bird always catches the worm.',
    'Where there is a will, there is always a way.',
    'Knowledge is power when it is used wisely.',
    'Every new day is a fresh chance to improve yourself.',
    'Hard work and patience always pay off in the end.',
    'Success belongs to those who prepare and work hard daily.',
    'Be kind to others, and they will be kind to you.',
    'A journey of a thousand miles begins with a single step.',
    'The secret of getting ahead in life is simply getting started.',

    // Level 16–30: Longer educational single sentences
    'The students gathered in the computer lab to improve their typing speed and accuracy.',
    'Learning any new skill well requires time, patience, and a great deal of consistent practice.',
    'Nepal is a beautiful and diverse country blessed with magnificent mountain scenery and rich culture.',
    'The Himalayan range contains eight of the world\'s ten highest peaks, including the mighty Everest.',
    'Computers have completely transformed the way that people work, learn, communicate, and entertain themselves.',
    'Reading widely every day will improve your vocabulary, your writing ability, and your general thinking skills.',
    'A good teacher explains ideas clearly and makes every student feel genuinely capable of understanding.',
    'Technology has made quality education far more accessible to students in countries all around the world.',
    'A dedicated student always listens attentively in class and asks good questions when anything is unclear.',
    'Mount Everest, standing at 8,848 metres above sea level, is the highest mountain peak on Earth.',
    'The internet connects billions of people and devices spread across countries on every continent of the world.',
    'We must always show respect and gratitude to our parents, teachers, and the elders of our community.',
    'A balanced diet that includes fresh fruits, vegetables, and protein keeps the body strong and the mind alert.',
    'Regular exercise, adequate sleep, and good nutrition together form the foundations of a truly healthy lifestyle.',
    'Teamwork and open communication make it far easier to achieve goals that would be impossible to reach alone.',

    // Level 31–50: Two-sentence educational pairs
    'I woke up before sunrise to make the most of the cool morning. The fresh air outside was calm and completely still.',
    'She opened her laptop and immediately began working on the assignment. Two focused hours later, the task was fully complete.',
    'The computer lesson started promptly at eight o\'clock in the morning. Every student was seated, ready, and eager to begin.',
    'He typed steadily and confidently without once looking down at the keyboard. His accuracy and speed were both genuinely impressive.',
    'The electronics store displayed many different models of computers and laptops. We took our time carefully and chose the very best one.',
    'Learning to type efficiently is an incredibly valuable life skill for everyone. It allows you to work faster and more comfortably on any computer.',
    'The principal gave a warm and encouraging speech to the entire student body. Everyone listened attentively and applauded enthusiastically at the end.',
    'She submitted her completed project two full days before the deadline. Her teacher was very impressed with the quality and depth of her work.',
    'A keyboard contains twenty-six letter keys arranged in the standard QWERTY layout. It also includes number keys, symbol keys, and useful function keys.',
    'Sitting with a straight back while typing helps you avoid developing back pain. Good posture also allows you to type more comfortably for much longer periods.',
    'Modern computers can process millions of individual calculations in under one second. They have become an essential and indispensable tool in every area of human activity.',
    'The internet was first developed in the second half of the twentieth century. It has since transformed nearly every aspect of how people work, learn, and connect worldwide.',
    'Students who practise their typing consistently will always improve their speed faster. The true key to visible progress is regular, focused effort applied over a period of time.',
    'A computer mouse allows you to move the cursor smoothly anywhere across the screen. It makes the tasks of selecting, clicking, and dragging objects much easier and more precise.',
    'The monitor is the primary output device of any desktop computer system. It displays everything the computer is processing in a clear visual format that the user can read and interact with.',
    'Always save your work regularly to make absolutely sure you never lose important data. Use the keyboard shortcut Control and S together to save your file quickly at any time.',
    'Creating clearly named folders helps you keep all your computer files neatly organised at all times. When everything has a proper name and a logical place, finding any file later becomes effortless.',
    'Spelling mistakes and careless typing errors can significantly slow down your overall typing speed over time. Focus entirely on accuracy first, and your speed will naturally increase as your confidence grows.',
    'Concentrate on typing each word correctly before you attempt to type more quickly than is comfortable. Accuracy is the true foundation of good typing, and greater speed will follow naturally with more practice.',
    'The home row is the central row of letter keys where your fingers should rest when not actively typing. Returning your fingers to the home row after every keystroke allows you to reach any key on the keyboard with speed and efficiency.',

    // Level 51–70: Short paragraphs (~50–70 words)
    'Typing is one of the most valuable computer skills any student can develop. When you type quickly and accurately, you save a great deal of time every single day. Students who type well can complete written assignments far faster than those who use only two fingers. The time you invest now in learning to type correctly will reward you throughout your entire education and career.',

    'The school computer laboratory has thirty computers available for all students to use. Each student receives dedicated practice time every week to work on improving their typing skills. Teachers have observed that students who attend every session and also practise regularly at home improve their speed much faster than those who only practise during scheduled class time in the lab.',

    'Nepal is one of the most geographically diverse and fascinating countries in the entire world. It is home to eight of the planet\'s ten highest mountain peaks, including the legendary summit of Mount Everest. Every year, many thousands of mountaineers and trekkers travel from countries all around the globe to experience the breathtaking and unforgettable beauty of the Nepalese Himalayas.',

    'A healthy lifestyle is built on three essential foundations: good nutrition, regular physical exercise, and adequate rest each night. Students who eat balanced and nutritious meals, exercise for at least thirty minutes daily, and sleep for eight to nine hours each night are consistently better able to concentrate during lessons and perform well across all of their academic subjects.',

    'The school library is an incredibly valuable resource for curious and motivated students. It contains hundreds of books covering a wide variety of subjects, from mathematics and science to history, literature, and the arts. Students who visit the library regularly and read beyond their textbooks consistently develop a far richer vocabulary and a much broader understanding of the world around them.',

    'Computers are now used in virtually every field of modern human activity, including medicine, education, engineering, banking, and entertainment. They help doctors manage patient records, help engineers design safer buildings and more efficient machines, and help students anywhere in the world access a vast wealth of information instantly. The importance of strong computer literacy skills has never been greater than it is today.',

    'Touch typing is the technique of typing without looking down at the keyboard at any point during the process. Instead of searching for each key visually, you train your fingers to memorise the position of every key through many repetitions over time. Once you have mastered touch typing, your speed and accuracy will improve dramatically, and you will be able to type freely while reading from a document or looking at the screen.',

    'The QWERTY keyboard layout was designed in the 1870s for use with early mechanical typewriters. The letters are deliberately not arranged in alphabetical order on the keyboard. Instead, they are positioned carefully to balance the workload evenly between your left and right hands and to reduce the chance of adjacent mechanical type bars jamming together during fast and continuous typing.',

    'Good sportsmanship is one of the most important values a young person can develop through participating in team sports and competitions. It means playing fairly, following the rules of the game honestly, and treating both your teammates and your opponents with genuine courtesy and respect at all times. A good sport congratulates the winner graciously and accepts defeat without making excuses or displaying poor behaviour.',

    'Mathematics is a subject that steadily builds logical thinking, problem-solving ability, and precision of thought in everyone who studies it seriously. Students who practise solving mathematical problems regularly develop stronger analytical skills that benefit them in science, technology, and everyday decision-making. A solid foundation in mathematics opens doors to careers in engineering, finance, computing, medicine, and many other important and well-rewarded professions.',

    'Electricity is the invisible force that powers nearly all of the technology and machinery that our modern way of life depends upon. From the lights in our classrooms to the computers we use every day to learn and work, electricity is absolutely essential to modern life. Developing the habit of switching off all lights and appliances when they are not being used is a simple but meaningful way to conserve energy.',

    'Water is the most essential substance for all living things on our planet. The human body is composed of approximately sixty percent water, and we need to drink at least eight glasses of clean water every single day to remain healthy and mentally alert. We also share a collective responsibility to protect our rivers, lakes, and underground water sources from pollution, for the benefit of all future generations who will depend on them.',

    'The calendar is one of humanity\'s oldest and most useful shared inventions. It divides the year into twelve months and three hundred and sixty-five days, helping us organise our time, plan ahead for the future, and mark important celebrations and events. Without a common system for measuring and dividing time, coordinating activities and appointments between individuals and communities across a society would be extraordinarily difficult.',

    'When you make a typing error during practice, the most important thing is to remain calm and correct it smoothly and efficiently. Panicking or becoming frustrated with yourself will only slow you down further and tend to cause more mistakes in quick succession. Press the backspace key once to erase the wrong character, then retype it correctly. With enough practice, this process of self-correction becomes fast, smooth, and virtually automatic.',

    'The shift key is one of the most frequently used keys on the entire keyboard. You press it simultaneously with a letter key to produce a capital letter, or together with a number key to produce the special symbol printed above that number. The caps lock key, meanwhile, locks all letter keys into uppercase mode and keeps them there until you press the caps lock key a second time to release it.',

    'Punctuation marks are essential tools for clear, precise, and effective written communication. Commas separate items in a list and create natural and helpful pauses within a longer sentence. Full stops mark the definite end of a complete thought or statement. Question marks signal that a sentence is asking for information or a response. Without punctuation, written text rapidly becomes confusing, ambiguous, and very difficult to read.',

    'Computer files can take many different forms, including text documents, spreadsheet tables, digital images, audio recordings, and video clips. You can perform many useful operations on files, such as copying, moving, renaming, and permanently deleting them. Keeping all your files carefully organised within clearly labelled folders makes your work far easier to locate and manage, especially as the total number of files you create continues to grow over time.',

    'The spacebar is the longest and most frequently pressed key on the entire keyboard. Every single time you finish typing one word and are ready to begin the next, you press the spacebar with your thumb to insert the necessary space between them. Developing a smooth, consistent, and natural spacebar technique is an important and often overlooked part of building good overall typing form and a high words-per-minute score.',

    'In Nepal, students study a broad and varied curriculum that includes the Nepali language, English, mathematics, social studies, science, health education, and computer science. Each subject contributes to the development of different skills, perspectives, and areas of knowledge. A well-rounded education equips students with the diverse tools they need to adapt successfully to many different situations, challenges, and opportunities throughout their working lives.',

    'Being safe and responsible online is a vital and increasingly important skill in today\'s connected world. You should never share personal information such as your home address, telephone number, school name, or daily schedule with anyone you have not met in person. If you ever see content online that makes you feel uncomfortable, worried, or unsafe, tell a trusted adult immediately so that they can help you deal with the situation.',

    // Level 71–85: Medium paragraphs (~70–95 words)
    'Computers have become an indispensable part of modern education at every level of schooling. Students use them daily to research topics, write and edit essays, create presentations, and communicate with their teachers and peers. The ability to use a computer confidently and competently gives students a significant advantage in both their academic studies and in their future careers. The very first step towards achieving full digital literacy is learning to type efficiently and accurately, because almost every single computer task involves typing in some form.',

    'The keyboard is the primary input device through which users communicate instructions and data to a computer. Modern keyboards use the QWERTY layout, which was originally designed for mechanical typewriters in the nineteenth century. While other keyboard layouts such as Dvorak have been proposed as potentially more efficient alternatives, QWERTY remains by far the most widely used standard in schools, offices, and homes all around the world today. Learning the positions of all the keys thoroughly is the first major challenge every new typist must work through and overcome.',

    'Every student, regardless of their natural ability or starting point, has the genuine potential to become a skilled and confident typist. The single most important factor in achieving this is not natural talent but consistent and deliberate practice. Even just fifteen focused minutes of practice every single day can produce remarkable and visible improvement within only a few weeks. Do not allow yourself to feel discouraged when your progress seems slow. Every minute of practice is building skill that will serve you for the rest of your life.',

    'Physical health and mental wellbeing are both absolutely essential for students to perform at their very best in all areas of school life. A student who eats nutritious food regularly, gets adequate sleep every night, and exercises their body consistently will have significantly more energy, sharper concentration, and a more consistently positive outlook throughout the school day. Developing strong and sustainable healthy habits while you are young makes it far easier to maintain them as you grow older and face increasing demands.',

    'The mountains and high valleys of Nepal attract visitors and adventurers from every corner of the globe. Trekkers follow ancient trails through lush green valleys, past terraced rice fields, and up through high-altitude forests and mountain meadows. The tourism industry that has grown around these magnificent landscapes provides employment and income for tens of thousands of Nepali families and remains one of the most significant contributors to the overall national economy.',

    'An inspiring teacher can have a profound and genuinely lasting impact on the direction that a student\'s entire life takes. The very best teachers do far more than simply deliver curriculum content from a textbook. They challenge their students to think critically, to ask thoughtful questions, and to form well-reasoned opinions of their own. They notice when a student is struggling and find patient, creative, and encouraging ways to help them understand and overcome their difficulties. The influence of a truly great teacher can be felt for an entire lifetime.',

    'The computer mouse was invented in the 1960s by the American engineer Douglas Engelbart. Before the invention of the mouse, all computer commands had to be entered manually using only the keyboard, which made computers far less intuitive and accessible to ordinary users. Today, mice are available in dozens of different shapes, sizes, and designs, with wireless models becoming increasingly popular. Many modern laptops use a built-in touchpad in place of an external mouse, though many users prefer the greater precision of a traditional mouse.',

    'Random-access memory, commonly known simply as RAM, is one of the most critical components inside any computer. It temporarily stores the data and program instructions that the processor is actively working with at any given moment in time. The more RAM a computer contains, the more tasks it can handle simultaneously without slowing down. When you shut down or restart the computer, all information held in RAM is completely cleared, which is precisely why saving your work regularly throughout a session is so important.',

    'Friendship is one of the most enriching and genuinely meaningful parts of human life. A true friend offers honest and caring advice even when it is not exactly what you want to hear, stands firmly by your side during difficult and uncertain times, and celebrates your successes with sincere and wholehearted joy. Maintaining strong friendships requires regular time and effort, honesty, and deep mutual respect. Always treat your friends with the same kindness, patience, and loyalty that you hope they will show to you.',

    'Every one of us has a genuine responsibility to care for the natural environment that sustains all life on our beautiful planet. Cutting down forests, dumping waste into rivers, and burning fossil fuels cause damage that takes many generations to repair. Students can make a meaningful positive contribution by reducing waste wherever possible, reusing and recycling materials, planting trees, and using water and electricity thoughtfully. When millions of individuals each make small positive changes to their daily habits, the collective impact on the health of the environment is enormous.',

    'Effective written communication is a skill that is highly valued in every profession and every area of life. Whether you are writing a formal letter, an academic essay, a business report, or even a simple text message to a friend, your ability to express your ideas clearly and correctly reflects your education, your intelligence, and your care for the reader. Typing accurately and quickly is the digital equivalent of having neat and legible handwriting. Both skills deserve consistent care, attention, and ongoing effort to improve.',

    'The human brain is the most extraordinary and complex organ known to modern science. It contains approximately eighty-six billion neurons, each connected to thousands of others, forming a network of almost unimaginable intricacy and capability. The brain controls every conscious and unconscious function of the body, from breathing and heartbeat regulation to memory formation, language use, and creative thinking. Scientists and researchers continue to make remarkable new discoveries about the brain every year, and many of its most fundamental mysteries still remain completely unsolved.',

    'Science is humanity\'s most powerful and reliable method for understanding the natural world and for solving the problems that threaten human wellbeing and progress. Through careful and systematic observation, rigorous experimentation, and honest analysis of evidence, scientists have discovered the fundamental laws governing the universe, developed life-saving medicines and vaccines, and created the technologies that form the backbone of modern civilisation. Students who develop a genuine and deep curiosity for science are well prepared to contribute to the future.',

    'A school community functions best when all of its members, including students, teachers, administrative staff, and families, feel genuinely respected, valued, and included in the life of the school. Clear expectations, consistent fairness, and open and honest communication between all groups create an environment in which every student feels safe, supported, and strongly motivated to learn and to grow. When students take real responsibility for their own behaviour and look out for one another, the whole community grows stronger together.',

    'Typing speed and accuracy are measured in words per minute, which is commonly abbreviated as WPM. In this widely used measurement, a word is defined as any sequence of exactly five characters, including spaces and punctuation marks. Complete beginners typically type at somewhere between ten and twenty WPM. Office workers and administrative professionals are generally expected to type at sixty WPM or above. Competitive speed typists can achieve speeds well in excess of one hundred and fifty WPM, and the current world record stands above two hundred and fifty WPM.',

    // Level 86–100: Long paragraphs (~90–115 words)
    'In the modern world, digital literacy is considered just as fundamental a skill as reading, writing, and arithmetic. The ability to use computers effectively and safely opens doors to an enormous range of educational and professional opportunities that remain out of reach for those without these skills. Learning to type efficiently is the foundation upon which all other digital skills are built. From composing emails and writing reports to creating presentations and writing computer programs, typing is involved in nearly every task performed on a computer. Investing your time and effort in developing this skill now will pay dividends for the rest of your working life.',

    'The history of computing is a remarkable story of human ingenuity, collaboration, and rapid technological change. The earliest computing machines, built in the 1940s, were enormous electromechanical devices that filled entire rooms and required whole teams of trained engineers just to operate them. Over the following decades, rapid advances in electronics led to computers becoming progressively smaller, faster, far cheaper, and vastly more capable. Today, the smartphone that fits easily in your shirt pocket contains far more computing power than the systems that guided the first crewed lunar landing missions back in the 1960s.',

    'This school is an important centre of learning and community for all the families it serves year after year. The dedicated and hardworking teachers who work here invest their time and energy not only in transmitting knowledge and academic skills but also in inspiring students to think independently and to aspire to their very highest potential. As a student of this school, you have both the great privilege of a good education and the clear responsibility to honour that privilege through consistent hard work, honesty, and genuine respect for every person around you.',

    'Managing your time wisely is one of the most valuable and transferable skills you can possibly develop during your school years. When you have a clear and realistic plan for how you will use your time each day, you are consistently able to complete your schoolwork, pursue your personal hobbies and interests, spend quality time with your family and friends, and still allow yourself adequate time for rest and recovery. Begin by writing out a daily schedule and committing yourself to following it faithfully. Good time management steadily reduces stress and brings a genuine sense of calm and control to daily life.',

    'Curiosity is the fundamental inner engine that drives all meaningful learning and discovery. When you are genuinely curious about a topic or a question, you naturally seek out new information, ask penetrating and thoughtful questions, and pursue a deeper understanding with real energy and enthusiasm. This powerful drive is what motivates scientists to conduct experiments, historians to analyse ancient records, and engineers to design new and better machines. Never allow your curiosity to be dulled by routine or familiarity. Every sincere question you ask, no matter how small it may seem, carries the potential to lead you toward a genuinely important discovery.',

    'TypingQuest is a game designed specifically to make the process of learning to type an engaging, motivating, and genuinely enjoyable experience for students. By organising practice into a clear structure of levels, goals, and achievements, it gives every student a strong sense of measurable progress and clear purpose. The multiplayer LAN race feature allows you to compete with your classmates in real time, turning every practice session into an exciting and memorable shared challenge. The students who consistently achieve the highest scores are invariably those who approach each session with focus, patience, and a genuine determination to keep improving.',

    'Problem-solving is widely regarded by educators and employers alike as the single most important skill for success in the twenty-first century. In school, you encounter problems in mathematics, science, language, and history. In your wider life, you face challenges in your personal relationships, your work, your health, and your finances. Students who develop the strong habit of approaching any problem calmly, breaking it down systematically into smaller and more manageable parts, and thinking both logically and creatively about the available options will be far better equipped to handle whatever challenges come their way.',

    'Language is arguably the most powerful and defining achievement of the human species over our long history on this earth. Through language, we transmit accumulated knowledge and wisdom across generations, express complex emotions that would otherwise remain locked inside us, coordinate enormously complex cooperative activities, and create works of art, literature, and music that move and inspire millions of people across centuries. The ability to communicate clearly, correctly, and persuasively in both speech and writing is one of the most highly valued capabilities in every professional field and every area of public life.',

    'The decisions and habits you develop during your school years will shape the course of your entire life in ways that can be genuinely difficult to appreciate fully while you are still young. The subjects you engage with deeply, the skills you practise diligently, the relationships you build with care, and the personal values you choose to embrace all contribute in important ways to determining the direction your life will ultimately take. Work hard now, even on the days when it is difficult or feels unrewarding. The effort you put into your education today is a direct and lasting investment in every single day of your future.',

    'Gratitude is a quality of character that researchers have shown to be strongly and consistently associated with greater happiness, emotional resilience, and more positive and fulfilling relationships with others. When you consciously notice and sincerely appreciate the good things present in your life, including your health, your education, your friendships, your family, and the many small everyday pleasures that surround you, you become more content, more motivated to contribute, and more generous toward the people around you. Taking just a few moments each day to reflect on what you are genuinely grateful for has the real power to transform your entire outlook on life.',

    'Computer networks allow devices to communicate with each other and to share data efficiently over both short and long distances. A local area network, commonly referred to as a LAN, connects devices within a single building or campus, such as the computers in your school laboratory. A wide area network, known as a WAN, connects devices over far larger geographical distances, potentially spanning entire countries or even continents. The internet itself is the largest and most complex network ever built, connecting billions of individual devices and enabling people everywhere to access a vast and ever-growing shared pool of information and digital services.',

    'Every meaningful achievement in life begins with a single committed decision to start and to persist. Your journey toward becoming a fluent and truly confident typist began with your very first practice session, and every subsequent session has added steadily to your growing skill, speed, and experience at the keyboard. Try not to measure your progress against others, because every person develops at their own natural pace and in their own unique way. Focus instead entirely on your own personal growth, celebrate each milestone and improvement as it comes, and keep moving forward with steady patience and quiet determination. You will one day look back with genuine pride.',

    'Digital citizenship encompasses all the rights, responsibilities, and practical skills involved in using digital technology in a safe, ethical, responsible, and constructive manner in every area of your life. Good digital citizens communicate with genuine respect and care toward others in all online spaces, think carefully and critically before sharing any content or personal information with anyone, and take concrete and consistent steps to protect their own privacy and online security at all times. They also understand clearly that their online behaviour carries real and often lasting consequences for themselves and for other people, and they act accordingly.',

    'Patience is one of the most underrated and yet most genuinely important qualities a person can choose to cultivate in themselves over time. Learning any truly valuable and lasting skill, whether it is typing fluently, playing a musical instrument beautifully, speaking a foreign language confidently, or mastering a sport at a high level, requires sustained and consistent effort applied over a long period of time with many setbacks along the way. There will always be days when your progress appears to have stopped completely or even gone backwards. On those difficult days, remind yourself that real skill development is always happening below the surface, even when you cannot yet see the results.',

    'You have now reached the final level of the Intermediate course in TypingQuest. From your very first sentence to this point, you have developed genuine and lasting typing skill. Your fingers know the positions of every key, your speed has improved considerably, and your accuracy under pressure has grown remarkably stronger. You are fully prepared to take on the Master difficulty course. Carry forward everything you have learned, approach each new level with calm focus and confidence, and type with justified pride in how far you have come.',
  ];

  // ── Master: 100 levels ────────────────────────────────────────────────
  // L1–20:   Complex single technical sentences          (~15–28 words)
  // L21–40:  Two-sentence technical content              (~30–50 words)
  // L41–60:  Short technical paragraphs                  (~50–75 words)
  // L61–80:  Medium technical paragraphs                 (~70–95 words)
  // L81–100: Longer technical paragraphs                 (~85–110 words)

  static const List<String> _masterLevels = [
    // Level 1–20: Complex single technical sentences
    'The processor completed one million floating-point operations in under a single millisecond.',
    'Efficient sorting algorithms reduce processing time from many hours down to mere fractions of a second.',
    'She refactored the entire legacy codebase overnight, improving performance without altering any externally visible behaviour.',
    'The binary numeral system represents all possible data using only the two digits zero and one.',
    'Artificial intelligence is actively reshaping industries ranging from precision medicine to fully autonomous vehicle navigation.',
    'The distributed cluster processed over fifty thousand concurrent database queries without any measurable increase in latency.',
    'Version control systems like Git allow development teams to track, merge, and safely revert changes to shared code.',
    'Supervised machine learning requires large volumes of carefully labelled training data to produce reliable and accurate predictive models.',
    'The asymmetric encryption algorithm successfully protected sensitive financial data from all unauthorised third-party access attempts.',
    'High-speed fibre broadband has fundamentally and permanently changed how billions of people access, share, and create digital information.',
    'Object-oriented programming encapsulates related data and behaviour into reusable classes with clearly defined and stable public interfaces.',
    'The relational database indexed millions of records efficiently, enabling even the most complex queries to complete in milliseconds.',
    'Cybersecurity engineers must constantly anticipate and neutralise threats that are evolving rapidly in both sophistication and destructive scale.',
    'The application terminated unexpectedly at runtime, permanently corrupting the unsaved session data belonging to thousands of active users.',
    'Responsive design uses fluid grids and adaptive media queries to guarantee usability and readability across all screen sizes and devices.',
    'Cloud infrastructure allows organisations to provision and scale their computing resources entirely on demand without any upfront capital expenditure.',
    'The lead developer refactored the legacy monolith into independent microservices, dramatically improving both maintainability and overall deployment speed.',
    'Open-source software grants any developer the full legal right to inspect, modify, and redistribute the complete underlying source code.',
    'Excessive network round-trip latency was introducing unacceptable and user-visible delays in the application\'s real-time data synchronisation pipeline.',
    'User experience design prioritises the creation of interfaces that are simultaneously intuitive, inclusive, accessible, and genuinely pleasurable to use.',

    // Level 21–40: Two-sentence technical content
    'A well-organised directory structure makes it straightforward to locate, manage, and back up all digital assets efficiently. Consistent naming conventions and logical folder hierarchies are the hallmarks of a disciplined and professional developer.',
    'The security team released a critical patch addressing two severe remote code execution vulnerabilities discovered in the production environment. All clients were strongly and urgently advised to apply the update within twenty-four hours of its public release.',
    'Parallel computing divides a complex computational problem into smaller independent sub-problems that multiple processors can solve simultaneously. This technique dramatically reduces the total wall-clock time needed for tasks such as scientific simulation, rendering, and large-scale data processing.',
    'The API documentation provided detailed endpoint descriptions, authentication requirements, supported request formats, and illustrative example response payloads. Well-written and accurate documentation significantly reduces the integration time required when third-party developers begin consuming a new service.',
    'Debugging complex software effectively requires methodical logical reasoning, precise and careful observation, and the disciplined elimination of possible root causes. The most consistently effective developers approach bugs as logical puzzles to be solved rather than as sources of frustration and anxiety.',
    'The recursive function traversed every node of the binary tree and correctly calculated the maximum depth at each step. Without a clearly and explicitly defined base case, a recursive function will call itself indefinitely and rapidly exhaust all available call stack memory.',
    'Comprehensive and thorough error handling prevents an application from crashing ungracefully when it receives invalid or completely unexpected input from any external source. All data crossing a system boundary, including user input, file contents, and network responses, must be carefully validated before it is processed or stored.',
    'The globally distributed development team maintained alignment through asynchronous video updates, shared collaborative documents, and concise daily written stand-up summaries. Effective remote collaboration requires explicit and disciplined communication habits that would simply be unnecessary when all team members share the same physical working space.',
    'Interactive data visualisations transform dense and difficult numerical datasets into clear charts, graphs, and maps that immediately reveal underlying patterns. Selecting the most appropriate visual representation for a particular dataset is every bit as important as ensuring the underlying accuracy and completeness of the data itself.',
    'The continuous integration server automatically ran the full automated test suite against every new commit pushed to the shared code repository. Any commit that caused a single test failure was immediately flagged and prevented from being merged into the protected main production branch.',
    'Nepal\'s rapidly expanding technology sector is generating significant new employment opportunities for skilled computer science and software engineering graduates. Several Kathmandu-based software companies now successfully export their products and professional services to clients based in Europe, North America, and Southeast Asia.',
    'The startup secured initial pre-seed funding from three regional investors to accelerate the development of their adaptive personalised learning platform. The founding team planned to launch a closed beta programme with one hundred selected students across five partner schools within the following quarter.',
    'Students who develop strong programming ability and fluent typing skills before leaving secondary school have a measurable and lasting advantage in the competitive technology job market. Employers consistently rate clear communication skills and the demonstrated ability to learn new things independently as the most highly sought-after attributes in recent graduates.',
    'The available network bandwidth determines the maximum rate at which data can be successfully transmitted between two connected devices over a given connection. Latency, packet loss, and jitter are three separate but equally important network performance characteristics that also significantly affect perceived application responsiveness and overall user experience.',
    'Automated testing frameworks continuously and automatically verify that all existing software features continue to function correctly after any new code changes are introduced into the codebase. A comprehensive and well-maintained test suite is one of the single most important long-term investments a development team can make in the health and maintainability of their product.',
    'The digital divide describes the persistent and deeply consequential gap in access to modern computing technology and reliable high-speed internet between wealthy and economically disadvantaged communities around the world. Bridging this divide requires coordinated and sustained investment in physical infrastructure, affordable devices, digital literacy training programmes, and locally relevant and useful digital content.',
    'File compression algorithms reduce the total size of stored data by encoding frequently repeated byte patterns more compactly and eliminating genuinely redundant information from the data stream. Compressed files can be transmitted across networks in significantly less time and can be stored using far less physical disk space than their uncompressed equivalents.',
    'The central processing unit\'s clock speed, measured in gigahertz, indicates precisely how many instruction execution cycles the processor can complete in every single second of operation. Modern high-performance processors also employ advanced architectural techniques including deep pipelining, branch prediction, and speculative out-of-order execution to process multiple instructions simultaneously.',
    'Modern operating systems implement preemptive multitasking by rapidly and continuously switching the processor\'s attention between all currently running processes, thereby creating the convincing illusion of true simultaneous parallelism. Each process receives a short predetermined time slice of processor attention before the scheduler automatically moves on to the next eligible process in the scheduling queue.',
    'The conditional branching instruction evaluates a boolean expression and directs the flow of program execution down one of exactly two possible paths depending on the result. Deeply nested conditional structures and overly complex logical expressions can make source code extremely difficult for others to read, understand, and maintain without introducing subtle logical errors.',

    // Level 41–60: Short technical paragraphs (~50–75 words)
    'A strong and unique password is one of the simplest and most immediately effective defences against unauthorised access to your personal accounts and sensitive data. It should be at least twelve characters in total length and must combine uppercase letters, lowercase letters, numeric digits, and special symbols. Avoid using easily guessable personal information such as birthdays, names, or common dictionary words. Using a completely different strong password for every account you maintain is an absolutely essential security practice in the modern digital world.',

    'The graphics processing unit, commonly abbreviated as GPU, was originally engineered to accelerate the intensive mathematical operations required for rendering complex three-dimensional graphics in real time. Modern GPUs contain many thousands of small but highly efficient processing cores, each capable of executing calculations simultaneously in a massively parallel fashion. This same parallel processing architecture has made GPUs extraordinarily well-suited to the large-scale matrix multiplication operations that lie at the computational heart of modern machine learning and deep neural network training.',

    'Phishing is a prevalent and highly damaging form of social engineering attack in which a malicious actor sends a deceptive message, most commonly disguised as an email from a trusted and legitimate organisation, with the explicit goal of tricking the recipient into revealing sensitive login credentials, clicking a link to a malicious website, or unwittingly downloading harmful software onto their device. Developing a healthy and informed scepticism about unsolicited messages requesting personal information is the most reliable defence against falling victim to phishing attacks.',

    'The loop control structure is a fundamental and indispensable building block of virtually every computer program ever written. It enables a defined block of code to be executed repeatedly and automatically until a specific termination condition becomes true and is evaluated. The three most commonly used forms of loop found in the majority of modern programming languages are the counted for loop, the condition-checked while loop, and the post-condition do-while loop, each of which suits a subtly different kind of repetitive computation.',

    'Software documentation serves as the essential and often irreplaceable bridge between the engineers who originally create a system and all those who must later maintain, extend, adapt, or simply use it. Well-written documentation measurably reduces the time and cognitive effort needed to understand an unfamiliar codebase, significantly lowers the risk of dangerous misunderstandings between team members, and makes the onboarding of new developers far faster and less painful. Despite all of this, documentation is consistently treated as an afterthought rather than a genuine first-class deliverable of the development process.',

    'Touchscreen technology fundamentally transformed the design and usability of consumer mobile devices by entirely replacing the physical keyboard and mouse with a direct and highly intuitive touch interface. The capacitive displays used in modern smartphones and tablets detect the small electrical perturbations caused by the conductivity of human skin when a fingertip makes contact with the glass surface. Multi-touch displays can track multiple simultaneous contact points independently, which enables natural and expressive multi-finger gestures such as pinch-to-zoom, rotation, and two-finger scrolling.',

    'Extended reality technologies, which encompass virtual reality, augmented reality, and the mixed reality spectrum between them, are rapidly moving beyond entertainment into serious professional applications including surgical training, architectural design review, and industrial maintenance and repair procedures. Virtual reality places the user inside a fully immersive and interactive computer-generated environment. Augmented reality, by contrast, overlays digital annotations and objects onto the user\'s real-world view through a camera or transparent display. Both technologies are expected to profoundly transform education within the coming decade.',

    'Algorithm complexity analysis is the systematic study of how the time and memory resource requirements of an algorithm scale as the size of its input data grows progressively larger. We describe this fundamental scaling behaviour using asymptotic Big-O notation. An algorithm classified as O(n) requires time proportional to the input size, while one classified as O(n²) becomes dramatically and prohibitively slower as the input grows. Selecting an efficient algorithm with low asymptotic complexity is often far more impactful on overall system performance than simply using more powerful hardware.',

    'Firmware is a specialised and distinct category of software that is permanently stored in a hardware device\'s non-volatile memory and provides the essential low-level control instructions the device requires to initialise and function correctly at the most fundamental level. Unlike standard application software installed by users, firmware typically persists unchanged through power cycles. Manufacturers occasionally release firmware updates to improve device performance, introduce new capabilities, or urgently patch critical security vulnerabilities that were discovered in the field after the device had already been manufactured and sold.',

    'A pull request is the formal and widely adopted mechanism used in modern collaborative software development to propose, present, review, discuss, and ultimately merge changes to a shared codebase. The author of a pull request provides a clear written description of what they changed and why, then tags appropriate colleagues to review the modified code carefully. Reviewers examine the changes line by line, leave inline comments, request specific revisions where necessary, and ultimately approve or reject the proposed changes, thereby collectively maintaining high code quality and strong team alignment.',

    'Quantum computers exploit deep and counterintuitive principles of quantum mechanics, particularly quantum superposition and quantum entanglement, to perform certain highly specific categories of computation in ways that are fundamentally different from classical binary computers and potentially orders of magnitude faster. Although quantum hardware remains in a relatively early and fragile stage of development and is currently very prone to operational errors, researchers have already demonstrated clear quantum advantage over the best classical algorithms in specific problem domains including discrete optimisation, certain cryptographic tasks, and the simulation of complex molecular and chemical systems.',

    'The operating system is the indispensable foundational layer of software that continuously manages all the hardware resources of a computer and provides the essential common services upon which every application program depends. It handles a wide range of critical tasks including process scheduling and prioritisation, virtual memory allocation and management, file system organisation and access control, device driver communication, and user authentication and session management. Without an operating system, every application developer would need to manage hardware resources directly, making software development enormously more complex, error-prone, and time-consuming.',

    'Code review is the disciplined and collaborative practice of having one or more experienced developers systematically and carefully examine code written by a colleague before it is incorporated into the shared production repository. Effective code review reliably catches bugs and logical errors that the original author overlooked in their own work, ensures that all code consistently meets the team\'s established quality and style standards, and actively spreads architectural knowledge and best practices across all members of the development team. It remains one of the most cost-effective software quality assurance practices available to any engineering organisation.',

    'The internet protocol suite, universally known as TCP/IP, is the foundational and comprehensive set of communication protocols that governs exactly how data is broken into discrete packets, logically addressed, physically transmitted, efficiently routed, and correctly reassembled across the global network of interconnected computers. The transmission control protocol layer provides reliable, fully ordered, and error-checked delivery of data streams between communicating applications. The internet protocol layer is solely responsible for assigning unique logical addresses to devices and for routing each individual data packet toward its correct ultimate destination machine.',

    'Accessibility in software and product design means building digital systems and interfaces that can be used effectively, independently, and with dignity by people with a broad range of abilities, including those living with visual, auditory, fine motor, or cognitive impairments. Genuinely accessible design benefits not only users with recognised disabilities but also users on small-screen mobile devices, users in low-bandwidth network environments, users of older hardware, and users with situational limitations. Proven accessibility techniques include providing descriptive text alternatives for all images, ensuring complete keyboard navigability throughout, and maintaining sufficient colour contrast ratios.',

    'A well-engineered deployment pipeline automates the entire process of moving a developer\'s committed code change through a clearly defined series of sequential quality gates, including automated unit and integration testing, static code analysis, security vulnerability scanning, container image assembly, and finally a staged and monitored rollout to the live production environment. Automating this complete end-to-end process dramatically reduces the risk of human error during deployment, significantly accelerates the delivery of valuable new features to end users, and guarantees that every single release passes the same consistent set of quality checks before any user is affected.',

    'Natural language processing is the branch of artificial intelligence research dedicated to enabling computers to understand, interpret, classify, and generate human language in ways that are both contextually accurate and practically useful. Current real-world applications of natural language processing include high-quality machine translation between many language pairs, nuanced sentiment analysis of customer feedback, conversational chatbots and virtual assistants, automatic summarisation of long documents, and intelligent information extraction from unstructured text. The dramatic advances in large transformer-based language models have fundamentally and permanently expanded what natural language processing systems are capable of achieving.',

    'A cryptographic hash function accepts an input of any arbitrary length and deterministically produces a fixed-length output string, called a digest or hash value, that uniquely represents the content of that specific input. The function is mathematically designed to be computationally infeasible to invert, meaning it is practically impossible to reconstruct the original input data given only the hash output. These one-way functions are used extensively to store passwords securely in databases, to verify the integrity and authenticity of downloaded files, and to underpin the digital signature schemes used in secure communications.',

    'Container orchestration platforms, with Kubernetes being by far the most widely adopted example in the industry, automate the complex and previously manual tasks of deploying, scaling, health-checking, and lifecycle-managing containerised application workloads across large clusters of physical or virtual machines. A software container packages a complete application together with all of its specific runtime dependencies into a single standardised and portable unit that runs consistently and predictably on any compliant infrastructure. By abstracting away the underlying heterogeneous hardware, containers greatly simplify the building of portable, reliably reproducible, and horizontally scalable software systems.',

    'The transistor is the fundamental electronic building block from which all modern digital integrated circuits and processors are constructed. A single contemporary high-end processor chip contains many tens of billions of individual transistors, with each one functioning as a microscopic electronic switch that can be toggled rapidly between its on and off states to represent a binary digit. The sustained and remarkable miniaturisation of transistors over successive generations of semiconductor manufacturing, famously described and predicted by Moore\'s Law, has been the primary driving force behind the exponential growth in available computing power over the past six decades.',

    // Level 61–80: Medium technical paragraphs (~70–95 words)
    'Agile software development is an iterative and highly collaborative methodology that explicitly prioritises flexibility, continuous close collaboration between developers and stakeholders, and the frequent delivery of small, working software increments over rigid and detailed upfront planning and exhaustive specification documentation. All development work is divided into short fixed-length cycles called sprints, which typically last between one and four calendar weeks. At the conclusion of each sprint, the team delivers a potentially shippable and demonstrable product increment and then conducts a structured retrospective meeting to honestly reflect on what went well and what specific practices could be improved in the subsequent cycle.',

    'A system log is a precise and ordered chronological record of events, significant actions, errors, warnings, and system state changes that have occurred within a software application or on a hardware device over time. System administrators and software developers rely heavily on comprehensive and well-formatted logs to diagnose operational problems, monitor overall system health and performance trends, detect and investigate potential security incidents, and maintain a clear audit trail of all significant user and system actions. The practical quality and diagnostic usefulness of a log depend critically on the developer\'s careful judgement about which specific events merit recording and how much helpful contextual information should accompany each log entry.',

    'Scalability is the fundamental capacity of a system to continue handling a continuously growing workload, whether measured in terms of the number of simultaneous active users, the volume of data being processed, or the complexity of the operations being performed, without any significant or noticeable degradation in response times, throughput, or overall reliability. Horizontal scalability is achieved by distributing the increasing workload across a larger number of machines working together in parallel. Vertical scalability, by contrast, is achieved by increasing the raw processing power and memory capacity of the existing machines. Well-architected systems are explicitly designed with both dimensions of scalability firmly in mind from the very earliest design decisions.',

    'A compiler is a specialised program that reads source code written by a programmer in a human-readable high-level programming language and translates it completely and automatically into a lower-level machine code representation that the target processor hardware can execute directly and efficiently. The full compilation process involves several well-defined sequential phases, including lexical analysis of the raw source text, syntactic parsing into a structured tree, semantic type-checking, machine-independent optimisation of the intermediate representation, and finally target-specific machine code generation. Compiled languages such as C, C++, and Rust produce programs that execute significantly faster than equivalent programs written in interpreted languages, at the cost of a longer initial compilation step.',

    'Distributed computing systems deliberately spread data storage responsibilities and computational processing tasks across multiple interconnected and cooperating machines rather than consolidating everything on a single powerful central server. This distributed architectural approach provides several critically important operational benefits, including significantly improved fault tolerance because the catastrophic failure of any single node does not bring down the entire system, the ability to scale capacity incrementally by simply adding more nodes, and potentially lower overall infrastructure cost through the use of commodity off-the-shelf server hardware. However, distributed systems necessarily introduce complex new engineering challenges around data consistency across replicas, handling network partitions gracefully, and safely coordinating concurrent update operations.',

    'Feature branching is a widely practised source control workflow strategy in which every piece of new functionality or every bug fix is developed in complete isolation within its own dedicated branch of the version control repository, entirely separate from the shared main production codebase throughout the duration of development. This powerful strategy allows multiple developers or teams to work on completely independent features simultaneously without any risk of their changes interfering with or blocking one another\'s work in progress. When a feature branch is fully complete, has passed all required automated tests, and has received approval through a thorough code review process, it is merged back into the main branch.',

    'The three most fundamental and interconnected metrics for characterising and measuring network performance are latency, available bandwidth, and observed packet loss rate. Latency measures the total time required for a single packet of data to travel from its origin to its intended destination and back again, commonly called the round-trip time. Available bandwidth measures the maximum sustainable volume of data that the connection can transfer per unit of time under ideal conditions. Packet loss quantifies the percentage of transmitted data packets that fail to reach their destination successfully and must be retransmitted. All three metrics interact and have a direct, measurable, and compounding impact on the perceived responsiveness and reliability of any networked application.',

    'An interrupt is a real-time asynchronous signal sent either by a hardware peripheral device or by a software process to the central processor, requesting that the processor immediately and temporarily suspend its current execution context and transfer control to a specialised routine called an interrupt handler or interrupt service routine. The interrupt mechanism allows the processor to respond promptly and efficiently to important time-sensitive external events, such as a key being pressed on the keyboard, a new packet of data arriving at a network interface, or a critical hardware error being detected, without the wasteful inefficiency of continuously polling every connected device in a tight loop to check whether anything needs attention.',

    'Static code analysis tools examine the complete source code of a software project thoroughly and systematically without actually compiling or executing any of the code itself, searching automatically for patterns and constructs that are known from experience to be associated with common bugs, exploitable security vulnerabilities, violations of established coding standards, or unnecessarily poor code quality. These powerful automated tools are capable of identifying many important categories of software defects very early in the development lifecycle, often before the code has even been compiled or run for the first time, which is consistently the least expensive and most efficient possible point in the entire process at which to detect and address quality issues.',

    'A microservices architecture structures a complete software application as a collection of many small, independently developed, independently deployed, and loosely coupled services, where each individual service is responsible for a single well-defined and clearly bounded area of specific business functionality. Each microservice maintains its own separate and independent data store, has its own fully autonomous deployment pipeline, and communicates with other services exclusively through well-defined and stable APIs, typically implemented over HTTP or through an asynchronous message queue. This architectural style significantly improves the ability of large engineering teams to work independently on different parts of the system and to deploy changes to individual services without requiring coordination or synchronisation with other teams working on other services.',

    'Two-factor authentication, universally abbreviated in the industry as 2FA or MFA, substantially and measurably strengthens the security of user account authentication by requiring the user to successfully provide two completely independent pieces of verifiable evidence to confirm their claimed identity before access is granted. The first authentication factor is typically something the user knows by memory, such as their password or a secret PIN. The second factor is typically something the user physically possesses, such as a mobile phone registered to their account that receives a short-lived one-time verification code via SMS or an authenticator app. Even if a sophisticated attacker successfully obtains the user\'s password through a data breach, they remain unable to log in without simultaneous physical access to the user\'s registered second-factor device.',

    'The stack is a fundamental and widely used abstract data structure that operates strictly according to the last-in, first-out access principle, meaning that the most recently added item is always and necessarily the first item to be removed from the collection. Stacks appear and serve critical roles across a remarkably wide range of important computing contexts, including the automatic management of function call frames and local variables in programming language runtime environments, the implementation of unlimited sequential undo and redo functionality in interactive applications and text editors, and the evaluation of mathematical expressions written in postfix or reverse Polish notation. The two defining primitive operations on a stack are push, which adds a new item to the top, and pop, which removes the current top item.',

    'Blockchain technology implements a distributed, append-only, and cryptographically secured chain of data records called blocks, where each individual block contains a validated batch of recent transactions, a precise timestamp, and the cryptographic hash of the immediately preceding block in the chain. This carefully designed chained structure makes it computationally and practically infeasible for any party to alter any historical transaction record without simultaneously invalidating and recomputing every single subsequent block in the entire chain, which would be detectable by all other participants. The complete blockchain ledger is replicated independently across many geographically distributed nodes participating in a peer-to-peer network, ensuring that no single controlling party can unilaterally manipulate or censor the historical transaction record.',

    'Automatic memory garbage collection is a runtime memory management technique in which the execution environment of a managed programming language automatically identifies all regions of dynamically allocated heap memory that have become unreachable from any live reference in the running program and reclaims those memory regions for future reuse. Widely used languages including Java, Python, Go, and C# all incorporate garbage collection as a standard runtime service, relieving application developers of the significant burden and constant risk of manually tracking and freeing every dynamically allocated memory object. While garbage collection eliminates entire well-known categories of dangerous memory-related bugs, it necessarily introduces occasional unpredictable pauses in program execution as the collector runs.',

    'Continuous delivery is a mature software engineering discipline and set of engineering practices in which a development team maintains their shared codebase in a state where any specific version of the software can be safely and reliably released to the live production environment at any moment with minimal manual intervention, review, or preparation required. Successfully achieving a state of continuous delivery requires a very high degree of comprehensive test automation covering all layers of the application, a fully automated and reliable deployment pipeline that handles all deployment steps without manual touch, and a strong team culture of making many small and incremental code changes frequently rather than accumulating large and risky changes over long periods before attempting to release them all at once.',

    'A user story is a concise, deliberately informal, and human-centred description of a single piece of desired software functionality, always written entirely from the subjective perspective of the specific type of end user who will directly benefit from that capability. A well-formed user story consistently follows the widely adopted template: as a particular type of user, I want to be able to perform some specific action or task, so that I can achieve some clearly stated business or personal goal. User stories serve as a central organisational artifact within agile development teams, providing a practical and shared common language for discussions between software engineers and business stakeholders, and ensuring that all development work remains firmly grounded in real, specific, and validated human needs.',

    'Legacy software systems represent one of the most persistent, costly, and technically challenging problems that large and long-established organisations regularly face in managing their technology portfolios. These systems were frequently built many decades ago using programming languages, frameworks, and architectural patterns that have long since become obsolete and are no longer actively maintained or supported. They commonly lack any meaningful automated test coverage, comprehensive technical documentation, and clean separation of concerns in their internal design. Despite these profound technical shortcomings and the considerable difficulties they create for ongoing maintenance and enhancement, legacy systems very often underpin critical revenue-generating or operationally essential business processes that absolutely cannot be casually disrupted.',

    'A zero-day vulnerability is a software security flaw that is currently completely unknown to the software\'s vendor and therefore has no available patch, update, or mitigation at the precise moment it is discovered and first actively exploited by a malicious attacker. The term zero-day specifically refers to the stark fact that the vendor\'s development team has had literally zero days of advance warning to prepare any kind of defensive remedy or workaround. Zero-day vulnerabilities are consequently extremely valuable commodities to sophisticated threat actors, both criminal and state-sponsored, because they can be exploited freely and without effective detection for an indefinite period until the vendor independently discovers the issue or is responsibly notified of it.',

    'Semantic versioning, abbreviated as SemVer, is a widely adopted convention for assigning meaningful version numbers to software releases in a way that communicates clear and unambiguous information about the nature and compatibility implications of each change. A complete semantic version number consists of three non-negative integer components: the major version, incremented only for breaking changes incompatible with the previous public API; the minor version, incremented for new backwards-compatible features; and the patch version, incremented only for backwards-compatible bug fixes. This shared convention helps downstream library consumers manage their dependency upgrades safely and with confidence.',

    'A load balancer is a critical network infrastructure component that intelligently distributes incoming client requests or network traffic across a pool of multiple backend servers or service instances, with the explicit goal of preventing any single server from becoming an overloaded performance bottleneck that degrades the experience of all users. By continuously spreading the processing workload across all available healthy servers, a load balancer simultaneously improves the overall throughput capacity, the fault tolerance, and the reliability and availability of the complete service from the perspective of every user. Load balancers may distribute traffic based on a variety of configurable strategies, including simple sequential round-robin assignment, weighted distribution based on server capacity, least-active-connections routing, and sophisticated content-aware or session-aware routing policies.',

    // Level 81–100: Longer technical paragraphs (~85–110 words)
    'Test-driven development, universally known in the software industry as TDD, is a disciplined software engineering practice in which developers write a precisely specified automated test that captures the desired behaviour of a new feature or function before writing a single line of the actual implementation code that will make that test pass. The development cycle follows a short, tightly bounded, and continuously repeated loop: first, write a failing test that clearly specifies the required behaviour; then, write the absolute minimum amount of implementation code necessary to make that specific test pass without breaking any existing tests; finally, refactor the implementation code to improve its internal design and clarity without changing any externally observable behaviour. This rigorous discipline produces software that is thoroughly and automatically tested by construction.',

    'The operating system kernel is the central and most privileged core of the entire software stack running on a computer system, executing with the highest level of hardware privilege and directly and exclusively managing the most fundamental physical hardware resources including the processor, all installed memory, every storage device, and all input and output peripherals. Standard application software never communicates directly with hardware. Instead, applications invoke well-defined system calls to request services from the kernel, which validates each incoming request against the caller\'s permissions, performs the necessary hardware operations on behalf of the requesting application, and returns the result. The carefully enforced boundary between the privileged kernel space and the restricted user space is a foundational and non-negotiable security property of every modern operating system.',

    'Peer code review is one of the most consistently practised and empirically validated quality assurance and knowledge-sharing techniques in professional software engineering organisations around the world. When an experienced and technically capable developer carefully reads through a colleague\'s recently written code before it is merged into the shared production repository, they frequently identify defects, edge cases, and logical errors that the original author inadvertently overlooked when writing the code, spot stylistic inconsistencies or violations of established conventions that could confuse future readers, and propose alternative and sometimes substantially better approaches to solving the same problem. Regularly conducted code reviews also accelerate the continuous spread of architectural knowledge, domain expertise, and technical best practices across all members of a development team.',

    'The internet protocol suite defines the complete set of layered communication protocols governing how digital data is broken into discrete packets, logically addressed, physically transmitted across multiple network hops, efficiently routed through the global network of interconnected routers, and ultimately reassembled into the original data stream at its destination. The transmission control protocol, operating at the transport layer, provides fully reliable, correctly ordered, and error-checked delivery of byte streams between communicating applications, retransmitting any lost packets transparently. The internet protocol, at the network layer, is responsible for assigning unique logical addresses to all connected devices and routing each packet toward its correct destination.',

    'Designing software applications and digital services for genuine and comprehensive accessibility ensures that they can be used effectively, comfortably, and with full independence by people who have a wide spectrum of abilities, including people living with visual impairments of varying severity, hearing loss, limited fine motor control, and various forms of cognitive difference. Crucially, genuinely accessible design is not merely an ethical obligation or a legal compliance checkbox; it is a reliable indicator of deep engineering quality and thoughtful user-centred design. Systems that are truly accessible to users with disabilities also consistently demonstrate better overall usability for every user, perform more reliably in low-bandwidth or constrained environments, and tend to degrade more gracefully on older or less capable hardware.',

    'A comprehensive continuous integration and continuous deployment pipeline fully automates the complete journey of a developer\'s committed code change, from the precise moment it is pushed to the shared version control repository all the way through to its live deployment in the production environment serving real users. At each carefully defined stage of the automated pipeline, specialised tools perform their assigned tasks including static code analysis for style and security, execution of the complete automated unit and integration test suite, container image building and vulnerability scanning, deployment to a staging environment for smoke testing, and finally a carefully orchestrated staged rollout to the full production fleet. This end-to-end automation compresses the time from code completion to users benefiting from the change from weeks down to hours, while providing multiple safety nets.',

    'Natural language processing has undergone a profound revolution over the past decade, driven by the development of large neural language models based on the transformer architecture and trained at unprecedented scale. These models are pre-trained on enormous corpora of text and code, through which they implicitly learn rich statistical patterns of human language at every level from word morphology to high-level narrative structure. The most capable frontier models, containing hundreds of billions of learned parameters, perform impressively across a wide range of language tasks including translation, summarisation, question answering, and code generation, often matching or exceeding human-level performance on carefully designed benchmarks.',

    'The principle of least privilege is a foundational and widely applied concept in computer and network security that holds that every system component, including every user account, every running process, every service, and every piece of application software, should be granted only the absolute minimum level of access permissions, capabilities, and resource entitlements that are strictly necessary to perform its specific and legitimate intended function, and categorically no more than that minimum. Consistently applying this principle throughout every layer of a system architecture dramatically limits the potential damage that can be caused if any individual component is successfully compromised by an external attacker or begins to behave unexpectedly due to an internal software defect. Minimising granted permissions reduces both the available attack surface and the potential blast radius of any security incident.',

    'Race conditions are a particularly insidious and challenging category of concurrency bug that arises when the observable correctness and output of a multi-threaded or multi-process program depends in an undefined way on the specific interleaving order or relative timing of two or more concurrent execution threads accessing and modifying shared mutable state without adequate mutual exclusion or synchronisation between them. If two threads simultaneously read and then attempt to write the same memory location without holding an appropriate lock, the final value stored will depend on which thread completes its write operation last, and this ordering is fundamentally non-deterministic and may vary unpredictably between different runs. Race conditions are notoriously difficult to reliably reproduce in testing because they may only manifest under very specific timing conditions.',

    'A hardware cache is a small, extremely fast, but relatively expensive memory subsystem that stores copies of recently accessed or statistically frequently needed data items close to the processor so that future requests for the same data can be served from the fast cache memory in a few nanoseconds rather than requiring a slow trip to the much larger but considerably slower main system memory which may take hundreds of nanoseconds. Cache hierarchies exist at multiple distinct levels within a modern computing system, including multiple levels of processor-internal cache, the operating system\'s managed page cache for disk data, the browser\'s local cache of previously fetched web resources, and the distributed in-memory cache clusters used as a critical performance layer in large-scale internet services. The cache hit rate is the primary operational metric for measuring a cache\'s effectiveness.',

    'Pair programming is a structured and intentional collaborative software development practice in which exactly two developers work together at the same physical or virtual workstation at all times during an active coding session. One developer, designated the driver for that period, actively types code and controls the keyboard and mouse, while the other developer, acting as the navigator, continuously observes and critically reviews each line of code as it is written in real time, actively thinking about the overall design, considering edge cases, and identifying potential issues before they become embedded. The driver and navigator roles are regularly and deliberately swapped throughout the session. Research and extensive industry experience consistently indicate that pair programming produces higher quality code with fewer post-release defects than solo programming.',

    'API rate limiting is a fundamental and widely deployed server-side protection technique used by web service providers and platform operators to enforce a maximum limit on the number of API requests that any individual authenticated client application or user account is permitted to submit within a defined rolling time window, such as one thousand requests per hour or ten requests per second. Rate limiting serves multiple important and complementary purposes simultaneously: it protects the shared service infrastructure from being accidentally or maliciously overwhelmed by a single badly behaved or compromised client, it ensures equitable and fair access to shared computational resources across all legitimate users of the service, and it provides a clear and enforceable technical basis for implementing tiered commercial subscription pricing models based on usage levels.',

    'Dependency injection is an important software design pattern and architectural technique that fundamentally inverts the conventional and tightly coupled relationship between a software component and the external services and objects it depends upon to function. Rather than creating and managing its own concrete dependency instances internally within its own code, a component following the dependency injection pattern simply declares what types of dependencies it requires through its public interface, and then receives fully constructed and configured instances of those dependencies from an external source, typically a dedicated dependency injection container or application framework. This deliberate inversion of the control of dependency creation makes individual components dramatically easier to test in complete isolation.',

    'Continuous operational monitoring of running production systems involves the systematic and automated collection, aggregation, storage, and real-time analysis of metrics, structured log events, and distributed execution traces from every component and layer of a deployed software system, with the primary operational goal of detecting anomalous behaviour, identifying emerging performance bottlenecks before they impact users, and automatically alerting the on-call engineering team when any monitored metric crosses a defined threshold indicating a potential problem or degradation. Effective monitoring at scale requires very careful and deliberate engineering decisions about which specific metrics genuinely indicate meaningful system health or user experience degradation, what specific threshold values should trigger pages versus warnings, and how to maintain alerting systems that remain sensitive to real problems without producing so many false positives.',

    'User acceptance testing, commonly abbreviated as UAT, is the final and most strategically important phase of the complete software quality assurance process, during which carefully selected and representative end users of the target user population evaluate and exercise the fully integrated and complete software system in an environment that accurately mirrors the production setting, with the specific goal of confirming definitively that the delivered system genuinely meets all of their real-world practical needs, expectations, and workflow requirements before it is formally signed off and released. Unlike earlier testing phases, which are primarily focused on verifying whether the software behaves correctly from a technical and functional specification perspective, UAT focuses specifically on whether the software is truly fit for its intended business purpose from the lived perspective of the people who will use it.',

    'Input validation is the critical and non-negotiable software security practice of systematically and rigorously examining every single piece of data received by a software application from any external source whatsoever, including direct user input through forms and APIs, data read from files on disk, responses received from third-party external services, and records retrieved from databases, to definitively verify that the incoming data conforms precisely to all expected constraints regarding its data type, format, length, character set, and numeric range before that data is used in any internal processing, stored persistently, or passed to any other system component. Failing to implement thorough and consistent input validation at every system boundary is one of the most common, most dangerous, and most thoroughly documented root causes of critical web application security vulnerabilities.',

    'An event-driven software architecture is a powerful and widely adopted design paradigm in which the overall flow of program execution and inter-component communication is structured around and driven by the asynchronous occurrence of discrete events rather than following a rigid, predetermined, and synchronous sequence of procedure calls and responses. When any component within the system produces a meaningful event, such as a user completing a form submission, a sensor recording a new data point, or an external payment gateway confirming a transaction, that event is published to a central event bus or message broker. Any number of completely independent subscriber components can then receive and process that event asynchronously in their own time. This loose and decoupled coupling between event producers and consumers makes event-driven systems inherently highly scalable.',

    'Technical debt is a useful and widely used metaphor in software engineering for the accumulated hidden cost of all the deliberate design shortcuts, expedient compromises, quick fixes, and deferred refactoring decisions that developers make during the software development process in order to deliver functionality more quickly in the short term at the expense of long-term code quality, maintainability, and architectural soundness. Like financial debt, technical debt compounds over time and accrues interest in the increasingly concrete and painful form of progressively slower and riskier future development, more frequent and harder-to-diagnose defects, and greater difficulty and expense in onboarding new team members to an unfamiliar and poorly structured codebase. Small, consciously incurred, and carefully tracked amounts of technical debt can sometimes be a reasonable strategic trade-off.',

    'Infrastructure as code, commonly abbreviated as IaC, is the increasingly standard engineering practice of defining, provisioning, configuring, and managing all computing infrastructure resources, including virtual machines, networks, load balancers, databases, and storage systems, using human-readable and machine-executable declarative configuration files or imperative scripts stored in version control, rather than through manual and error-prone point-and-click configuration in web-based management consoles or interactive command-line sessions. By treating infrastructure configuration with exactly the same disciplined engineering rigour as application source code, development and operations teams can apply the full power of version control history, systematic code review, automated testing, and continuous integration pipelines to every infrastructure change, dramatically improving consistency, reproducibility, and the speed and safety of infrastructure modifications.',

    'You have now completed every one of the one hundred demanding levels of TypingQuest Master difficulty, reaching the very highest pinnacle of skill that this course requires. Throughout this journey, you have typed complex technical sentences about algorithms, security, and distributed systems, and extended paragraphs that challenged both the fluency of your fingers and the sustained focus of your mind under constant time pressure. Your typing speed, accuracy at pace, and ability to maintain concentration across long and difficult passages have all grown substantially. You have demonstrated a genuine level of typing mastery that very few people ever achieve. Carry this hard-won skill forward with pride into every area of your academic study and professional career.',
  ];
}