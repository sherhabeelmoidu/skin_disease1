import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorApprovals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .where('role', isEqualTo: 'doctor')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green.withOpacity(0.5)),
                SizedBox(height: 16),
                Text('No pending doctor approvals', style: TextStyle(color: Color(0xFF7F8C8D))),
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
            return _buildApprovalCard(context, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1),
                child: Text(data['name'][0].toUpperCase(), style: TextStyle(color: Color(0xFF3B9AE1), fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(data['email'], style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('ID Proof / License:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          SizedBox(height: 8),
          if (data['idProofUrl'] != null)
            GestureDetector(
              onTap: () => _showFullImage(context, data['idProofUrl']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['idProofUrl'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Text('No ID proof uploaded', style: TextStyle(color: Colors.red, fontSize: 12)),
          
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(docId, 'rejected'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red)),
                  child: Text('Reject'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(docId, 'approved'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Image.network(url),
                IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('user').doc(docId).update({'status': status});
  }
}
