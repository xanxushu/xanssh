import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:xanssh/models/connect.dart';
import 'package:xanssh/models/sftp.dart';

class SFTPService {
  SSHClient? _client;
  SftpClient? _sftp;

  /// 连接到SFTP服务器
  Future<bool> connect(SSHConnectionInfo info) async {
    try {
      _client = SSHClient(
        await SSHSocket.connect(info.host, info.port),
        username: info.username,
        onPasswordRequest: () => info.password,
      );
      _sftp = await _client?.sftp();
      return true;
    } catch (e) {
      print('Error connecting to SFTP server: $e');
      return false;
    }
  }

  /// 断开与SFTP服务器的连接
  Future<void> disconnect() async {
    _sftp?.close();
    _client?.close();
  }

  /// 列出指定目录的内容
  Future<List<FileInfo>> listDirectory(String path) async {
    final files = <FileInfo>[];
    try {
      final entries = await _sftp?.listdir(path) ?? [];
      for (final entry in entries) {
        files.add(FileInfo(
          name: entry.filename,
          type: entry.attr.isDirectory ? FileType.directory : FileType.file,
          size: entry.attr.size ?? 0,
          modificationDate: entry.attr.modifyTime != null ? DateTime.fromMillisecondsSinceEpoch(entry.attr.modifyTime! * 1000) : null,
        ));
      }
    } catch (e) {
      print('Error listing directory: $e');
    }
    return files;
  }

  /// 上传文件到服务器
  Future<bool> uploadFile(String localPath, String remotePath) async {
    try {
      final file = File(localPath);
      final remoteFile = await _sftp?.open(remotePath, mode: SftpFileOpenMode.write);
      await remoteFile?.write(Stream.value(file.readAsBytesSync()));
      await remoteFile?.close();
      return true;
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }

  /// 从服务器下载文件
  Future<bool> downloadFile(String remotePath, String localPath) async {
    try {
      final remoteFile = await _sftp?.open(remotePath, mode: SftpFileOpenMode.read);
      final data = remoteFile?.read();
      final buffer = await data!.toList(); // 将Stream转换为List
      await remoteFile?.close();
      final file = File(localPath);
      await file.writeAsBytes(buffer.expand((i) => i).toList());
      return true;
    } catch (e) {
      print('Error downloading file: $e');
      return false;
    }
  }
}
