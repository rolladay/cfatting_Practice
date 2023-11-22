import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychatapp/widgets/message_bubble.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {

    // final authenticatedUser = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Chat')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        //스냅샷이 스트림을 뱉어냄...
        builder: (ctx, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Message'),
            );
          }

          if (chatSnapshot.hasError) {
            return const Center(
              child: Text('ERROR'),
            );
          }

          final loadesMessages = chatSnapshot.data!.docs;

          return ListView.builder(
            reverse: true,
            padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
            itemCount: loadesMessages.length,
            itemBuilder: (ctx, index) {
              final chatMessage = loadesMessages[index].data();
              final nextMessage = index + 1 < loadesMessages.length
                  ? loadesMessages[index + 1].data()
                  : null;
              final currentMessageUserId = chatMessage['userId'];
              final nextMessageUserId =
                  nextMessage != null ? nextMessage['userId'] : null;
              final nextUserisSame = currentMessageUserId == nextMessageUserId;

              if (nextUserisSame) {
                return MessageBubble.next(
                    message: chatMessage['text'],
                    isMe: currentMessageUserId ==
                        FirebaseAuth.instance.currentUser!.uid);
              }
              return MessageBubble.first(
                  userImage: chatMessage['userImage'],
                  username: chatMessage['userName'],
                  message: chatMessage['text'],
                  isMe: currentMessageUserId ==
                      FirebaseAuth.instance.currentUser!.uid);
            },
          );
        });
    // 스타림 빌더라는건 이 스트림 파라메터에 변경이 있을때마다, 빌드 파라메터의 펑션을 실행한다고 보면됨
  }
}
