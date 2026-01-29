// import 'package:flutter/material.dart';
// import '../database/database_helper.dart';

// class CustomerListScreen extends StatefulWidget {
//   const CustomerListScreen({super.key});

//   @override
//   State<CustomerListScreen> createState() => _CustomerListScreenState();
// }

// class _CustomerListScreenState extends State<CustomerListScreen> {
//   late Future<List<Map<String, dynamic>>> _customersFuture;
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadCustomers();
//   }

//   void _loadCustomers([String keyword = '']) {
//     setState(() {
//       _customersFuture = keyword.isEmpty
//           ? DatabaseHelper.instance.getAllCustomers()
//           : DatabaseHelper.instance.searchCustomers(keyword);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F8),
//       appBar: AppBar(
//         title: const Text('Data Pelanggan'),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           // ===== SEARCH =====
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: TextField(
//               controller: _searchController,
//               onChanged: _loadCustomers,
//               decoration: InputDecoration(
//                 hintText: 'Cari nama pelanggan...',
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//           ),

//           // ===== LIST =====
//           Expanded(
//             child: FutureBuilder<List<Map<String, dynamic>>>(
//               future: _customersFuture,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.data!.isEmpty) {
//                   return const Center(
//                     child: Text('Belum ada data pelanggan'),
//                   );
//                 }

//                 final customers = snapshot.data!;

//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   itemCount: customers.length,
//                   itemBuilder: (context, index) {
//                     final c = customers[index];

//                     return Container(
//                       margin: const EdgeInsets.only(bottom: 12),
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 24,
//                             backgroundColor: Colors.blue.withValues(alpha: 0.1),
//                             child: const Icon(Icons.person, color: Colors.blue),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   c['name'],
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Tipe: ${c['vehicle_type'] ?? '-'}',
//                                   style: TextStyle(color: Colors.grey[600]),
//                                 ),
//                                 if (c['plate_number'] != null &&
//                                     c['plate_number'].toString().isNotEmpty)
//                                   Text(
//                                     'Plat: ${c['plate_number']}',
//                                     style:
//                                         TextStyle(color: Colors.grey[600]),
//                                   ),
//                               ],
//                             ),
//                           ),
//                           const Icon(Icons.chevron_right),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
