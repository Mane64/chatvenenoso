import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatvenenoso/screens/signin_screen.dart';
import 'package:chatvenenoso/reusable_widgets/reusable_widgets.dart';
import 'package:chatvenenoso/utils/color_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  bool _isPasswordVisible = false; // Variable para mostrar u ocultar la contraseña

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("#03D894"),
              hexStringToColor("#03BED8"),
              hexStringToColor("#0370D8"),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                reusableTextField(
                  "Ingresa un nombre de usuario",
                  Icons.person_outline,
                  false,
                  _userNameTextController,
                ),
                const SizedBox(height: 20),
                reusableTextField(
                  "Ingresa un correo",
                  Icons.email,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    reusableTextField("Ingresa una contraseña", Icons.lock_outlined, !_isPasswordVisible, _passwordTextController),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible; // Cambiar el estado para mostrar u ocultar la contraseña
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                firebaseUIButton(context, "Ingresar", _registerUser),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isValidEmail(String email) {
    // Expresión regular para validar el correo electrónico
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  void _registerUser() async {
    final email = _emailTextController.text.trim();
    final password = _passwordTextController.text.trim();
    final userName = _userNameTextController.text.trim();

    // Validar si algún campo está vacío
    if (userName.isEmpty || email.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Campos vacíos'),
          content: Text('Debes de rellenar todos los campos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return; // Detener el registro si algún campo está vacío
    }

    // Validar que la contraseña tenga al menos 6 caracteres
    if (password.length < 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error de Registro'),
          content: Text('La contraseña debe tener al menos 6 caracteres.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return; // Detener el registro si la contraseña es demasiado corta
    }

    // Validar si el correo electrónico es válido
    if (!isValidEmail(email)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error de Registro'),
          content: Text('Ingresa un correo electrónico válido.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return; // Detener el registro si el correo no es válido
    }

    try {
      // Validar si el correo electrónico ya está en uso por otra cuenta
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error de Registro'),
            content: Text('Este correo ya está en uso por otra cuenta.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
        return; // Detener el registro si el correo ya está en uso
      }

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener el UID del usuario recién registrado
      final newUserUID = userCredential.user!.uid;

      // Agregar los datos del usuario a la colección 'usuarios' en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(newUserUID)
          .set({
        'nombre': userName, // Agregar el nombre de usuario
        'email': email,
        'uid': newUserUID,
      });

      print("Created New Account");

      // Mostrar el cuadro de diálogo con el mensaje de cuenta creada
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cuenta Creada'),
          content: Text('¡La cuenta ha sido creada con éxito!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      var begin = Offset(1.0, 0.0);
                      var end = Offset.zero;
                      var tween = Tween(begin: begin, end: end);
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return SignInScreen();
                    },
                  ),
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('Error de registro: $e');
      // Mostrar mensaje de error si el registro falla
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error de Registro'),
          content: Text('Hubo un error al registrar la cuenta.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
