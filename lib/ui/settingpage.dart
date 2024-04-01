import 'package:flutter/cupertino.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
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
                      leading: const Icon(CupertinoIcons.upload_circle),
                      title: const Text('导出数据'),
                      onTap: () {}
                  ),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.download_circle),
                      title: const Text('导入数据'),
                      onTap: () {}
                  ),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.question_circle),
                      title: const Text('关于'),
                      onTap: () {}
                  ),
                  CupertinoListTile(
                      leading: const Icon(CupertinoIcons.info_circle),
                      title: const Text('版本'),
                      trailing: const Text('v0.1.0'),
                      onTap: () {}
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
