import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersRef = firestore.collection('Users');
FirebaseAuth auth = FirebaseAuth.instance;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  getUserID();
  runApp(const MyApp());
}

getUserID() {
  auth.authStateChanges().listen((User? user) {
    if(user == null) {
      try {
        print('Utilisateur non connecté');
        auth.signInWithEmailAndPassword(
          email: 'elon@me.com', password: 'lololol');
      } catch(e) {
        print(e.toString());
      }
    } else {
      print('Utlisateur connecté' + user.email!);
    }
  });
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
      body: const SingleChildScrollView(
        child: ListSection(),
      ),
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
  // Ajouter un utlisateur
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

class ListSection extends StatefulWidget {
  const ListSection({Key? key}) : super(key: key);

  @override
  _ListSectionState createState() => _ListSectionState();
}

class _ListSectionState extends State<ListSection> {
  late List<DocumentSnapshot> _docs;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: usersRef.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        _docs = snapshot.data!.docs;
        if(_docs == null) return const Center(child: Text('Aucun contact!'));
        return Container(
          child: Column(
            children: _docs.map((document) {
              return InkWell(
                onTap: () => openChat(
                  document.id, document['pseudo'], document['photoUrl']
                ),
                child: UserLineDesign(document.id, document['pseudo'], document['photoUrl'])
              );
            }).toList(),
          )
        );
      },
    );
  }
  void openChat(String userID, String userName, String userPhoto) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ChatPage(userID, userName, userPhoto)),
    );
  }
}

//Design list contact
class UserLineDesign extends StatelessWidget {
  final String _userID;
  final String _pseudo;
  final String _photoUrl;
  const UserLineDesign(this._userID, this._pseudo, this._photoUrl, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 10, 10, 10),
      child: Row(
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircleAvatar(
              backgroundImage: NetworkImage(_photoUrl),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_pseudo,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(_userID, style: const TextStyle(fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final otherUserID;
  final otherUserName;
  final otherUserPhoto;
  const ChatPage(
      String this.otherUserID, this.otherUserName, this.otherUserPhoto,
      {Key? key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    print(otherUserID);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(otherUserPhoto),
            ),
            const SizedBox(width: 20),
            Text(
              otherUserName,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.grey[100],
      ),
    );
  }
}