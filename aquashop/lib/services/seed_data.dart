import 'package:cloud_firestore/cloud_firestore.dart';

const _catalog = <String, List<(String, int)>>{
  'Purifiers': [
    ('AquaPure RO+UV 7L', 12999), ('AquaPure RO+UV+TDS 10L', 15499),
    ('AquaPure Compact RO 6L', 9499), ('AquaPure UV Gravity 12L', 3999),
    ('AquaPure Alkaline RO 8L', 16999), ('AquaPure Copper RO 9L', 17999),
    ('AquaPure Under-Sink RO', 14499), ('AquaPure Wall-Mount RO 8L', 13499),
    ('AquaPure Smart WiFi RO 10L', 22999), ('AquaPure Commercial RO 25 LPH', 38999),
    ('AquaPure Industrial RO 50 LPH', 64999), ('AquaPure UF Non-Electric 9L', 2499),
  ],
  'Dispensers': [
    ('HydroCool Hot & Cold Dispenser', 8999), ('HydroCool Floor Standing Dispenser', 11499),
    ('HydroCool Table-Top Dispenser', 6499), ('HydroCool Bottom-Load Dispenser', 13999),
    ('HydroCool Hot Normal Cold Dispenser', 9999), ('HydroCool Pipeline Dispenser', 15999),
    ('HydroCool Stainless Steel Dispenser', 18999), ('HydroCool Touchless Dispenser', 21499),
  ],
  'Pumps': [
    ('FlowMax 0.5 HP Water Pump', 4999), ('FlowMax 1 HP Water Pump', 6999),
    ('FlowMax Booster Pump 24V', 3299), ('FlowMax RO Booster Pump 100 GPD', 2199),
    ('FlowMax Submersible Pump 1 HP', 9499), ('FlowMax Self-Priming Pump', 7999),
    ('FlowMax Pressure Pump', 5799), ('FlowMax Dosing Pump', 4299),
  ],
  'Filters': [
    ('Sediment Filter 10 inch', 299), ('Carbon Block Filter 10 inch', 449),
    ('Pre-Filter Cartridge 20 inch', 599), ('Spun Filter 5 micron', 199),
    ('UF Membrane Cartridge', 1299), ('RO Membrane 75 GPD', 1499),
    ('RO Membrane 100 GPD', 1899), ('Inline Carbon Filter', 249),
    ('Alkaline Mineral Cartridge', 699), ('Copper Infusion Cartridge', 799),
    ('Whole House Filter 20 inch', 3499), ('Iron Removal Filter', 4299),
  ],
  'Accessories': [
    ('UV Lamp 11W', 699), ('UV Lamp Choke Set', 549), ('SMPS Adapter 24V', 649),
    ('Solenoid Valve', 449), ('Flow Restrictor', 149), ('Pressure Switch', 399),
    ('Filter Housing 10 inch', 899), ('Chrome Faucet Tap', 349),
  ],
  'Spares': [
    ('Float Valve', 229), ('Pipe Fitting Kit', 599), ('Water Storage Tank 20L', 1799),
    ('TDS Meter Digital', 499), ('Filter Wrench Set', 299), ('Installation Kit', 999),
  ],
};

List<String> get categories => _catalog.keys.toList();

/// Writes all products with fixed ids, so running it twice never duplicates.
Future<int> seedProducts() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  var i = 0;
  _catalog.forEach((cat, items) {
    for (final (name, price) in items) {
      i++;
      final prompt = Uri.encodeComponent(
          'product photo of $name, water purifier industry, white background, studio lighting');
      batch.set(db.collection('products').doc('p${i.toString().padLeft(3, '0')}'), {
        'name': name, 'category': cat, 'price': price,
        'stock': 10 + (i * 7) % 90,
        'description': '$name. Reliable ${cat.toLowerCase()} for home and commercial use.',
        'imageUrl': 'https://image.pollinations.ai/prompt/$prompt?width=512&height=512&nologo=true&seed=$i',
      });
    }
  });
  await batch.commit();
  return i;
}
