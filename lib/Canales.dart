import 'package:chatvenenoso/Chatscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelListScreen extends StatefulWidget {
  @override
  _ChannelListScreenState createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newChannelController = TextEditingController();

  late String currentUserUID; // Definimos la variable currentUserUID

  @override
  void initState() {
    super.initState();
    currentUserUID =
        _auth.currentUser!.uid; // Obtenemos el UID del usuario actual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Canales'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddChannelDialog(); // Mostrar el cuadro de diálogo para agregar un nuevo canal
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
            final authorizedUsers = List.from(channel.get('authorized_users'));

            // Verificamos si el UID del usuario actual está en la lista de usuarios autorizados
            if (authorizedUsers.contains(currentUserUID)) {
              final channelWidget = ListTile(
                title: Text(channelName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(channel: channelName),
                    ),
                  );
                },
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

  void _showAddChannelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Nuevo Canal'),
          content: TextField(
            controller: _newChannelController,
            decoration: InputDecoration(hintText: 'Nombre del Canal'),
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
                _addNewChannel(); // Agregar el nuevo canal a Firestore
                Navigator.pop(context); // Cerrar el cuadro de diálogo
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
      // Obtener la referencia de la colección 'channels'
      final channelsRef = _firestore.collection('channels');

      // Consultar si ya existe un canal con el mismo nombre
      channelsRef
          .where('name', isEqualTo: newChannelName)
          .get()
          .then((querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          // Si no existe, agregar el nuevo canal a Firestore
          channelsRef.add({
            'name': newChannelName,
            'authorized_users': [currentUserUID],
          });
          _newChannelController.clear();
        } else {
          // Si ya existe, mostrar un mensaje o realizar alguna acción apropiada
          print('El canal ya existe');
        }
      }).catchError((error) {
        print('Error al agregar el canal: $error');
      });
    }
  }
}
