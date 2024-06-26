import 'package:flutter/cupertino.dart';
import 'package:xanssh/models/connect.dart';
import 'package:xanssh/ui/inputsshpage.dart';
import 'package:xanssh/service/databasehelp.dart';
import 'package:xanssh/service/openterminal.dart';
import 'package:intl/intl.dart';

class MyConnectionsPage extends StatefulWidget {
  const MyConnectionsPage({super.key});

  @override
  _MyConnectionsPageState createState() => _MyConnectionsPageState();
}

class _MyConnectionsPageState extends State<MyConnectionsPage> {
  //Future<List<SSHConnectionInfo>>? _connections;
  List<SSHConnectionInfo>? _filteredConnections = []; // 用于显示的过滤后的连接列表
  //String _searchText = ''; // 搜索框文本

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  void _loadConnections() async {
    final allConnections =
        await SSHConnectionDatabase.instance.readAllConnections("default");
    setState(() {
      _filteredConnections = allConnections;
    });
  }

  void _filterConnections(String searchText) {
    if (searchText.isEmpty) {
      _loadConnections();
    } else {
      setState(() {
        _filteredConnections = _filteredConnections?.where((connection) {
          return connection.host.contains(searchText) ||
              connection.username.contains(searchText);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Title and Subtitle
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '我的连接',
                    style:
                        CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoSearchTextField(
                      onChanged: (value) {
                        _filterConnections(value);
                      },
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const ConnectPage()),
                      );
                    },
                    child: const Icon(CupertinoIcons.add),
                  ),
                ],
              ),
            ),
            // Connection List
            Expanded(
              child: FutureBuilder<List<SSHConnectionInfo>>(
                future: Future.value(_filteredConnections), // 使用过滤后的连接列表
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final connections = snapshot.data!;
                    // Adjust layout based on platform
                    final isDesktop = MediaQuery.of(context).size.width > 600;
                    final crossAxisCount = isDesktop ? 2 : 1;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 3, // 调整这个比例以增加垂直空间
                      ),
                      itemCount: connections.length,
                      itemBuilder: (context, index) {
                        final connection = connections[index];
                        return Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${connection.username}@${connection.host}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4), // 调整间距
                              Text(
                                '上次连接: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(connection.lastLoginTime!)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.systemBlue,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CupertinoButton(
                                    child: const Icon(CupertinoIcons.play_fill),
                                    onPressed: () async {
                                      openNewWindow(context, connection);
                                      _loadConnections();
                                    },
                                  ),
                                  CupertinoButton(
                                    child: const Icon(CupertinoIcons.pencil),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (context) => ConnectPage(
                                                existingConnection:
                                                    connection)),
                                      );
                                      _loadConnections();
                                    },
                                  ),
                                  CupertinoButton(
                                    child: const Icon(CupertinoIcons.trash),
                                    onPressed: () {
                                      // 弹出确认删除的对话框
                                      showCupertinoDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            CupertinoAlertDialog(
                                          title: const Text('确认删除'),
                                          content: const Text('你确定要删除这个连接吗？'),
                                          actions: <Widget>[
                                            CupertinoDialogAction(
                                              child: const Text('取消'),
                                              onPressed: () {
                                                Navigator.pop(
                                                    context); // 关闭对话框，不执行删除操作
                                              },
                                            ),
                                            CupertinoDialogAction(
                                              isDestructiveAction: true,
                                              onPressed: () async {
                                                // 执行删除操作
                                                await SSHConnectionDatabase
                                                    .instance
                                                    .delete(connection
                                                        .id!); // 假设你的数据库类有这个方法
                                                Navigator.pop(context); // 关闭对话框

                                                // 刷新连接列表
                                                _loadConnections();
                                              },
                                              child: const Text('删除'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('暂无连接，请点击右上角+按钮添加连接。'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
