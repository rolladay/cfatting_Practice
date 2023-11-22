import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {

  final messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void submitMessage() async {
    final enteredMessage = messageController.text;

    if(enteredMessage.trim().isEmpty){
      return;
    }
    FocusScope.of(context).unfocus();


    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    FirebaseFirestore.instance.collection('Chat').add({
      'text' : enteredMessage,
      'createdAt' : Timestamp.now(),
      'userId' : user.uid,
      'userName' : userData.data()!['userName'] ,
      'userImage' : userData.data()!['image_url'],

    });



    //Send to FB
    messageController.clear();


  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 1,
        right: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              enableSuggestions: true,
              decoration: const InputDecoration(
                labelText: 'Send a message',
              ),
            ),
          ),
          IconButton(
            onPressed: submitMessage,
            icon: Icon(Icons.send),
          )
        ],
      ),
    );
  }
}
