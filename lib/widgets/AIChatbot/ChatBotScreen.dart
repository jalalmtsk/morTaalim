import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/widgets/AIChatbot/wakiEngine.dart';  // Ton moteur WakiBrain

class WakiBot extends StatelessWidget {
  const WakiBot({super.key});
  @override
  Widget build(BuildContext context) {
    return const ChatPage();
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  String? _userName;
  bool _awaitingName = true;

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('username');
    if (storedName != null) {
      setState(() {
        _userName = storedName;
        _awaitingName = false;
        _messages.add(_ChatMessage(sender: "Waki", text: "Bienvenue de nouveau, $_userName ! Parle-moi !"));
      });
    } else {
      setState(() {
        _awaitingName = true;
        _messages.add(_ChatMessage(sender: "Waki", text: "Bonjour ! Comment tu t'appelles ?"));
      });
    }
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    setState(() {
      _userName = name;
      _awaitingName = false;
    });
  }

  void _handleSubmit(String input) {
    if (input.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(sender: _userName ?? "Toi", text: input));
    });

    if (_awaitingName) {
      _saveUserName(input.trim());
      setState(() {
        _messages.add(_ChatMessage(sender: "Waki", text: "Enchanté, $input! Pose-moi des questions ou parle-moi."));
      });
      return;
    }

    final reply = WakiBrain.getReply(input, userName: _userName);
    setState(() {
      _messages.add(_ChatMessage(sender: "Waki", text: reply));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Waki le Chatbot"),
        backgroundColor: Colors.deepOrangeAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Animation Lottie en haut
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            child: Lottie.asset(
              'assets/animations/UI_Animations/WakiBot.json', // Mets ici ton fichier Lottie (robot sympa)
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == (_userName ?? "Toi");

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.deepOrangeAccent,
                          child: Image.asset(
                            'assets/images/waki_avatar.png', // Ton avatar Waki
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (!isUser) const SizedBox(width: 10),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.deepOrangeAccent : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isUser ? 16 : 0),
                              topRight: Radius.circular(isUser ? 0 : 16),
                              bottomLeft: const Radius.circular(16),
                              bottomRight: const Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              )
                            ],
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 10),
                      if (isUser)
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _handleSubmit,
                    decoration: InputDecoration(
                      hintText: _awaitingName ? "Tape ton prénom..." : "Parle à Waki...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _handleSubmit(_controller.text),
                  child: const Icon(Icons.send, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  _ChatMessage({required this.sender, required this.text});
}
