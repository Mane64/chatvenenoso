import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:chatvenenoso/ChatSettingsScreen.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  late final String channel;
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
  List<Map<String, dynamic>> _chatUsersData = [];
  final AudioCache _audioCache = AudioCache();
  bool _showEmojiPicker = false;
  late String currentUserName;
  File? _selectedImage;
  List<String> _chatUsers = [];

  @override
  void initState() {
    super.initState();
    _getUserName();
    _getChatUsers();
    _getUserData();
  }

  Future<void> _attachFile() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Configuración del Chat'),
                    onTap: () {
                      Navigator.of(context).pop(); // Cerrar el menú emergente
                      _navigateToChatSettingsScreen();
                    },
                  ),
                ),
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Agregar Usuario al Canal'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showAddUserDialog();
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
  final messageTime = timestamp != null ? (timestamp as Timestamp).toDate() : DateTime.now();

  final messageBubble = ChatBubble(
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

  final timeWidget = Align(
    alignment: sender == _auth.currentUser!.uid
        ? Alignment.bottomRight
        : Alignment.bottomLeft,
    child: Text(
      DateFormat('HH:mm').format(messageTime),
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[500],
      ),
    ),
  );

  final messageWidget = Column(
    children: [
      messageBubble,
      timeWidget,
    ],
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.emoji_emotions),
                        onPressed: () {
                          setState(() => _showEmojiPicker = !_showEmojiPicker);
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 16.0,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file),
                        onPressed: _attachFile,
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: _takePicture,
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showEmojiPicker)
            Expanded(
              child: SizedBox(
                height: 36,
                child: EmojiPicker(
                  textEditingController: _messageController,
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.30
                            : 1.0),
                  ),
                ),
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

  void _navigateToChatSettingsScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatSettingsScreen(channelID: widget.channelID),
      ),
    );

    if (result != null) {
      // Si el resultado no es nulo, actualiza el nombre del chat en esta pantalla
      setState(() {
        widget.channel = result;
      });
    }
  }

  void _getChatName() async {
    final channelSnapshot =
        await _firestore.collection('channels').doc(widget.channelID).get();
    final chatName = channelSnapshot.get('name');
    setState(() {
      widget.channel = chatName;
    });
  }
}
