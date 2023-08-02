import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/Uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';


import 'Chatscreen.dart';

class ChannelListScreen extends StatefulWidget {
  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newChannelController = TextEditingController();

  late String currentUserUID;

  @override
  void initState() {
    super.initState();
    currentUserUID = _auth.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPPE Chat'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Nuevo Chat'),
                value: 'add_channel',
              ),
              PopupMenuItem(
                child: Text('Cerrar Sesión'),
                value: 'sign_out',
              ),
            ],
            onSelected: (value) {
              if (value == 'add_channel') {
                _showAddChannelDialog();
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
                          'https://example.com/' + channelID,
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channelName,
                              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6.0),
                            Text(
                              'Último mensaje',
                              style: TextStyle(fontSize: 14.0, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  void _showPopupMenu() {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final relativePosition = RelativeRect.fromLTRB(1000, 80, 0, 0);

    showMenu<String>(
      context: context,
      position: relativePosition,
      items: [
        PopupMenuItem(
          child: Text('Nuevo Chat'),
          value: 'add_channel',
        ),
        PopupMenuItem(
          child: Text('Chats archivados'),
          value: 'archived_chats',
        ),
        PopupMenuItem(
          child: Text('Configuración'),
          value: 'settings',
        ),
        PopupMenuItem(
          child: Text('Cerrar Sesión'),
          value: 'sign_out',
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
    ).then((value) {
      if (value == 'yes') {
        Navigator.pop(context);
      }
    });
  }
}
