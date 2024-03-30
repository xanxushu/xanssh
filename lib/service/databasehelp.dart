import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/connect.dart';

class SSHConnectionDatabase {
  static final SSHConnectionDatabase instance = SSHConnectionDatabase._init();
  static Database? _database;

  SSHConnectionDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ssh_connections.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE ssh_connections (
  id $idType,
  host $textType,
  port $integerType,
  username $textType,
  password $textType,
  lastLoginTime $textType
)
''');
  }

  Future<void> create(SSHConnectionInfo info) async {
    final db = await instance.database;

    final json = info.toJson();
    final columns = json.keys.join(', ');
    final values = json.values.map((value) => '?').join(', ');

    await db.rawInsert(
        'INSERT INTO ssh_connections ($columns) VALUES ($values)',
        json.values.toList());
  }

  Future<List<SSHConnectionInfo>> readAllConnections(String method) async {
    final db = await instance.database;
    late String orderBy;
    switch (method) { // 根据添加时间升序排序
      case 'last_asc':
        orderBy = 'lastLoginTime ASC'; //
      default:
        orderBy = 'lastLoginTime DESC';
    }
    final result = await db.query('ssh_connections', orderBy: orderBy);

    return result.map((json) => SSHConnectionInfo.fromJson(json)).toList();
  }

  Future<int> update(SSHConnectionInfo info) async {
    final db = await instance.database;

    return db.update(
      'ssh_connections',
      info.toJson(),
      where: 'id = ?',
      whereArgs: [info.id],
    );
  }


  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      'ssh_connections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SSHConnectionInfo?> findConnectionByHostAndUsername(String host, String username) async {
    final db = await database; // 获取数据库实例
    final maps = await db.query(
      'ssh_connections',
      columns: ['id', 'host', 'port', 'username', 'password', 'lastLoginTime'],
      where: 'host = ? AND username = ?',
      whereArgs: [host, username],
    );

    if (maps.isNotEmpty) {
      // 如果找到匹配项，返回第一个结果
      return SSHConnectionInfo.fromJson(maps.first);
    } else {
      // 如果没有找到匹配项，返回null
      return null;
    }
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
