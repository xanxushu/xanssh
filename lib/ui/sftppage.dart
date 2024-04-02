// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xanssh/models/sftp.dart';
import 'package:xanssh/models/connect.dart';
import 'package:xanssh/service/sftphelp.dart';
import 'package:xanssh/service/databasehelp.dart';
import 'package:xanssh/ui/cupertinosnackbar.dart';

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        child: const Icon(CupertinoIcons.add),
                        onPressed: () =>
                            showConnectionListModal(context, 'Left'),
                      ),
                      CupertinoButton(
                        child: const Icon(CupertinoIcons.folder_badge_plus),
                        onPressed: () async {
                          if (_serviceLeft != null) {
                            final String? newFolderName =
                                await showCreateFolderDialog(context);
                            if (newFolderName != null &&
                                newFolderName.trim().isNotEmpty) {
                              final bool success = await _serviceLeft!
                                  .createDirectory(
                                      '$_currentPathLeft/$newFolderName');
                              if (success) {
                                // 如果创建成功，刷新当前目录列表
                                final filesAfter = await _serviceLeft!
                                    .listDirectory(_currentPathLeft);
                                setState(() {
                                  _filesLeft = filesAfter;
                                });
                                showCupertinoSnackBar(
                                    context: context,
                                    message: '文件夹创建成功',
                                    durationMillis: 2 * 1000);
                              } else {
                                // 处理创建失败的情况
                                showCupertinoSnackBar(
                                    context: context,
                                    message: '文件夹创建失败',
                                    durationMillis: 2 * 1000);
                              }
                            }
                          } else {
                            // 处理未选择连接的情况
                            showCupertinoSnackBar(
                                context: context,
                                message: '请先选择一个连接',
                                durationMillis: 2 * 1000);
                          }
                        },
                      ),
                    ],
                  ),
                  Expanded(
                      child: _buildFileBrowser(
                          _filesLeft, _currentPathLeft, true)),
                ],
              ),
            ),
            // 右边的连接和文件浏览器面板
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        child: const Icon(CupertinoIcons.add),
                        onPressed: () =>
                            showConnectionListModal(context, 'Right'),
                      ),
                      CupertinoButton(
                        child: const Icon(CupertinoIcons.folder_badge_plus),
                        onPressed: () async {
                          if (_serviceRight != null) {
                            final String? newFolderName =
                                await showCreateFolderDialog(context);
                            if (newFolderName != null &&
                                newFolderName.trim().isNotEmpty) {
                              final bool success = await _serviceRight!
                                  .createDirectory(
                                      '$_currentPathRight/$newFolderName');
                              if (success) {
                                // 如果创建成功，刷新当前目录列表
                                final filesAfter = await _serviceRight!
                                    .listDirectory(_currentPathRight);
                                setState(() {
                                  _filesRight = filesAfter;
                                });
                                showCupertinoSnackBar(
                                    context: context,
                                    message: '成功创建文件夹',
                                    durationMillis: 2 * 1000);
                              } else {
                                // 处理创建失败的情况
                                showCupertinoSnackBar(
                                    context: context,
                                    message: '文件夹创建失败',
                                    durationMillis: 2 * 1000);
                              }
                            }
                          } else {
                            // 处理未选择连接的情况
                            showCupertinoSnackBar(
                                context: context,
                                message: '请先选择一个连接',
                                durationMillis: 2 * 1000);
                          }
                        },
                      ),
                    ],
                  ),
                  Expanded(
                      child: _buildFileBrowser(
                          _filesRight, _currentPathRight, false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBrowser(
      List<FileInfo>? files, String currentPath, bool isLeftPanel) {
    ScrollController scrollController =
        isLeftPanel ? _scrollControllerLeft : _scrollControllerRight;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('当前路径: $currentPath',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: DragTarget<FileInfo>(
            onWillAccept: (file) =>
                file != null &&
                file.type != FileType.directory, // 仅接受文件类型，如果需要支持目录，可以调整这里的逻辑
            onAccept: (file) async {
              await transferFileBetweenServers(file, !isLeftPanel);
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
                                  trailing: Text(file.size.toString()),
                                  onTap: () => _handleFileOrDirectoryTap(
                                      file, currentPath, isLeftPanel),
                                )
                              : _buildDraggableFileItem(file, currentPath,
                                  isLeftPanel); // 使用之前定义的方法构建可拖拽的文件项
                        },
                      ),
                    );
            },
          ),
        ),
      ],
    );
  }

  void _listDirectoryLeft(String username, String host) async {
    if (_serviceLeft != null) {
      if (username == 'root') {
        String path = '/';
        final files = await _serviceLeft!.listDirectory(path); // 假设列出根目录
        setState(() {
          _currentPathLeft = path;
          _filesLeft = files;
        });
      } else {
        String path = '';
        if (host == 'localhost') {
          if (Platform.isMacOS) {
            path = '/Users/$username';
          } else {
            path = '/home/$username';
          }
        } else {
          path = '/home/$username';
        }
        final files = await _serviceLeft!.listDirectory(path);
        setState(() {
          _currentPathLeft = path;
          _filesLeft = files; // 更新文件列表
        });
      }
    }
  }

  void _listDirectoryRight(String username, String host) async {
    if (_serviceRight != null) {
      if (username == 'root') {
        String path = '/';
        final files = await _serviceRight!.listDirectory(path); // 假设列出根目录
        setState(() {
          _currentPathRight = path;
          _filesRight = files; // 根目录不显示'..'目录
        });
      } else {
        String path = '';
        if (host == 'localhost') {
          if (Platform.isMacOS) {
            path = '/Users/$username';
          } else {
            path = '/home/$username';
          }
        } else {
          path = '/home/$username';
        }
        final files = await _serviceRight!.listDirectory(path);
        setState(() {
          _currentPathRight = path;
          _filesRight = files; // 更新文件列表
        });
      }
    }
  }

  Future<void> showConnectionListModal(
      BuildContext context, String label) async {
    List<SSHConnectionInfo>? connections;
    String errorMessage = '';
    bool nuler = false;

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
          //return Center(child: Text(errorMessage));
          nuler = true;
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
          nuler
              ? Expanded(
                  child: CupertinoListTile(
                  title: Text(errorMessage),
                ))
              : Expanded(
                  child: ListView.builder(
                    itemCount: connections!.length,
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
                              _listDirectoryLeft(
                                  connection.username, connection.host);
                            } else {
                              _serviceRight = service;
                              _listDirectoryRight(
                                  connection.username, connection.host);
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
                )
        ]);
      },
    );
  }

  void _handleFileOrDirectoryTap(
      FileInfo file, String currentPath, bool isLeftOrRight) async {
    if (file.type == FileType.directory) {
      // 构建新的路径
      String newPath;
      if (file.name == '..') {
        // 使用Uri解析路径，处理回退到上一级目录的情况
        final currentUri = Uri.directory(currentPath);
        final parentUri = Uri.directory(currentUri.resolve('..').path);
        newPath = parentUri.path;
      } else {
        // 对于正常目录，继续叠加路径
        newPath = Uri.directory(currentPath).resolve(file.name).path;
      }

      // 调用服务列出新路径下的文件

      if (isLeftOrRight) {
        final files = await _serviceLeft!.listDirectory(newPath);
        setState(() {
          _filesLeft = files;
          _currentPathLeft = newPath;
        });
      } else {
        final files = await _serviceRight!.listDirectory(newPath);
        setState(() {
          _filesRight = files;
          _currentPathRight = newPath;
        });
      }
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
                Text(
                    '修改日期: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(file.modificationDate!)}'),
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                  child: const Text('删除'),
                  onPressed: () async {
                    final filename = file.name;
                    if (isLeftOrRight) {
                      await _serviceLeft!.deleteFile("$currentPath/$filename");
                      final fileafter =
                          await _serviceLeft!.listDirectory(currentPath);
                      setState(() {
                        _filesLeft = fileafter;
                      });
                    } else {
                      await _serviceRight!
                          .deleteFile('$currentPath}/$filename');
                      final fileafter =
                          await _serviceRight!.listDirectory(currentPath);
                      setState(() {
                        _filesRight = fileafter;
                      });
                    }
                    Navigator.of(context).pop();
                  }),
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

  Future<void> transferFileBetweenServers(
      FileInfo file, bool fromLeftToRight) async {
    SFTPService sourceService =
        fromLeftToRight ? _serviceLeft! : _serviceRight!;
    SFTPService targetService =
        fromLeftToRight ? _serviceRight! : _serviceLeft!;
    String sourcePath = fromLeftToRight ? _currentPathLeft : _currentPathRight;
    String targetPath = fromLeftToRight ? _currentPathRight : _currentPathLeft;
    String fileName = file.name;

    // 1. 创建本地临时文件路径
    Directory tempDir = Directory.systemTemp;
    String localTempFilePath = path.join(tempDir.path, fileName);

    // 2. 从源服务器下载文件到本地临时路径
    bool downloadResult = await sourceService.downloadFile(
        "$sourcePath/$fileName", localTempFilePath);
    if (!downloadResult) {
      showCupertinoSnackBar(
          context: context, message: '文件下载失败', durationMillis: 2 * 1000);
      return;
    }

    // 3. 从本地上传文件到目标服务器
    bool uploadResult = await targetService.uploadFile(
        localTempFilePath, "$targetPath/$fileName");
    if (!uploadResult) {
      showCupertinoSnackBar(
          context: context, message: '文件上传失败', durationMillis: 2 * 1000);
      // 尝试删除本地临时文件
      File(localTempFilePath).delete();
      return;
    }

    showCupertinoSnackBar(
        context: context, message: '文件传输成功', durationMillis: 2 * 1000);

    // 4. 清理本地临时文件
    File(localTempFilePath).delete();
    if (downloadResult && uploadResult) {
      final filesL = await _serviceLeft!.listDirectory(_currentPathLeft);
      final filesR = await _serviceRight!.listDirectory(_currentPathRight);
      setState(() {
        _filesLeft = filesL;
        _filesRight = filesR;
      });
    }
  }

  Widget _buildDraggableFileItem(
      FileInfo file, String currentPath, bool isLeft) {
    return Draggable<FileInfo>(
      data: file,
      feedback: CupertinoPageScaffold(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: CupertinoListTile(
            title: Text(file.name),
            trailing: Text(file.size.toString()),
            leading: Icon(file.type == FileType.directory
                ? CupertinoIcons.folder
                : CupertinoIcons.doc),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: CupertinoListTile(
          title: Text(file.name),
          trailing: Text(file.size.toString()),
          leading: Icon(file.type == FileType.directory
              ? CupertinoIcons.folder
              : CupertinoIcons.doc),
        ),
      ),
      child: CupertinoListTile(
        title: Text(file.name),
        trailing: Text(file.size.toString()),
        leading: Icon(file.type == FileType.directory
            ? CupertinoIcons.folder
            : CupertinoIcons.doc),
        onTap: () => _handleFileOrDirectoryTap(file, currentPath, isLeft),
      ),
    );
  }

  Future<String?> showCreateFolderDialog(BuildContext context) async {
    String? folderName;

    await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('新文件夹命名为'),
          content: CupertinoTextField(
            placeholder: '请输入新文件夹名称',
            onChanged: (String value) {
              folderName = value;
            },
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(folderName);
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );

    return folderName;
  }
}
