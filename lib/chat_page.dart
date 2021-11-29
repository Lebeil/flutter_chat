import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;
CollectionReference chatRef = firestore.collection('chat');
FirebaseAuth auth = FirebaseAuth.instance;
String currentUserID = auth.currentUser!.uid;

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
      bottomNavigationBar: MessageField(otherUserID),
    );
  }
}

class MessageField extends StatelessWidget {
  final String otherUserID;
  final textField = TextEditingController();
  MessageField(this.otherUserID, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
      child: BottomAppBar(
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.camera_alt), onPressed: (){},),
              IconButton(icon: const Icon(Icons.image), onPressed: (){},),
              IconButton(icon: const Icon(Icons.voice_chat), onPressed: (){},),
              Expanded(
                child: TextField(
                  controller: textField,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Entrez votre message',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: ()=> sendMessage(),
              )
            ]
          )
        ),
      ),
    );
  }

  void sendMessage() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd - kk:mm:ss').format(now);
    try {
      chatRef.doc(currentUserID).collection(otherUserID).add({
        "text": textField.text,
        "userID": currentUserID,
        "date": formattedDate,
      }).then((value) {
        chatRef.doc(otherUserID).collection(currentUserID).add({
          "text": textField.text,
          "userID": currentUserID,
          "date": formattedDate,
        }).then((value) {
          textField.clear();
        });
      });
    } catch (e) {
      print(e.toString());
    }
  }

}
