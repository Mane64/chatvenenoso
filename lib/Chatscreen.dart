import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String channel;

  ChatScreen({required this.channel});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed:
                _showAddUserDialog, // Mostrar el cuadro de diálogo para agregar usuarios
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('messages')
                  .doc(widget.channel)
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
                  final sender = message.get(
                      'sender'); // Obtener la información del remitente (sender)
                  final currentUserUID = _auth.currentUser!.uid;

                  final messageWidget = ChatBubble(
                    clipper: ChatBubbleClipper9(
                      type: sender == currentUserUID
                          ? BubbleType.sendBubble
                          : BubbleType.receiverBubble,
                    ),
                    alignment: sender == currentUserUID
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    backGroundColor: sender == currentUserUID
                        ? Colors.blue
                        : Colors.grey[300],
                    child: Column(
                      crossAxisAlignment: sender == currentUserUID
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender == currentUserUID ? 'Tú' : 'Otro usuario',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          messageText,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );

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
          .doc(widget.channel)
          .collection('chats')
          .add({
        'text': message,
        'sender': _auth
            .currentUser!.uid, // Agregar la información del remitente (sender)
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pop();
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Usuario al Canal'),
          content: TextField(
            controller: _newUserEmailController,
            decoration:
                InputDecoration(hintText: 'Correo Electrónico del Usuario'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _addUserToChannel(); // Agregar el usuario al canal
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _addUserToChannel() {
    final newUserEmail = _newUserEmailController.text.trim();
    if (newUserEmail.isNotEmpty) {
      // Buscar el UID del usuario a agregar por su correo electrónico
      _firestore
          .collection('users')
          .where('email', isEqualTo: newUserEmail)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final newUserUID = querySnapshot.docs.first.id;
          _firestore.collection('channels').doc(widget.channel).update({
            'authorized_users': FieldValue.arrayUnion([newUserUID]),
          });
          _newUserEmailController.clear();
        } else {
          // Mostrar un mensaje de error si el usuario no existe
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario no encontrado')),
          );
        }
      }).catchError((error) {
        // Mostrar un mensaje de error si ocurre algún problema
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar usuario')),
        );
      });
    }
  }
}
