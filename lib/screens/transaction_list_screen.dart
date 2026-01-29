import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import 'home_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _transactionsFuture =
        DatabaseHelper.instance.getTransactionsByKeyword('');
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = DatabaseHelper.instance
          .getTransactionsByKeyword(_searchKeyword);
    });
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Data Transaksi'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau plat nomor...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchKeyword = value;
                _refreshTransactions();
              },
            ),
          ),

          // ================= LIST DATA =================
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Data tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final transactions = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    final isPaid = trx['status'] == 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Colors.blue.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trx['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tipe: ${trx['vehicle_type']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (trx['plate_number'] != null &&
                                    trx['plate_number']
                                        .toString()
                                        .isNotEmpty)
                                  Text(
                                    'Plat: ${trx['plate_number']}',
                                    style:
                                        TextStyle(color: Colors.grey[600]),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(trx['created_at']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rp ${trx['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ========== STATUS BADGE ==========
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: isPaid
                                                    ? Colors.orange.withValues(alpha: 0.15)
                                                    : Colors.green.withValues(alpha: 0.15),
                                                child: Icon(
                                                  Icons.swap_horiz_rounded,
                                                  color: isPaid ? Colors.orange : Colors.green,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Konfirmasi Perubahan Status',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                isPaid
                                                    ? 'Ubah status transaksi ini menjadi\nBELUM BAYAR?'
                                                    : 'Ubah status transaksi ini menjadi\nSUDAH BAYAR?',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.grey[700]),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      style: OutlinedButton.styleFrom(
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
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            isPaid ? Colors.orange : Colors.green,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Text('Ya, Ubah'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );


                                  if (confirm != true) return;

                                  final newStatus = isPaid ? 0 : 1;

                                  await DatabaseHelper.instance
                                      .updateTransactionStatus(
                                    trx['id'],
                                    newStatus,
                                  );

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      content: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: newStatus == 1
                                              ? Colors.green.shade600
                                              : Colors.orange.shade600,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              newStatus == 1
                                                  ? Icons.check_circle_outline
                                                  : Icons.info_outline,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                newStatus == 1
                                                    ? 'Status berhasil diubah menjadi SUDAH BAYAR'
                                                    : 'Status berhasil diubah menjadi BELUM BAYAR',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );


                                  _refreshTransactions();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green
                                            .withValues(alpha: 0.15)
                                        : Colors.orange
                                            .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPaid
                                        ? 'Sudah Bayar'
                                        : 'Belum Bayar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isPaid
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
