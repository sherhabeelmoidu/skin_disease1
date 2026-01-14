import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
  }) async {
    try {
      await _firestore
          .collection('user')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<void> broadcastNotification({
    required String title,
    required String message,
    String type = 'broadcast',
  }) async {
    try {
      final usersSnapshot = await _firestore.collection('user').get();
      final batch = _firestore.batch();

      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection('user')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'type': type,
          'read': false,
        });
      }

      // Also store in a global broadcasts collection for admin history
      await _firestore.collection('broadcasts').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
      });

      await batch.commit();
    } catch (e) {
      print('Error broadcasting notification: $e');
    }
  }
}
