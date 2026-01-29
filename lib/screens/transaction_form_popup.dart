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
  bool _isExistingCustomer = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();


  String? _selectedType;
  int _price = 0;
  int _status = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();

  void _updatePrice(String type) {
    setState(() {
      if (type == 'tangki') {
        _price = 16000;
      } else if (type == 'box') {
        _price = 10000;
      }
    });
  }

  Future<void> _searchName(String value) async {
    if (value.length < 2) {
      _removeOverlay();
      return;
    }

    final result =
        await DatabaseHelper.instance.searchCustomerByName(value);

    if (!mounted) return;

    setState(() {
      _suggestions = result;
    });

    _showOverlay();
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
              children: _suggestions.map((item) {
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(
                    '${item['vehicle_type']} • ${item['plate_number'] ?? '-'}',
                  ),
                  onTap: () => _selectExistingCustomer(item),
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

  void _selectExistingCustomer(Map<String, dynamic> data) {
    setState(() {
      _nameController.text = data['name'];
      _selectedType = data['vehicle_type'];
      _plateController.text = data['plate_number'] ?? '';
      _price = data['price'];
      _isExistingCustomer = true;
    });

    _removeOverlay();
  }



  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
                    _isExistingCustomer = false;
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
                  _isExistingCustomer ? 'Data Lama (Existing)' : 'Data Baru',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isExistingCustomer ? Colors.green : Colors.orange,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ================= TIPE =================
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipe Kendaraan',
                  prefixIcon: const Icon(Icons.local_shipping),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'tangki',
                    child: Text('Truck Tangki'),
                  ),
                  DropdownMenuItem(
                    value: 'box',
                    child: Text('Box'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _selectedType = value;
                    _updatePrice(value);
                  }
                },
                validator: (value) =>
                    value == null ? 'Pilih tipe kendaraan' : null,
              ),

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
                  color: Colors.blue.withOpacity(0.08),
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
                      'Rp $_price',
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

              Text(
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
                        setState(() => _status = value!);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      value: 0,
                      groupValue: _status,
                      title: const Text('Belum Bayar'),
                      onChanged: (value) {
                        setState(() => _status = value!);
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
                          final id = await DatabaseHelper.instance.insertTransaction({
                            'name': _nameController.text,
                            'vehicle_type': _selectedType,
                            'plate_number': _plateController.text,
                            'price': _price,
                            'status': _status,
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          print('TRANSAKSI MASUK, ID: $id');

                          // 👉 kirim sinyal sukses
                          Navigator.pop(context, true);
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
    );
  }
}
