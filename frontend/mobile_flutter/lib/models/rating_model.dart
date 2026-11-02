// Khớp backend/Dtos/RatingDtos.cs
import 'payment_model.dart';

/// GET api/ratings/me - đánh giá app của mình (chưa đánh giá thì [stars] = null)
class MyRating {
  final int? stars;
  final String? comment;
  final DateTime? updatedAt;

  /// Chưa đánh giá và đã dùng app đủ lâu -> app tự hỏi 1 lần
  final bool shouldAsk;

  const MyRating({this.stars, this.comment, this.updatedAt, this.shouldAsk = false});

  bool get hasRated => stars != null;

  factory MyRating.fromJson(Map<String, dynamic> json) => MyRating(
        stars: json['stars'] as int?,
        comment: json['comment'] as String?,
        updatedAt: parseServerDate(json['updatedAt']),
        shouldAsk: json['shouldAsk'] as bool? ?? false,
      );
}
