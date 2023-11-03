import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class LatestValues extends StatefulWidget {
  @override
  _LatestValuesState createState() => _LatestValuesState();
}

class _LatestValuesState extends State<LatestValues> {
  String temperature = '0';
  String humidity = '0';
  String rainPercentage = '0';
  String soilMoisturePercentage = '0';

  @override
  void initState() {
    super.initState();
    fetchLatestValues();
  }

  List<String> temperatureTips = [
    'Consider using a greenhouse to regulate temperature',
    'Monitor temperature closely for frost-sensitive crops',
    'Use row covers to protect plants from extreme temperatures',
    'Choose heat-tolerant crop varieties',
    'Use shade cloth to protect plants from excessive heat',
    'Water plants early in the day to avoid heat stress',
    'Use mulch to regulate soil temperature',
    'Consider intercropping to buffer temperature fluctuations',
    'Plan crop rotation based on temperature requirements',
    'Adjust planting dates based on temperature trends',
  ];

  List<String> humidityTips = [
    'Use drip irrigation to control humidity',
    'Ensure proper drainage to prevent waterlogging',
    'Monitor humidity levels for disease prevention',
    'Choose humidity-tolerant crop varieties',
    'Provide ample space between plants for air circulation',
    'Water plants early in the day to reduce humidity',
    'Avoid over-watering plants',
    'Use moisture-resistant mulches',
    'Implement proper weed management',
    'Consider using a greenhouse to regulate humidity',
  ];

  List<String> rainPercentageTips = [
    'Use rainwater harvesting techniques',
    'Prepare soil to maximize water infiltration',
    'Implement proper drainage systems',
    'Use cover crops to reduce soil erosion',
    'Select drought-tolerant crop varieties',
    'Monitor rain forecasts to plan irrigation',
    'Implement rainwater storage for irrigation',
    'Choose crops with short growing seasons',
    'Use mulch to conserve soil moisture',
    'Optimize irrigation schedules based on rainfall',
  ];

  List<String> soilMoisturePercentageTips = [
    'Monitor soil moisture to optimize irrigation',
    'Use soil moisture sensors for precise measurements',
    'Improve soil structure to enhance water retention',
    'Choose crops with deep root systems',
    'Use organic matter to improve soil moisture retention',
    'Implement proper drainage systems',
    'Avoid over-watering plants',
    'Water plants early in the day to conserve moisture',
    'Use mulch to reduce evaporation',
    'Choose drought-tolerant crop varieties',
  ];
  Future<void> fetchLatestValues() async {
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/channels/2010330/feeds.json?api_key=SIBADRFIPZEA1PEN'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var feeds = data['feeds'];

      var latestEntry = feeds[feeds.length - 1];

      if (mounted) {
        setState(() {
          temperature = latestEntry['field1'] ?? '';
          humidity = latestEntry['field2'] ?? '';
          rainPercentage = latestEntry['field3'] ?? '';
          soilMoisturePercentage = latestEntry['field4'] ?? '';
        });
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Latest Sensor Values'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _sensorCard(
                Icons.thermostat,
                'Temperature',
                '$temperature°C',
                temperatureTips,
                double.parse(temperature) > 30 ||
                    double.parse(temperature) < 10),
            _sensorCard(Icons.water, 'Humidity', '$humidity%', humidityTips,
                double.parse(humidity) > 80 || double.parse(humidity) < 20),
            _sensorCard(Icons.water_drop, 'Rain Percentage', '$rainPercentage%',
                rainPercentageTips, double.parse(rainPercentage) > 60),
            _sensorCard(
                Icons.grass,
                'Soil Moisture Percentage',
                '$soilMoisturePercentage%',
                soilMoisturePercentageTips,
                double.parse(soilMoisturePercentage) > 80 ||
                    double.parse(soilMoisturePercentage) < 20),
          ],
        ),
      ),
    );
  }

  Widget _sensorCard(IconData icon, String title, String value,
      List<String> tips, bool warningCondition) {
    // Generate a random index for the list of tips
    int randomIndex = Random().nextInt(tips.length);

    // Get a random tip from the list
    String randomTip = tips[randomIndex];

    Color valueColor;
    Color cardColor;
    if (title == 'Temperature') {
      valueColor = Colors.black; // Set temperature value color to blue
      cardColor = Colors.yellowAccent; // Set card color for temperature
    } else if (title == 'Soil Moisture Percentage') {
      valueColor = Colors.black; // Set soil moisture value color to brown
      cardColor = Colors.brown; // Set card color for soil moisture
    } else if (title == 'Humidity') {
      valueColor = Colors.black; // Set other values to default color
      cardColor = Colors.blue.shade200; // Set default card color
    } else if (title == 'Rain Percentage') {
      valueColor = Colors.black; // Set other values to default color
      cardColor = Colors.lightBlue; // Set default card color
    } else {
      valueColor = Colors.black; // Set other values to default color
      cardColor = Colors.white; // Set default card color
    }

    return Card(
      elevation: 4,
      color: warningCondition ? Colors.red.withOpacity(0.8) : cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 48),
            title: Text(title, style: TextStyle(fontSize: 24)),
            subtitle: Text(
              value,
              style:
                  TextStyle(fontSize: 18, color: valueColor), // Set value color
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Tip: $randomTip',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
