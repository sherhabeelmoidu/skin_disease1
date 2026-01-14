import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skin_disease1/chat_room.dart';
import 'package:intl/intl.dart';

class ChatList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Messages', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('No conversations yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Find the peer user
              final users = List<String>.from(data['users']);
              final peerId = users.firstWhere((id) => id != currentUserId);
              final peerNames = data['peerNames'] as Map<String, dynamic>?;
              final peerName = peerNames?[peerId] ?? 'Doctor';

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1),
                    child: Text(peerName[0].toUpperCase(), style: TextStyle(color: Color(0xFF3B9AE1), fontWeight: FontWeight.bold)),
                  ),
                  title: Text(peerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    data['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    data['lastTimestamp'] != null 
                      ? _formatTimestamp(data['lastTimestamp'] as Timestamp)
                      : '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoom(peerId: peerId, peerName: peerName),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    if (DateTime(now.year, now.month, now.day) == DateTime(date.year, date.month, date.day)) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }
}
