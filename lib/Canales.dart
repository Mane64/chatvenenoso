import 'package:chatvenenoso/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/Uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatvenenoso/screens/config_screen.dart';
import 'Chatscreen.dart';

class ChannelListScreen extends StatefulWidget {
  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
  
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newChannelController = TextEditingController();
  final TextEditingController _searchController =
   TextEditingController(); // New controller for search
   Map<String, String> lastMessages = {};


  late String currentUserUID;

  @override
  void initState() {
    super.initState();
    currentUserUID = _auth.currentUser!.uid;
  }
    Future<String> getLastMessage(String channelID) async {
   print("Getting last message for channel: $channelID"); // Imprime el mensaje de depuración

  final querySnapshot = await _firestore
      .collection('channels')
      .doc(channelID)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    final lastMessage = querySnapshot.docs.first.get('text');
    print("Last message for channel $channelID: $lastMessage"); // Imprime el último mensaje obtenido
    return lastMessage;
  } else {
    print("No messages for channel $channelID"); // Imprime si no hay mensajes
    return 'Sin mensajes';
  }
}






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPP VIBORE SA. DE CV.'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ChatSearchDelegate(), // Implement this delegate class
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Nuevo Chat'),
                value: 'add_channel',
              ),
              PopupMenuItem(
                child: Text('Chats archivados'),
                value: 'archived_chats',
              ),
              PopupMenuItem(
                child: Text('Configuracion'),
                value: 'settings',
              ),
              PopupMenuItem(
                child: Text('Cerrar Sesión'),
                value: 'sign_out',
              ),
            ],
            onSelected: (value) {
              if (value == 'add_channel') {
                _showAddChannelDialog();
              } else if (value == 'settings') {
                _openConfiguracionScreen();
              } else if (value == 'sign_out') {
                _signOut();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('channels').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final channels = snapshot.data!.docs;
          List<Widget> channelWidgets = [];
          for (var channel in channels) {
            final channelName = channel.get('name');
            final channelID = channel.id;
              if (channel.get('authorized_users').contains(currentUserUID)) {
                final channelWidget = GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          channel: channelName,
                          channelID: channelID,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: CachedNetworkImageProvider(
                            'assets/chat-icon.jpg',
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                channelName,
                                style: TextStyle(
                                    fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6.0),
                              FutureBuilder<String>(
                                future: getLastMessage(channelID),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      'Cargando...',
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.grey),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text(
                                      'Error al obtener el último mensaje',
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.grey),
                                    );
                                  } else {
                                    final lastMessage =
                                        snapshot.data ?? 'Sin mensajes';
                                    return Text(
                                      lastMessage,
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Text(
                          '10:30 AM',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
                channelWidgets.add(channelWidget);
              }
          }
          return ListView(
            children: channelWidgets,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPopupMenu();
        },
        child: Icon(Icons.chat),
      ),
    );
  }

  void _openConfiguracionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ConfiguracionScreen()), // Navegar a la pantalla de configuración
    );
  }

  void _showPopupMenu() {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final relativePosition = RelativeRect.fromLTRB(1000, 80, 0, 0);

    showMenu<String>(
      context: context,
      position: relativePosition,
      items: [
        PopupMenuItem(
          child: Text('Nuevo Chat'),
          value: 'add_channel',
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value == 'add_channel') {
        _showAddChannelDialog();
      } else if (value == 'sign_out') {
        _signOut();
      }
    });
  }

  void _showAddChannelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nuevo Chat'),
          content: TextField(
            controller: _newChannelController,
            decoration: InputDecoration(hintText: 'Nombre del Canal'),
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
                _addNewChannel();
                Navigator.pop(context);
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _addNewChannel() {
    final newChannelName = _newChannelController.text.trim();
    if (newChannelName.isNotEmpty) {
      final channelID = Uuid().v4();

      _firestore.collection('channels').doc(channelID).set({
        'name': newChannelName,
        'authorized_users': [currentUserUID],
      });

      _newChannelController.clear();
    }
  }

  void _signOut() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'no');
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context, 'yes');
              },
              child: Text('Sí'),
            ),
          ],
        );
      },
    ).then((value) async {
      if (value == 'yes') {
        await _auth.signOut(); // Cerrar sesión nuevamente para asegurarse
        Navigator.pushReplacement(
          // Navegar a la pantalla de inicio de sesión
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      }
    });
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Buscar chat';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // Cerrar la búsqueda y volver al estado anterior
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implementar la lógica de búsqueda y mostrar resultados
    return Text('Resultados de búsqueda para: $query');
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Mostrar sugerencias mientras el usuario escribe
    return Text('Sugerencias de búsqueda para: $query');
  }
}
