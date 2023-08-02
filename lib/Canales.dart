import 'package:chatvenenoso/Chatscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/Uuid.dart'; // Importar el paquete uuid

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
        title: Text('UPPE Chat'),
        automaticallyImplyLeading: false, // Eliminar el botón de regresar
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showPopupMenu(); // Mostrar el menú de opciones
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
            final channelID = channel.id; // Obtener el ID del canal

            // Verificamos si el UID del usuario actual está en la lista de usuarios autorizados
            if (channel.get('authorized_users').contains(currentUserUID)) {
              final channelWidget = ListTile(
                title: Text(channelName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        channel: channelName,
                        channelID:
                            channelID, // Pasar el channelID a la pantalla de chat
                      ),
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

  void _showPopupMenu() {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final relativePosition = RelativeRect.fromLTRB(1000, 80, 0, 0); // Posición relativa para mostrar el menú

    // Mostrar el menú de opciones
    showMenu<String>(
      context: context,
      position: relativePosition,
      items: [
        PopupMenuItem(
          child: Text('Agregar Nuevo Canal'),
          value: 'add_channel',
        ),
        PopupMenuItem(
          child: Text('Cerrar Sesión'),
          value: 'sign_out',
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      // Procesar la opción seleccionada del menú
      if (value == 'add_channel') {
        _showAddChannelDialog(); // Mostrar el cuadro de diálogo para agregar un nuevo canal
      } else if (value == 'sign_out') {
        _signOut(); // Cerrar sesión actual
      }
    });
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
      final channelID = Uuid().v4(); // Obtener un channelID único con uuid

      // Agregar el nuevo canal a Firestore con el channelID generado
      _firestore.collection('channels').doc(channelID).set({
        'name': newChannelName,
        'authorized_users': [currentUserUID],
      });

      _newChannelController.clear();
    }
  }

  void _signOut() async {
    // Mostrar el cuadro de diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cerrar Sesión'),
          content: Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'no'); // Cerrar el cuadro de diálogo con respuesta 'no'
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context, 'yes'); // Cerrar el cuadro de diálogo con respuesta 'sí'
              },
              child: Text('Sí'),
            ),
          ],
        );
      },
    ).then((value) {
      // Obtener la respuesta del cuadro de diálogo
      if (value == 'yes') {
        Navigator.pop(context); // Cerrar la pantalla de lista de canales y volver a la pantalla de inicio de sesión
      }
    });
  }
}
