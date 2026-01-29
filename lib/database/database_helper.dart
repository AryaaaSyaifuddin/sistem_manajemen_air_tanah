import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'air_tanah.db');

    return await openDatabase(
      path,
      version: 2, // Versi dinaikkan karena ada perubahan schema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Buat tabel customers terlebih dahulu karena ada foreign key
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        vehicle_type TEXT NOT NULL,
        plate_number TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Buat tabel transactions dengan foreign key
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        price INTEGER NOT NULL,
        status INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrasi dari versi 1 ke 2
      // 1. Buat tabel customers
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          vehicle_type TEXT NOT NULL,
          plate_number TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 2. Ambil data unik dari transaksi dan masukkan ke customers
      final transactions = await db.query('transactions');
      
      // Gunakan Map untuk menghindari duplikat nama
      final Map<String, Map<String, dynamic>> uniqueCustomers = {};
      
      for (var transaction in transactions) {
        final name = transaction['name'] as String;
        if (!uniqueCustomers.containsKey(name)) {
          uniqueCustomers[name] = {
            'name': name,
            'vehicle_type': transaction['vehicle_type'],
            'plate_number': transaction['plate_number'],
            'created_at': transaction['created_at'],
          };
        }
      }

      // 3. Insert data ke tabel customers
      for (var customer in uniqueCustomers.values) {
        await db.insert('customers', customer);
      }

      // 4. Tambah kolom customer_id ke tabel transactions
      await db.execute('ALTER TABLE transactions ADD COLUMN customer_id INTEGER');

      // 5. Update customer_id di transactions berdasarkan nama
      final customers = await db.query('customers');
      
      for (var customer in customers) {
        await db.update(
          'transactions',
          {'customer_id': customer['id']},
          where: 'name = ?',
          whereArgs: [customer['name']],
        );
      }

      // 6. Hapus kolom yang sudah pindah ke customers
      await db.execute('''
        CREATE TABLE transactions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER,
          price INTEGER NOT NULL,
          status INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
        )
      ''');

      // 7. Pindah data ke tabel baru
      final List<Map<String, dynamic>> oldTransactions = await db.rawQuery('''
        SELECT t.id, t.customer_id, t.price, t.status, t.created_at
        FROM transactions t
      ''');

      for (var transaction in oldTransactions) {
        await db.insert('transactions_new', transaction);
      }

      // 8. Hapus tabel lama dan rename tabel baru
      await db.execute('DROP TABLE transactions');
      await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
    }
  }

  // ================= CUSTOMER METHODS =================
  Future<int> insertCustomer(Map<String, dynamic> data) async {
    final db = await database;
    try {
      return await db.insert('customers', data);
    } catch (e) {
      // Jika terjadi duplicate (nama sudah ada), kembalikan -1
      return -1;
    }
  }

  Future<Map<String, dynamic>?> findCustomerByName(String name) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> searchCustomerByName(String keyword) async {
    final db = await database;
    return await db.query(
      'customers',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'name ASC',
      limit: 5,
    );
  }

  
// Get customer by ID
Future<Map<String, dynamic>?> getCustomerById(int id) async {
  final db = await database;
  final result = await db.query(
    'customers',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return result.isNotEmpty ? result.first : null;
}

// Update customer
Future<int> updateCustomer(int id, Map<String, dynamic> data) async {
  final db = await database;
  return await db.update(
    'customers',
    data,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Delete customer with transaction check
Future<Map<String, dynamic>> deleteCustomer(int id) async {
  final db = await database;
  
  // 1. Cek apakah customer memiliki transaksi terkait
  final transactions = await db.query(
    'transactions',
    where: 'customer_id = ?',
    whereArgs: [id],
  );
  
  if (transactions.isNotEmpty) {
    return {
      'success': false,
      'message': 'Pelanggan memiliki transaksi terkait',
      'transaction_count': transactions.length,
    };
  }
  
  // 2. Hapus customer
  final deletedCount = await db.delete(
    'customers',
    where: 'id = ?',
    whereArgs: [id],
  );
  
  return {
    'success': deletedCount > 0,
    'message': deletedCount > 0 
        ? 'Pelanggan berhasil dihapus' 
        : 'Gagal menghapus pelanggan',
    'deleted_count': deletedCount,
  };
}

// Search customers with pagination
Future<List<Map<String, dynamic>>> searchCustomers(
  String keyword, {
  int limit = 50,
  int offset = 0,
}) async {
  final db = await database;
  
  if (keyword.isEmpty) {
    return await db.query(
      'customers',
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
  }
  
  return await db.query(
    'customers',
    where: 'name LIKE ? OR plate_number LIKE ?',
    whereArgs: ['%$keyword%', '%$keyword%'],
    orderBy: 'name ASC',
    limit: limit,
    offset: offset,
  );
}

// Get customer statistics
Future<Map<String, dynamic>> getCustomerStats(int customerId) async {
    final db = await database;
    
    final stats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        SUM(CASE WHEN status = 1 THEN price ELSE 0 END) as total_spent,
        MIN(created_at) as first_transaction,
        MAX(created_at) as last_transaction
      FROM transactions
      WHERE customer_id = ?
    ''', [customerId]);
    
    return {
      'total_transactions': stats.first['total_transactions'] as int? ?? 0,
      'total_spent': stats.first['total_spent'] as int? ?? 0,
      'first_transaction': stats.first['first_transaction'],
      'last_transaction': stats.first['last_transaction'],
    };
  }
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query(
      'customers',
      orderBy: 'name ASC',
    );
  }

  // ================= TRANSACTION METHODS =================
  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        c.name,
        c.vehicle_type,
        c.plate_number
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.created_at DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTransactionsByKeyword(String keyword) async {
    final db = await database;

    if (keyword.isEmpty) {
      return await db.rawQuery('''
        SELECT 
          t.*,
          c.name,
          c.vehicle_type,
          c.plate_number
        FROM transactions t
        LEFT JOIN customers c ON t.customer_id = c.id
        ORDER BY t.created_at DESC
      ''');
    }

    return await db.rawQuery('''
      SELECT 
        t.*,
        c.name,
        c.vehicle_type,
        c.plate_number
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE c.name LIKE ? OR c.plate_number LIKE ?
      ORDER BY t.created_at DESC
    ''', ['%$keyword%', '%$keyword%']);
  }

  Future<int> updateTransactionStatus(int id, int status) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getTodaySummary() async {
    final db = await database;

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_transaksi,
        SUM(CASE WHEN t.status = 1 THEN t.price ELSE 0 END) as total_pendapatan,
        SUM(CASE WHEN c.vehicle_type = 'tangki' THEN 1 ELSE 0 END) as total_tangki,
        SUM(CASE WHEN c.vehicle_type = 'box' THEN 1 ELSE 0 END) as total_box
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.created_at BETWEEN ? AND ?
    ''', [start, end]);

    return {
      'total_transaksi': result.first['total_transaksi'] as int? ?? 0,
      'total_pendapatan': result.first['total_pendapatan'] as int? ?? 0,
      'total_tangki': result.first['total_tangki'] as int? ?? 0,
      'total_box': result.first['total_box'] as int? ?? 0,
    };
  }
}