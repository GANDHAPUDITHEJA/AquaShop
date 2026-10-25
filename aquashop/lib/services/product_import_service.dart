import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

class ProductImportRow {
  final int line;
  final Map<String, dynamic> data;

  const ProductImportRow(this.line, this.data);
}

class ProductImportResult {
  final List<ProductImportRow> rows;
  final List<String> errors;

  const ProductImportResult(this.rows, this.errors);
}

class ProductImportService {
  static const headers = [
    'id',
    'name',
    'category',
    'price',
    'stock',
    'description',
    'imageUrl',
  ];

  static ProductImportResult parse(String content) {
    final records =
        CsvToListConverter(shouldParseNumbers: false).convert(content);
    if (records.isEmpty) {
      return const ProductImportResult([], ['The CSV file is empty.']);
    }

    final actualHeaders =
        records.first.map((value) => value.toString().trim()).toList();
    final indexes = <String, int>{};
    for (var i = 0; i < actualHeaders.length; i++) {
      indexes[actualHeaders[i].toLowerCase()] = i;
    }

    final missing = headers.where((header) =>
        header != 'id' && !indexes.containsKey(header.toLowerCase()));
    if (missing.isNotEmpty) {
      return ProductImportResult(
          [], ['Missing required columns: ${missing.join(', ')}']);
    }

    final rows = <ProductImportRow>[];
    final errors = <String>[];
    for (var recordIndex = 1; recordIndex < records.length; recordIndex++) {
      final record = records[recordIndex];
      final line = recordIndex + 1;
      if (record.every((value) => value.toString().trim().isEmpty)) continue;

      String value(String header) {
        final index = indexes[header.toLowerCase()];
        return index == null || index >= record.length
            ? ''
            : record[index].toString().trim();
      }

      final name = value('name');
      final category = value('category');
      final priceText = value('price');
      final stockText = value('stock');
      final price = double.tryParse(priceText);
      final stock = int.tryParse(stockText);
      final rowErrors = <String>[];
      if (name.isEmpty) rowErrors.add('name is required');
      if (category.isEmpty) rowErrors.add('category is required');
      if (price == null || price < 0)
        rowErrors.add('price must be a number >= 0');
      if (stock == null || stock < 0)
        rowErrors.add('stock must be a whole number >= 0');
      if (value('imageUrl').isEmpty) rowErrors.add('imageUrl is required');

      if (rowErrors.isNotEmpty) {
        errors.add('Line $line: ${rowErrors.join('; ')}');
        continue;
      }

      rows.add(ProductImportRow(line, {
        if (value('id').isNotEmpty) 'id': value('id'),
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'description': value('description'),
        'imageUrl': value('imageUrl'),
      }));
    }

    if (rows.isEmpty && errors.isEmpty) errors.add('No product rows found.');
    return ProductImportResult(rows, errors);
  }

  static Future<void> save(ProductImportResult result) async {
    final db = FirebaseFirestore.instance;
    for (var start = 0; start < result.rows.length; start += 500) {
      final batch = db.batch();
      final end =
          (start + 500 < result.rows.length) ? start + 500 : result.rows.length;
      for (final row in result.rows.sublist(start, end)) {
        final data = Map<String, dynamic>.from(row.data);
        final id = data.remove('id') as String?;
        final ref = id == null || id.isEmpty
            ? db.collection('products').doc()
            : db.collection('products').doc(id);
        batch.set(ref, data);
      }
      await batch.commit();
    }
  }

  static String decode(List<int> bytes) =>
      utf8.decode(bytes, allowMalformed: true);
}
