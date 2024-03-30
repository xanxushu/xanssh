import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xanssh/models/sftp.dart';
import 'package:xanssh/models/connect.dart';
import 'package:xanssh/service/sftphelp.dart';
import 'package:xanssh/service/databasehelp.dart';

class SFTPExplorer extends StatefulWidget {
  const SFTPExplorer({super.key});

  @override
  _SFTPExplorerState createState() => _SFTPExplorerState();
}

class _SFTPExplorerState extends State<SFTPExplorer> {
  SFTPService? _serviceLeft;
  SFTPService? _serviceRight;
  List<FileInfo>? _filesLeft;
  List<FileInfo>? _filesRight;
//  Future<List<SSHConnectionInfo>>? _connections;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('SFTP文件传输'),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 左边的连接和文件浏览器面板
            Expanded(
              child: Column(
                children: [
                  CupertinoButton(
                    child: const Text('显示连接列表'),
                    onPressed: () => showConnectionListModal(context, 'Left'),
                  ),
                  Expanded(child: _buildFileBrowser(_filesLeft)),
                ],
              ),
            ),
            // 右边的连接和文件浏览器面板
            Expanded(
              child: Column(
                children: [
                  CupertinoButton(
                    child: const Icon(CupertinoIcons.add),
                    onPressed: () => showConnectionListModal(context, 'Right'),
                  ),
                  Expanded(child: _buildFileBrowser(_filesRight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

/*  Widget _buildConnectionPanel(
      String label, Function(SFTPService) onConnected) {
    setState(() {
      _connections =
          SSHConnectionDatabase.instance.readAllConnections('default');
    });

    return Expanded(
      child: FutureBuilder<List<SSHConnectionInfo>>(
          future: _connections,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final connections = snapshot.data!;
              return ListView.builder(
                  itemCount: connections.length,
                  itemBuilder: (context, index) {
                    final connection = connections[index];
                    return CupertinoListTile(
                      title: Text('${connection.username}@${connection.host}'),
                      // 根据文件类型显示不同的图标
                      leading: const Icon(CupertinoIcons.device_desktop),
                      trailing: CupertinoButton(
                        child: const Icon(CupertinoIcons.play_fill),
                        onPressed: () async {
                          final service = SFTPService();
                          final connected = await service.connect(connection); // 确保等待连接完成
                          if (connected) {
                            onConnected(service);
                          } else {
                            // 可以在这里处理连接失败的情况，比如通过对话框通知用户
                            print('无法连接到SFTP服务器。');
                          }
                        },
                      ),
                    );
                  });
            } else {
              return const Center(child: Text('没有保存的连接。'));
            }
          }),
    );
  }
*/
  Widget _buildFileBrowser(List<FileInfo>? files) {
    if (files == null) {
      return const Center(child: Text('请选择一个连接。'));
    }
    return CupertinoScrollbar(
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return CupertinoListTile(
            title: Text(file.name),
            // 根据文件类型显示不同的图标
            leading: Icon(file.type == FileType.directory
                ? CupertinoIcons.folder
                : CupertinoIcons.doc),
            trailing: Text(file.size.toString()),
            onTap: () {
              // 添加文件点击事件
            },
          );
        },
      ),
    );
  }

  void _listDirectoryLeft(String username) async {
    if (_serviceLeft != null) {
      if (username == 'root') {
        final files = await _serviceLeft!.listDirectory('/'); // 假设列出根目录
        setState(() => _filesLeft = files);
      } else {
        final files = await _serviceLeft!.listDirectory('/home/$username');
        setState(() => _filesLeft = files);
      }
    }
  }

  void _listDirectoryRight(String username) async {
    if (_serviceRight != null) {
      if (username == 'root') {
        final files = await _serviceRight!.listDirectory('/'); // 假设列出根目录
        setState(() => _filesRight = files);
      } else {
        final files = await _serviceRight!.listDirectory('/home/$username');
        setState(() => _filesRight = files);
      }
    }
  }

  Future<void> showConnectionListModal(
      BuildContext context, String label) async {
    List<SSHConnectionInfo>? connections;
    String errorMessage = '';

    try {
      connections =
          await SSHConnectionDatabase.instance.readAllConnections('default');
      if (connections.isEmpty) {
        errorMessage = '没有保存的连接。';
      }
    } catch (e) {
      errorMessage = '加载连接时出错：$e';
    }

    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      barrierColor:
          CupertinoColors.systemGroupedBackground, //.extraLightBackgroundGray,
      builder: (BuildContext context) {
        // 检查连接是否为空或出现错误
        if (connections == null || connections.isEmpty) {
          return Center(child: Text(errorMessage));
        }

        // 如果有连接数据，则构建列表显示
        return ListView.builder(
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections![index];
            return CupertinoListTile(
              leading: const Icon(CupertinoIcons.device_desktop),
              title: Text(
                '${connection.username}@${connection.host}',
                style: const TextStyle(color: Colors.blueAccent),
              ),
              onTap: () async {
                final service = SFTPService();
                final connected = await service.connect(connection);
                if (connected) {
                  if (label == 'Left') {
                    _serviceLeft = service;
                    _listDirectoryLeft(connection.username);
                  } else {
                    _serviceRight = service;
                    _listDirectoryRight(connection.username);
                  }
                  Navigator.of(context).pop();
                } else {
                  // 可以在这里显示连接失败的信息
                  Navigator.of(context).pop();
                }
              },
            );
          },
        );
      },
    );
  }
}
