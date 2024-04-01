import 'package:flutter/cupertino.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'models/connect.dart';
import 'ui/terminalpage.dart';
import 'ui/myconnectpage.dart';
import 'ui/sftppage.dart';
import 'ui/settingpage.dart';
import 'dart:convert';

void main(List<String> args) {
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument = jsonDecode(args[2]) as Map<String, dynamic>;
    if (argument['page'] == 'TerminalPage') {
      runApp(_ExampleSubWindow(
        windowController: WindowController.fromWindowId(windowId),
        connection: SSHConnectionInfo.fromJson(
            argument['connection']), // 传递给TerminalPage的参数
        args: argument['args'],
      ));
    }
  } else {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'XANSSH',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int initialPageIndex;

  const MyHomePage({super.key, this.initialPageIndex = 0});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<SSHConnectionInfo> connections = [];
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
    _widgetOptions = [
      const MyConnectionsPage(),
      const SFTPExplorer(), // 将原有的终端连接逻辑放入此页面
      const SettingPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            CupertinoTabBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: '我的连接',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.folder),
                  label: 'SFTP',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings_solid),
                  label: '设置',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleSubWindow extends StatelessWidget {
  final WindowController windowController;
  final SSHConnectionInfo connection;
  final Map? args;

  const _ExampleSubWindow({
    Key? key,
    required this.windowController,
    required this.connection,
    required this.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据传递的参数创建TerminalPage
    return CupertinoApp(
      title: "${connection.username}@${connection.host}",
      home: TerminalPage(connection: connection),
    );
  }
}
