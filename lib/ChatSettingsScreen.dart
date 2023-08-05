import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatvenenoso/Canales.dart';

class ChatSettingsScreen extends StatefulWidget {
  final String channelID;

  ChatSettingsScreen({required this.channelID});

  @override
  _ChatSettingsScreenState createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _chatNameController = TextEditingController();
  List<String> _chatMembers = []; // Lista de IDs de los miembros del chat
  Map<String, String> _userNames =
      {}; // Mapa para almacenar nombres de usuarios
  @override
  void initState() {
    super.initState();
    _fetchChatData();
  }

  // Método para obtener los datos del chat desde Firestore
  void _fetchChatData() async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelID)
        .get();
    final chatData = chatSnapshot.data();

    if (chatData != null) {
      // Actualiza el nombre del chat en el controlador de texto
      _chatNameController.text = chatData['name'];

      // Actualiza la lista de miembros del chat
      setState(() {
        _chatMembers = List<String>.from(chatData['authorized_users']);
      });

      // Obtiene los nombres de los usuarios y los almacena en el mapa _userNames
      _getUserNames();
    }
  }

  // Método para guardar los cambios en el nombre del chat
  void _saveChatName() {
    final newChatName = _chatNameController.text.trim();
    if (newChatName.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channelID)
          .update({
        'name': newChatName,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nombre del chat actualizado')));
    }
  }

  // Método para obtener los nombres de los usuarios
  void _getUserNames() async {
    for (String userId in _chatMembers) {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
      final userName = userSnapshot.data()?['nombre'] ?? 'Usuario Desconocido';
      setState(() {
        _userNames[userId] = userName;
      });
    }
  }

  // Método para eliminar un usuario del chat
  void _removeUserFromChat(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Usuario del Chat'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a este usuario del chat?',
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
                Navigator.pop(context);
                _removeUser(userId);
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar al usuario de Firestore y actualizar la lista de miembros del chat
  void _removeUser(String userId) {
    setState(() {
      _chatMembers.remove(userId);
    });
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelID)
        .update({
      'authorized_users': FieldValue.arrayRemove([userId]),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario eliminado del chat')),
      );
      // Redirigir al usuario a ChatScreen después de eliminarlo del chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChannelListScreen(),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar al usuario del chat')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserID = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración del Chat'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Sección para editar el nombre del chat
          Text(
            'Nombre del Chat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _chatNameController,
            decoration: InputDecoration(
              hintText: 'Ingrese el nuevo nombre del chat',
              border: OutlineInputBorder(),
            ),
          ),
          ElevatedButton(
            onPressed: _saveChatName,
            child: Text('Guardar Cambios'),
          ),
          SizedBox(height: 16),

          // Sección para mostrar la lista de miembros del chat
          Text(
            'Miembros del Chat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          for (var memberId in _chatMembers)
            if (memberId == currentUserID)
              ListTile(
                title: Text('Tú'),
                trailing: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Salir del Canal'),
                          content: Text(
                            '¿Estás seguro de que deseas salir del canal?',
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
                                Navigator.pop(context);
                                _removeUser(memberId);
                              },
                              child: Text('Salir'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Salir del Canal'),
                ),
              )
            else
              ListTile(
                title: Text(
                  _userNames[memberId] ?? 'Usuario Desconocido',
                ),
                // Aquí mostramos el nombre del usuario usando el mapa _userNames
                // Si no se encuentra el nombre, mostramos "Usuario Desconocido"
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _removeUserFromChat(memberId);
                  },
                ),
              ),
        ],
      ),
    );
  }
}
