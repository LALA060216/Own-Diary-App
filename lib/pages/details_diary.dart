import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/models/diary_entry_model.dart';
import 'full_screen_image_page.dart'; // import your full-screen page

class DetailsDiary extends StatelessWidget {
  final DiaryEntryModel diary;

  const DetailsDiary({super.key, required this.diary});

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
        // Embed the image inline using WidgetSpan with tap & hero
        if (index < diary.imageUrls.length) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.bottom,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(
                        imageUrls: diary.imageUrls,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: diary.imageUrls[index],
                  child: Image.network(
                    diary.imageUrls[index],
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            ),
          );
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
        title: const Text('Diary Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(diary.created),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Show all images in a horizontal scroll view
            if (diary.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: diary.imageUrls.length,
                  itemBuilder: (context, index) {
                    final url = diary.imageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImagePage(
                                imageUrls: diary.imageUrls,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: url,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width * 0.8,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            // Render combined text and images inline
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
