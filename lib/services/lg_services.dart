import 'dart:convert';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/kml_entity.dart';
import '../entities/overlay.dart';

class LGService {
  final SSHClient _client;

  LGService(SSHClient client) : _client = client;
  final String _url = 'http://lg1:81';

  int screenAmount = 3;
  int getLogoScreen() {
    if (screenAmount == 1) {
      return 1;
    }
    return (screenAmount / 2).floor() + 2;
  }

  Future<String?> getScreenAmount() async {
    final session = await _client
        .execute("grep -oP '(?<=DHCP_LG_FRAMES_MAX=).*' personavars.txt");
    final result = await utf8.decoder.bind(session.stdout).join();
    return result;
  }

  int get firstScreen {
    if (screenAmount == 1) {
      return 1;
    }
    return (screenAmount / 2).floor() + 2;
  }

  int get lastScreen {
    if (screenAmount == 1) {
      return 1;
    }
    return (screenAmount / 2).floor();
  }

  Future<void> setRefresh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('password') ?? '';

    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    final command =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';

    final clear =
        'echo $pw | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= screenAmount; i++) {
      final clearCmd = clear.replaceAll('{{slave}}', i.toString());
      final cmd = command.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'{{cmd}}\'';

      try {
        await _client.execute(query.replaceAll('{{cmd}}', clearCmd));
        await _client.execute(query.replaceAll('{{cmd}}', cmd));
        await reboot();
      } catch (e) {
        // ignore: avoid_print
        print('error occured');
        print(e);
      }
    }
  }

  Future<void> resetRefresh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('password') ?? '';

    const search =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>2<\\/refreshInterval>';
    const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';

    final clear =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';

    for (var i = 2; i <= screenAmount; i++) {
      final cmd = clear.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'$cmd\'';

      try {
        await _client.execute(query);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }

    await reboot();
  }

  Future<void> relaunch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('password') ?? '';

    final user = _client.username;

    for (var i = screenAmount; i >= 1; i--) {
      try {
        final relaunchCommand = """RELAUNCH_CMD="\\
              if [ -f /etc/init/lxdm.conf ]; then
                export SERVICE=lxdm
              elif [ -f /etc/init/lightdm.conf ]; then
                export SERVICE=lightdm
              else
                exit 1
              fi
              if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
                echo $pw | sudo -S service \\\${SERVICE} start
              else
                echo $pw | sudo -S service \\\${SERVICE} restart
              fi
              " && sshpass -p $pw ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";
        await _client
            .execute('"/home/$user/bin/lg-relaunch" > /home/$user/log.txt');
        await _client.execute(relaunchCommand);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  Future<void> poweroff() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('password') ?? '';

    for (var i = screenAmount; i >= 1; i--) {
      try {
        await _client.execute(
            'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S poweroff"');
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  Future<void> reboot() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pw = prefs.getString('password') ?? '';
    for (var i = screenAmount; i >= 1; i--) {
      try {
        await _client
            .execute('sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"');
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }
  }

  String generateBlank(String id) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document id="$id">
  </Document>
</kml>
    ''';
  }

  Future<void> clearKml({bool keepLogos = true}) async {
    int logoScreen = getLogoScreen();
    String query =
        'echo "exittour=true" > /tmp/query.txt && > /var/www/html/kmls.txt';

    for (var i = 2; i <= screenAmount; i++) {
      String blankKml = generateBlank('slave_$i');
      query += " && echo '$blankKml' > /var/www/html/kml/slave_$i.kml";
    }

    if (keepLogos) {
      final kml = KMLEntity(
        name: 'SVT-logos',
        content: '<name>Logos</name>',
        screenOverlay: ScreenOverlayEntity.logos().tag,
      );

      query +=
          " && echo '${kml.body}' > /var/www/html/kml/slave_$logoScreen.kml";
    }
    try {
      await _client.execute(query);
    } catch (e) {
      print('error occured in clearKml');
      // ignore: avoid_print
      print(e);
    }
    // await _client.execute(query);
  }

  Future<void> setLogos({
    String name = 'ARCA-Dashboard',
    String content = '<name>Logos</name>',
  }) async {
    final screenOverlay = ScreenOverlayEntity.logos();

    final kml = KMLEntity(
      name: name,
      content: content,
      screenOverlay: screenOverlay.tag,
    );

    try {
      final result = await getScreenAmount();
      if (result != null) {
        screenAmount = int.parse(result);
      }
      print('screenAmount: $screenAmount');
      await sendKMLToSlave(firstScreen, kml.body);
    } catch (e) {
      print('error occured in set logos');
      // ignore: avoid_print
      print(e);
    }
  }

  Future<void> sendKMLToSlave(int screen, String content) async {
    try {
      await _client
          .execute("echo '$content' > /var/www/html/kml/slave_$screen.kml");
    } catch (e) {
      print('error occured in sendKMLToSlave');
      // ignore: avoid_print
      print(e);
    }
  }

  // Future<void> sendKml(String kml) async {
  //   const fileName = 'prova.kml';
  //   await clearKml(keepLogos: true);
  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/$fileName');
  //   file.writeAsStringSync(kml);
  //   await _client.connectSFTP();
  //   await _client.sftpUpload(
  //       path: file.path,
  //       toPath: '/var/www/html',
  //       callback: (progress) {
  //         //print('Sent $progress');
  //       });
  //   await _client.execute('echo "$_url/${fileName}" > /var/www/html/kmls.txt');
  // }

  // Future<void> sendTour(double latitude, double longitude, double zoom,
  //     double tilt, double bearing) async {
  //   await query(
  //       'flytoview=${LookAtEntity.lookAtLinear(latitude, longitude, zoom, tilt, bearing)}');
  // }

//   Future<void> query(String content) async {
//     await _client.execute('echo "$content" > /tmp/query.txt');
//   }

//   Future<void> buildOrbit(LookAtEntity lookAt) async {
//     final orbit = OrbitEntity.buildOrbit(OrbitEntity.tag(lookAt));
//     await sendOrbit(orbit, "Orbit");
//   }

//   Future<Object?> sendOrbit(String tourKml, String tourName) async {
//     final fileName = '$tourName.kml';

//     final directory = await getApplicationDocumentsDirectory();
//     final file = File('${directory.path}/$fileName');
//     file.writeAsStringSync(tourKml);

//     await _client.connectSFTP();

//     await _client.sftpUpload(
//         path: file.path,
//         toPath: '/var/www/html',
//         callback: (progress) {
//           print('Sent $progress');
//         });
//     _client.execute(
//         "echo '\nhttp://lg1:81/${fileName}' >> /var/www/html/kmls.txt");

//     try {
//       return await _client.execute('echo "playtour=Orbit" > /tmp/query.txt');
//     } catch (e) {
//       print('Could not connect to host LG');
//       return Future.error(e);
//     }
//   }

//   Future<void> stopTour() async {
//     try {
//       await query('exittour=true');
//     } catch (e) {
//       print('Could not connect to host LG');
//       return Future.error(e);
//     }
//   }
}
