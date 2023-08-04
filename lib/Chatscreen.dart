import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final String channel;
  final String channelID;

  ChatScreen({required this.channel, required this.channelID});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _newUserEmailController = TextEditingController();
  List<Map<String, dynamic>> _chatUsersData =
      []; // Lista de datos de usuarios en el chat
  final AudioCache _audioCache = AudioCache();

  late String currentUserName;

  List<String> _chatUsers = []; // Lista de usuarios en el chat

  @override
  void initState() {
    super.initState();
    _getUserName();
    _getChatUsers();
    _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel),
        actions: [
          // Agregar el PopUpMenuButton a la lista de acciones del app bar
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.chat),
                    title: Text('Ver usuarios en el chat'),
                    onTap: () {
                      Navigator.of(context).pop(); // Cerrar el menú emergente
                      _showChatUsersDialog(); // Mostrar el cuadro de diálogo con los usuarios en el chat
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Agregar Usuario al Canal'),
                    onTap: () {
                      Navigator.of(context).pop(); // Cerrar el menú emergente
                      _showAddUserDialog(); // Mostrar el cuadro de diálogo para agregar usuario al canal
                    },
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('messages')
                  .doc(widget.channelID)
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
                  final sender = message.get('sender');
                  final timestamp = message.get('timestamp');

                  final messageWidget = ChatBubble(
                    clipper: ChatBubbleClipper9(
                      type: sender == _auth.currentUser!.uid
                          ? BubbleType.sendBubble
                          : BubbleType.receiverBubble,
                    ),
                    alignment: sender == _auth.currentUser!.uid
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    margin: EdgeInsets.only(top: 8, bottom: 8),
                    backGroundColor: sender == _auth.currentUser!.uid
                        ? Colors.blue
                        : Colors.white,
                    child: Column(
                      crossAxisAlignment: sender == _auth.currentUser!.uid
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender == _auth.currentUser!.uid
                              ? 'Tú'
                              : message.get('senderName'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          messageText,
                          style: TextStyle(
                            color: sender == _auth.currentUser!.uid
                                ? Colors.white
                                : Colors.black,
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

  void _getUserName() async {
    final currentUserUID = _auth.currentUser!.uid;
    final userSnapshot =
        await _firestore.collection('usuarios').doc(currentUserUID).get();
    setState(() {
      currentUserName = userSnapshot['nombre'];
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _firestore
          .collection('messages')
          .doc(widget.channelID)
          .collection('chats')
          .add({
        'text': message,
        'sender': _auth.currentUser!.uid,
        'senderName': currentUserName, // Agregar el nombre del remitente
        'timestamp': FieldValue.serverTimestamp(),
      });

      _playSentSound(); // Llama a la función para reproducir el sonido
      _messageController.clear();
    }
  }

  void _playSentSound() async {
    final player = AudioPlayer(); // Crea una instancia de AudioPlayer
    await player.play(UrlSource('assets/pop.mp3')); // Reproduce el sonido
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
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _addUserToChannel();
                Navigator.pop(context);
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
      _firestore
          .collection('usuarios')
          .where('email', isEqualTo: newUserEmail)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final newUserUID = querySnapshot.docs.first.id;
          _firestore.collection('channels').doc(widget.channelID).update({
            'authorized_users': FieldValue.arrayUnion([newUserUID]),
          });
          _newUserEmailController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario no encontrado')),
          );
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar usuario')),
        );
      });
    }
  }

  void _removeUserFromChat(String userId) {
    setState(() {
      _chatUsers.remove(userId);
    });
    _firestore.collection('channels').doc(widget.channelID).update({
      'authorized_users': FieldValue.arrayRemove([userId]),
    });
  }

  // Función para mostrar un cuadro de diálogo con los usuarios en el chat
  void _showChatUsersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Usuarios en el Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var userData in _chatUsersData)
                ListTile(
                  title: Text(userData['nombre']),
                  subtitle: Text(userData['email']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _removeUserFromChat(userData['uid']);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _getChatUsers() async {
    final channelSnapshot =
        await _firestore.collection('channels').doc(widget.channelID).get();
    final users = channelSnapshot.get('authorized_users');
    setState(() {
      _chatUsers = List<String>.from(users);
    });
  }

  void _getUserData() async {
    List<Map<String, dynamic>> usersData = [];
    for (String userId in _chatUsers) {
      final userSnapshot =
          await _firestore.collection('usuarios').doc(userId).get();
      final userData = userSnapshot.data();
      if (userData != null) {
        usersData.add(userData);
      }
    }
    setState(() {
      _chatUsersData = usersData;
    });
  }
}
