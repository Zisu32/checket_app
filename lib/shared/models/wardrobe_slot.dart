import 'package:isar/isar.dart';

part 'wardrobe_slot.g.dart';

@collection
class WardrobeSlot {
  // Id is non-nullable in Isar 4.0.0-dev.14
  int id;
  
  String status;
  
  @Index()
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

  factory WardrobeSlot.fromSupabase(Map<String, dynamic> json) {
    return WardrobeSlot(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'free',
      isPaid: json['is_paid'] as bool? ?? false,
      paymentMethod: json['payment_method'] as String? ?? 'none',
      secret: json['secret'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toSupabase() {
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
