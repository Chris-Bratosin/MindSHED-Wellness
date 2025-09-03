import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'activities_screen.dart'; // for back-button fallback

// =====================================================
// Journal Create Screen (Screen 1)
// =====================================================
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryNameController = TextEditingController();
  final TextEditingController _entryTextController = TextEditingController();

  // local state
  List<Map<String, String>> _entries = []; // name, text, date, mood(1-5)
  int _mood = 0;
  String? _userId;

  // palette
  static const cream = Color(0xFFFFF9DA);
  static const mint  = Color(0xFFB6FFB1);
  static const sage  = Color(0xFFD9E3C4);
  //static const rose  = Color(0xFFFF8A7D);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sessionBox = await Hive.openBox('session');
    final id = sessionBox.get('loggedInUser') as String?;
    _userId = id;
    if (id != null) await _loadFromHive(id);
  }

  String _today() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    return '$dd/$mm/${now.year}';
  }

  Future<void> _loadFromHive(String userId) async {
    final box = await Hive.openBox('journalBox');
    final saved = box.get('journal_$userId');
    setState(() {
      _entries = saved == null
          ? []
          : List<Map<String, String>>.from(
          (saved as List).map((e) => Map<String, String>.from(e as Map)));
    });
  }

  Future<void> _saveToHive() async {
    if (_userId == null) return;
    final box = await Hive.openBox('journalBox');
    await box.put('journal_$_userId', _entries);
  }

  // ---------- actions ----------
  Future<void> _confirmEntry() async {
    final name = _entryNameController.text.trim();
    final text = _entryTextController.text.trim();
    if (_userId == null || name.isEmpty || text.isEmpty) return;

    setState(() {
      _entries.insert(0, {
        'name': name,
        'text': text,
        'date': _today(),
        'mood': _mood.toString(),
      });
      _entryNameController.clear();
      _entryTextController.clear();
      _mood = 0;
    });
    await _saveToHive();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry saved')),
    );
  }

  void _goBackToActivities() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Fallback if this screen wasn’t pushed (just in case)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
      );
    }
  }

  Future<void> _openEntriesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntriesScreen(userId: _userId),
      ),
    );
    // refresh after returning
    if (_userId != null) await _loadFromHive(_userId!);
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
            _pillHeader('My Journal'),
            const SizedBox(height: 16),
            _createEntryCard(),
            const SizedBox(height: 12),
            _backButton(),
          ],
        ),
      ),
    );
  }

  Widget _pillHeader(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Text(title, style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 22, color: Colors.black)),
      ),
    );
  }

  Widget _cardShell({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: sage,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Center(
              child: Text(title, style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 18, color: Colors.black)),
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _createEntryCard() {
    return _cardShell(
      title: 'Create new entry',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Entry name (single line)
          _inputBox(
            controller: _entryNameController,
            hint: 'Entry Name',
            minLines: 1,
            maxLines: 1,
          ),
          const SizedBox(height: 12),

          // Mood stars
          Container(
            decoration: _outlinedDecoration(),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              children: [
                const Text('Rate current mood:',
                    style: TextStyle(fontFamily: 'HappyMonkey', fontSize: 16, color: Colors.black)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    final filled = _mood >= idx;
                    return GestureDetector(
                      onTap: () => setState(() => _mood = idx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          filled ? Icons.star : Icons.star_border,
                          size: 28,
                          color: Colors.amber[600],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Entry text (multiline textarea)
          _inputBox(
            controller: _entryTextController,
            hint: 'Enter Text',
            minLines: 8,
            maxLines: null, // grow
            multiline: true,
          ),
          const SizedBox(height: 14),

          // Confirm entry
          _mintButton('Confirm entry', _confirmEntry),
          const SizedBox(height: 10),

          // View entries
          _mintButton('View Entries', _openEntriesScreen),
        ],
      ),
    );
  }

  // ---------- inputs ----------
  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int? maxLines,
    bool multiline = false,
  }) {
    return Container(
      decoration: _outlinedDecoration(),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,            // <-- typed text is black
          fontFamily: 'HappyMonkey',
        ),
        cursorColor: Colors.black,
        textAlignVertical:
        multiline ? TextAlignVertical.top : TextAlignVertical.center, // <- hint aligns like text
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.black54,     // <- dimmed hint
            fontSize: 16,
            fontFamily: 'HappyMonkey',
          ),
        ),
      ),
    );
  }

  BoxDecoration _outlinedDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black, width: 2),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
  );

  Widget _mintButton(String label, VoidCallback onTap) {
    return Center(
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _goBackToActivities,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const Text('Back', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryNameController.dispose();
    _entryTextController.dispose();
    super.dispose();
  }
}

// =====================================================
// Journal Entries Screen (Screen 2)
// =====================================================
class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key, required this.userId});
  final String? userId;

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  static const cream = Color(0xFFFFF9DA);
  static const mint  = Color(0xFFB6FFB1);
  static const sage  = Color(0xFFD9E3C4);
  static const rose  = Color(0xFFFF8A7D);

  List<Map<String, String>> _entries = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.userId == null) return;
    final box = await Hive.openBox('journalBox');
    final saved = box.get('journal_${widget.userId}');
    setState(() {
      _entries = saved == null
          ? []
          : List<Map<String, String>>.from(
          (saved as List).map((e) => Map<String, String>.from(e as Map)));
    });
  }

  Future<void> _save() async {
    if (widget.userId == null) return;
    final box = await Hive.openBox('journalBox');
    await box.put('journal_${widget.userId}', _entries);
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Delete this journal entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ??
        false;
    if (!ok) return;
    setState(() {
      _entries.removeAt(index);
      if (_selectedIndex == index) _selectedIndex = null;
      if (_selectedIndex != null && _selectedIndex! > index) _selectedIndex = _selectedIndex! - 1;
    });
    await _save();
  }

  void _goBack() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _pillHeader('View Journal Notes'),
            const SizedBox(height: 16),
            _entriesCard(),
            const SizedBox(height: 12),
            _backButton(),
          ],
        ),
      ),
    );
  }

  Widget _pillHeader(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Text(title, style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 22, color: Colors.black)),
      ),
    );
  }

  Widget _entriesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: sage,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: const Center(
              child: Text('View Journal Notes',
                  style: TextStyle(fontFamily: 'HappyMonkey', fontSize: 18, color: Colors.black)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No entries yet.',
                        style: TextStyle(fontFamily: 'HappyMonkey', fontSize: 16)),
                  )
                else
                  ListView.separated(
                    itemCount: _entries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F1D8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${e['name'] ?? 'Entry'} - ${e['date'] ?? ''}',
                                style: const TextStyle(fontSize: 16, color: Colors.black),
                              ),
                            ),
                            _chip('View', mint, onTap: () => setState(() => _selectedIndex = i)),
                            const SizedBox(width: 8),
                            _chip('Delete', rose, onTap: () => _delete(i)),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                if (_selectedIndex != null) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        "${_entries[_selectedIndex!]['name']} - ${_entries[_selectedIndex!]['date']}",
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 150),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(_entries[_selectedIndex!]['text'] ?? '',
                        style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color fill, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _goBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const Text('Back', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
