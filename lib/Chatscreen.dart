import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String channel; // Agrega el parámetro channel

  ChatScreen({required this.channel}); // Constructor con el parámetro channel
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  String _currentChannel = 'general'; // Canal de chat predeterminado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con Firebase'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (channel) {
              setState(() {
                _currentChannel = channel;
              });
            },
            itemBuilder: (BuildContext context) {
              return ['general', 'random', 'tech', 'news'].map((channel) {
                return PopupMenuItem<String>(
                  value: channel,
                  child: Text(channel),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .doc(_currentChannel)
                  .collection('chats')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  final messageText = message.get('text');
                  final messageWidget = Text(messageText);
                  messageWidgets.add(messageWidget);
                }
                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _firestore
          .collection('messages')
          .doc(_currentChannel)
          .collection('chats')
          .add({
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pop(); // Regresar a la pantalla anterior
  }
}
