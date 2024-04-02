import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import '../models/connect.dart';
import 'dart:io';
import 'dart:convert';
import 'package:xanssh/service/secrethelp.dart';

class SSHConnectionDatabase {
  static final SSHConnectionDatabase instance = SSHConnectionDatabase._init();
  static Database? _database;
  MyEncryptor? _myEncryptor;

  SSHConnectionDatabase._init();

  void setEncryptor(MyEncryptor myEncryptor) {
    _myEncryptor = myEncryptor;
  }

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
    switch (method) {
      // 根据添加时间升序排序
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

  Future<SSHConnectionInfo?> findConnectionByHostAndUsername(
      String host, String username) async {
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

  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.rawDelete('DELETE FROM ssh_connections');
  }

  Future<String?> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // 用户取消了选择
      //print('No directory selected');
      return null;
    } else {
      return selectedDirectory;
    }
  }

  Future<void> exportDataToSelectedFolder() async {
    final String? folderPath = await pickFolder();
    if (folderPath != null) {
      final String encryptedData = await exportData(); // 使用之前定义的导出加密数据的方法
      final String filePath = join(folderPath, 'exported_data.bak'); // 定义文件名
      final File file = File(filePath);
      await file.writeAsString(encryptedData);
      //print('Data exported to $filePath');
    }
  }

  Future<void> importDataFromSelectedFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final String filePath = result.files.single.path!;
      final File file = File(filePath);
      final String encryptedData = await file.readAsString();
      await importData(encryptedData); // 使用之前定义的导入数据的方法
      //print('Data imported from $filePath');
    } else {
      // 用户取消了选择
      //print('No file selected');
    }
  }

  Future<String> exportData() async {
    final db = await instance.database;
    final result = await db.query('ssh_connections');
    final String jsonData = jsonEncode(result);
    // 这里假设你有一个encryptData方法来加密JSON数据
    final encryptedData = encryptData(jsonData);
    return encryptedData;
  }

  String encryptData(String data) {
    if (_myEncryptor != null) {
      return _myEncryptor!.encryptData(data); // 返回加密后的数据
    } else {
      //print("请先设置密钥");
      return "";
    }
  }

  Future<void> importData(String encryptedData) async {
    final db = await instance.database;
    // 假设你有一个decryptData方法来解密数据
    final decryptedData = decryptData(encryptedData);
    final List<dynamic> dataList = jsonDecode(decryptedData);
    for (final data in dataList) {
      await db.insert('ssh_connections', data);
    }
  }

  String decryptData(String data) {
    if (_myEncryptor != null) {
      return _myEncryptor!.decryptData(data); // 返回解密后的数据
    } else {
      //print("请先设置密钥");
      return "";
    }
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
