import 'dart:async';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SSHService {
  late String _host;
  late String _port;
  late String _username;
  late String _passwordOrKey;
  bool connected = false;
  SSHClient? _client;

  Future<void> initConnectionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('ipAddress') ?? '';
    _port = prefs.getString('port') ?? '';
    _username = prefs.getString('username') ?? '';
    _passwordOrKey = prefs.getString('password') ?? '';
  }

  Future<bool?> connect() async {
    await initConnectionDetails();
    print('connect function called');
    try {
      final socket = await SSHSocket.connect(_host, int.parse(_port));
      _client = SSHClient(
        socket,
        username: _username,
        onPasswordRequest: () => _passwordOrKey,
      );
      print(_client);
      final execResult =
          await _client!.execute('echo "search=Lleida" >/tmp/query.txt');
      connected = true;
      return true;
    } catch (e) {
      print('Failed to connect: $e');
      return false;
    }
  }

  Future<SSHSession?> execute() async {
    try {
      if (_client == null) {
        print('SSH client is not initialized.');
        return null;
      }

      final execResult =
          await _client!.execute('echo "search=Lleida" >/tmp/query.txt');
      print('Execution result: $execResult');
      return execResult;
    } catch (e) {
      print('An error occurred while executing the command: $e');
      return null;
    }
  }
}
