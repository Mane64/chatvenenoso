import 'package:chatvenenoso/reusable_widgets/reusable_widgets.dart';
import 'package:chatvenenoso/utils/color_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController _emailTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Restablecer contraseña",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
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
                const SizedBox(
                  height: 20,
                ),
                reusableTextField(
                  "Ingresa tu correo",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                ),
                const SizedBox(
                  height: 20,
                ),
                firebaseUIButton(context, "Restablecer contraseña", () {
                  final email = _emailTextController.text.trim();
                  if (email.isEmpty) {
                    // Mostrar mensaje si el campo de correo está vacío
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Campo Vacío'),
                        content: Text('Debes de rellenar el campo del correo.'),
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
                  } else {
                    // Enviar correo de restablecimiento si el campo no está vacío
                    FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email)
                        .then((value) => Navigator.of(context).pop());
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
