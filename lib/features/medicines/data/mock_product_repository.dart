import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';

/// In-memory mock of [ProductRepository] used until the backend exists.
///
/// Categories match the dashboard's `homeCategoriesProvider` labels so tapping
/// a category on the home page filters this list.
class MockProductRepository implements ProductRepository {
  static const _catalog = <Product>[
    // Medicines
    Product(
      id: 'p1', name: 'Paracetamol 500mg Tablets', brand: 'Micro Labs',
      category: 'Medicines', price: 30, mrp: 35,
      description: 'Relieves mild to moderate pain and reduces fever.',
      composition: 'Paracetamol 500mg', dosage: '1 tablet every 6 hours, as needed (max 4/day)',
      ingredients: ['Paracetamol', 'Starch', 'Povidone', 'Magnesium stearate'],
    ),
    Product(
      id: 'p2', name: 'Azithromycin 500mg', brand: 'Cipla',
      category: 'Medicines', price: 70, mrp: 84, requiresPrescription: true,
      description: 'Antibiotic used to treat a range of bacterial infections.',
      composition: 'Azithromycin 500mg', dosage: '1 tablet once daily for 3 days, or as prescribed',
      ingredients: ['Azithromycin dihydrate', 'Lactose', 'Croscarmellose sodium'],
    ),
    Product(
      id: 'p3', name: 'Cetirizine 10mg', brand: "Dr. Reddy's",
      category: 'Medicines', price: 25, mrp: 30,
      description: 'Antihistamine that relieves allergy symptoms and runny nose.',
      composition: 'Cetirizine Hydrochloride 10mg', dosage: '1 tablet once daily at night',
      ingredients: ['Cetirizine HCl', 'Lactose', 'Maize starch'],
    ),
    Product(
      id: 'p4', name: 'Pantoprazole 40mg', brand: 'Sun Pharma',
      category: 'Medicines', price: 90, mrp: 110, requiresPrescription: true,
      description: 'Reduces stomach acid; treats acidity and reflux.',
      composition: 'Pantoprazole 40mg', dosage: '1 tablet before breakfast',
      ingredients: ['Pantoprazole sodium', 'Mannitol', 'Crospovidone'],
    ),
    // Wellness
    Product(
      id: 'p5', name: 'Vitamin C 1000mg', brand: 'HealthKart',
      category: 'Wellness', price: 250, mrp: 320,
      description: 'Supports immunity and skin health.',
      composition: 'Ascorbic Acid 1000mg', dosage: '1 tablet daily after a meal',
      ingredients: ['Vitamin C', 'Rose hips extract', 'Citrus bioflavonoids'],
    ),
    Product(
      id: 'p6', name: 'Daily Multivitamin', brand: 'Revital',
      category: 'Wellness', price: 300, mrp: 350,
      description: 'Everyday vitamins and minerals for energy and immunity.',
      composition: 'Multivitamins + Multiminerals', dosage: '1 capsule daily after breakfast',
      ingredients: ['Vitamins A, B, C, D, E', 'Zinc', 'Ginseng extract', 'Calcium'],
    ),
    Product(
      id: 'p7', name: 'Omega-3 Fish Oil', brand: 'WOW',
      category: 'Wellness', price: 500, mrp: 699,
      description: 'Supports heart, brain and joint health.',
      composition: 'Fish Oil 1000mg (EPA 180mg, DHA 120mg)', dosage: '1-2 softgels daily after meals',
      ingredients: ['Fish oil', 'EPA', 'DHA', 'Vitamin E'],
    ),
    // Personal Care
    Product(
      id: 'p8', name: 'Moisturizing Lotion', brand: 'Nivea',
      category: 'Personal Care', price: 220, mrp: 275,
      description: '48-hour deep moisture for soft, smooth skin.',
      ingredients: ['Glycerin', 'Shea butter', 'Almond oil'],
    ),
    Product(
      id: 'p9', name: 'Sunscreen SPF 50', brand: 'Lakmé',
      category: 'Personal Care', price: 350, mrp: 425,
      description: 'Broad-spectrum protection against UVA/UVB rays.',
      ingredients: ['Zinc oxide', 'Titanium dioxide', 'Niacinamide'],
    ),
    Product(
      id: 'p10', name: 'Hand Sanitizer 500ml', brand: 'Dettol',
      category: 'Personal Care', price: 150, mrp: 180,
      description: 'Kills 99.9% of germs without water.',
      ingredients: ['Ethyl alcohol 70%', 'Glycerin', 'Aloe vera'],
    ),
    // Devices (no composition/dosage/ingredients)
    Product(
      id: 'p11', name: 'Digital Thermometer', brand: 'Omron',
      category: 'Devices', price: 200, mrp: 250,
      description: 'Fast, accurate temperature readings with a flexible tip.',
    ),
    Product(
      id: 'p12', name: 'Blood Pressure Monitor', brand: 'Omron',
      category: 'Devices', price: 1800, mrp: 2200,
      description: 'Automatic upper-arm BP monitor with irregular-heartbeat detection.',
    ),
    Product(
      id: 'p13', name: 'Pulse Oximeter', brand: 'Dr Trust',
      category: 'Devices', price: 1200, mrp: 1500,
      description: 'Measures blood oxygen (SpO2) and pulse rate in seconds.',
    ),
    // Baby Care
    Product(
      id: 'p14', name: 'Baby Diapers (M, 62s)', brand: 'Pampers',
      category: 'Baby Care', price: 799, mrp: 999,
      description: 'Up to 12 hours of dryness with a soft cottony top sheet.',
      ingredients: ['Absorbent gel', 'Cotton-soft cover', 'Aloe lotion'],
    ),
    Product(
      id: 'p15', name: 'Baby Lotion', brand: "Johnson's",
      category: 'Baby Care', price: 180, mrp: 210,
      description: 'Gentle, hypoallergenic moisturizer for delicate skin.',
      ingredients: ['Glycerin', 'Coconut oil', 'Vitamin E'],
    ),
    // Ayurveda
    Product(
      id: 'p16', name: 'Chyawanprash 1kg', brand: 'Dabur',
      category: 'Ayurveda', price: 320, mrp: 400,
      description: 'Ayurvedic immunity booster with 40+ herbs.',
      composition: 'Amla-based herbal blend', dosage: '1-2 teaspoons daily',
      ingredients: ['Amla', 'Ashwagandha', 'Giloy', 'Honey', 'Ghee'],
    ),
    Product(
      id: 'p17', name: 'Ashwagandha Tablets', brand: 'Himalaya',
      category: 'Ayurveda', price: 250, mrp: 300,
      description: 'Helps reduce stress and improve stamina.',
      composition: 'Ashwagandha extract 500mg', dosage: '1 tablet twice daily after meals',
      ingredients: ['Ashwagandha root extract'],
    ),
    Product(
      id: 'p18', name: 'Tulsi Drops', brand: 'Patanjali',
      category: 'Ayurveda', price: 90, mrp: 110,
      description: 'Concentrated tulsi extract for immunity and cough relief.',
      composition: 'Five-tulsi extract', dosage: '1-2 drops in water or tea, twice daily',
      ingredients: ['Rama Tulsi', 'Shyama Tulsi', 'Vana Tulsi'],
    ),
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
