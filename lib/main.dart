import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Chat page
import 'chat_page.dart';
import 'login_page.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference usersRef = firestore.collection('Users');
FirebaseAuth auth = FirebaseAuth.instance;
String? currentUserID;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  auth.authStateChanges().listen((User? user) {
    if(user == null) {
      try {
        print('Utilisateur non connecté');
        runApp(const LoginTabBar());
      } catch(e) {
        print(e.toString());
      }
    } else {
      print('Utlisateur connecté' + user.email!);
      runApp(const MyApp());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: ()=> auth.signOut(),
          )
        ]
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
        return SizedBox(
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
              Text(_userID, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class GetUserData extends StatelessWidget {
  const GetUserData({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    CollectionReference users = firestore.collection('Users');
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(currentUserID).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Un problème est survenu');
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> document =
          snapshot.data!.data() as Map<String, dynamic>;
          return Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(document['photoUrl']),
              ),
              const SizedBox(width: 20),
              Text(document['pseudo']),
            ],
          );
        }
        return const Text('En cours de chargement');
      },
    );
  }
}

class GetLastMessage extends StatelessWidget {
  final String otherUserID;
  const GetLastMessage(this.otherUserID, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    CollectionReference users = firestore.collection('Users');
    return FutureBuilder<DocumentSnapshot>(
      future: users
          .doc(currentUserID)
          .collection('Messages')
          .doc(otherUserID)
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Un problème est survenu');
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Text("Aucun message");
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> document =
          snapshot.data!.data() as Map<String, dynamic>;
          return Text(document['lastMessage'],
              style: const TextStyle(fontSize: 17));
        }
        return const Text(
          'Chargement',
          style: TextStyle(fontSize: 17, color: Colors.grey),
        );
      },
    );
  }
}

refreshPage(context) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MyApp(),
      transitionDuration: const Duration(seconds: 0),
    ),
  );
}


