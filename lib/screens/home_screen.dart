import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'customer_list_screen.dart';
import 'transaction_form_popup.dart';
import 'transaction_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, int>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = DatabaseHelper.instance.getTodaySummary();
  }

  void _refreshSummary() {
    setState(() {
      _summaryFuture = DatabaseHelper.instance.getTodaySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          'Manajemen Air Tanah',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),

                _buildSummaryCard(
                  transaksi: data['total_transaksi']!,
                  pendapatan: data['total_pendapatan']!,
                ),
                const SizedBox(height: 16),

                _buildOperationalInfo(
                  tangki: data['total_tangki']!,
                  box: data['total_box']!,
                ),
                const SizedBox(height: 16),

                _buildDailyInsight(data['total_transaksi']!),
                const SizedBox(height: 24),

                const Text(
                  'Menu Utama',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildMenuGrid(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Kelola penjualan air tanah dengan mudah',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummaryCard({
    required int transaksi,
    required int pendapatan,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            title: 'Transaksi Hari Ini',
            value: transaksi.toString(),
            icon: Icons.local_shipping,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryItem(
            title: 'Pendapatan Hari Ini',
            value: 'Rp $pendapatan',
            icon: Icons.attach_money,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ================= OPERASIONAL =================
  Widget _buildOperationalInfo({
    required int tangki,
    required int box,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryItem(
            title: 'Truck Tangki',
            value: tangki.toString(),
            icon: Icons.water,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryItem(
            title: 'Box',
            value: box.toString(),
            icon: Icons.inventory_2,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  // ================= INSIGHT =================
  Widget _buildDailyInsight(int totalTransaksi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            totalTransaksi > 0 ? Icons.check_circle : Icons.info_outline,
            color: totalTransaksi > 0 ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              totalTransaksi > 0
                  ? 'Hari ini sudah ada transaksi. Teruskan operasional 👍'
                  : 'Belum ada transaksi hari ini. Tambahkan transaksi untuk mulai mencatat.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU =================
  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _menuItem(
          icon: Icons.add_circle,
          label: 'Tambah\nTransaksi',
          color: Colors.blue,
          onTap: () async {
            final result = await showDialog(
              context: context,
              builder: (_) => const TransactionFormPopup(),
            );

            if (result == true) {
              _refreshSummary();
            }
          },
        ),
        _menuItem(
          icon: Icons.receipt_long,
          label: 'Data\nTransaksi',
          color: Colors.green,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionListScreen(),
              ),
            );
            _refreshSummary();
          },
        ),
        _menuItem(
          icon: Icons.people,
          label: 'Data\nPelanggan',
          color: Colors.orange,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerListScreen(),
              ),
            );
            _refreshSummary();
          },
        ),
        _menuItem(
          icon: Icons.settings,
          label: 'Harga\nAir',
          color: Colors.purple,
          onTap: () {},
        ),
      ],
    );
  }

  // ================= COMPONENT =================
  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
