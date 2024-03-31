import 'package:flutter/cupertino.dart';
import '../models/connect.dart';
import '../service/openterminal.dart';
import 'package:xanssh/main.dart';


class ConnectPage extends StatefulWidget {
  final SSHConnectionInfo? existingConnection;

  const ConnectPage({super.key, this.existingConnection});

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _formKey = GlobalKey<FormState>();
  late SSHConnectionInfo _connection;
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingConnection != null) {
      _connection = widget.existingConnection!;
      _hostController.text = _connection.host;
      _portController.text = _connection.port.toString();
      _usernameController.text = _connection.username;
      _passwordController.text = _connection.password;
    } else {
      _connection = SSHConnectionInfo(host: '', username: '', password: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('编辑连接'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 70),
              CupertinoFormSection(
                children: [
                  CupertinoTextFormFieldRow(
                    prefix: const Text('主机'),
                    controller: _hostController,
                    placeholder: 'Enter hostname',
                    onSaved: (value) => _connection.host = value ?? '',
                  ),
                  CupertinoTextFormFieldRow(
                    prefix: const Text('端口'),
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    placeholder: 'Port number (default 22)',
                    onSaved: (value) =>
                        _connection.port = int.tryParse(value!) ?? 22,
                  ),
                  CupertinoTextFormFieldRow(
                    prefix: const Text('用户名'),
                    controller: _usernameController,
                    placeholder: 'Enter username',
                    onSaved: (value) => _connection.username = value ?? '',
                  ),
                  CupertinoTextFormFieldRow(
                    prefix: const Text('密码'),
                    controller: _passwordController,
                    placeholder: 'Enter password',
                    obscureText: true,
                    onSaved: (value) => _connection.password = value ?? '',
                  ),
                ],
              ),
              CupertinoButton(
                child: const Text('连接'),
                onPressed: () async {
                  _formKey.currentState!.save();
                  openNewWindow(context, _connection);
                  Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(builder: (context) => const MyHomePage(initialPageIndex: 0)), // 使用修改后的 MyHomePage 构造函数
                    (Route<dynamic> route) => false, // 移除所有旧的页面
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
