import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryNameController = TextEditingController();
  final TextEditingController _entryTextController = TextEditingController();

  List<Map<String, String>> journalEntries = [];
  Set<int> expandedIndexes = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sessionBox = await Hive.openBox('session');
    final userId = sessionBox.get('loggedInUser');

    if (userId != null) {
      _userId = userId;
      await _loadFromHive(userId);
    }
  }

  void _saveEntry() async {
    final name = _entryNameController.text.trim();
    final text = _entryTextController.text.trim();

    if (_userId == null || name.isEmpty || text.isEmpty) return;

    setState(() {
      journalEntries.insert(0, {
        'name': name,
        'text': text,
        'date': _getTodayDate(),
      });
    });
    _entryNameController.clear();
    _entryTextController.clear();
    await _saveToHive(_userId!);
  }

  void _editEntry(int index) async {
    final entry = journalEntries[index];
    _entryNameController.text = entry['name']!;
    _entryTextController.text = entry['text']!;

    setState(() {
      journalEntries.removeAt(index);
      expandedIndexes.remove(index);
    });

    if (_userId != null) {
      await _saveToHive(_userId!);
    }
  }

  void _deleteEntry(int index) async {
    final confirm = await _showDeleteConfirmationDialog();
    if (confirm) {
      setState(() {
        journalEntries.removeAt(index);
        expandedIndexes.remove(index);
      });
      if (_userId != null) {
        await _saveToHive(_userId!);
      }
    }
  }

  Future<void> _saveToHive(String userId) async {
    final journalBox = await Hive.openBox('journalBox');
    await journalBox.put('journal_$userId', journalEntries);
  }

  Future<void> _loadFromHive(String userId) async {
    final journalBox = await Hive.openBox('journalBox');
    final List<dynamic>? saved = journalBox.get('journal_$userId');

    if (saved != null) {
      setState(() {
        journalEntries = List<Map<String, String>>.from(
          saved.map((item) => Map<String, String>.from(item)),
        );
      });
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Deletion',
                style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize)),
            content: Text('Are you sure you want to delete this journal entry?',
                style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete',
                    style: TextStyle(color: Colors.red, fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize)),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCreateEntrySection(),
          const SizedBox(height: 20),
          _buildViewEntriesSection(),
        ],
      ),
    );
  }

  Widget _buildCreateEntrySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Create New Entry',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _entryNameController,
            decoration: InputDecoration(
              hintText: 'Entry Name',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _entryTextController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter Text',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF40D404) : Colors.lightGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _saveEntry,
              child: Text(
                'Save Entry',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewEntriesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2F36) : Colors.blue.shade300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'View Journal Notes',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          journalEntries.isEmpty
              ? Center(
                  child: Text(
                    'No entries yet. Create one!',
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                      color: Colors.white,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: journalEntries.length,
                  itemBuilder: (context, index) {
                    final entry = journalEntries[index];
                    final isExpanded = expandedIndexes.contains(index);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            expandedIndexes.remove(index);
                          } else {
                            expandedIndexes.add(index);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry['name']} - ${entry['date']}',
                              style: TextStyle(
                                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 8),
                              Text(
                                entry['text'] ?? '',
                                style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF40D404)
                                          : Colors.lightGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Colors.black, width: 2),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () => _editEntry(index),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFFF00404)
                                          : Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Colors.black, width: 2),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () => _deleteEntry(index),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}