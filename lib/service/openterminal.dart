import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import '../models/connect.dart';
import '../ui/terminalpage.dart';
import 'databasehelp.dart';

void openNewWindow(BuildContext context,SSHConnectionInfo connection) async {
    final now = DateTime.now();
    var existingConnection = await SSHConnectionDatabase.instance
      .findConnectionByHostAndUsername(connection.host, connection.username);

    if (existingConnection != null) {
      // 如果存在，更新 lastLoginTime
      existingConnection.lastLoginTime = now;
      await SSHConnectionDatabase.instance.update(existingConnection);
    } else {
      // 如果不存在，插入新记录，同时设置 addedTime 和 lastLoginTime
      connection.lastLoginTime = now;
                    
      await SSHConnectionDatabase.instance.create(connection);
    }
    // 现在，根据平台打开新窗口或导航至 TerminalPage
    if (Platform.isIOS || Platform.isAndroid) {
      Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => TerminalPage(connection: connection)),
      );
    } else {
      // 对于非移动平台，将连接信息传递给新窗口
      final window = await DesktopMultiWindow.createWindow(jsonEncode({
        'page': 'TerminalPage',
        'connection': connection.toJson(),
      }));
      window
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..center()
        ..setTitle('Terminal')
        ..show();
    }
  }