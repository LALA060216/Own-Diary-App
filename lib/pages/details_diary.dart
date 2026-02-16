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
    // Build a list of TextSpans and WidgetSpans based on placeholders
    final RegExp imgRegex = RegExp(r'\[img(\d+)\]');
    final List<InlineSpan> spans = [];
    int currentIndex = 0;

    diary.context.splitMapJoin(
      imgRegex,
      onMatch: (Match match) {
        final index = int.parse(match.group(1)!);
        // Add text before the placeholder
        spans.add(TextSpan(text: diary.context.substring(currentIndex, match.start)));
        // Embed the image inline using WidgetSpan
        if (index < diary.imageUrls.length) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.bottom,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.network(
                diary.imageUrls[index],
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ));
        }
        currentIndex = match.end;
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text));
        return '';
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Diary Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat("dd MMM yyyy").format(diary.created),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Show the first image at the top if available
            if (diary.imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Image.network(
                  diary.imageUrls[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            // Render combined text and images
            Text.rich(
              TextSpan(children: spans),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
