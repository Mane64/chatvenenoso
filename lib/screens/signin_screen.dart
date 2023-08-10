import 'package:chatvenenoso/reusable_widgets/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatvenenoso/screens/reset_password.dart';
import 'package:chatvenenoso/screens/signinup_screen.dart';
import 'package:chatvenenoso/utils/color_utils.dart';
import 'package:chatvenenoso/Canales.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool _isPasswordVisible =
      false; // Variable para mostrar u ocultar la contraseña

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget("assets/LOGOUPPECOLOR.png"),
                const SizedBox(
                  height: 30,
                ),
                reusableTextField("Ingresa tu correo", Icons.person_outline,
                    false, _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    reusableTextField(
                        "Ingresa la contraseña",
                        Icons.lock_outline,
                        !_isPasswordVisible,
                        _passwordTextController),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible =
                              !_isPasswordVisible; // Cambiar el estado para mostrar u ocultar la contraseña
                        });
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                forgetPassword(context),
                firebaseUIButton(
                    context, "Ingresar", _signInUser), // Modificación aquí
                signUpOption()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("¿No tienes cuenta?",
            style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration(milliseconds: 500),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                  return SignUpScreen();
                },
              ),
            );
          },
          child: const Text(
            " Crea una",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget forgetPassword(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 35,
      alignment: Alignment.bottomRight,
      child: TextButton(
        child: const Text(
          "¿Haz olvidado la contraseña?",
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.right,
        ),
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 500),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
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
                return ResetPassword(); //ddddddddd
              },
            ),
          );
        },
      ),
    );
  }

  void _signInUser() {
    final email = _emailTextController.text.trim();
    final password = _passwordTextController.text;

    if (email.isEmpty || password.isEmpty) {
      // Mostrar mensaje de error si algún campo está vacío
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error de Inicio de Sesión'),
          content:
              Text('Debes rellenar todos los campos con tus credenciales.'),
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
      return; // Detener el inicio de sesión si algún campo está vacío
    }

    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .then((value) {
      Navigator.push(
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
            return ChannelListScreen();
          },
        ),
      );
    }).onError((error, stackTrace) {
      // Mostrar mensaje de error si el inicio de sesión falla
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error de Inicio de Sesión'),
          content: Text(
              'Hubo un error al iniciar sesión. Verifica tus credenciales e intenta nuevamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    });
  }
}
