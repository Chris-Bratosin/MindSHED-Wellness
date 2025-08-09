import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<String, List<Map<String, dynamic>>> quizData = {
    "Learn about your stress": [
      {"question": "What is a common sign of stress?", "options": ["Headaches", "Hunger", "Sleepiness"], "answer": "Headaches"},
      {"question": "How can you reduce stress?", "options": ["Deep breathing", "Skipping meals", "Watching TV"], "answer": "Deep breathing"},
      {"question": "What hormone is released during stress?", "options": ["Cortisol", "Insulin", "Serotonin"], "answer": "Cortisol"},
    ],
    "How does your sleep affect you?": [
      {"question": "Why is getting enough sleep important?", "options": ["It helps your mind and body recharge", "Because it is fun to stay in bed all day", "So you can skip meals and still have energy"], "answer": "It helps your mind and body recharge"},
      {"question": "What is the recommended amount of sleep for adults?", "options": ["7-9 hours", "3-5 hours", "10-12 hours"], "answer": "7-9 hours"},
      {"question": "What happens if you don't get enough sleep?", "options": ["Memory issues", "Increased energy", "Better concentration"], "answer": "Memory issues"},
    ],
    "The importance of a balanced diet": [
      {"question": "What does a balanced diet include?", "options": ["All food groups", "Only protein", "Only fruits"], "answer": "All food groups"},
      {"question": "Why is water important?", "options": ["Hydration", "Color", "Flavour"], "answer": "Hydration"},
      {"question": "What nutrient gives energy?", "options": ["Carbohydrates", "Vitamins", "Fiber"], "answer": "Carbohydrates"},
    ],
    "Exercise and fitness habits": [
      {"question": "How often should you exercise?", "options": ["3-5 times a week", "Once a month", "Every hour"], "answer": "3-5 times a week"},
      {"question": "What type of exercise improves heart health?", "options": ["Cardio", "Stretching", "Sleep"], "answer": "Cardio"},
      {"question": "What does strength training build?", "options": ["Muscle", "Fat", "Sweat"], "answer": "Muscle"},
    ],
    "Digital wellbeing": [
      {"question": "Too much screen time affects?", "options": ["Sleep", "Vision", "Both"], "answer": "Both"},
      {"question": "What helps digital wellness?", "options": ["Taking breaks", "Binge watching", "Ignoring messages"], "answer": "Taking breaks"},
      {"question": "What can reduce blue light exposure?", "options": ["Night mode", "More screen time", "Louder sound"], "answer": "Night mode"},
    ],
    "Hydration awareness": [
      {"question": "How much water should adults drink daily?", "options": ["2-3 liters", "1 cup", "10 liters"], "answer": "2-3 liters"},
      {"question": "What are signs of dehydration?", "options": ["Dry mouth", "Energy boost", "Clear urine"], "answer": "Dry mouth"},
      {"question": "Best drink for hydration?", "options": ["Water", "Coffee", "Soda"], "answer": "Water"},
    ],
    "Mental health check": [
      {"question": "Which activity boosts mental health?", "options": ["Meditation", "Stressing", "Skipping sleep"], "answer": "Meditation"},
      {"question": "Talking to friends helps?", "options": ["Yes", "No", "Never"], "answer": "Yes"},
      {"question": "Which is a sign of burnout?", "options": ["Exhaustion", "Joy", "Excitement"], "answer": "Exhaustion"},
    ],
  };

  String? selectedTopic;
  List<Map<String, dynamic>> selectedQuestions = [];
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  int score = 0;
  bool quizCompleted = false;

  void startQuiz(String topic) {
    setState(() {
      selectedTopic = topic;
      selectedQuestions = List.from(quizData[topic]!);
      selectedQuestions.shuffle();
      selectedQuestions = selectedQuestions.take(5).toList();
      currentQuestionIndex = 0;
      selectedAnswer = null;
      score = 0;
      quizCompleted = false;
    });
  }

  void nextQuestion() {
    if (selectedAnswer == selectedQuestions[currentQuestionIndex]['answer']) {
      score++;
    }

    if (currentQuestionIndex < selectedQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    } else {
      setState(() {
        quizCompleted = true;
      });
    }
  }

  void restartQuiz() {
    setState(() {
      selectedTopic = null;
      quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selectedTopic == null && !quizCompleted) ...[
                const SizedBox(height: 10),
                Text(
                  "Discover more about\nyour wellness",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontFamily: 'HappyMonkey',
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                ...quizData.keys.map(
                      (quiz) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF40D404)
                            : Colors.green.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        elevation: 2,
                      ),
                      onPressed: () => startQuiz(quiz),
                      child: Text(
                        quiz,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontFamily: 'HappyMonkey',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (!quizCompleted) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF40D404)
                        : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      "${currentQuestionIndex + 1}/${selectedQuestions.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'HappyMonkey',
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black),
                    boxShadow: isDark
                        ? []
                        : [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedQuestions[currentQuestionIndex]['question'],
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'HappyMonkey',
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...selectedQuestions[currentQuestionIndex]['options']
                          .map<Widget>((option) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selectedAnswer == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        title: Text(
                          option,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontFamily: 'HappyMonkey',
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        onTap: () => setState(() {
                          selectedAnswer = option;
                        }),
                      )),
                      if (selectedAnswer != null)
                        Center(
                          child: ElevatedButton(
                            onPressed: nextQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              side: const BorderSide(color: Colors.black, width: 2),
                            ),
                            child: Text(
                              "Next",
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 40),
                Text(
                  "Quiz Completed!",
                  style: TextStyle(
                    fontSize: fontSize + 4,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'HappyMonkey',
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your final score is: $score / ${selectedQuestions.length}",
                  style: TextStyle(
                    fontSize: fontSize,
                    fontFamily: 'HappyMonkey',
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    "Finish",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'HappyMonkey',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}