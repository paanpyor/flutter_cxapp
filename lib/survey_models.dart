
/// Represents a specific response to a survey question
class SurveyQuestionResponse {
  final String type; // "CSAT", "CES", "NPS"
  final double averageScore;
  final int count;

  SurveyQuestionResponse({
    required this.type,
    required this.averageScore,
    required this.count,
  });
}

/// Represents the full data payload for a submission
class SurveySubmission {
  final String userId;
  final String restaurantId;
  final String type;
  final double score;
  final String? comment;
  final DateTime date;

  SurveySubmission({
    required this.userId,
    required this.restaurantId,
    required this.type,
    required this.score,
    this.comment,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'restaurantId': restaurantId, // Added for consistency
        'type': type,
        'score': score,
        'comment': comment,
        'date': date.toIso8601String(),
      };
}