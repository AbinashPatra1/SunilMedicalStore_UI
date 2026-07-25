import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';

/// In-memory mock of [ProductRepository] used until the backend exists.
///
/// Categories match the dashboard's `homeCategoriesProvider` labels so tapping
/// a category on the home page filters this list.
class MockProductRepository implements ProductRepository {
  static const _catalog = <Product>[
    // Medicines
    Product(id: 'p1', name: 'Paracetamol 500mg Tablets', brand: 'Micro Labs', category: 'Medicines', price: 30, mrp: 35),
    Product(id: 'p2', name: 'Azithromycin 500mg', brand: 'Cipla', category: 'Medicines', price: 70, mrp: 84, requiresPrescription: true),
    Product(id: 'p3', name: 'Cetirizine 10mg', brand: "Dr. Reddy's", category: 'Medicines', price: 25, mrp: 30),
    Product(id: 'p4', name: 'Pantoprazole 40mg', brand: 'Sun Pharma', category: 'Medicines', price: 90, mrp: 110, requiresPrescription: true),
    // Wellness
    Product(id: 'p5', name: 'Vitamin C 1000mg', brand: 'HealthKart', category: 'Wellness', price: 250, mrp: 320),
    Product(id: 'p6', name: 'Daily Multivitamin', brand: 'Revital', category: 'Wellness', price: 300, mrp: 350),
    Product(id: 'p7', name: 'Omega-3 Fish Oil', brand: 'WOW', category: 'Wellness', price: 500, mrp: 699),
    // Personal Care
    Product(id: 'p8', name: 'Moisturizing Lotion', brand: 'Nivea', category: 'Personal Care', price: 220, mrp: 275),
    Product(id: 'p9', name: 'Sunscreen SPF 50', brand: 'Lakmé', category: 'Personal Care', price: 350, mrp: 425),
    Product(id: 'p10', name: 'Hand Sanitizer 500ml', brand: 'Dettol', category: 'Personal Care', price: 150, mrp: 180),
    // Devices
    Product(id: 'p11', name: 'Digital Thermometer', brand: 'Omron', category: 'Devices', price: 200, mrp: 250),
    Product(id: 'p12', name: 'Blood Pressure Monitor', brand: 'Omron', category: 'Devices', price: 1800, mrp: 2200),
    Product(id: 'p13', name: 'Pulse Oximeter', brand: 'Dr Trust', category: 'Devices', price: 1200, mrp: 1500),
    // Baby Care
    Product(id: 'p14', name: 'Baby Diapers (M, 62s)', brand: 'Pampers', category: 'Baby Care', price: 799, mrp: 999),
    Product(id: 'p15', name: 'Baby Lotion', brand: "Johnson's", category: 'Baby Care', price: 180, mrp: 210),
    // Ayurveda
    Product(id: 'p16', name: 'Chyawanprash 1kg', brand: 'Dabur', category: 'Ayurveda', price: 320, mrp: 400),
    Product(id: 'p17', name: 'Ashwagandha Tablets', brand: 'Himalaya', category: 'Ayurveda', price: 250, mrp: 300),
    Product(id: 'p18', name: 'Tulsi Drops', brand: 'Patanjali', category: 'Ayurveda', price: 90, mrp: 110),
  ];

  static const _suggestedIds = {'p1', 'p5', 'p11', 'p9', 'p16', 'p6'};

  @override
  Future<List<Product>> suggestedProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _catalog.where((p) => _suggestedIds.contains(p.id)).toList();
  }

  @override
  Future<List<Product>> allProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _catalog;
  }

  @override
  Future<List<Product>> productsByCategory(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _catalog.where((p) => p.category == category).toList();
  }
}
