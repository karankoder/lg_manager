import 'package:flutter/material.dart';
import './lg_connection_page.dart';
import 'package:lg_manager/utility/config.dart';
import '../entities/orbit_entity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedScreen;
  bool connectionStatus = AppConfig.ssh.connected;
  bool isSystemTab = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/lglogo.jpg', height: 30),
            const SizedBox(width: 10),
            const Text('LG Visual Manager'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LGConnectionPage()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConfig.ssh.connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: AppConfig.ssh.connected ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTabs(),
            const SizedBox(height: 16),
            Expanded(
              child:
                  isSystemTab ? _buildSystemControls() : _buildManageControls(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No active logos',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTabButton('Manage', !isSystemTab),
        _buildTabButton('System', isSystemTab)
      ],
    );
  }

  Widget _buildTabButton(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSystemTab = title == 'System';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'System Controls',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              _buildButton(
                onPressed: () {
                  AppConfig.lg.relaunch();
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Relaunch'),
                color: const Color(0xFF3B83F6),
              ),
              const SizedBox(height: 10),
              _buildButton(
                onPressed: () {
                  _showConfirmationDialog(
                    context,
                    'Reboot',
                    'Are you sure you want to reboot?',
                    () {
                      AppConfig.lg.reboot();
                      Navigator.of(context).pop();
                    },
                  );
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reboot'),
                color: const Color(0xFFF55347), // Red
              ),
              const SizedBox(height: 10),
              _buildButton(
                onPressed: () {
                  _showConfirmationDialog(
                    context,
                    'Power Off',
                    'Are you sure you want to power off?',
                    () {
                      AppConfig.lg.poweroff();
                      Navigator.of(context).pop();
                    },
                  );
                },
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Power Off'),
                color: const Color(0xFFF9C440), // Yellow
              ),
              const SizedBox(height: 20),
              _buildButton(
                onPressed: () {
                  AppConfig.lg.setRefresh();
                },
                icon: const Icon(Icons.update),
                label: const Text('Set Refresh'),
                color: const Color(0xFF3B83F6), // Blue
              ),
              const SizedBox(height: 10),
              _buildButton(
                onPressed: () {
                  AppConfig.lg.resetRefresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Refresh'),
                color: const Color(0xFF4CAF50), // Green
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control KML and logos',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              _buildButton(
                onPressed: () {
                  AppConfig.lg.setLogos();
                },
                icon: const Icon(Icons.add),
                label: const Text('Set LG Logo'),
                color: const Color(0xFF3B83F6),
              ),
              const SizedBox(height: 10),
              _buildButton(
                onPressed: () {
                  AppConfig.lg.clearKml(keepLogos: false);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Logos'),
                color: const Color(0xFFF55347),
              ),
              const SizedBox(height: 20),
              _buildButton(
                onPressed: () async {
                  await AppConfig.lg.showOrbitBalloon();
                },
                icon: const Icon(Icons.send),
                label: const Text('Go to Home'),
                color: const Color(0xFFF9C440), // Yellow
              ),
              const SizedBox(height: 10),
              _buildButton(
                onPressed: () async {
                  await AppConfig.lg
                      .buildOrbit(Orbit.buildOrbit(Orbit.generateOrbitTag()));
                },
                icon: const Icon(Icons.send),
                label: const Text('Start Orbit'),
                color: const Color(0xFF3B83F6), // Blue
              ),
              const SizedBox(height: 20),
              _buildButton(
                onPressed: () {
                  AppConfig.lg.clearKml(keepLogos: true);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear KMLs'),
                color: const Color(0xFF4CAF50), // Red
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      {required VoidCallback onPressed,
      required Icon icon,
      required Text label,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.data!,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              Icon(icon.icon, size: 24, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: onConfirm,
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
