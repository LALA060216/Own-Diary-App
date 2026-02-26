import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../services/gemini_service.dart';
import '../services/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:diaryapp/services/firestore_service.dart';

final List<_ChatMessage> _messages = [];
final List<String> _diaryContexts = [];
List<Content> _chatHistory = [];

void clearAiChatState() {
  _messages.clear();
  _diaryContexts.clear();
  _chatHistory.clear();
}

class AISummaryPage extends StatefulWidget {

  const AISummaryPage({super.key});

  @override
  _ASummaryPageState createState() => _ASummaryPageState();
}

class _ASummaryPageState extends State<AISummaryPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  
  bool is_sending = false;

  late final GeminiService _geminiServiceKeyWord;
  late final GeminiService _geminiServiceSummary;
  final FirestoreService _firestoreService = FirestoreService();


  Future<List<String>> _fetchDiaryEntriesWithKeyword(List<String> keywords) async {
    if (keywords.isEmpty) {
      return [];
    }

    Query query = FirebaseFirestore.instance
        .collection('diaryEntries')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid);

    if (keywords.isNotEmpty) {
      if (keywords.length == 1) {
        query = query.where('keywords', arrayContains: keywords.first);
      } else {
        query = query.where('keywords', arrayContainsAny: keywords);
      }
    }

    final querySnapshot = await query.get();

    List<String> allContexts = [];
    for (var doc in querySnapshot.docs) {
      String context = doc['context'] ?? '';
      Timestamp? timestamp = doc['created'];
      String title = doc['title'];
      if (timestamp != null) {
        DateTime date = timestamp.toDate();
        allContexts.add('date: ${DateFormat('yyyy-MM-dd').format(date)}\nDiary title: $title \nDiary: $context');
      }
    }
    allContexts.add('Date Today: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}');
    print(allContexts);
    return allContexts;
  }

  List<String> _normalizeKeywords(List<String> keywords) {
    final List<String> normalized = [];
    for (final keyword in keywords) {
      final parts = keyword.split(',');
      for (final part in parts) {
        final cleaned = part.trim();
        if (cleaned.isNotEmpty) {
          normalized.add(cleaned);
        }
      }
    }
    return normalized;
  }

  List<String> _parseKeywords(String keywordResponse) {
    final cleaned = keywordResponse
        .replaceAll('\r\n', '\n')
        .replaceAll('/n', '\n')
        .trim();

    try {
      // Prefer the first JSON array if the response contains extra text.
      final arrayMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(cleaned);
      final jsonText = arrayMatch?.group(0) ?? cleaned;
      final decoded = jsonDecode(jsonText);
      if (decoded is List) {
        return _normalizeKeywords(
          decoded.map((k) => k.toString().trim()).toList(),
        );
      }
    } catch (_) {
      // Fallback to comma-separated parsing if JSON fails.
      return _normalizeKeywords(
        cleaned
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList(),
      );
    }

    return [];
  }
  
  @override
  void initState(){
    super.initState();
    // Initialize AIChatModel
    final chatModelKeyWord = AIChatModel(
      prompt: 'You are a keyword matching assistant./nSelect 0 to 10 keywords that are most related to the user input text./nOnly choose keywords from the provided keyword list\nPrioritize semantic similarity, not exact matches./nIgnore unrelated keywords./nIf nothing is relevant, return []./nReturn ONLY a JSON array of strings with no extra text.',
      model: 'gemini-2.5-flash'
    );
    final chatModelSummary = AIChatModel(
      prompt: 'Reply the user text using the list of diary entries with date provided\nReply using "you" or refer to the user\'s text only. Example: "You played...", "John finished..."\nIf user text ask about date and the date is close, use today or yesterday to represent it when answer.\nstaying directly relevant to them with no extra assumptions or unrelated information. If the diary entries have no relevant information, respond with normal conversation.\nReturn a concise response.',
      model: 'gemini-2.5-flash'
    );
    
    // Initialize GeminiService with the model
    _geminiServiceKeyWord = GeminiService(chatModel: chatModelKeyWord);
    _geminiServiceSummary = GeminiService(chatModel: chatModelSummary);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty || is_sending) return;
    print('User input: $text');

    setState((){
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      is_sending = true;
      _controller.clear();
    });

    // Add user message to chat history
    _chatHistory.add(Content.text(text));


    try{
      final allKeywords = await _firestoreService.getAllUserKeywords();
      final keywordResponse = await _geminiServiceKeyWord.sendMessage('Date Now: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\nUser text: $text\nall keywords from user diary entries: ${allKeywords.join(', ')}');
      print('keywordResponse: $keywordResponse');
      final keywords = _parseKeywords(keywordResponse);
      final contexts = await _fetchDiaryEntriesWithKeyword(keywords);
      if (contexts.isNotEmpty) {
        _diaryContexts.addAll(contexts);
      }
      print('contexts: $_diaryContexts');
      final summary = await _geminiServiceSummary.sendMessageWithDiaryEntry('user text: $text', _chatHistory, _diaryContexts);
      
      // Limit chat history to the most recent 20 entries to manage token usage
      const maxHistory = 10;
      if (_chatHistory.length > maxHistory) {
        _chatHistory = _chatHistory.sublist(_chatHistory.length - maxHistory);
      }

      setState(() {
        _messages.add(_ChatMessage(role: _Role.ai, text: summary));
        is_sending = false;
        
      });
      _chatHistory.add(Content.text('User text: $text'));
      _chatHistory.add(Content.text('AI response: $summary'));

    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(role: _Role.ai, text: "Error: $e"));
        is_sending = false;
      });
    } finally {
      _scrollToButtom();
    }
  }

  void _scrollToButtom() {
    if(_scrollController.hasClients){
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xffffffff),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Chat with your Personal AI', 
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'Lobstertwo'
          ),
        ), 
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == _Role.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Color(0xffdadada): null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(msg.text),
                  )
                );
              }
            ),
          ),
          SafeArea(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),

              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                      ),
                    )
                  ),
                  const SizedBox(width: 8),
                  if (is_sending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: SizedBox(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    )
                  else
                    IconButton(
                      onPressed: is_sending ? null : _sendMessage, 
                      icon: const Icon(Icons.send, color: Color.fromARGB(255, 48, 48, 48))
                    )
                  ]
                )
              )
            ),
            SizedBox(height: 10)
        ]
    )
  );
}

}

enum _Role {user, ai}

class _ChatMessage {
  final _Role role;
  final String text;

  _ChatMessage({required this.role, required this.text});
}