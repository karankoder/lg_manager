import 'dart:convert';
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/kml_entity.dart';
import '../entities/overlay_entity.dart';

class LGService {
  final SSHClient _client;
  LGService(SSHClient client) : _client = client;

  int screenAmount = 3; //default 3
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

  Future<void> clearKml({bool keepLogos = true}) async {
    int logoScreen = getLogoScreen();
    String query =
        'echo "exittour=true" > /tmp/query.txt && > /var/www/html/kmls.txt';

    for (var i = 2; i <= screenAmount; i++) {
      String blankKml = KMLEntity.generateBlank('slave_$i');
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

  searchPlace(String placeName) async {
    try {
      final execResult =
          await _client.execute('echo "search=$placeName" >/tmp/query.txt');
      return execResult;
    } catch (e) {
      print('An error occurred while executing the command: $e');
      return null;
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

  String orbitBalloon(
    String cityImage,
  ) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
 <name>About Data</name>
 <Style id="about_style">
   <BalloonStyle>
     <textColor>ffffffff</textColor>
     <text>
        <h1>Kolkata</h1>
        <h1>Karan</h1>
        <img src="$cityImage" alt="City" width="300" height="200" />
     </text>
     <bgColor>ff15151a</bgColor>
   </BalloonStyle>
 </Style>
 <Placemark id="ab">
   <description>
   </description>
   <LookAt>
  <longitude>88.3639</longitude><latitude>22.5726</latitude>
     <heading>0</heading>
     <tilt>0</tilt>
     <range>200</range>
   </LookAt>
   <styleUrl>#about_style</styleUrl>
   <gx:balloonVisibility>1</gx:balloonVisibility>
   <Point>
     <coordinates>88.3639,22.5726,0</coordinates>
   </Point>
 </Placemark>
</Document>
</kml>''';
  }

  Future<void> showOrbitBalloon() async {
    print('heiiiy');

    String img = 'https://www.holidify.com/images/bgImages/KOLKATA.jpg';
    await _client
        .execute("echo '${orbitBalloon(img)}' > /var/www/html/kml/slave_2.kml");
    await _client.execute(
        'echo "flytoview=${KMLEntity.generateLinearString('88.3639', '22.5726', '4000', '60', '10')})}" > /tmp/query.txt');

    print('hello');
  }

  Future<void> query(String content) async {
    await _client.execute('echo "$content" > /tmp/query.txt');
  }

  buildOrbit(String content) async {
    try {
      await _client.run("echo '$content' > /var/www/html/Orbit.kml");
      await _client.execute(
          "echo '\nhttp://lg1:81/Orbit.kml' >> /var/www/html/kmls.txt");
      return await query('playtour=Orbit');
    } catch (e) {
      print('Error in building orbit');
      return Future.error(e);
    }
  }

  startOrbit() async {
    try {
      return await query('playtour=Orbit');
    } catch (e) {
      print('Could not connect to host LG');
      return Future.error(e);
    }
  }

  stopOrbit() async {
    try {
      return await query('exittour=true');
    } catch (e) {
      print('Could not connect to host LG');
      return Future.error(e);
    }
  }

  sendKml(String content) async {
    try {
      await _client.execute("echo '$content' > /var/www/html/dummy.kml");
      await _client.execute(
          "echo  '\nhttp://lg1:81/dummy.kml' > /var/www/html/kmls.txt");
      await _client.execute('echo "playtour=dummy" > /tmp/query.txt');
    } catch (e) {
      print('Error in building dummy');
      return Future.error(e);
    }
  }

  sendKml2(String content) async {
    try {
      await _client.execute("echo '$content' > /var/www/html/helllo.kml");
      await _client.execute(
          "echo  '\nhttp://lg1:81/helllo.kml' > /var/www/html/kmls.txt");

      await _client.execute(
          'echo "flytoview=${KMLEntity.generateLinearString('72.81555865828552', '18.956721869849535', '40000', '60', '10')})}" > /tmp/query.txt');
    } catch (e) {
      print('Error in building dummy');
      return Future.error(e);
    }
  }
}
