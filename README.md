# xanssh

## 简介

本项目基于flutter构建，主要用于解决日常的 SSH、SFTP等需求，因为在macOS上没找到好用开源的工具，姑且就自己写了一个，因为正在使用flutter做毕设，也就顺便做成了一个跨平台的SSH客户端。

## 构建

- flutter stable version 最好是3.16.x版本及以上，但最好还是3.16.x版本，低版本和高版本都会有引用第三方库的兼容问题
- [dartssh](https://pub.dev/packages/dartssh2) SSH、SFTP功能库，这是功能实现的 核心
- CupertinoUI 因为没有精力写那么多套UI所以全部平台统一使用Cupertino风格的界面，感觉还蛮顺眼的

## 功能
- 实现SSH连接远程服务器
  - 目前仅支持username+password登录
  - 使用sqlite对连接数据进行本地存储、包括密码、所以理论上存在风险
  - 没有用户系统、没有存储服务器、所有信息均在本地保留记录、所以不存在多端同步
- 实现SFTP在服务器之间传输文件
  - 目前仅支持文件、文件夹暂不支持、但是有计划
  - 该界面不稳定、目前正在测试
- 实现一些额外的设置功能
  - 虽然不能同步但是可以将记录导出和导入
  - 这个是加密的所以不用担心
  - 密钥具有一次性

## 站在巨人的肩膀上
- [dartssh](https://pub.dev/packages/dartssh2)提供了SSH、SFTP相关功能
- [xterm](https://pub.dev/packages/xterm)提供了终端构建
- [rmalviya在回答中手搓的](https://stackoverflow.com/questions/55382651/use-snackbar-with-cupertinopagescaffold)Cupertino风格的SnackBar

## 一个不那么成功的样品
- 全平台使用Cupertino风格除了便利一点外还会带来除Apple设备外的不适配
- 一些组件的构建方式并不是最优解，因为还没学会Provider
- 移动端的开始按钮仍有一些问题，好在没什么人会在移动端进行大量的SSH、SFTP操作；事实上SFTP没有什么问题，主要是SSH和终端构建的连接中出了些问题

## clone注意事项：
- 确保设备的flutter环境 `flutter doctor -v`，如果没有的话请[下载](https://docs.flutter.dev/get-started/install)
- 建议使用Visual Studio Code 、Android Studio、IntelliJ IDEA 下载flutter拓展即可对语法、调试等进行操作
- clone本项目
- 在项目目录下运行`flutter pub get`获取调用库
- xterm、sqflite等库和flutter版本有着相当密切的关系建议使用时查看[对照表](https://pub.dev/packages/xterm/versions)
- 使用`flutter run -v`或编译器的调试来运行项目
