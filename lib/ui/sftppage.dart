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
  String _currentPathLeft = '/';
  String _currentPathRight = '/';
  final ScrollController _scrollControllerLeft = ScrollController();
  final ScrollController _scrollControllerRight = ScrollController();

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
                  Expanded(
                      child: _buildFileBrowser(_filesLeft, _currentPathLeft,true)),
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
                  Expanded(
                      child: _buildFileBrowser(_filesRight, _currentPathRight,false)),
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
  Widget _buildFileBrowser(List<FileInfo>? files, String currentPath, bool isLeftPanel) {
    ScrollController scrollController = isLeftPanel ? _scrollControllerLeft : _scrollControllerRight;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('当前路径: $currentPath',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      Expanded(
        child: DragTarget<FileInfo>(
          onWillAccept: (file) => file != null && file.type != FileType.directory, // 仅接受文件类型，如果需要支持目录，可以调整这里的逻辑
          onAccept: (file) async {
            // 处理文件传输的逻辑
            // isLeftPanel 表示是否是左侧面板，根据这个标志可以判断文件是从左拖到右还是从右拖到左
            String targetPath = isLeftPanel ? _currentPathRight : _currentPathLeft;
            // 根据实际情况调用上传或下载方法...
          },
          builder: (context, candidateData, rejectedData) {
            return files == null
                ? const Center(child: Text('请选择一个连接。'))
                : CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        // 这里仅对文件应用拖拽功能，目录不应用
                        return file.type == FileType.directory
                            ? CupertinoListTile(
                                title: Text(file.name),
                                leading: const Icon(CupertinoIcons.folder),
                                onTap: () => _handleFileOrDirectoryTap(file, currentPath),
                              )
                            : _buildDraggableFileItem(file, currentPath); // 使用之前定义的方法构建可拖拽的文件项
                      },
                    ),
                  );
          },
        ),
      ),
    ],
  );
}

  void _listDirectoryLeft(String username) async {
    if (_serviceLeft != null) {
      if (username == 'root') {
        String path = '/';
        final files = await _serviceLeft!.listDirectory(path); // 假设列出根目录
        final processedFiles = files.where((file) => file.name != '.').toList();
        processedFiles.sort((a, b) {
          if (a.name == '..') return -1;
          if (b.name == '..') return 1;
          return a.name.compareTo(b.name);
        });
        setState(() {
          _currentPathLeft = path;
          _filesLeft = processedFiles.where((file) => file.name != '..').toList(); // 根目录不显示'..'目录
        });
      } else {
        String path = '/home/$username';
        final files = await _serviceLeft!.listDirectory(path);
        final processedFiles = files.where((file) => file.name != '.').toList();
        processedFiles.sort((a, b) {
          if (a.name == '..') return -1;
          if (b.name == '..') return 1;
          return a.name.compareTo(b.name);
        });
        setState(() {
          _currentPathLeft = path;
          _filesLeft = processedFiles; // 更新文件列表
        });
      }
    }
  }

  void _listDirectoryRight(String username) async {
    if (_serviceRight != null) {
      if (username == 'root') {
        String path = '/';
        final files = await _serviceRight!.listDirectory(path); // 假设列出根目录
        final processedFiles = files.where((file) => file.name != '.').toList();
        processedFiles.sort((a, b) {
          if (a.name == '..') return -1;
          if (b.name == '..') return 1;
          return a.name.compareTo(b.name);
        });
        setState(() {
          _currentPathRight = path;
          _filesRight = processedFiles.where((file) => file.name != '..').toList(); // 根目录不显示'..'目录
        });
      } else {
        String path = '/home/$username';
        final files = await _serviceRight!.listDirectory(path);
        final processedFiles = files.where((file) => file.name != '.').toList();
        processedFiles.sort((a, b) {
          if (a.name == '..') return -1;
          if (b.name == '..') return 1;
          return a.name.compareTo(b.name);
        });
        setState(() {
          _currentPathRight = path;
          _filesRight = processedFiles; // 更新文件列表
        });
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
        return Column(children: [
          // 添加一个关闭按钮
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoButton(
                child: const Text('关闭'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // 使用Expanded包裹ListView以充满剩余空间
          Expanded(
            child: ListView.builder(
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
            ),
          ),
        ]);
      },
    );
  }

  void _handleFileOrDirectoryTap(FileInfo file, String currentPath) async {
    if (file.type == FileType.directory) {
      // 如果是目录，则更新列表和当前路径
      String newPath = currentPath.endsWith('/')
          ? '$currentPath${file.name}'
          : '$currentPath/${file.name}';
      final files = await _serviceLeft!
          .listDirectory(newPath); // 根据实际情况使用 _serviceLeft 或 _serviceRight
      setState(() {
        _filesLeft = files; // 根据是左侧还是右侧进行更新
        _currentPathLeft = newPath; // 同上
      });
    } else {
      // 如果是文件，弹出一个窗口显示文件信息
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(file.name),
            content: Column(
              children: <Widget>[
                Text('大小: ${file.size}'),
                Text('修改日期: ${file.modificationDate}'),
                // 可以添加更多文件信息
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('关闭'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

Widget _buildDraggableFileItem(FileInfo file, String currentPath) {
  return Draggable<FileInfo>(
    data: file,
    feedback: CupertinoPageScaffold(
      child: SizedBox( 
        width: MediaQuery.of(context).size.width,
        child:CupertinoListTile(
        title: Text(file.name),
        leading: Icon(file.type == FileType.directory ? CupertinoIcons.folder : CupertinoIcons.doc),
      ),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.5,
      child: CupertinoListTile(
        title: Text(file.name),
        leading: Icon(file.type == FileType.directory ? CupertinoIcons.folder : CupertinoIcons.doc),
      ),
    ),
    child: CupertinoListTile(
      title: Text(file.name),
      leading: Icon(file.type == FileType.directory ? CupertinoIcons.folder : CupertinoIcons.doc),
      onTap: () => _handleFileOrDirectoryTap(file, currentPath),
    ),
  );
}


}
