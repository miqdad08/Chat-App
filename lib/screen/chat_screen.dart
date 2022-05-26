import 'package:chat_app/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

late User loggedInUser;
final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const String id = "CHAT_SCREEN";

  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String message;

  final _textController = TextEditingController();

  late DateTime now;
  late String formattedDate;

  final _auth = FirebaseAuth.instance;

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser!;
      loggedInUser = user;
      print(loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.forum),
        title: const Text("Chat"),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close))
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.black),
                      onChanged: (nilai) {
                        message = nilai;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        now = DateTime.now();
                        formattedDate = DateFormat('kk:mm:ss').format(now);
                      });
                      _textController.clear();
                      _firestore.collection("messages").add({
                        'sender': loggedInUser.email!,
                        'text': message,
                        'time': formattedDate
                      });
                    },
                    child: const Text('Send', style: kSendButtonTextStyle),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("messages")
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlue,
              ),
            );
          }

          final messages = snapshot.data!.docs;
          List<MessageBubble> messageBubble = [];
          for (var message in messages) {
            final messageText = message['text'];
            final messeageSender = message['sender'];

            final currentUserEmail = loggedInUser.email;

            final messageWidget = MessageBubble(
              text: messageText,
              sender: messeageSender,
              isMe: currentUserEmail == messeageSender,
            );
            messageBubble.add(messageWidget);
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: ListView(
                reverse: true,
                children: messageBubble,
              ),
            ),
          );
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  const MessageBubble(
      {Key? key, required this.sender, required this.text, required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          Material(
            borderRadius: BorderRadius.only(
                topLeft:
                    isMe ? const Radius.circular(30) : const Radius.circular(0),
                topRight:
                    isMe ? const Radius.circular(0) : const Radius.circular(30),
                bottomRight: const Radius.circular(30),
                bottomLeft: const Radius.circular(30)),
            elevation: 5,
            color: Colors.lightBlue,
            // : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(text,
                  style: TextStyle(
                      color: isMe ? Colors.white : Colors.black54,
                      fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }
}
