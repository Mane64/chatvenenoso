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
  final TextEditingController _newUserEmailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchQueryController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<String> _searchResults = []; // Store search results
  List<String> _chatMessages = []; // Add this line to define the chat messages list
  



  List<String> _chatMembers = [];
  Map<String, String> _userNames = {};
  final TextEditingController _descriptionController = TextEditingController();
  bool _isEditingDescription = false;


  @override
  void initState() {
    super.initState();
    _fetchChatData();
  }

  void _fetchChatData() async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelID)
        .get();
    final chatData = chatSnapshot.data();

  if (chatData != null) {
    _chatNameController.text = chatData['name'];
    _descriptionController.text = chatData['description'] ?? ''; // Asignar la descripción o una cadena vacía
    setState(() {
      _chatMembers = List<String>.from(chatData['authorized_users']);
    });
    _getUserNames();
  }
  }


void _saveChatName() {
  final newChatName = _chatNameController.text.trim();
  if (newChatName.isNotEmpty) {
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelID)
        .update({
      'name': newChatName,
    }).then((_) {
      setState(() {
        _chatNameController.text = newChatName;
      });
      _chatNameController.clear(); // Limpiar el campo de texto
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nombre del chat actualizado')));
      _fetchChatData(); // Actualizar la información del chat
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el nombre del chat')));
    });
  }
}


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

  void _removeUserFromChat(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Usuario del Grupo'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a este usuario del grupo?',
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
        SnackBar(content: Text('Usuario eliminado del grupo')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChannelListScreen(),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar al usuario del grupo')),
      );
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final currentUserID = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes del Grupo'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implementar la búsqueda de miembros del grupo
            },
          ),
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'invite',
                  child: Text('Invitar a un amigo'),
                ),
                PopupMenuItem(
                  value: 'exit',
                  child: Text('Salir del Grupo'),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 'invite') {
                      _showAddUserDialog();
              } else if (value == 'exit') {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Salir del Grupo'),
                      content: Text(
                        '¿Estás seguro de que deseas salir del grupo?',
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
                            _removeUser(currentUserID);
                          },
                          child: Text('Salir'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: CircleAvatar(
              radius: 60,// Coloca aquí la imagen del grupo o el icono
              // Puedes usar un AssetImage, NetworkImage, etc.
              child: Icon(Icons.group,size: 100,),
            ),
          ),
          Text(
            _chatNameController.text, // Mostrar el nombre del grupo
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.person_add),
          onPressed: () { 
            _showAddUserDialog();
          },
        ),
        Text('Añadir'),
        SizedBox(width: 20),
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
           _performSearch(_searchQueryController.text);

          },
        ),
        Text('Buscar'),
      ],
    ),
          TextField(
            controller: _chatNameController,
            decoration: InputDecoration(
              hintText: 'Ingrese el nombre del grupo',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.edit),
                onPressed: _saveChatName, // Actualizar el nombre al presionar el botón
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Descripción del Grupo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ingrese una descripción para el grupo',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isEditingDescription
                    ? () {
                        // Guardar la descripción editada
                        FirebaseFirestore.instance
                            .collection('channels')
                            .doc(widget.channelID)
                            .update({
                          'description': _descriptionController.text,
                        }).then((_) {
                          setState(() {
                            _isEditingDescription = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Descripción guardada')));
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al guardar la descripción')));
                        });
                      }
                    : null,
                child: Text('Guardar Descripción'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditingDescription = true;
                  });
                },
                child: Text('Editar Descripción'),
              ),
            ],
          ),
          Divider(),
          SizedBox(height: 16),
          Text(
            'Miembros del Grupo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          for (var memberId in _chatMembers)
            ListTile(
              leading: CircleAvatar(
                // Puedes mostrar avatares de usuario aquí
                child: Text(_userNames[memberId]?.substring(0, 1) ?? ''),
              ),
              title: Text(_userNames[memberId] ?? 'Usuario Desconocido'),
              subtitle: Text(memberId == currentUserID ? 'Tú' : ''),
              trailing: memberId == currentUserID
                  ? ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Salir del Grupo'),
                              content: Text(
                                '¿Estás seguro de que deseas salir del grupo?',
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
                      child: Text('Salir'),
                    )
                  : IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        _removeUserFromChat(memberId);
                      },
                    ),
            ),
        ],
      ),
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

  void _showSearchDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Buscar Mensajes'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchQueryController,
              decoration: InputDecoration(hintText: 'Ingrese su búsqueda'),
            ),
            SizedBox(height: 16), // Add spacing between the search field and results
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults[index]),
                    // Other ListTile properties as needed
                  );
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
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _performSearch(_searchQueryController.text);
              Navigator.pop(context);
            },
            child: Text('Buscar'),
          ),
        ],
      );
    },
  );
}


void _performSearch(String query) {
  List<String> filteredMessages = _chatMessages.where((message) =>
      message.toLowerCase().contains(query.toLowerCase())).toList();

  setState(() {
    _searchResults = filteredMessages; // Update search results
  });
}


   
}