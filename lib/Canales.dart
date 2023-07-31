import 'package:flutter/material.dart';
import 'package:chatvenenoso/Chatscreen.dart';

class ChannelListScreen extends StatelessWidget {
  final List<String> channels = [
    'general',
    'random',
    'tech',
    'news'
  ]; // Lista de canales disponibles

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Canales'),
      ),
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(channels[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(channel: channels[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
