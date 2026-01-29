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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        plate_number TEXT,
        price INTEGER NOT NULL,
        status INTEGER,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ================= INSERT =================
  Future<int> insertTransaction(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> searchCustomerByName(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      groupBy: 'name',
      limit: 5,
    );
  }


  // ================= GET ALL =================
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query(
      'transactions',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateTransactionStatus(int id, int status) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByKeyword(
    String keyword) async {
    final db = await database;

    if (keyword.isEmpty) {
      return db.query(
        'transactions',
        orderBy: 'created_at DESC',
      );
    }

    return db.query(
      'transactions',
      where: 'name LIKE ? OR plate_number LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, int>> getTodaySummary() async {
    final db = await database;

    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final end =
        DateTime(today.year, today.month, today.day, 23, 59, 59)
            .toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_transaksi,
        SUM(CASE WHEN status = 1 THEN price ELSE 0 END) as total_pendapatan,
        SUM(CASE WHEN vehicle_type = 'tangki' THEN 1 ELSE 0 END) as total_tangki,
        SUM(CASE WHEN vehicle_type = 'box' THEN 1 ELSE 0 END) as total_box
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
    ''', [start, end]);

    return {
      'total_transaksi': result.first['total_transaksi'] as int? ?? 0,
      'total_pendapatan': result.first['total_pendapatan'] as int? ?? 0,
      'total_tangki': result.first['total_tangki'] as int? ?? 0,
      'total_box': result.first['total_box'] as int? ?? 0,
    };
  }




}
