import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import '../service/virtual_keyboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:xterm/xterm.dart';
import '../models/connect.dart';

class TerminalPage extends StatefulWidget {
  final SSHConnectionInfo? connection;
  const TerminalPage({super.key, this.connection});

  @override
  // ignore: library_private_types_in_public_api
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.connection == null) {
      return const Center(
        child: Text('请选择一个连接'),
      );
    } else {
      // 正常显示终端界面
      return _buildTerminal(context);
    }
  }

  Widget _buildTerminal(BuildContext context) {
    // 具体的终端界面实现
    return _TerminalBody(connection: widget.connection!);
  }
}

class _TerminalBody extends StatefulWidget {
  final SSHConnectionInfo connection;
  const _TerminalBody({required this.connection});

  @override
  // ignore: library_private_types_in_public_api
  __TerminalBodyState createState() => __TerminalBodyState();
}

class __TerminalBodyState extends State<_TerminalBody> {
  late final terminal = Terminal(inputHandler: keyboard);

  final keyboard = VirtualKeyboard(defaultInputHandler);

  late String title;

  @override
  void initState() {
    super.initState();
    title = widget.connection.host;
    initTerminal();
  }

  Future<void> initTerminal() async {
    terminal.write('Connecting...\r\n');

    final client = SSHClient(
      await SSHSocket.connect(widget.connection.host, widget.connection.port),
      username: widget.connection.username,
      onPasswordRequest: () => widget.connection.password,
    );

    terminal.write('Connected\r\n');

    final session = await client.shell(
      pty: SSHPtyConfig(
        width: terminal.viewWidth,
        height: terminal.viewHeight,
      ),
    );

    terminal.buffer.clear();
    terminal.buffer.setCursor(0, 0);

    terminal.onTitleChange = (title) {
      setState(() => this.title = title);
    };

    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      session.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };

    terminal.onOutput = (data) {
      session.write(utf8.encode(data));
    };

    session.stdout
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);

    session.stderr
        .cast<List<int>>()
        .transform(const Utf8Decoder())
        .listen(terminal.write);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor:
            CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: TerminalView(terminal),
          ),
          if (Platform.isIOS || Platform.isAndroid)
            VirtualKeyboardView(keyboard)
        ],
      ),
    );
  }
}
