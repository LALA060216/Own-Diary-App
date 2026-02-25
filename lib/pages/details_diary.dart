import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/models/diary_entry_model.dart';
import 'full_screen_image_page.dart';
import 'newdiary_page.dart';

class DetailsDiary extends StatefulWidget {
  final DiaryEntryModel diary;
  final int? focusImageIndex;

  const DetailsDiary({
    super.key,
    required this.diary,
    this.focusImageIndex,
  });

  @override
  State<DetailsDiary> createState() => _DetailsDiaryState();
}

class _DetailsDiaryState extends State<DetailsDiary> {
  static final RegExp _inlineImageTokenPattern = RegExp(r'\[img:(\d+)\]');
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusTokenKey = GlobalKey();

  late String _currentTitle;
  late String _currentContext;
  late List<String> _imageUrls;

  bool _didAutoScrollToFocusToken = false;
  int _focusScrollAttempt = 0;
  bool _highlightFocusToken = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.diary.title;
    _currentContext = widget.diary.context;
    _imageUrls = List<String>.from(widget.diary.imageUrls);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFocusTokenIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFocusTokenIfNeeded() {
    if (!mounted) return;
    if (_didAutoScrollToFocusToken) return;
    final targetIndex = widget.focusImageIndex;
    if (targetIndex == null || targetIndex < 0) return;

    final focusContext = _focusTokenKey.currentContext;
    if (focusContext == null) {
      if (_focusScrollAttempt >= 8) return;
      _focusScrollAttempt++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocusTokenIfNeeded();
      });
      return;
    }

    _didAutoScrollToFocusToken = true;
    _highlightFocusToken = true;
    setState(() {});
    Scrollable.ensureVisible(
      focusContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _highlightFocusToken = false;
      });
    });
  }

  void _navigateToEdit() {
    final diaryController = TextEditingController(text: _currentContext);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiary(
          diaryId: widget.diary.id,
          previousImageUrls: _imageUrls,
          previousDiaryController: diaryController,
          previousTitle: _currentTitle,
          fromDetails: true,
        ),
      ),
    );
  }

  InlineSpan _buildInlineContextSpan(String text) {
    final spans = <InlineSpan>[];
    int cursor = 0;
    bool attachedFocusKey = false;
    final focusIndex = widget.focusImageIndex;

    for (final match in _inlineImageTokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        );
      }

      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index >= 0 && index < _imageUrls.length) {
        final shouldAttachFocusKey =
            !attachedFocusKey && focusIndex != null && index == focusIndex;
        if (shouldAttachFocusKey) {
          attachedFocusKey = true;
        }
        final shouldHighlightFocusedToken =
            shouldAttachFocusKey && _highlightFocusToken;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImagePage(
                      imageUrls: _imageUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: AnimatedScale(
                scale: shouldHighlightFocusedToken ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  key: shouldAttachFocusKey ? _focusTokenKey : null,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: shouldHighlightFocusedToken
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFFEDEADE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(
        const TextSpan(
          text: '',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: const Color(0xffffffff),
        surfaceTintColor: const Color(0xffffffff),
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Diary Details',
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'Lobstertwo',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: _buildDetailsBody(),
    );
  }

  Widget _buildDetailsBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentTitle.trim().isEmpty ? 'Untitled' : _currentTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy').format(widget.diary.created),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _imageUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImagePage(
                              imageUrls: _imageUrls,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: imageUrl,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.8,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          RichText(
            text: _buildInlineContextSpan(_currentContext),
          ),
        ],
      ),
    );
  }
}
