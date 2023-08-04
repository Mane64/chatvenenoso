import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

final FirebaseStorage storage = FirebaseStorage.instance;

Future<bool> uploadImage() async {
  FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles();

  if (result != null) {
    PlatformFile file = result.files.single;

    final String namefile = file.name;
    Reference ref = storage.ref().child("images").child(namefile);

    final UploadTask uploadTask = ref.putData(file.bytes!);
    final TaskSnapshot snapshot = await uploadTask.whenComplete(() => true);

    final String url = await snapshot.ref.getDownloadURL();
    print(url);

    return true;
  } else {
    // El usuario canceló la selección de archivo
    return false;
  }
}
