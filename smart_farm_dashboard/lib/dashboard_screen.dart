import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'alerts_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<List<dynamic>> csvData = [];
  Timer? timer;
  final random = Random();
  double light = 0, humidity = 0, temperature = 0, soilMoisture = 0, wind = 0;

  @override
  void initState() {
    super.initState();
    loadCSV();
  }

  Future<void> loadCSV() async {
    final data = await rootBundle.loadString('assets/Crop_recommendationV2.csv');
    final lines = LineSplitter.split(data).skip(1);
    csvData = lines.map((e) => e.split(',')).toList();
    updateValues();
    timer = Timer.periodic(Duration(seconds: 1), (_) => updateValues());
  }

  void updateValues() {
    if (csvData.isEmpty) return;
    final row = csvData[random.nextInt(csvData.length)];

    setState(() {
      light = double.parse(row[10]);
      humidity = double.parse(row[4]);
      temperature = double.parse(row[3]);
      soilMoisture = double.parse(row[8]);
      wind = double.parse(row[11]);
    });

    storeDataToFirestore({
      'timestamp': Timestamp.now(),
      'light': light,
      'humidity': humidity,
      'temperature': temperature,
      'soilMoisture': soilMoisture,
      'wind': wind,
      // ... other fields
    });
  }

  Future<void> storeDataToFirestore(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('sensor_data').add(data);
    } catch (e) {
      print('Failed to store data: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = [
      {'title': 'Light', 'value': '${light.toStringAsFixed(1)} lux', 'icon': FontAwesomeIcons.sun},
      {'title': 'Humidity', 'value': '${humidity.toStringAsFixed(1)}%', 'icon': FontAwesomeIcons.droplet},
      {'title': 'Temperature', 'value': '${temperature.toStringAsFixed(1)}°C', 'icon': FontAwesomeIcons.temperatureHigh},
      {'title': 'Soil Moisture', 'value': '${soilMoisture.toStringAsFixed(1)}%', 'icon': FontAwesomeIcons.seedling},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Farm Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlertsScreen()),
              );
            },
          ),

        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE8F5E9).withOpacity(0.3)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSensorGrid(sensorData),
              SizedBox(height: 20),
              _buildWeatherCard(),
              SizedBox(height: 20),
              _buildFarmMap(),
              SizedBox(height: 20),
              _buildIrrigationSystem(),
              SizedBox(height: 20),
              _buildSoilQualityChart(),
              SizedBox(height: 20),
              _buildLivestockMonitoring(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco, size: 40, color: Colors.white),
              SizedBox(height: 10),
              Text('Smart Farm', 
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ...['Dashboard', 'Weather', 'Map', 'Irrigation', 'Soil', 'Livestock']
            .map((title) => ListTile(
                  leading: Icon(_getDrawerIcon(title), color: Colors.grey[700]),
                  title: Text(title),
                  onTap: () {},
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ))
            .toList(),
        Divider(indent: 16, endIndent: 16),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.grey[700]),
          title: Text("Logout", style: TextStyle(color: Colors.grey[700])),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AuthScreen()),
            );
          },
        ),
      ],
    ),
  );
}

  IconData _getDrawerIcon(String title) {
    final iconColor = Colors.grey[700];
    switch (title) {
      case 'Weather': return Icons.cloud;
      case 'Map': return Icons.map_outlined;
      case 'Irrigation': return FontAwesomeIcons.tint;
      case 'Soil': return FontAwesomeIcons.leaf;
      case 'Livestock': return FontAwesomeIcons.cow;
      default: return Icons.dashboard;
    }
  }

  Widget _buildSensorGrid(List<Map<String, dynamic>> sensorData) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: sensorData.map((data) => SensorCard(
        title: data['title'],
        value: data['value'],
        icon: data['icon'],
      )).toList(),
    );
  }

  Widget _buildWeatherCard() {
    return _cardWrapper(
      title: 'Current Weather',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeatherItem(Icons.thermostat, '${temperature.toStringAsFixed(1)}°C', 'Temperature'),
          _buildWeatherItem(Icons.opacity, '${humidity.toStringAsFixed(1)}%', 'Humidity'),
          _buildWeatherItem(FontAwesomeIcons.wind, '${wind.toStringAsFixed(1)} km/h', 'Wind'),
        ],
      ),
    );
  }

  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          spreadRadius: 2,
        )],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, 
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
            SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 28, color: Theme.of(context).primaryColor)),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildFarmMap() => _cardWrapper(
    title: 'Farm Map',
    child: Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage('../assets/map_placeholder.jpg'),
          fit: BoxFit.cover),
      ),
      child: Center(
        child: Text('Interactive Map Coming Soon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    ),
  );

  Widget _buildIrrigationSystem() => _cardWrapper(
    title: 'Irrigation System',
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: Colors.green),
                SizedBox(width: 8),
                Text('Status: Active', style: TextStyle(color: Colors.grey[800])),
              ],
            ),
            Text('Water Usage: 150L', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        SizedBox(height: 12),
        LinearProgressIndicator(
          value: 0.7,
          minHeight: 12,
          borderRadius: BorderRadius.circular(20),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      ],
    ),
  );

  Widget _buildSoilQualityChart() => _cardWrapper(
    title: 'Soil Quality',
    child: Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(5, (i) => FlSpot(i.toDouble(), 6 + Random().nextDouble())),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildLivestockMonitoring() => _cardWrapper(
    title: 'Livestock Monitoring',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLivestockInfo('Cattle', '12', FontAwesomeIcons.cow),
        _buildLivestockInfo('Sheep', '25', FontAwesomeIcons.horse),
        _buildLivestockInfo('Poultry', '40', FontAwesomeIcons.kiwiBird),
      ],
    ),
  );

  Widget _buildLivestockInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
          child: FaIcon(icon, size: 28, color: Theme.of(context).primaryColor)),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SensorCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          spreadRadius: 2,
        )],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: FaIcon(icon, size: 24, color: Theme.of(context).primaryColor)),
            SizedBox(height: 12),
            Text(value, 
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800])),
            SizedBox(height: 4),
            Text(title, 
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}