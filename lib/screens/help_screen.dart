import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayuda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              'Preguntas Frecuentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              title: Text('¿Cómo cambiar mi foto de perfil?'),
              subtitle: Text('Aprende a personalizar tu imagen de perfil.'),
              onTap: () {
                // Acción al presionar una pregunta frecuente
              },
            ),
            Divider(),
            ListTile(
              title: Text('¿Cómo enviar un mensaje?'),
              subtitle: Text('Descubre cómo enviar mensajes a tus contactos.'),
              onTap: () {
                // Acción al presionar una pregunta frecuente
              },
            ),
            Divider(),
            // Agrega más preguntas frecuentes aquí
          ],
        ),
      ),
    );
  }
}
