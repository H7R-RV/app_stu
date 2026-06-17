import '../models/question.dart';

/// Builds a large, ready-to-use question bank spanning several subjects,
/// grades and every supported [QuestionType]. Combines hand-authored items
/// with generated drill questions so the app ships with hundreds of entries.
List<Question> buildQuestionBank() {
  final List<Question> list = [];
  int counter = 0;
  String nextId() => 'b${counter++}';

  void add(
    QuestionType type,
    String subject,
    String grade,
    String text, {
    List<String> options = const [],
    int? correctOption,
    String answer = '',
    List<String> wordBank = const [],
    List<MatchPair>? pairs,
    bool? isTrue,
    String? emoji,
    int marks = 1,
  }) {
    list.add(Question(
      id: nextId(),
      type: type,
      subject: subject,
      grade: grade,
      text: text,
      options: options,
      correctOption: correctOption,
      answer: answer,
      wordBank: wordBank,
      pairs: pairs,
      isTrue: isTrue,
      emoji: emoji,
      marks: marks,
    ));
  }

  // ===================== MATHEMATICS =====================
  const math = 'Mathematics';

  // Generated multiplication MCQs (drill bulk).
  for (var a = 2; a <= 9; a++) {
    for (var b = 3; b <= 9; b += 3) {
      final correct = a * b;
      final opts = <int>{correct, correct + 1, correct - 2, a + b}.toList();
      opts.shuffle();
      add(
        QuestionType.mcq,
        math,
        'Grade 3',
        'What is $a × $b?',
        options: opts.map((e) => e.toString()).toList(),
        correctOption: opts.indexOf(correct),
      );
    }
  }

  // Generated addition fill-in-the-blanks.
  for (var a = 11; a <= 19; a += 2) {
    final b = a + 7;
    add(
      QuestionType.fillBlank,
      math,
      'Grade 2',
      '$a + $b = ____',
      answer: '${a + b}',
    );
  }

  add(QuestionType.mcq, math, 'Grade 5', 'Which of these is a prime number?',
      options: ['9', '15', '17', '21'], correctOption: 2);
  add(QuestionType.mcq, math, 'Grade 5', 'The value of π (pi) is approximately:',
      options: ['1.41', '2.72', '3.14', '9.81'], correctOption: 2);
  add(QuestionType.mcq, math, 'Grade 4', 'How many sides does a hexagon have?',
      options: ['5', '6', '7', '8'], correctOption: 1);
  add(QuestionType.mcq, math, 'Grade 4', 'What is the LCM of 4 and 6?',
      options: ['8', '12', '18', '24'], correctOption: 1);
  add(QuestionType.mcq, math, 'Grade 6', '½ + ¼ equals:',
      options: ['⅓', '¾', '⅔', '1'], correctOption: 1);

  add(QuestionType.fillBlank, math, 'Grade 4',
      'A triangle has ____ angles that add up to ____ degrees.',
      answer: 'three, 180');
  add(QuestionType.fillBlank, math, 'Grade 5',
      'The perimeter of a square with side 6 cm is ____ cm.',
      answer: '24');

  add(QuestionType.shortQuestion, math, 'Grade 5',
      'Define a factor and give one example.',
      answer: 'A factor divides a number exactly, e.g. 3 is a factor of 12.',
      marks: 2);
  add(QuestionType.shortQuestion, math, 'Grade 6',
      'Write the formula for the area of a circle.',
      answer: 'Area = π r²', marks: 2);
  add(QuestionType.longQuestion, math, 'Grade 6',
      'A rectangular garden is 12 m long and 8 m wide. Find its perimeter and area, showing all steps.',
      answer: 'Perimeter = 2(12+8) = 40 m; Area = 12×8 = 96 m².', marks: 5);
  add(QuestionType.longQuestion, math, 'Grade 7',
      'Solve the equation 3x + 7 = 22 and verify your answer.',
      answer: 'x = 5; check 3(5)+7 = 22.', marks: 5);

  add(QuestionType.trueFalse, math, 'Grade 4',
      'Zero is an even number.', isTrue: true);
  add(QuestionType.trueFalse, math, 'Grade 4',
      'A right angle measures 100 degrees.', isTrue: false);
  add(QuestionType.trueFalse, math, 'Grade 5',
      'Every square is a rectangle.', isTrue: true);

  add(
    QuestionType.columnMatch,
    math,
    'Grade 5',
    'Match the shape with its number of sides.',
    pairs: [
      MatchPair(left: 'Triangle', right: '3'),
      MatchPair(left: 'Square', right: '4'),
      MatchPair(left: 'Pentagon', right: '5'),
      MatchPair(left: 'Hexagon', right: '6'),
    ],
    marks: 4,
  );
  add(
    QuestionType.fillBlankWithOptions,
    math,
    'Grade 5',
    'Complete using the word bank: A polygon with three sides is a ____. '
        'A polygon with four equal sides is a ____. The distance around a '
        'shape is its ____.',
    wordBank: ['triangle', 'square', 'perimeter', 'radius'],
    answer: 'triangle, square, perimeter',
    marks: 3,
  );

  // ===================== SCIENCE =====================
  const science = 'Science';
  add(QuestionType.mcq, science, 'Grade 5', 'Which gas do plants absorb during photosynthesis?',
      options: ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'],
      correctOption: 2);
  add(QuestionType.mcq, science, 'Grade 5', 'The powerhouse of the cell is the:',
      options: ['Nucleus', 'Mitochondria', 'Ribosome', 'Vacuole'],
      correctOption: 1);
  add(QuestionType.mcq, science, 'Grade 6', 'Which planet is known as the Red Planet?',
      options: ['Venus', 'Mars', 'Jupiter', 'Saturn'], correctOption: 1);
  add(QuestionType.mcq, science, 'Grade 4', 'Water boils at what temperature (°C)?',
      options: ['50', '90', '100', '120'], correctOption: 2);
  add(QuestionType.mcq, science, 'Grade 6', 'Which of the following is a renewable source of energy?',
      options: ['Coal', 'Petrol', 'Solar', 'Natural gas'], correctOption: 2);

  add(QuestionType.fillBlank, science, 'Grade 5',
      'Humans breathe in oxygen and breathe out ____.',
      answer: 'carbon dioxide');
  add(QuestionType.fillBlank, science, 'Grade 6',
      'The process by which plants make food is called ____.',
      answer: 'photosynthesis');
  add(QuestionType.fillBlankWithOptions, science, 'Grade 5',
      'Fill the blanks using the word bank: The ____ pumps blood, the ____ '
          'helps us breathe, and the ____ controls the body.',
      wordBank: ['heart', 'lungs', 'brain', 'kidney'],
      answer: 'heart, lungs, brain', marks: 3);

  add(QuestionType.shortQuestion, science, 'Grade 5',
      'Name three states of matter.',
      answer: 'Solid, liquid, gas.', marks: 3);
  add(QuestionType.shortQuestion, science, 'Grade 6',
      'What is evaporation?',
      answer: 'Changing of a liquid into vapour on heating.', marks: 2);
  add(QuestionType.longQuestion, science, 'Grade 6',
      'Describe the water cycle with the help of its main stages.',
      answer: 'Evaporation, condensation, precipitation, collection.',
      marks: 5);
  add(QuestionType.longQuestion, science, 'Grade 7',
      'Explain the difference between conductors and insulators with two examples each.',
      answer: 'Conductors allow current (copper, iron); insulators do not (rubber, plastic).',
      marks: 5);

  add(QuestionType.trueFalse, science, 'Grade 4',
      'The Sun is a star.', isTrue: true);
  add(QuestionType.trueFalse, science, 'Grade 5',
      'Sound travels faster than light.', isTrue: false);
  add(QuestionType.trueFalse, science, 'Grade 5',
      'Spiders are insects.', isTrue: false);

  add(
    QuestionType.columnMatch,
    science,
    'Grade 6',
    'Match the organ with its function.',
    pairs: [
      MatchPair(left: 'Heart', right: 'Pumps blood'),
      MatchPair(left: 'Lungs', right: 'Exchange gases'),
      MatchPair(left: 'Stomach', right: 'Digests food'),
      MatchPair(left: 'Kidney', right: 'Filters waste'),
    ],
    marks: 4,
  );

  // ===================== ENGLISH =====================
  const english = 'English';
  add(QuestionType.mcq, english, 'Grade 4', 'Choose the correct article: ___ apple a day keeps the doctor away.',
      options: ['A', 'An', 'The', 'No article'], correctOption: 1);
  add(QuestionType.mcq, english, 'Grade 5', 'Which word is a noun?',
      options: ['Quickly', 'Beautiful', 'Garden', 'Run'], correctOption: 2);
  add(QuestionType.mcq, english, 'Grade 5', 'The plural of "child" is:',
      options: ['childs', 'childes', 'children', 'childrens'],
      correctOption: 2);
  add(QuestionType.mcq, english, 'Grade 6', 'Select the correctly spelled word:',
      options: ['Recieve', 'Receive', 'Receeve', 'Receve'], correctOption: 1);

  add(QuestionType.fillBlank, english, 'Grade 4',
      'She ____ (go) to school every day.',
      answer: 'goes');
  add(QuestionType.fillBlankWithOptions, english, 'Grade 5',
      'Complete the sentences with the word bank: The opposite of hot is ____. '
          'The opposite of happy is ____. The opposite of fast is ____.',
      wordBank: ['cold', 'sad', 'slow', 'tall'],
      answer: 'cold, sad, slow', marks: 3);

  add(QuestionType.shortQuestion, english, 'Grade 5',
      'Write the past tense of: go, eat, run.',
      answer: 'went, ate, ran.', marks: 3);
  add(QuestionType.shortQuestion, english, 'Grade 6',
      'Use the word "honest" in a sentence.',
      answer: 'Open answer.', marks: 2);
  add(QuestionType.longQuestion, english, 'Grade 6',
      'Write a paragraph of about 100 words on "My Best Friend".',
      answer: 'Open-ended composition.', marks: 8);
  add(QuestionType.longQuestion, english, 'Grade 7',
      'Write a letter to your friend inviting him/her to your birthday party.',
      answer: 'Open-ended letter writing.', marks: 10);

  add(QuestionType.trueFalse, english, 'Grade 4',
      '"Happy" is an adjective.', isTrue: true);
  add(QuestionType.trueFalse, english, 'Grade 5',
      'A sentence always ends with a comma.', isTrue: false);

  add(
    QuestionType.columnMatch,
    english,
    'Grade 5',
    'Match the word with its synonym.',
    pairs: [
      MatchPair(left: 'Big', right: 'Large'),
      MatchPair(left: 'Happy', right: 'Glad'),
      MatchPair(left: 'Fast', right: 'Quick'),
      MatchPair(left: 'Begin', right: 'Start'),
    ],
    marks: 4,
  );
  add(
    QuestionType.columnMatch,
    english,
    'Grade 6',
    'Match the word with its antonym.',
    pairs: [
      MatchPair(left: 'Up', right: 'Down'),
      MatchPair(left: 'Open', right: 'Close'),
      MatchPair(left: 'Day', right: 'Night'),
      MatchPair(left: 'Empty', right: 'Full'),
    ],
    marks: 4,
  );

  // ===================== GENERAL KNOWLEDGE =====================
  const gk = 'General Knowledge';
  add(QuestionType.mcq, gk, 'Grade 5', 'How many continents are there on Earth?',
      options: ['5', '6', '7', '8'], correctOption: 2);
  add(QuestionType.mcq, gk, 'Grade 5', 'Which is the largest ocean?',
      options: ['Atlantic', 'Indian', 'Arctic', 'Pacific'], correctOption: 3);
  add(QuestionType.mcq, gk, 'Grade 6', 'The Great Wall is located in:',
      options: ['India', 'China', 'Japan', 'Egypt'], correctOption: 1);
  add(QuestionType.shortQuestion, gk, 'Grade 5',
      'Name any two sources of light.',
      answer: 'Sun and bulb (any valid).', marks: 2);
  add(QuestionType.trueFalse, gk, 'Grade 4',
      'The Earth revolves around the Sun.', isTrue: true);
  add(QuestionType.trueFalse, gk, 'Grade 5',
      'A camel is found in the polar region.', isTrue: false);

  // ===================== COMPUTER =====================
  const computer = 'Computer';
  add(QuestionType.mcq, computer, 'Grade 6', 'CPU stands for:',
      options: [
        'Central Process Unit',
        'Central Processing Unit',
        'Computer Personal Unit',
        'Central Print Unit'
      ],
      correctOption: 1);
  add(QuestionType.mcq, computer, 'Grade 5', 'Which device is used to type?',
      options: ['Mouse', 'Keyboard', 'Monitor', 'Speaker'], correctOption: 1);
  add(QuestionType.fillBlank, computer, 'Grade 6',
      'The brain of the computer is the ____.',
      answer: 'CPU');
  add(QuestionType.shortQuestion, computer, 'Grade 6',
      'Differentiate between hardware and software.',
      answer: 'Hardware is physical; software is programs.', marks: 2);
  add(QuestionType.trueFalse, computer, 'Grade 5',
      'A monitor is an output device.', isTrue: true);
  add(
    QuestionType.columnMatch,
    computer,
    'Grade 6',
    'Match the device with its type.',
    pairs: [
      MatchPair(left: 'Keyboard', right: 'Input'),
      MatchPair(left: 'Printer', right: 'Output'),
      MatchPair(left: 'Scanner', right: 'Input'),
      MatchPair(left: 'Speaker', right: 'Output'),
    ],
    marks: 4,
  );

  // ===================== PRE-SCHOOL (picture based) =====================
  const pre = 'Pre-School';
  add(QuestionType.preschoolImage, pre, 'Nursery',
      'Count the apples and write the number in the box.',
      emoji: '🍎🍎🍎', answer: '3');
  add(QuestionType.preschoolImage, pre, 'Nursery',
      'How many stars do you see?',
      emoji: '⭐⭐⭐⭐⭐', answer: '5');
  add(QuestionType.preschoolImage, pre, 'Nursery',
      'Circle the picture that shows a fruit.',
      emoji: '🍌  🚗  🐶', answer: 'Banana');
  add(QuestionType.preschoolImage, pre, 'KG',
      'Colour the two balloons.',
      emoji: '🎈🎈', answer: '');
  add(QuestionType.preschoolImage, pre, 'KG',
      'Match the animal to its sound (say it aloud).',
      emoji: '🐄  🐱  🐶', answer: 'Moo / Meow / Woof');
  add(QuestionType.preschoolImage, pre, 'Nursery',
      'Count the fingers and tick the right number.',
      emoji: '✋', options: ['3', '4', '5'], correctOption: 2);

  add(QuestionType.fillBlank, pre, 'KG',
      'A, B, ____, D, E. Write the missing letter.',
      answer: 'C');
  add(QuestionType.fillBlank, pre, 'KG',
      '1, 2, 3, ____, 5. Write the missing number.',
      answer: '4');
  add(QuestionType.fillBlankWithOptions, pre, 'KG',
      'Choose from the word bank: A cat says ____. A dog says ____. A cow says ____.',
      wordBank: ['meow', 'woof', 'moo'],
      answer: 'meow, woof, moo', marks: 3);
  add(QuestionType.trueFalse, pre, 'KG',
      'The sky is green.', isTrue: false);
  add(QuestionType.trueFalse, pre, 'KG',
      'A ball is round.', isTrue: true);
  add(
    QuestionType.columnMatch,
    pre,
    'KG',
    'Match the animal with its baby.',
    pairs: [
      MatchPair(left: 'Cat', right: 'Kitten'),
      MatchPair(left: 'Dog', right: 'Puppy'),
      MatchPair(left: 'Cow', right: 'Calf'),
    ],
    marks: 3,
  );

  // A few more MCQs to broaden the bank.
  add(QuestionType.mcq, gk, 'Grade 6', 'Which is the fastest land animal?',
      options: ['Lion', 'Cheetah', 'Horse', 'Tiger'], correctOption: 1);
  add(QuestionType.mcq, science, 'Grade 7', 'Force is measured in:',
      options: ['Watt', 'Joule', 'Newton', 'Pascal'], correctOption: 2);
  add(QuestionType.mcq, math, 'Grade 7', 'The square root of 144 is:',
      options: ['11', '12', '13', '14'], correctOption: 1);

  return list;
}
