import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/models/diary_entry_model.dart';

class DetailsDiary extends StatelessWidget {
  final DiaryEntryModel diary;

  const DetailsDiary({
    super.key,
    required this.diary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diary Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              DateFormat("dd MMM yyyy")
                  .format(diary.created),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              diary.context,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
