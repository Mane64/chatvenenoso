import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ConfiguracionScreen extends StatefulWidget {
  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesActivadas = true;
  bool _guardarAutomaticamente = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración'),
      ),
      body: ListView(
        children: [
          _buildHeader(),
          Divider(),
          _buildNotificaciones(),
          Divider(),
          _buildGuardarAutomaticamente(),
          Divider(),
          _buildOpcionesChat(),
          Divider(),
          _buildCuenta(),
          Divider(),
          _buildAyuda(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ListTile(
      leading: CircleAvatar(
        // Agrega la imagen del perfil aquí
        radius: 25,
        backgroundColor: Colors.grey, // Puedes cambiar el color de fondo
      ),
      title: Text(
        'Nombre de Usuario',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Estado en línea'),
      trailing: Icon(Icons.edit), // Icono para editar perfil
      onTap: () {
        // Acción cuando se toca el encabezado del perfil
      },
    );
  }

   Widget _buildNotificaciones() {
    return ListTile(
      title: Text('Notificaciones'),
      trailing: Switch(
        value: _notificacionesActivadas,
        onChanged: (value) {
          setState(() {
            _notificacionesActivadas = value;
          });
        },
      ),
    );
  }

  Widget _buildGuardarAutomaticamente() {
    return ListTile(
      title: Text('Guardar automáticamente en la galería'),
      trailing: Switch(
        value: _guardarAutomaticamente,
        onChanged: (value) {
          setState(() {
            _guardarAutomaticamente = value;
          });
        },
      ),
    );
  }

  Widget _buildOpcionesChat() {
    return ListTile(
      title: Text('Opciones de Chat'),
      onTap: () {
        // Acción cuando se toca la opción de chat
      },
    );
  }

  Widget _buildCuenta() {
    return ListTile(
      title: Text('Cuenta'),
      onTap: () {
        // Acción cuando se toca la opción de cuenta
      },
    );
  }

  Widget _buildAyuda() {
    return ListTile(
      title: Text('Ayuda'),
      onTap: () {
        // Acción cuando se toca la opción de ayuda
      },
    );
  }

  // Agrega más métodos _build para las otras secciones de ajustes

}
