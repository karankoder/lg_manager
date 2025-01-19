import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SSHService {
  late String _host;
  late String _port;
  late String _username;
  late String _passwordOrKey;
  bool connected = false;
  late SSHClient client;
  static SSHService shared = SSHService();

  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? '';
    _port = prefs.getString('port') ?? '';
    _username = prefs.getString('username') ?? '';
    _passwordOrKey = prefs.getString('password') ?? '';
  }

  Future<bool?> connect() async {
    await initConnectionDetails();
    try {
      final socket = await SSHSocket.connect(_host, int.parse(_port)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection attempt timed out');
        },
      );
      client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _passwordOrKey,
      );

      await client.execute('echo "search=Lleida" >/tmp/query.txt');
      connected = true;
      return true;
    } catch (e) {
      return false;
    }
  }
}
