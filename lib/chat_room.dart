import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatRoom extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatRoom({required this.peerId, required this.peerName});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late String chatId;

  String? currentUserName;

  @override
  void initState() {
    super.initState();
    // Unique chat ID based on two users
    List<String> ids = [currentUserId, widget.peerId];
    ids.sort();
    chatId = ids.join('_');
    _fetchCurrentUserName();
    _markAsRead();
  }

  void _fetchCurrentUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUserId)
        .get();
    if (doc.exists) {
      setState(() {
        currentUserName = (doc.data() as Map<String, dynamic>)['name'];
      });
    }
  }

  void _markAsRead() {
    // Optional: add unread counters logic here
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final timestamp = FieldValue.serverTimestamp();

    // Batch update for atomicity
    final batch = FirebaseFirestore.instance.batch();

    // 1. Add message
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': currentUserId,
      'receiverId': widget.peerId,
      'text': message,
      'timestamp': timestamp,
    });

    // 2. Update chat metadata
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'users': [currentUserId, widget.peerId],
      'peerNames': {
        currentUserId: currentUserName ?? 'User',
        widget.peerId: widget.peerName,
      },
      'lastMessage': message,
      'lastTimestamp': timestamp,
      'lastSenderId': currentUserId,
    }, SetOptions(merge: true));

    await batch.commit();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1),
              child: Text(
                widget.peerName[0].toUpperCase(),
                style: TextStyle(
                  color: Color(0xFF3B9AE1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              widget.peerName,
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    return _buildMessageBubble(
                      data['text'],
                      isMe,
                      data['timestamp'],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, dynamic timestamp) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFF3B9AE1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Color(0xFF2C3E50),
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              timestamp != null
                  ? DateFormat(
                      'hh:mm a',
                    ).format((timestamp as Timestamp).toDate())
                  : '...',
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                backgroundColor: Color(0xFF3B9AE1),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
