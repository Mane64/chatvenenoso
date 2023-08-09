import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ArchivedChannelsScreen extends StatefulWidget {
  @override
  _ArchivedChannelsScreenState createState() => _ArchivedChannelsScreenState();
}

class _ArchivedChannelsScreenState extends State<ArchivedChannelsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String currentUserUID;
  List<String> userArchivedChannels =
      []; // Lista de canales archivados por el usuario

  @override
  void initState() {
    super.initState();
    currentUserUID = _auth.currentUser!.uid;
    _getUserArchivedChannels(); // Obtener los canales archivados del usuario al cargar la pantalla
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
   Future<void> _unarchiveChannel(String channelID) async {
        final currentUserDoc = _firestore.collection('usuarios').doc(currentUserUID);
        userArchivedChannels.remove(channelID);
        await currentUserDoc.update({
       'chatsarchivados': FieldValue.arrayRemove([channelID]),});
        setState(() {
          userArchivedChannels = List<String>.from(userArchivedChannels);
        });
       
      }

     Future<void> _showDeleteConfirmationDialog(String channelID) async {
     return showDialog<void>(
      context: context,
      barrierDismissible: false, // Evita que el usuario cierre el diálogo haciendo clic fuera de él
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Chat'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Desea eliminar este chat de chats archivados?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: Text('Sí'),
              onPressed: () {
                _unarchiveChannel(channelID); // Llamar al método para desarchivar el canal
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canales Archivados'),
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
            if (userArchivedChannels.contains(channelID)) {
              final channelWidget = InkWell(
              onLongPress: () {
                _showDeleteConfirmationDialog(channelID); // Mostrar el diálogo de confirmación al dejar presionado
              },
                child: ListTile(
                  title: Text(channelName),
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      'assets/chat-icon.jpg',
                    ),
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
    );
  }
}
