import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  
  static const int _databaseVersion = 4; // Versi terakhir

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'air_tanah.db');
    print('Database path: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Buat tabel vehicle_types terlebih dahulu
    await db.execute('''
      CREATE TABLE vehicle_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert data default
    await db.insert('vehicle_types', {
      'name': 'Truck Tangki',
      'price': 16000,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    await db.insert('vehicle_types', {
      'name': 'Box',
      'price': 10000,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Buat tabel customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        vehicle_type TEXT NOT NULL,
        plate_number TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Buat tabel transactions dengan foreign keys
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        vehicle_type_id INTEGER,
        price INTEGER NOT NULL,
        status INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
        FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi dari versi 1 ke 2
    if (oldVersion < 2) {
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

      // 6. Buat tabel baru tanpa kolom name, vehicle_type, plate_number
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

    // Migrasi dari versi 2 ke 3 (tambah vehicle_types)
    if (oldVersion < 3) {
      // 1. Buat tabel vehicle_types
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vehicle_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          price INTEGER NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // 2. Insert data default jika belum ada
      final existingTypes = await db.query('vehicle_types');
      if (existingTypes.isEmpty) {
        await db.insert('vehicle_types', {
          'name': 'Truck Tangki',
          'price': 16000,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        await db.insert('vehicle_types', {
          'name': 'Box',
          'price': 10000,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Tambah kolom vehicle_type_id ke transactions
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN vehicle_type_id INTEGER');
      } catch (e) {
        // Kolom mungkin sudah ada
      }

      // 4. Update vehicle_type_id berdasarkan data customers
      final customers = await db.query('customers');
      for (var customer in customers) {
        final vehicleTypeName = customer['vehicle_type'];
        if (vehicleTypeName != null) {
          final vehicleType = await db.query(
            'vehicle_types',
            where: 'name LIKE ?',
            whereArgs: ['%$vehicleTypeName%'],
            limit: 1,
          );
          
          if (vehicleType.isNotEmpty) {
            await db.update(
              'transactions',
              {'vehicle_type_id': vehicleType.first['id']},
              where: 'customer_id = ?',
              whereArgs: [customer['id']],
            );
          }
        }
      }
    }

    // Migrasi dari versi 3 ke 4 (perbaikan dan optimasi)
    if (oldVersion < 4) {
      // Tambah index untuk performa
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions(customer_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_vehicle_type_id ON transactions(vehicle_type_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
    }
  }

  // ================= VEHICLE TYPES METHODS =================

  Future<List<Map<String, dynamic>>> getAllVehicleTypes() async {
    final db = await database;
    return await db.query(
      'vehicle_types',
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getActiveVehicleTypes() async {
    final db = await database;
    return await db.query(
      'vehicle_types',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getVehicleTypeById(int id) async {
    final db = await database;
    final result = await db.query(
      'vehicle_types',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertVehicleType(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert('vehicle_types', data);
  }

  Future<int> updateVehicleType(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'vehicle_types',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVehicleType(int id) async {
    final db = await database;
    
    // Cek apakah vehicle type digunakan di transaksi
    final transactions = await db.query(
      'transactions',
      where: 'vehicle_type_id = ?',
      whereArgs: [id],
    );
    
    if (transactions.isNotEmpty) {
      // Jangan hapus, nonaktifkan saja
      return await db.update(
        'vehicle_types',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    return await db.delete(
      'vehicle_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isVehicleTypeInUse(int id) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'vehicle_type_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
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

  Future<int> updateCustomer(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'customers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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
        c.plate_number,
        vt.name as vehicle_type_name,
        vt.price as vehicle_type_price
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN vehicle_types vt ON t.vehicle_type_id = vt.id
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
          c.plate_number,
          vt.name as vehicle_type_name,
          vt.price as vehicle_type_price
        FROM transactions t
        LEFT JOIN customers c ON t.customer_id = c.id
        LEFT JOIN vehicle_types vt ON t.vehicle_type_id = vt.id
        ORDER BY t.created_at DESC
      ''');
    }

    return await db.rawQuery('''
      SELECT 
        t.*,
        c.name,
        c.plate_number,
        vt.name as vehicle_type_name,
        vt.price as vehicle_type_price
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN vehicle_types vt ON t.vehicle_type_id = vt.id
      WHERE c.name LIKE ? OR c.plate_number LIKE ? OR vt.name LIKE ?
      ORDER BY t.created_at DESC
    ''', ['%$keyword%', '%$keyword%', '%$keyword%']);
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
        COUNT(CASE WHEN vt.name LIKE '%tangki%' OR vt.name LIKE '%Tangki%' THEN 1 END) as total_tangki,
        COUNT(CASE WHEN vt.name LIKE '%box%' OR vt.name LIKE '%Box%' THEN 1 END) as total_box
      FROM transactions t
      LEFT JOIN vehicle_types vt ON t.vehicle_type_id = vt.id
      WHERE t.created_at BETWEEN ? AND ?
    ''', [start, end]);

    return {
      'total_transaksi': result.first['total_transaksi'] as int? ?? 0,
      'total_pendapatan': result.first['total_pendapatan'] as int? ?? 0,
      'total_tangki': result.first['total_tangki'] as int? ?? 0,
      'total_box': result.first['total_box'] as int? ?? 0,
    };
  }

  // ================= UTILITY METHODS =================

  Future<int> getTotalCustomers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getTotalTransactions() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getTotalRevenue() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM transactions WHERE status = 1'
    );
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.*,
        c.name,
        vt.name as vehicle_type_name
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN vehicle_types vt ON t.vehicle_type_id = vt.id
      ORDER BY t.created_at DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('customers');
      await txn.delete('vehicle_types');
      
      // Reset auto increment
      await txn.execute('DELETE FROM sqlite_sequence WHERE name IN ("transactions", "customers", "vehicle_types")');
    });
  }

  Future<void> backupDatabase() async {
    final db = await database;
    // Implementasi backup sederhana
    // Di aplikasi nyata, ini bisa menyalin file database ke lokasi aman
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'air_tanah.db');
    print('Database backed up at: $path');
  }
}
