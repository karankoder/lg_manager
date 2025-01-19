import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = true; // Example connection status
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          children: [
            Text(
              'LG Manager',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('System', 0),
              _buildTabButton('Manage', 1),
            ],
          ),
          Expanded(
            child: selectedIndex == 0
                ? _buildSystemControls()
                : _buildManageControls(),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current KMLs or logos selected',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: selectedIndex == index ? Colors.grey[800] : Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton('Relaunch', Icons.refresh),
        _buildControlButton('Reboot', Icons.loop),
        _buildControlButton('Power Off', Icons.power_settings_new),
      ],
    );
  }

  Widget _buildManageControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton('Set LG Logo', Icons.image),
        _buildControlButton('Clear Logos', Icons.brush),
        _buildControlButton('Send KML 1', Icons.public),
        _buildControlButton('Send KML 2', Icons.public),
        _buildControlButton('Clear KMLs', Icons.delete),
      ],
    );
  }

  Widget _buildControlButton(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.white),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Corrected primary color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}
