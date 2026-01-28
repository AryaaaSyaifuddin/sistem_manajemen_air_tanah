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


}
