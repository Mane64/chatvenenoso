import 'dart:io';
import 'package:chatvenenoso/reusable_widgets/upload_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? imagen_to_upload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material App Bar'),
      ),
      body: Column(
        children: [
          imagen_to_upload != null
              ? Image.network(imagen_to_upload!
                  .path) // Mostrar la imagen desde la URL de la imagen local
              : Container(
                  margin: EdgeInsets.all(10),
                  height: 200,
                  width: double.infinity,
                  color: Colors.amber,
                ),
          ElevatedButton(
            onPressed: () async {
              final XFile? imagen = await _pickImage();

              setState(() {
                if (imagen != null) {
                  imagen_to_upload = File(imagen.path);
                }
              });
            },
            child: const Text("SELECCIONAR IMAGEN"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uploaded = await uploadImage();
              if (imagen_to_upload != null) {
              } else {
                return;
              }
            },
            child: const Text("SUBIR"),
          )
        ],
      ),
    );
  }

  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }
}
