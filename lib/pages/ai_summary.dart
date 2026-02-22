import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import '../services/gemini_service.dart';
import '../services/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final List<_ChatMessage> _messages = [];
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
  final List<Content> _chatHistory = [];
  final List<String> _diaryContexts = [];

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
      allContexts.add(context);
    }
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
    try {
      final decoded = jsonDecode(keywordResponse);
      if (decoded is List) {
        return _normalizeKeywords(
          decoded.map((k) => k.toString().trim()).toList(),
        );
      }
    } catch (_) {
      // Fallback to comma-separated parsing if JSON fails.
      return _normalizeKeywords(
        keywordResponse
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
      prompt: 'You are a keyword extraction assistant for a diary search system.\nTask:\nExtract keywords from the user text to help find related diary entries.\nIMPORTANT:\nDo NOT ignore meaningful words. Preserve important details such as people (friend, mom, boss, girlfriend), places (school, office, beach, japan), events (exam, meeting, trip, argument), emotions (stress, happy, angry, anxious), and activities (study, travel, dinner, workout).\nRules:\n- Return 0 to 10 keywords\n- Use lowercase\n- No duplicates\n- Single words or short phrases\n- Keep specific nouns if present\n- Include synonyms only if helpful\n- Do NOT remove words just because they seem common if they carry meaning\return empty list if nothing\nFormat:Example format: ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"]',
      model: 'gemma-3-27b-it'
    );
    final chatModelSummary = AIChatModel(
      prompt: 'Reply the user text using the list of diary entries provided, staying directly relevant to them with no extra assumptions or unrelated information.\nReturn a concise response.',
      model: 'gemini-2.5-flash'
    );
    
    // Initialize GeminiService with the model
    _geminiServiceKeyWord = GeminiService(chatModel: chatModelKeyWord);
    _geminiServiceSummary = GeminiService(chatModel: chatModelSummary);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty || is_sending) return;
    print(  'User input: $text');

    setState((){
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      is_sending = true;
    });

    // Add user message to chat history
    _chatHistory.add(Content.text(text));

    try{
      final keywordResponse = await _geminiServiceKeyWord.sendMessage('user text: $text');
      print('keywordResponse: $keywordResponse');
      final keywords = _parseKeywords(keywordResponse);
      final contexts = await _fetchDiaryEntriesWithKeyword(keywords);
      _diaryContexts.addAll(contexts);
      print('contexts: $_diaryContexts');
      final summary = await _geminiServiceSummary.sendMessageWithDiaryEntry('user text: $text', _chatHistory, _diaryContexts);

      setState(() {
        _messages.add(_ChatMessage(role: _Role.ai, text: summary));
        is_sending = false;
        _controller.clear();
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shadowColor: Color(0xffEDEADE),
        elevation: 2,
        backgroundColor: Color(0xfffffaf0),
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
                      color: isUser ? Colors.blue.shade100: null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  )
                );
              }
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400)
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
            )
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