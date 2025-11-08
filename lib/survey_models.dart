
import 'package:firebase_database/firebase_database.dart';

/// Represents one CSAT question + score
class CSATResponse {
  final int index;
  final int score;
  final String question;

  CSATResponse({
    required this.index,
    required this.score,
    required this.question,
  });

  Map<String, dynamic> toJson() => {
        'questionIndex': index,
        'question': question,
        'score': score,
      };
}

/// Represents full survey data
class SurveySubmission {
  final String userId;
  final DateTime timestamp;
  final List<CSATResponse> csatResponses;
  final int cesScore;
  final int npsScore;

  SurveySubmission({
    required this.userId,
    required this.timestamp,
    required this.csatResponses,
    required this.cesScore,
    required this.npsScore,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'csat': csatResponses.map((r) => r.toJson()).toList(),
        'ces': cesScore,
        'nps': npsScore,
      };
}

/// Service to interact with Firebase Realtime Database
class RealtimeDatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Save survey under a restaurant
  Future<void> saveSurvey({
    required String restaurantId,
    required SurveySubmission submission,
  }) async {
    try {
      final newRef =
          _db.child("restaurants/$restaurantId/surveys").push();
      await newRef.set(submission.toJson());
      print("✅ Survey saved successfully to restaurant $restaurantId");
    } catch (e) {
      print("❌ Error saving survey: $e");
    }
  }

  // Save restaurant owned by a specific owner
  Future<void> saveRestaurant({
    required String ownerId,
    required String restaurantName,
    required String location,
  }) async {
    try {
      final newRef = _db.child("restaurants").push();
      await newRef.set({
        "name": restaurantName,
        "ownerId": ownerId,
        "location": location,
        "createdAt": ServerValue.timestamp,
      });
      print("✅ Restaurant created successfully");
    } catch (e) {
      print("❌ Error creating restaurant: $e");
    }
  }

  // Get all surveys under the owner’s restaurants
  Future<List<Map<String, dynamic>>> getOwnerSurveys(String ownerId) async {
    List<Map<String, dynamic>> result = [];
    try {
      final event = await _db.child("restaurants").get();
      if (!event.exists) return result;

      final data = (event.value as Map).cast<String, dynamic>();
      for (final entry in data.entries) {
        final restaurantId = entry.key;
        final map = Map<String, dynamic>.from(entry.value);
        if (map["ownerId"] == ownerId) {
          final surveySnap =
              await _db.child("restaurants/$restaurantId/surveys").get();
          if (surveySnap.exists) {
            final surveys =
                (surveySnap.value as Map).cast<String, dynamic>();
            for (final s in surveys.entries) {
              final survey = Map<String, dynamic>.from(s.value);
              result.add({
                "restaurantName": map["name"],
                "survey": survey,
              });
            }
          }
        }
      }
    } catch (e) {
      print("❌ Error loading owner surveys: $e");
    }
    return result;
  }
}
