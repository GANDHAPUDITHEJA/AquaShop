import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/product_import_service.dart';
import '../services/seed_data.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _busy = false;

  Future<void> _importCsv() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty || !mounted) return;

    final parsed = ProductImportService.parse(
        ProductImportService.decode(await files.single.readAsBytes()));
    if (parsed.errors.isNotEmpty || parsed.rows.isEmpty) {
      _showImportReport(parsed, saved: false);
      return;
    }

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import ${parsed.rows.length} products?'),
        content: Text(
          parsed.errors.isEmpty
              ? 'These rows will be added or updated in Firestore.'
              : '${parsed.errors.length} row(s) will be skipped.\n\n${parsed.errors.join('\n')}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import valid rows')),
        ],
      ),
    );
    if (shouldImport != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ProductImportService.save(parsed);
      if (mounted) _showImportReport(parsed, saved: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showImportReport(ProductImportResult result, {required bool saved}) {
    final message = saved
        ? 'Imported ${result.rows.length} product(s).'
        : result.errors.join('\n');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (_, snapshot) {
          final count = snapshot.data?.size ?? 0;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$count products in catalog',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Add products in bulk with a CSV file. Existing IDs are updated; blank IDs create new products.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(_busy ? 'Importing…' : 'Import products CSV'),
                      onPressed: _busy ? null : _importCsv,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Load sample products'),
                      onPressed: _busy
                          ? null
                          : () async {
                              final n = await seedProducts();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Loaded $n products')));
                              }
                            },
                    ),
                    const SizedBox(height: 20),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'CSV columns:\n'
                          'name, category, price, stock, description, imageUrl\n\n'
                          'Optional column: id\n'
                          'Example: AquaPure RO, Purifiers, 12999, 10, RO purifier, https://…',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
