import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xanssh/service/databasehelp.dart';
import 'package:xanssh/service/secrethelp.dart';
import 'package:xanssh/ui/cupertinosnackbar.dart';
import 'package:url_launcher/url_launcher.dart';



class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? _base64EncodedKey;
  String? _base64Encodediv;

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
                    '设置',
                    style:
                        CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                  ),
                ],
              ),
            ),
            // Connection List
            Expanded(
              child: Column(
                children: [
                  CupertinoListTile(
                    leading: const Icon(CupertinoIcons.xmark_circle),
                    title: const Text('删除所有连接'),
                    onTap: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            title: const Text('删除所有连接'),
                            content: const Text('您确定要删除所有连接吗？'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('取消'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              CupertinoDialogAction(
                                child: const Text('删除'),
                                onPressed: () async {
                                  await SSHConnectionDatabase.instance
                                      .deleteAll();
                                  Navigator.of(context).pop();
                                  showCupertinoSnackBar(
                                      context: context,
                                      message: '所有连接已删除。',
                                      durationMillis: 2 * 1000);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.upload_circle),
                      title: const Text('导出数据'),
                      onTap: () {
                        _exportData();
                      }),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.download_circle),
                      title: const Text('导入数据'),
                      onTap: () {
                        _promptForKeyAndImportData();
                      }),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.paw_solid),
                      title: const Text('设置密钥'),
                      onTap: () {
                        _showKeyOptionsDialog(context);
                      }),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.question_circle),
                      title: const Text('关于'),
                      onTap: () {
                        launchUrl(Uri.parse('https://github.com/xanxushu/xanssh'));
                      }),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.info_circle),
                      title: const Text('版本'),
                      trailing: const Text('v0.1.0'),
                      onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeyOptionsDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('密钥设置'),
          content: _base64EncodedKey == null
              ? const Text('当前没有密钥。')
              : const Text(
                  '当前密钥：点击下方显示密钥按钮查看\n请复制保存该密钥\n密钥仅本次会话生效\n密钥分为key和iv\n结尾的!不计入在内'),
          actions: <Widget>[
            if (_base64EncodedKey != null)
              CupertinoDialogAction(
                child: const Text('显示密钥'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showKeyDialog(context,
                      'key:$_base64EncodedKey!\niv:$_base64Encodediv!');
                },
              ),
            CupertinoDialogAction(
              child: Text(_base64EncodedKey == null ? '生成密钥' : '更改密钥'),
              onPressed: () {
                final myEncryptor = MyEncryptor.fromSecureRandomKey();
                setState(() {
                  _base64EncodedKey = myEncryptor.getBase64EncodedKey();
                  _base64Encodediv = myEncryptor.getBase64EncodedIV();
                });
                Navigator.of(context).pop();
                _showKeyDialog(
                    context, 'key:$_base64EncodedKey!\niv:$_base64Encodediv!');
              },
            ),
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showKeyDialog(BuildContext context, String key) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('当前密钥'),
          content: SelectableText(key),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    if (_base64EncodedKey == null) {
      // 如果没有密钥，显示提示去生成密钥
      _showAlert(context, '提示', '没有密钥，请先生成密钥。');
    } else {
      // 有密钥时，开始导出数据
      try {
        // 显示一个加载指示器
        showCupertinoDialog(
          context: context,
          builder: (_) => const CupertinoAlertDialog(
            content: CupertinoActivityIndicator(),
            title: Text('正在导出数据...'),
          ),
        );

        // 调用数据库帮助类的导出方法
        SSHConnectionDatabase.instance.setEncryptor(
            MyEncryptor.fromBase64EncodedKey(_base64EncodedKey!,
                base64Iv: _base64Encodediv!));
        await SSHConnectionDatabase.instance.exportDataToSelectedFolder();

        // 导出完成后关闭加载指示器
        Navigator.of(context).pop();

        // 显示导出成功的提示
        _showAlert(context, '导出成功', '数据已成功导出。');
      } catch (e) {
        // 处理可能的错误
        Navigator.of(context).pop(); // 确保关闭加载指示器
        _showAlert(context, '导出失败', '导出过程中发生错误：$e');
      }
    }
  }

  void _showAlert(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _promptForKeyAndImportData() async {
    TextEditingController keyController = TextEditingController();
    TextEditingController ivController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('输入密钥'),
          content: Column(
            children: [
              CupertinoTextField(
                controller: keyController,
                placeholder: '请输入密钥key',
              ),
              CupertinoTextField(
                controller: ivController,
                placeholder: '请输入密钥iv',
              ),
            ],
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('导入'),
              onPressed: () {
                Navigator.of(context).pop();
                _importData(keyController.text, ivController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importData(String key, String iv) async {
    if (key.isEmpty) {
      _showAlert(context, '导入失败', '密钥不能为空。');
      return;
    }

    // 显示加载指示器
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        content: CupertinoActivityIndicator(),
        title: Text('正在导入数据...'),
      ),
    );

    try {
      // 假设 _decryptAndImportData 是实际处理解密和导入逻辑的方法
      SSHConnectionDatabase.instance
          .setEncryptor(MyEncryptor.fromBase64EncodedKey(key, base64Iv: iv));
      await SSHConnectionDatabase.instance.importDataFromSelectedFile();
      Navigator.of(context).pop(); // 关闭加载指示器

      _showAlert(context, '导入成功', '数据已成功导入。');
    } catch (e) {
      Navigator.of(context).pop(); // 确保在出错时关闭加载指示器
      _showAlert(context, '导入失败', '导入过程中发生错误：$e');
    }
  }
}
