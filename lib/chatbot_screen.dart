import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, String>> messages = [];

  //////////////////////////////////////////////////////////
  // SIMPLE BOT LOGIC
  //////////////////////////////////////////////////////////
  String getBotReply(String userMsg) {
    userMsg = userMsg.toLowerCase();

    if (userMsg.contains("add food")) {
      return "Click the + button on home screen to add food.";
    } else if (userMsg.contains("claim")) {
      return "Press the Claim button to claim food and open location.";
    } else if (userMsg.contains("report")) {
      return "Click top right report icon to download PDF or Excel.";
    } else if (userMsg.contains("login")) {
      return "Use your registered email and password to login.";
    } else if (userMsg.contains("signup")) {
      return "Click Signup and fill all details to create account.";
    } else {
      return "I am your guide 🤖. Ask about add food, claim, report, login.";
    }
  }

  //////////////////////////////////////////////////////////
  // SEND MESSAGE
  //////////////////////////////////////////////////////////
  void sendMessage() {
    if (controller.text.isEmpty) return;

    String userMsg = controller.text;

    setState(() {
      messages.add({"type": "user", "msg": userMsg});
      messages.add({"type": "bot", "msg": getBotReply(userMsg)});
    });

    controller.clear();
  }

  //////////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guide Assistant 🤖"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, i) {
                var msg = messages[i];

                return Container(
                  alignment: msg["type"] == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: EdgeInsets.all(10),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["type"] == "user"
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg["msg"]!),
                  ),
                );
              },
            ),
          ),

          //////////////////////////////////////////////////////
          // INPUT
          //////////////////////////////////////////////////////
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),

              IconButton(
                icon: Icon(Icons.send, color: Colors.green),
                onPressed: sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}