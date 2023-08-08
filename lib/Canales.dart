import 'package:chatvenenoso/screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/Uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatvenenoso/screens/config_screen.dart';
import 'Chatscreen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';
import 'package:chatvenenoso/CanalesArchivados.dart';

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
  List<String> userArchivedChannels =
      []; // Lista de canales archivados por el usuario
  @override
  void initState() {
    super.initState();
    currentUserUID = _auth.currentUser!.uid;
    _getUserArchivedChannels();
  }

  Future<void> _showArchiveConfirmationDialog(String channelID) async {
    bool archiveChat = false; // Variable para almacenar la opción seleccionada

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Archivar Chat'),
          content: Text('¿Deseas archivar este chat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // No archivar
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Archivar
              },
              child: Text('Sí'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value is bool) {
        archiveChat = value;
        if (archiveChat) {
          _archiveChannel(channelID); // Archivar el chat si el usuario aceptó
          // Actualizar la lista de canales aquí
          setState(() {
            userArchivedChannels.add(channelID);
          });
        }
      }
    });
  }

  Future<void> _getUserArchivedChannels() async {
    final currentUserDoc =
        _firestore.collection('usuarios').doc(currentUserUID);

    final userSnapshot = await currentUserDoc.get();
    if (userSnapshot.exists) {
      final archivedChannels =
          userSnapshot.get('chatsarchivados') as List<dynamic>?;

      if (archivedChannels != null) {
        setState(() {
          userArchivedChannels = List<String>.from(archivedChannels);
        });
      }
    }
  }

  Future<void> _archiveChannel(String channelID) async {
    final currentUserDoc =
        _firestore.collection('usuarios').doc(currentUserUID);

    // Agregar el canal a la lista de canales archivados del usuario
    userArchivedChannels.add(channelID);

    // Actualizar la lista de canales archivados del usuario en Firestore
    await currentUserDoc.update({
      'chatsarchivados': FieldValue.arrayUnion(userArchivedChannels),
    });
  }

  Future<String> getLastMessage(String channelID) async {
    print(
        "Getting last message for channel: $channelID"); // Imprime el mensaje de depuración

    final querySnapshot = await _firestore
        .collection('messages')
        .doc(channelID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastMessage = querySnapshot.docs.first.get('text');
      print(
          "Last message for channel $channelID: $lastMessage"); // Imprime el último mensaje obtenido
      return lastMessage;
    } else {
      print("No messages for channel $channelID"); // Imprime si no hay mensajes
      return 'Sin mensajes';
    }
  }

  Future<String> getLastMessageTime(String channelID) async {
    print("Getting last message time for channel: $channelID");

    final querySnapshot = await _firestore
        .collection('messages')
        .doc(channelID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastMessageDoc = querySnapshot.docs.first;
      final timestamp = lastMessageDoc.get('timestamp');

      final time =
          DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      final formattedTime = DateFormat.jm().format(time);
      print("Last message time for channel $channelID: $formattedTime");
      return formattedTime;
    } else {
      print("No messages for channel $channelID");
      return '10:30 AM';
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
                delegate: ChatSearchDelegate(),
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
              } else if (value == 'archived_chats') {
                _openArchivedChannelsScreen();
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
              final isChannelArchived =
                  userArchivedChannels.contains(channelID);
              if (!isChannelArchived) {
                final channelWidget = InkWell(
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
                  onLongPress: () {
                    _showArchiveConfirmationDialog(
                        channelID); // Mostrar cuadro emergente de archivar
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
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
                              FutureBuilder<String>(
                                future: getLastMessageTime(channelID),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text(
                                      'Cargando...',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey,
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text(
                                      'Error al obtener la hora del mensaje',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey,
                                      ),
                                    );
                                  } else {
                                    final lastMessageTime =
                                        snapshot.data ?? '----';
                                    return Text(
                                      lastMessageTime,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                channelWidgets.add(channelWidget);
              }
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

  void _openArchivedChannelsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArchivedChannelsScreen(), // Navegar a la pantalla de canales archivados
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get searchFieldLabel => 'Buscar chat';
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
        close(context, ''); // Cierra la búsqueda y vuelve al estado anterior
      },
    );
  }

  Future<String> getLastMessage(String channelID) async {
    print(
        "Getting last message for channel: $channelID"); // Imprime el mensaje de depuración

    final querySnapshot = await _firestore
        .collection('messages')
        .doc(channelID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastMessageDoc = querySnapshot.docs.first;
      final timestamp = lastMessageDoc.get('timestamp');

      final time =
          DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      final formattedTime = DateFormat.jm().format(time);
      print("Last message time for channel $channelID: $formattedTime");
      return formattedTime;
    } else {
      print("No messages for channel $channelID");
      return '10:30 AM';
    }
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('channels') // Cambia aquí a la colección 'channels'
          .where('name',
              isGreaterThanOrEqualTo:
                  query) // Realiza la búsqueda utilizando la consulta
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar los resultados'),
          );
        } else {
          final channels = snapshot.data!.docs;
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final channelName = channel.get('name');
              final channelID = channel.id;
              return GestureDetector(
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
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
                            FutureBuilder<String>(
                              future: getLastMessageTime(channelID),
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
                                    'Error al obtener la hora del mensaje',
                                    style: TextStyle(
                                        fontSize: 14.0, color: Colors.grey),
                                  );
                                } else {
                                  final lastMessageTime =
                                      snapshot.data ?? '10:30 AM';
                                  return Text(
                                    lastMessageTime,
                                    style: TextStyle(
                                        fontSize: 14.0, color: Colors.grey),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Mostrar sugerencias mientras el usuario escribe
    return Text('Sugerencias de búsqueda para: $query');
  }

  Future<String> getLastMessageTime(String channelID) async {
    print("Getting last message time for channel: $channelID");

    final querySnapshot = await _firestore
        .collection('messages')
        .doc(channelID)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastMessageDoc = querySnapshot.docs.first;
      final timestamp = lastMessageDoc.get('timestamp');

      final time =
          DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
      final formattedTime = DateFormat.jm().format(time);
      print("Last message time for channel $channelID: $formattedTime");
      return formattedTime;
    } else {
      print("No messages for channel $channelID");
      return '10:30 AM';
    }
  }
}
