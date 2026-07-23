import 'package:isar/isar.dart';

part 'wardrobe_slot.g.dart';

@collection
class WardrobeSlot {
  Id id;
  String status;
  bool isPaid;
  String paymentMethod;
  String secret;
  DateTime updatedAt;

  WardrobeSlot({
    required this.id,
    this.status = 'free',
    this.isPaid = false,
    this.paymentMethod = 'none',
    this.secret = '',
    required this.updatedAt,
  });

  factory WardrobeSlot.fromJson(Map<String, dynamic> json) {
    return WardrobeSlot(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'free',
      isPaid: json['is_paid'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'none',
      secret: json['secret'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'is_paid': isPaid,
      'payment_method': paymentMethod,
      'secret': secret,
      'updated_at': updatedAt.toIso8601String()
    };
  }
}
