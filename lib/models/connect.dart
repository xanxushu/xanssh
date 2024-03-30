class SSHConnectionInfo {
  int? id;
  String host;
  int port;
  String username;
  String password;
  DateTime? lastLoginTime;

  SSHConnectionInfo({
    this.id,
    required this.host,
    this.port = 22,
    required this.username,
    required this.password,
    this.lastLoginTime,
  });

  factory SSHConnectionInfo.fromJson(Map<String, dynamic> json) {
    return SSHConnectionInfo(
      id: json['id'],
      host: json['host'],
      port: json['port'],
      username: json['username'],
      password: json['password'],
      lastLoginTime: json['lastLoginTime'] != null ? DateTime.parse(json['lastLoginTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };

    if (lastLoginTime != null) {
      map['lastLoginTime'] = lastLoginTime!.toIso8601String();
    }
    if (id != null) {
      map['id'] = id!;
    }

    return map;
  }
}
