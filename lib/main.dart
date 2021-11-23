import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersRef = firestore.collection('Users');

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  final pseudoField = TextEditingController();
  final photoField = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Chat'),
      ),
      body: Container(),
        floatingActionButton: FloatingActionButton(
          onPressed: ()=> _showOptions(context),
          child: const Icon(Icons.add),
        )
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 260,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Ajouter un utilisateur'),
              TextField(
                controller: pseudoField,
                decoration: const InputDecoration(
                  hintText: 'Pseudo',
                ),
              ),
              TextField(
                controller: photoField,
                decoration: const InputDecoration(
                  hintText: 'Photo de profil',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent.shade400,
                  ),
                  child: const Text('Ajouter'),
                  onPressed: () => addUser(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void addUser(context) {
    try {
      usersRef.add({
        "pseudo": pseudoField.text,
        "photoUrl": photoField.text,
      }).then((value) {
        print(value.id);
        pseudoField.clear();
        photoField.clear();
        Navigator.pop(context);
      });
    } catch (error) {
      print(error.toString());
    }
  }
}