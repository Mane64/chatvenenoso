import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConfiguracionScreen extends StatefulWidget {
  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesActivadas = true;
  bool _guardarAutomaticamente = false;

  late User _currentUser;
  String _currentUserName = '';
  String _currentUserEmail = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getUserName();
  }

  void _getUserName() async {
    final currentUserUID = _currentUser.uid;
    final userSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUserUID)
        .get();
    setState(() {
      _currentUserName = userSnapshot['nombre'];
      _currentUserEmail = userSnapshot['email'];
      _nameController.text =
          _currentUserName; // Actualizar el texto del controlador
    });
  }

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
        _currentUserName.isNotEmpty ? _currentUserName : 'Nombre de Usuario',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text('Estado en línea'),
      trailing: Icon(Icons.edit), // Icono para editar perfil
      onTap: () {
        _showEditProfileDialog(); // Mostrar el cuadro de diálogo para editar el perfil
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
      title: Text('Cambiar contraseña'),
      onTap: () {
        _showChangePasswordDialog(); // Mostrar el cuadro de diálogo para cambiar la contraseña
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

  void _showEditProfileDialog() {
    // Obtener los valores actuales del usuario
    _nameController.text = _currentUserName;
    _emailController.text = _currentUserEmail;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                ),
              ),
            ],
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
                _updateProfile(); // Actualizar el perfil
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cambiar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña Anterior',
                ),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                ),
                obscureText: true,
              ),
            ],
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
                _updatePassword(); // Actualizar la contraseña
                Navigator.pop(context); // Cerrar el cuadro de diálogo
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _updateProfile() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Validar que los campos no estén vacíos
    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    // Actualizar el usuario actual en FirebaseAuth
    try {
      await _currentUser?.updateEmail(newEmail);
      await _currentUser?.updateDisplayName(newName);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('YA EXISTE ESE CORREO USA OTRO')),
      );
      return;
    }

    // Realizar la actualización del perfil en Firestore
    final currentUserUID = _currentUser.uid;
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUserUID)
        .update({
      'nombre': newName,
      'email': newEmail,
    });

    // Actualizar la información mostrada en la pantalla
    setState(() {
      _currentUserName = newName;
      _currentUserEmail = newEmail;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Perfil actualizado correctamente')),
    );
  }

  void _updatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    // Validar que los campos no estén vacíos y que la nueva contraseña tenga al menos 6 caracteres
    if (oldPassword.isEmpty || newPassword.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Por favor, completa todos los campos y asegúrate de que la nueva contraseña tenga al menos 6 caracteres')),
      );
      return;
    }

    // Validar que la contraseña anterior coincida
    if (_currentUser.email != null) {
      final email = _currentUser.email!;
      final credentials =
          EmailAuthProvider.credential(email: email, password: oldPassword);
      try {
        await _currentUser.reauthenticateWithCredential(credentials);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La contraseña anterior es incorrecta')),
        );
        return;
      }
    } else {
      // Manejar el caso en el que el email sea nulo (por ejemplo, mostrar un mensaje de error)
    }

    // Actualizar la contraseña en FirebaseAuth
    try {
      await _currentUser.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contraseña actualizada correctamente')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la contraseña')),
      );
    }
  }
}
