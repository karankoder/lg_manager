import '../services/lg_services.dart';
import '../services/ssh_services.dart';

class AppConfig {
  static SSHService ssh = SSHService();
  static LGService lg = LGService(ssh.client);
}
