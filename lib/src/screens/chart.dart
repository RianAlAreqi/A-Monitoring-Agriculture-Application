import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

class SensorChart extends StatefulWidget {
  const SensorChart({Key? key}) : super(key: key);

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart> {
  late Future<Map<String, dynamic>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<void> _launchFileExplorer(String path) async {
    final url = 'file://$path';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> downloadCSV(List<dynamic> feeds) async {
    List<List<dynamic>> csvData = [
      [
        'Entry ID',
        'Created At',
        'Temperature',
        'Humidity',
        'Rain',
        'Soil Moisture'
      ]
    ];
    for (var feed in feeds) {
      csvData.add([
        feed['entry_id'],
        feed['created_at'],
        feed['field1'],
        feed['field2'],
        feed['field3'],
        feed['field4'],
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final fileName = 'sensor_data.csv';
    final file = File('$path/$fileName');
    await file.writeAsString(csv);

    // Convert the File to XFile
    final xFile = XFile(file.path);

    await Share.shareXFiles(
      [xFile],
      subject: 'Sensor Data',
      text: 'Here is the sensor data in CSV format.',
    );
  }

  Future<Map<String, dynamic>> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/channels/2010330/feeds.json?api_key=SIBADRFIPZEA1PEN'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  String formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget buildLineChart(List<dynamic> feeds, String field, String title,
      Color color, double minY, double maxY) {
    List<FlSpot> dataPoints = feeds
        .map((feed) => FlSpot(double.parse(feed['entry_id'].toString()),
            double.parse(feed[field].toString())))
        .toList();

    Map<double, String> dateLabels = {};
    for (var feed in feeds) {
      final entryId = double.parse(feed['entry_id'].toString());
      final dateString = feed['created_at'];
      final dateTime = DateTime.parse(dateString);
      final formattedDateTime =
          DateFormat('MM/dd HH:mm').format(dateTime); // Change the format here
      dateLabels[entryId] = formattedDateTime;
    }

    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 24)),
        SizedBox(height: 10),
        Container(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: dataPoints.length.toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: dataPoints,
                  isCurved: true,
                  colors: [color],
                  dotData: FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: SideTitles(
                  showTitles: true,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff68737d),
                    fontSize:
                        12, // Adjust the font size to give more room for labels
                  ),
                  getTitles: (value) {
                    if (value % 20 == 0) {
                      // Change this value to adjust the separation between labels
                      return value.toInt().toString();
                    } else {
                      return '';
                    }
                  },
                ),
                bottomTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 15,
                  getTextStyles: (context, value) => const TextStyle(
                    color: Color(0xff68737d),
                    fontSize: 12, // Reduced font size
                  ),
                  margin: 5,
                  rotateAngle: 45, // Rotated labels
                  getTitles: (value) {
                    if (value % 8 == 0) {
                      // Increased spacing between labels
                      return dateLabels[value] ?? '';
                    } else {
                      return '';
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agro Sensor Charts'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              if (futureData != null) {
                futureData.then((data) => downloadCSV(data['feeds']));
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<dynamic> feeds = snapshot.data!['feeds'];
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildLineChart(feeds, 'field1', 'Temperature (°C)',
                        Colors.redAccent, 5, 60),
                    SizedBox(height: 50),
                    buildLineChart(feeds, 'field2', 'Humidity (%)',
                        Colors.blueAccent, 0, 100),
                    SizedBox(height: 50),
                    buildLineChart(feeds, 'field3', 'Rain (%)',
                        Colors.greenAccent, 0, 100),
                    SizedBox(height: 50),
                    buildLineChart(feeds, 'field4', 'Soil Moisture (%)',
                        Colors.purpleAccent, 0, 100),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
