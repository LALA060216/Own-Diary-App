import 'package:flutter/material.dart';
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

  final FirestoreService firestoreService = FirestoreService();

  String? userId;
  Stream<List<DiaryEntryModel>>? diaryStream;

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
    setState(() {
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void nextMonth() {
    setState(() {
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  String monthName(int month) {
    const months = [
      "January","February","March","April",
      "May","June","July","August",
      "September","October","November","December"
    ];
    return months[month - 1];
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
                fontWeight: FontWeight.bold,
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
                                style: TextStyle(color: Colors.red, fontSize: 16),
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
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  DateTime? pickedDate =
                      await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
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

                final diaries =
                    snapshot.data!.where((d) {
                  return d.created.month ==
                          selectedDate.month &&
                      d.created.year ==
                          selectedDate.year;
                }).toList();

                if (diaries.isEmpty) {
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
                          splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
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
