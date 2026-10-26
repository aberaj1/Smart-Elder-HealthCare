
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthcareOwnerService {
  HealthcareOwnerService._();

  static Future<String> getDataOwnerUid() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please login first.');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final role = data?['role']?.toString().toLowerCase();

    if (role == 'caregiver') {
      final elderId = data?['elderId']?.toString().trim();

      if (elderId == null || elderId.isEmpty) {
        throw Exception(
          'No elder linked. Please use Connect Elder first.',
        );
      }

      return elderId;
    }

    return user.uid;
  }
}
