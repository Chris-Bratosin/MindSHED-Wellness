import 'package:flutter/material.dart';
import 'activities_screen.dart'; // for Back -> Activities

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ---------- palette ----------
  static const cream = Color(0xFFFFF9DA);
  static const mint = Color(0xFFB6FFB1);
  static const panel = Color(0xFFFFFFFF);
  static const header = Color(0xFFF1EEDB);

  // ---------- quizzes & questions (unchanged) ----------
  final Map<String, List<Map<String, dynamic>>> quizData = {
    "Learn about your stress": [
      {
        "question": "What is a common sign of stress?",
        "options": ["Headaches", "Hunger", "Sleepiness"],
        "answer": "Headaches"
      },
      {
        "question": "How can you reduce stress?",
        "options": ["Deep breathing", "Skipping meals", "Watching TV"],
        "answer": "Deep breathing"
      },
      {
        "question": "What hormone is released during stress?",
        "options": ["Cortisol", "Insulin", "Serotonin"],
        "answer": "Cortisol"
      },
    ],
    "How does your sleep affect you?": [
      {
        "question": "Why is getting enough sleep important?",
        "options": [
          "It helps your mind and body recharge",
          "Because it is fun to stay in bed all day",
          "So you can skip meals and still have energy"
        ],
        "answer": "It helps your mind and body recharge"
      },
      {
        "question": "What is the recommended amount of sleep for adults?",
        "options": ["7-9 hours", "3-5 hours", "10-12 hours"],
        "answer": "7-9 hours"
      },
      {
        "question": "What happens if you don't get enough sleep?",
        "options": [
          "Memory issues",
          "Increased energy",
          "Better concentration"
        ],
        "answer": "Memory issues"
      },
    ],
    "The importance of a balanced diet": [
      {
        "question": "What does a balanced diet include?",
        "options": ["All food groups", "Only protein", "Only fruits"],
        "answer": "All food groups"
      },
      {
        "question": "Why is water important?",
        "options": ["Hydration", "Color", "Flavour"],
        "answer": "Hydration"
      },
      {
        "question": "What nutrient gives energy?",
        "options": ["Carbohydrates", "Vitamins", "Fiber"],
        "answer": "Carbohydrates"
      },
    ],
    "Exercise and fitness habits": [
      {
        "question": "How often should you exercise?",
        "options": ["3-5 times a week", "Once a month", "Every hour"],
        "answer": "3-5 times a week"
      },
      {
        "question": "What type of exercise improves heart health?",
        "options": ["Cardio", "Stretching", "Sleep"],
        "answer": "Cardio"
      },
      {
        "question": "What does strength training build?",
        "options": ["Muscle", "Fat", "Sweat"],
        "answer": "Muscle"
      },
    ],
    "Digital wellbeing": [
      {
        "question": "Too much screen time affects?",
        "options": ["Sleep", "Vision", "Both"],
        "answer": "Both"
      },
      {
        "question": "What helps digital wellness?",
        "options": ["Taking breaks", "Binge watching", "Ignoring messages"],
        "answer": "Taking breaks"
      },
      {
        "question": "What can reduce blue light exposure?",
        "options": ["Night mode", "More screen time", "Louder sound"],
        "answer": "Night mode"
      },
    ],
    "Hydration awareness": [
      {
        "question": "How much water should adults drink daily?",
        "options": ["2-3 liters", "1 cup", "10 liters"],
        "answer": "2-3 liters"
      },
      {
        "question": "What are signs of dehydration?",
        "options": ["Dry mouth", "Energy boost", "Clear urine"],
        "answer": "Dry mouth"
      },
      {
        "question": "Best drink for hydration?",
        "options": ["Water", "Coffee", "Soda"],
        "answer": "Water"
      },
    ],
    "Mental health check": [
      {
        "question": "Which activity boosts mental health?",
        "options": ["Meditation", "Stressing", "Skipping sleep"],
        "answer": "Meditation"
      },
      {
        "question": "Talking to friends helps?",
        "options": ["Yes", "No", "Never"],
        "answer": "Yes"
      },
      {
        "question": "Which is a sign of burnout?",
        "options": ["Exhaustion", "Joy", "Excitement"],
        "answer": "Exhaustion"
      },
    ],
  };

  // ---------- state ----------
  String? selectedTopic;
  List<Map<String, dynamic>> selectedQuestions = [];
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  int score = 0;
  bool quizCompleted = false;

  // ---------- actions ----------
  void startQuiz(String topic) {
    setState(() {
      selectedTopic = topic;
      selectedQuestions = List<Map<String, dynamic>>.from(quizData[topic]!);
      selectedQuestions.shuffle();
      selectedQuestions = selectedQuestions.take(5).toList();
      currentQuestionIndex = 0;
      selectedAnswer = null;
      score = 0;
      quizCompleted = false;
    });
  }

  void _nextQuestion() {
    if (selectedAnswer ==
        selectedQuestions[currentQuestionIndex]['answer']) {
      score++;
    }
    if (currentQuestionIndex < selectedQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    } else {
      setState(() => quizCompleted = true);
    }
  }

  void _restartToMenu() {
    setState(() {
      selectedTopic = null; // back to quiz list
      quizCompleted = false;
      selectedAnswer = null;
      currentQuestionIndex = 0;
      score = 0;
    });
  }

  void _backToActivities() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _pillHeader('Quizzes'),
            const SizedBox(height: 14),

            // ====== QUIZ LIST ======
            if (selectedTopic == null && !quizCompleted) ...[
              _quizListCard(),
              const SizedBox(height: 12),
              _mintButton('Back', _backToActivities), // To Activities
            ]

            // ====== IN-QUIZ ======
            else if (!quizCompleted) ...[
              _topicHeader(selectedTopic!),
              const SizedBox(height: 12),
              _questionBubble(
                counter:
                '${currentQuestionIndex + 1}/${selectedQuestions.length}',
                question: selectedQuestions[currentQuestionIndex]['question'],
                options: List<String>.from(
                  selectedQuestions[currentQuestionIndex]['options'],
                ),
              ),
            ]

            // ====== FINISHED ======
            else ...[
                _resultBubble(score, selectedQuestions.length),
                const SizedBox(height: 16),
                _mintButton('Finish', _restartToMenu), // back to list
              ],
          ],
        ),
      ),
    );
  }

  // ---------- pieces ----------
  Widget _pillHeader(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 22,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _quizListCard() {
    final font = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          const Text(
            '“Discover more about\nyour wellness”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...quizData.keys.map(
                (title) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _quizChip(
                title,
                onTap: () => startQuiz(title),
                fontSize: font,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizChip(String text,
      {required VoidCallback onTap, required double fontSize}) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: header,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'HappyMonkey',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _questionBubble({
    required String counter,
    required String question,
    required List<String> options,
  }) {
    final font = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16.0;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        // Bubble body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // question line
              Center(
                child: Text(
                  question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'HappyMonkey',
                    fontSize: font,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // options
              ...options.map(
                    (o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    selectedAnswer == o
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Colors.black87,
                  ),
                  title: Text(
                    o,
                    style: TextStyle(
                      fontFamily: 'HappyMonkey',
                      fontSize: font,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () => setState(() => selectedAnswer = o),
                ),
              ),

              if (selectedAnswer != null) ...[
                const SizedBox(height: 10),
                _mintButton('Next', _nextQuestion),
              ],
            ],
          ),
        ),

        // small counter pill (like mock “1/5”)
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              counter,
              style: const TextStyle(
                fontFamily: 'HappyMonkey',
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ),

        // little tail pointer
        Positioned(
          bottom: -10,
          left: 28,
          child: Transform.rotate(
            angle: 3.14159 / 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: panel,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultBubble(int score, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quiz Completed!',
            style: TextStyle(
              fontFamily: 'HappyMonkey',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your final score is: $score / $total',
            style: const TextStyle(
              fontFamily: 'HappyMonkey',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- small helper: Positional arguments ----------
  Widget _mintButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
