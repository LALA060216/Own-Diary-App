import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/models/diary_entry_model.dart';
import 'details_diary.dart';

class Diaries extends StatefulWidget {
  const Diaries({super.key});

  @override
  State<Diaries> createState() => _DiariesState();
}

class _DiariesState extends State<Diaries> {
  DateTime selectedDate = DateTime.now();
  DateTime? selectedDay;
  String titleQuery = '';
  bool isSearchOpen = false;
  bool _isProgrammaticSearchUpdate = false;
  final TextEditingController _searchController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  String? userId;
  Stream<List<DiaryEntryModel>>? diaryStream;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userId = user.uid;
      diaryStream =
      firestoreService.getUserDiaryEntriesStream(userId!);
    }
  }

  void previousMonth() {
    _safeSetState(() {
      selectedDay = null;
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void nextMonth() {
    _safeSetState(() {
      selectedDay = null;
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  Future<void> pickDateFromSearch() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDay ?? selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _safeSetState(() {
        selectedDay = pickedDate;
        selectedDate = pickedDate;
      });
    }
  }

  void _clearAllFilters() {
    _isProgrammaticSearchUpdate = true;
    _searchController.clear();
    _isProgrammaticSearchUpdate = false;
    if (!mounted) return;
    _safeSetState(() {
      titleQuery = '';
      selectedDay = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String monthName(int month) {
    const months = [
      "January","February","March","April",
      "May","June","July","August",
      "September","October","November","December"
    ];
    return months[month - 1];
  }

  List<DiaryEntryModel> _applyDiaryFilters(List<DiaryEntryModel> allDiaries) {
    return allDiaries.where((d) {
      final hasBody = d.context.trim().isNotEmpty;
      final hasImages = d.imageUrls.isNotEmpty;
      final hasSavableContent = hasBody || hasImages;
      final titleMatches = titleQuery.isEmpty ||
          d.title.toLowerCase().contains(titleQuery.toLowerCase());
      final monthMatches = selectedDay == null
          ? (d.created.month == selectedDate.month &&
              d.created.year == selectedDate.year)
          : true;
      final dateMatches = selectedDay != null
          ? DateUtils.isSameDay(d.created, selectedDay)
          : true;
      return monthMatches && hasSavableContent && titleMatches && dateMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || diaryStream == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true, // allow tap outside to dismiss
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFFF5F5F5), // subtle off‑white
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Delete diary?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'This diary entry will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            // Row with two actions and vertical divider
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: 55,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                            onTap: () =>
                                Navigator.of(context).pop(false),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ),
                      ),

                        Container(
                          width: 1,
                          height: double.infinity,
                          color: Colors.grey.shade300,
                        ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, 
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                            onTap:() => 
                              Navigator.of(context).pop(true),
                            child: const Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red, 
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ),
          ],
        ),
      );
    },
  );
}

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 2,
        backgroundColor: const Color(0xfffffaf0),
        title: const Text(
          'Diary Summary',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontFamily: 'lobstertwo',
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 10, 10),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(height: 5),
                      Text("Event ${index + 1}"),
                    ],
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: previousMonth,
              ),

              const SizedBox(width: 10),

              Text(
                "${monthName(selectedDate.month)} ${selectedDate.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              IconButton(
                icon: Icon(isSearchOpen ? Icons.close : Icons.search),
                onPressed: () {
                  if (isSearchOpen) {
                    _isProgrammaticSearchUpdate = true;
                    _searchController.clear();
                    _isProgrammaticSearchUpdate = false;
                    if (!mounted) return;
                    _safeSetState(() {
                      isSearchOpen = false;
                      titleQuery = '';
                      selectedDay = null;
                    });
                  } else {
                    _safeSetState(() {
                      isSearchOpen = true;
                    });
                  }
                },
              ),

              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: nextMonth,
              ),
            ],
          ),

          if (isSearchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (_isProgrammaticSearchUpdate || !mounted) return;
                          _safeSetState(() {
                            titleQuery = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search title',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: Colors.black54),
                            onPressed: pickDateFromSearch,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          if (selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDay!),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            _safeSetState(() {
                              selectedDay = null;
                            });
                          },
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<DiaryEntryModel>>(
              stream: diaryStream,
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No diaries yet"));
                }

                final diaries = _applyDiaryFilters(snapshot.data!);

                if (diaries.isEmpty) {
                  if (selectedDay != null) {
                    return const Center(
                      child: Text('No diary was created on this day'),
                    );
                  }
                  if (titleQuery.isNotEmpty) {
                    return const Center(
                      child: Text('No diary matched your search'),
                    );
                  }
                  return const Center(
                      child:
                          Text("No diaries this month"));
                }

                return ListView.builder(
                  itemCount: diaries.length,
                  itemBuilder: (context, index) {
                    final diary = diaries[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // only margin; no decoration here so ripple isn't hidden
                      child: Material(
                        // Material provides the surface for the ripple
                        color: Colors.white,
                        elevation: 2, // replaces the BoxShadow on Container
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsDiary(diary: diary),
                              ),
                            );
                          },
                          onLongPress: () async {
                            // handle long‑press actions if needed
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat("dd MMM yyyy").format(diary.created),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFF483D3C)),
                                      onPressed: () async {
                                        final bool? confirm = await showDeleteConfirmationDialog(context);
                                        if (confirm == true) {
                                          await firestoreService.deleteDiaryEntry(diary.id, userId!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  diary.title.trim().isEmpty ? 'Untitled' : diary.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diary.context,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
