class BackpackItem {
  final String id;
  final String name;
  final String? image;
  final int quantity;
  final Map<String, dynamic> extra;

  BackpackItem({
    required this.id,
    required this.name,
    this.image,
    required this.quantity,
    this.extra = const {},
  });

  factory BackpackItem.fromJson(Map<String, dynamic> json) {
    // Accept multiple possible id/name keys used by different APIs
    String id = (json['id'] ?? json['backpack_id'] ?? json['item_id'] ?? json['uid'] ?? '').toString();
    String name = (json['name'] ?? json['title'] ?? json['item_name'] ?? '').toString();
    String? image = (json['image'] ?? json['img'] ?? json['item_image'])?.toString();

    int quantity = 0;
    try {
      final q = json['quantity'] ?? json['qty'] ?? json['count'] ?? json['item_count'];
      if (q != null) quantity = int.tryParse(q.toString()) ?? 0;
    } catch (_) {
      quantity = 0;
    }

    final Map<String, dynamic> extra = Map<String, dynamic>.from(json);

    return BackpackItem(
      id: id,
      name: name,
      image: image,
      quantity: quantity,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'quantity': quantity,
      ...extra,
    };
  }
}
