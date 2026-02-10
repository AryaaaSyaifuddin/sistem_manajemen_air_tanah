import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TransactionFormPopup extends StatefulWidget {
  const TransactionFormPopup({super.key});

  @override
  State<TransactionFormPopup> createState() => _TransactionFormPopupState();
}

class _TransactionFormPopupState extends State<TransactionFormPopup> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _vehicleTypes = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  String? _selectedType;
  int _price = 0;
  int _status = 0;
  int? _selectedCustomerId;
  int? _selectedVehicleTypeId;
  bool _isLoadingVehicleTypes = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    final vehicleTypes = await DatabaseHelper.instance.getActiveVehicleTypes();
    if (mounted) {
      setState(() {
        _vehicleTypes = vehicleTypes;
        _isLoadingVehicleTypes = false;
        
        // Set default jika ada data
        if (vehicleTypes.isNotEmpty && _selectedVehicleTypeId == null) {
          _selectedVehicleTypeId = vehicleTypes.first['id'] as int;
          _selectedType = vehicleTypes.first['name'] as String;
          _price = vehicleTypes.first['price'] as int;
        }
      });
    }
  }

  void _updatePrice(int vehicleTypeId) {
    final selectedVehicle = _vehicleTypes.firstWhere(
      (vt) => vt['id'] as int == vehicleTypeId,
      orElse: () => <String, dynamic>{},
    );
    
    if (selectedVehicle.isNotEmpty) {
      setState(() {
        _selectedVehicleTypeId = vehicleTypeId;
        _selectedType = selectedVehicle['name'] as String;
        _price = selectedVehicle['price'] as int;
      });
    }
  }

  Future<void> _searchName(String value) async {
    if (value.length < 2) {
      _removeOverlay();
      return;
    }

    final result = await DatabaseHelper.instance.searchCustomerByName(value);

    if (!mounted) return;

    setState(() {
      _suggestions = result;
    });

    if (_suggestions.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: _suggestions.map((customer) {
                return ListTile(
                  title: Text(customer['name'] as String),
                  subtitle: Text(
                    '${customer['vehicle_type'] as String} • ${customer['plate_number'] ?? '-'}',
                  ),
                  onTap: () => _selectExistingCustomer(customer),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectExistingCustomer(Map<String, dynamic> customer) {
    // Cari vehicle type yang sesuai
    final vehicleTypeName = customer['vehicle_type'] as String;
    
    // Coba cari exact match
    var vehicleType = _vehicleTypes.firstWhere(
      (vt) => (vt['name'] as String).toLowerCase() == vehicleTypeName.toLowerCase(),
      orElse: () {
        // Jika tidak ditemukan exact match, coba cari partial match
        return _vehicleTypes.firstWhere(
          (vt) => (vt['name'] as String).toLowerCase().contains(vehicleTypeName.toLowerCase()) ||
                 vehicleTypeName.toLowerCase().contains((vt['name'] as String).toLowerCase()),
          orElse: () => _vehicleTypes.isNotEmpty ? _vehicleTypes.first : <String, dynamic>{},
        );
      },
    );

    if (mounted) {
      setState(() {
        _selectedCustomerId = customer['id'] as int;
        _nameController.text = customer['name'] as String;
        
        if (vehicleType.isNotEmpty) {
          _selectedVehicleTypeId = vehicleType['id'] as int;
          _selectedType = vehicleType['name'] as String;
          _price = vehicleType['price'] as int;
        } else if (_vehicleTypes.isNotEmpty) {
          // Fallback ke vehicle type pertama
          _selectedVehicleTypeId = _vehicleTypes.first['id'] as int;
          _selectedType = _vehicleTypes.first['name'] as String;
          _price = _vehicleTypes.first['price'] as int;
        }
        
        _plateController.text = customer['plate_number']?.toString() ?? '';
      });
    }

    _removeOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    _nameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Widget _buildVehicleTypeDropdown() {
    if (_isLoadingVehicleTypes) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_vehicleTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Belum ada tipe kendaraan. Silakan tambah di menu Tipe Kendaraan.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Buat list items dengan tipe yang jelas
    List<DropdownMenuItem<int>> dropdownItems = [];
    
    for (var vehicleType in _vehicleTypes) {
      final id = int.tryParse(vehicleType['id'].toString()) ?? 0;
      final name = vehicleType['name']?.toString() ?? '';
      final price = int.tryParse(vehicleType['price'].toString()) ?? 0;
      
      if (id > 0) {
        dropdownItems.add(
          DropdownMenuItem<int>(
            value: id,
            child: Container(
              constraints: const BoxConstraints(minWidth: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Rp ${price.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return DropdownButtonFormField<int>(
      value: _selectedVehicleTypeId,
      decoration: const InputDecoration(
        labelText: 'Tipe Kendaraan',
        prefixIcon: Icon(Icons.local_shipping),
        border: OutlineInputBorder(),
      ),
      items: dropdownItems,
      onChanged: (value) {
        if (value != null) {
          _updatePrice(value);
        }
      },
      validator: (value) =>
          value == null ? 'Pilih tipe kendaraan' : null,
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Tambah Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),

                const Divider(),
                const SizedBox(height: 12),

                // ================= NAMA =================
                CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _selectedCustomerId = null;
                      _searchName(value);
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                ),

                const SizedBox(height: 6),

                // ================= Status Customer =================
                Center(
                  child: Text(
                    _selectedCustomerId != null ? 'Pelanggan Lama' : 'Pelanggan Baru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedCustomerId != null ? Colors.green : Colors.orange,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ================= TIPE KENDARAAN DINAMIS =================
                _buildVehicleTypeDropdown(),

                const SizedBox(height: 12),

                // ================= PLAT =================
                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Plat Nomor (Opsional)',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= HARGA =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Harga:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Rp ${_price.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Status Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        value: 1,
                        groupValue: _status,
                        title: const Text('Sudah Bayar'),
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _status = value!);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        value: 0,
                        groupValue: _status,
                        title: const Text('Belum Bayar'),
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _status = value!);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ================= ACTION =================
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedVehicleTypeId == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pilih tipe kendaraan terlebih dahulu'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            // Cek apakah customer sudah ada
                            final existingCustomer = 
                                await DatabaseHelper.instance.findCustomerByName(_nameController.text);
                            
                            int customerId;
                            
                            if (existingCustomer != null) {
                              // Gunakan customer yang sudah ada
                              customerId = existingCustomer['id'] as int;
                              // Update vehicle type customer jika berbeda
                              if (existingCustomer['vehicle_type'] != _selectedType) {
                                await DatabaseHelper.instance.updateCustomer(customerId, {
                                  'vehicle_type': _selectedType!,
                                  'plate_number': _plateController.text.isNotEmpty 
                                      ? _plateController.text 
                                      : existingCustomer['plate_number'],
                                });
                              }
                            } else {
                              // Insert customer baru
                              final newCustomerId = await DatabaseHelper.instance.insertCustomer({
                                'name': _nameController.text,
                                'vehicle_type': _selectedType!,
                                'plate_number': _plateController.text,
                                'created_at': DateTime.now().toIso8601String(),
                              });
                              
                              if (newCustomerId == -1) {
                                // Jika terjadi duplikat (nama sudah ada), cari lagi
                                final customer = await DatabaseHelper.instance
                                    .findCustomerByName(_nameController.text);
                                customerId = customer!['id'] as int;
                              } else {
                                customerId = newCustomerId;
                              }
                            }

                            // Insert transaksi
                            final transactionId = await DatabaseHelper.instance.insertTransaction({
                              'customer_id': customerId,
                              'vehicle_type_id': _selectedVehicleTypeId,
                              'price': _price,
                              'status': _status,
                              'created_at': DateTime.now().toIso8601String(),
                            });

                            if (mounted) {
                              Navigator.pop(context, true);
                            }
                          }
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}