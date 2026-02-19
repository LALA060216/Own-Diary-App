import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AISummaryPage extends StatefulWidget {

  const AISummaryPage({super.key});

  @override
  _ASummaryPageState createState() => _ASummaryPageState();
}

class _ASummaryPageState extends State<AISummaryPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool is_sending = false;

  late final GenerativeModel _model;

  @override
  void initState(){
    super.initState();
    const apiKey = 'AIzaSyCcLIyQT03Skh9Cr4l-b7acBDF8pfjgwiw';
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || is_sending) return;

    setState((){
      _messages.add(_ChatMessage(role: _Role.user, text: text));
      is_sending = true;
    });

    try{
      final chat = _model.startChat(
        history: _messages.map((m) => Content.text(m.text)).toList(),
      );

      final response = await chat.sendMessage(Content.text(text));
      final reply = response.text ?? "Sorry, I couldn't generate a response.";

      setState(() {
        _messages.add(_ChatMessage(role: _Role.ai, text: reply));
        is_sending = false;
        _controller.clear();
      });

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