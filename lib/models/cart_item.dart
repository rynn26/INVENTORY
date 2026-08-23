class CartItem {
  final String id;
  final String name;
  final int price;
  int quantity;
  final String imageUrl;
  final String? barcode;
  final String? penitipName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    required this.imageUrl,
    this.barcode,
    this.penitipName,
  });

  int get totalPrice => price * quantity;
}

