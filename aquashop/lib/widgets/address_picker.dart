import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PickedAddress {
  final String address;
  final double latitude;
  final double longitude;

  const PickedAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class AddressPicker extends StatefulWidget {
  final String title;
  final String initialAddress;

  const AddressPicker({
    super.key,
    required this.title,
    this.initialAddress = '',
  });

  @override
  State<AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  final _mapController = MapController();
  late final TextEditingController _addressController;
  LatLng? _selected;
  bool _lookingUp = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _select(LatLng point) async {
    setState(() {
      _selected = point;
      _lookingUp = true;
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '1',
      });
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'AquaShop/1.0 address picker',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          _addressController.text = displayName;
        }
      }
    } catch (_) {
      // The coordinates remain usable when reverse geocoding is unavailable.
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  void _submit() {
    final point = _selected;
    final address = _addressController.text.trim();
    if (point == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tap the map and enter or confirm the address.')));
      return;
    }
    Navigator.pop(
      context,
      PickedAddress(
        address: address,
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const initial = LatLng(20.5937, 78.9629);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selected ?? initial,
                initialZoom: 5,
                onTap: (_, point) => _select(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aquashop.app',
                ),
                RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ]),
                if (_selected != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 44),
                    ),
                  ]),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
            child: Column(
              children: [
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    suffixIcon: _lookingUp
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Use this address'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
