import 'dart:async';
import 'dart:io';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:intl/intl.dart';

class HomeConnectMqtt extends StatefulWidget {
  final String mqttServer;
  final String username;
  final String password;

  const HomeConnectMqtt({
    Key? key,
    required this.mqttServer,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<HomeConnectMqtt> createState() => _HomeConnectMqttState();
}

class _HomeConnectMqttState extends State<HomeConnectMqtt> {

  String currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
  TextEditingController co2thresholdController = TextEditingController();
  TextEditingController co2measurementController = TextEditingController();
  late ProgressDialog progressDialog;
  late MqttServerClient client;
  late List<String> topicsSub = ['temp' ,'humid' ,'co2' ,'radar' ,'press' ,'light' ,'move_rate' ,'fall_state' ,'respi_rate' ,'heart_rate', 'breath_state','led_control'];
  late List<String> values = List.filled(13, ''); // List để lưu giá trị của các topic
  late List<String> topicsPub = ['cfco2','led_d', 'f_control_d', 'b_control_d','a_or_m'];
  bool completedSub = false;
  bool isProcessTerminated = false;
  int co2Threshold = 400;
  int co2Measurement = 5; // Default interval in minutes

  // Lấy ngày hiện tại
  // Lấy ngày hiện tại
  bool isAutoOrManual =true;
  bool isRadar = false;
  bool isRadarSub = false;
  bool isCO2 = false;
  bool isCO2Sub = false;
  bool isFall= false;
  bool isBreath = false;
  bool isPress = false;
  bool isLux = false;
  late int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    client = MqttServerClient(widget.mqttServer, widget.username);
    connectMqttServer();
    co2thresholdController.text = co2Threshold.toString();
    co2measurementController.text = co2Measurement.toString();
    progressDialog = ProgressDialog(context);

  }
  @override
  void dispose() {
    client.disconnect(); // Ngắt kết nối khi StatefulWidget bị dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfaf8833f),
      appBar: AppBar(
        backgroundColor: const Color(0xfaf8833f),
        title: const Text(
          "Hi Nam",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // home page
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.only(bottom: 20),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 45, left: 10, right: 10),
                          width: double.infinity,
                          child: Row(
                            children: [
                              Switch(
                                value: isAutoOrManual, // Assuming isAutoMode is a boolean variable
                                onChanged: (value) {
                                  // Update the isAutoMode variable when the switch is toggled
                                  setState(() {
                                    isAutoOrManual = value;
                                  });
                                  if(value){
                                    publishMessage(topicsPub[4], "auto");
                                  }
                                  else{
                                    publishMessage(topicsPub[4], "manual");
                                  }
                                },
                                activeColor: Colors.deepOrange,
                                inactiveThumbColor: Colors.deepOrange,
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 90),
                                  child: Text(
                                    isAutoOrManual ? 'Auto' : 'Manual', // Display "Auto" or "Manual" based on the switch state
                                    style: const TextStyle(
                                      color: Color(0xFF262626),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 12,
                                height: 17,
                                child: const Image(
                                  fit: BoxFit.fill, image: AssetImage('assets/images/calendar.png'),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 13),
                                child: Text(
                                  currentDate,
                                  style: const TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 14,
                                height: 12,
                                child: Image(
                                  fit: BoxFit.fill, image: AssetImage('assets/images/down.png'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: double.infinity,
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 24,
                                height: 31,
                                child: const Image(
                                  fit: BoxFit.fill, image: AssetImage('assets/images/celsius.png'),
                                ),
                              ),
                              Expanded(
                                child: IntrinsicHeight(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          child: const Text(
                                            'Temperature',
                                            style: TextStyle(
                                              color: Color(0xFF8d8d8d),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${values[0]} °C',
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 34),
                                width: 1,
                                height: 47,
                                child: Image.network(
                                  'https://i.imgur.com/1tMFzp8.png',
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 24,
                                height: 31,
                                child: const Image(
                                  image: AssetImage('assets/images/humidity.png'),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              SizedBox(
                                width: 84,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: const Text(
                                        'Humidity',
                                        style: TextStyle(
                                          color: Color(0xFF8d8d8d),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${values[1]} rH',
                                      style: const TextStyle(
                                        color: Color(0xFF262626),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFffffff),
                        ),
                        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: const Color(0x26ffffff),
                              ),
                              margin: const EdgeInsets.only(bottom: 14),
                              width: 32,
                              height: 32,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: Image(image: AssetImage('assets/images/carbon-neutral.png')),
                              ),
                            ),
                            const Text(
                              'Carbon Dioxide',
                              style: TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${values[2]} ppm',
                                  style: const TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child:  Switch(
                                value: isCO2,
                                onChanged: isAutoOrManual ? null: (isCO2Value){
                                  setState(() {
                                    isCO2 = isCO2Value;
                                  });
                                  if(isCO2Value){
                                    publishMessage(topicsPub[1], "co2_on");
                                  }
                                  else{
                                    publishMessage(topicsPub[1], "co2_off");
                                  }
                                }, // Sử dụng null để vô hiệu hóa onChanged
                                activeColor: Colors.deepOrange,
                                inactiveThumbColor: Colors.deepOrange,
                              ),
                            )

                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFffffff),
                        ),
                        padding: const EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: const Color(0x263c81b5),
                              ),
                              margin: const EdgeInsets.only(bottom: 15),
                              width: 32,
                              height: 32,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: Image(image: AssetImage('assets/images/radar.png')),
                              ),
                            ),
                            const Text(
                              'Distance',
                              style: TextStyle(
                                color: Color(0xFF262626),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  '${values[3]} cm',
                                  style: const TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child:  Switch(
                                value: isRadar,
                                onChanged: isAutoOrManual ? null: (isRadarValue){
                                  setState(() {
                                    isRadar = isRadarValue;
                                  });
                                  if(isRadarValue){
                                    publishMessage(topicsPub[1], "radar_on");
                                  }
                                  else{
                                    publishMessage(topicsPub[1], "radar_off");
                                  }
                                },
                                activeColor: Colors.deepOrange,
                                inactiveThumbColor: Colors.deepOrange,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFffffff),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0a000000),
                                blurRadius: 16,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only( top: 12, bottom: 12, left: 12, right: 12),
                          width: 160,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: const Color(0x263c81b5),
                                  ),
                                  margin: const EdgeInsets.only( bottom: 11),
                                  width: 32,
                                  height: 32,
                                  child: const SizedBox(
                                    width: 24,  // Đặt kích thước bạn muốn cho hình ảnh
                                    height: 24,
                                    child: Image(image: AssetImage('assets/images/gauge.png')
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Pressure',
                                  style: TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${values[4]} hPa',
                                      style: const TextStyle(
                                        color: Color(0xFF262626),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child:  Switch(
                                    value: isPress,
                                    onChanged: isAutoOrManual ? null: (isPressValue){
                                      setState(() {
                                        isPress = isPressValue;
                                      });
                                      if(isPressValue){
                                        publishMessage(topicsPub[1], "press_on");
                                      }
                                      else{
                                        publishMessage(topicsPub[1], "press_off");
                                      }
                                    },
                                    activeColor: Colors.deepOrange,
                                    inactiveThumbColor: Colors.deepOrange,
                                  ),
                                )
                              ]
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFffffff),
                          ),
                          padding: const EdgeInsets.only( top: 12, bottom: 12, left: 12, right: 12),
                          width: 160,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: const Color(0x263c81b5),
                                  ),
                                  margin: const EdgeInsets.only( bottom: 11),
                                  width: 32,
                                  height: 32,
                                  child: const SizedBox(
                                    width: 24,  // Đặt kích thước bạn muốn cho hình ảnh
                                    height: 24,
                                    child: Image(image: AssetImage('assets/images/light.png')
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Light Intensity',
                                  style: TextStyle(
                                    color: Color(0xFF262626),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      '${values[5]} lux',
                                      style: const TextStyle(
                                        color: Color(0xFF262626),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child:  Switch(
                                    value: isLux,
                                    onChanged: isAutoOrManual ? null: (isLuxValue){
                                      setState(() {
                                        isLux = isLuxValue;
                                      });
                                      if(isLuxValue){
                                        publishMessage(topicsPub[1], "lux_on");
                                      }
                                      else{
                                        publishMessage(topicsPub[1], "lux_off");
                                      }
                                    },
                                    activeColor: Colors.deepOrange,
                                    inactiveThumbColor: Colors.deepOrange,
                                  ),
                                )
                              ]
                          ),
                        ),
                      ]
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFffffff),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0a000000),
                                blurRadius: 16,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only( top: 12, bottom: 12, left: 12, right: 12),
                          width: 160,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: const Color(0x263c81b5),
                                      ),
                                      margin: const EdgeInsets.only( bottom: 11),
                                      width: 32,
                                      height: 32,
                                      child: const SizedBox(
                                        width: 24,  // Đặt kích thước bạn muốn cho hình ảnh
                                        height: 24,
                                        child: Image(image: AssetImage('assets/images/falling.png')
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 18,),
                                    Container(
                                      margin: const EdgeInsets.only( bottom: 11),
                                      child: const Text(
                                        'Falling',
                                        style: TextStyle(
                                          color: Color(0xFF262626),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 0, left: 0, right: 0),
                                        child: Text(
                                          '${values[6]} %',
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 0, left: 0, right: 0),
                                        child: const Text(
                                          '',
                                          style: TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 3, left: 0, right: 0),
                                        child: Text(
                                          values[7],
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child:  Switch(
                                    value: isFall,
                                    onChanged: isAutoOrManual ? null: (isFallValue){
                                      setState(() {
                                        isFall = isFallValue;
                                      });
                                      if(isFallValue){
                                        publishMessage(topicsPub[2], "fall_on");
                                      }
                                      else{
                                        publishMessage(topicsPub[2], "fall_off");
                                      }
                                    },
                                    activeColor: Colors.deepOrange,
                                    inactiveThumbColor: Colors.deepOrange,
                                  ),
                                )
                              ]
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFffffff),
                          ),
                          padding: const EdgeInsets.only( top: 12, bottom: 12, left: 12, right: 12),
                          width: 160,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: const Color(0x263c81b5),
                                      ),
                                      margin: const EdgeInsets.only( bottom: 11),
                                      width: 32,
                                      height: 32,
                                      child: const SizedBox(
                                        width: 24,  // Đặt kích thước bạn muốn cho hình ảnh
                                        height: 24,
                                        child: Image(image: AssetImage('assets/images/breathing.png')
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 18,),
                                    Container(
                                      margin: const EdgeInsets.only( bottom: 11),
                                      child: const Text(
                                        'Breathing',
                                        style: TextStyle(
                                          color: Color(0xFF262626),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 0, left: 0, right: 0),
                                        child: Text(
                                          '${values[8]} Bpm',
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 0, left: 0, right: 0),
                                        child: Text(
                                          '${values[9]} BPM',
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only( top: 3, bottom: 3, left: 0, right: 0),
                                        child: Text(
                                          values[10],
                                          style: const TextStyle(
                                            color: Color(0xFF262626),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 40,
                                  child:  Switch(
                                    value: isBreath,
                                    onChanged: isAutoOrManual ? null: (isBreathValue){
                                      setState(() {
                                        isBreath = isBreathValue;
                                      });
                                      if(isBreathValue){
                                        publishMessage(topicsPub[3], "breath_on");
                                      }
                                      else{
                                        publishMessage(topicsPub[3], "breath_off");
                                      }
                                    },
                                    activeColor: Colors.deepOrange,
                                    inactiveThumbColor: Colors.deepOrange,
                                  ),
                                )
                              ]
                          ),
                        ),
                      ]
                  ),
                )
              ],
            ),
          ),
          Container(),
          Container(),
          Container(),
          // Setting
          Padding(
              padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CO2 Threshold (Ppm):',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: co2Threshold.toDouble(),
                          min: 0,
                          max: 2000,
                          onChanged: (value) {
                            setState(() {
                              co2Threshold = value.toInt();
                              co2thresholdController.text = co2Threshold.toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 60,
                        child: TextField(
                          controller: co2thresholdController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            int newValue = int.tryParse(value) ?? 0;
                            if (newValue > 2000) {
                              // Nếu giá trị vượt quá giới hạn, đặt lại giá trị và hiển thị thông báo
                              setState(() {
                                co2Threshold = 2000;
                                co2thresholdController.text = '2000';
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Thông báo'),
                                    content: const Text('Giá trị ngưỡng CO2 không thể lớn hơn 2000.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              setState(() {
                                co2Threshold = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Text('Selected Threshold: $co2Threshold'),

                  const SizedBox(height: 20),

                  const Text(
                    'CO2 Reading Interval (second):',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: co2Measurement.toDouble(),
                          min: 0,
                          max: 2000,
                          onChanged: (value) {
                            setState(() {
                              co2Measurement = value.toInt();
                              co2measurementController.text = co2Measurement.toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 60,
                        child: TextField(
                          controller: co2measurementController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            int newValue = int.tryParse(value) ?? 0;
                            if (newValue > 2000) {
                              // Nếu giá trị vượt quá giới hạn, đặt lại giá trị và hiển thị thông báo
                              setState(() {
                                co2Measurement = 2000;
                                co2measurementController.text = '2000';
                              });
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Thông báo'),
                                    content: const Text('Giá trị thời gian đo CO2 không thể lớn hơn 2000.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              setState(() {
                                co2Measurement = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Text('Selected Interval: $co2Measurement second'),
                  const SizedBox(height: 20),
                  // Nút Publish
                  Container(
                    width: double.infinity,
                    child: Center(
                        child: ElevatedButton(
                          onPressed:() => publishValues(context),
                          style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(8))
                            ),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.orangeAccent,
                            fixedSize: const Size(200, 50),
                          ),
                          child: const Center(
                            child: Text("Configuration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                          ),
                        )
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange, // Màu của nút được chọn
        unselectedItemColor: Colors.black, // Màu của các nút không được chọn
        elevation: 6,
        currentIndex: _selectedIndex,
        onTap: (int newIndex){
          setState(() {
            _selectedIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  // Hàm kết nối MQTT server
  Future<void> connectMqttServer() async {
    final String mqttServerHome = widget.mqttServer;
    final String clientID = widget.username;
    client = MqttServerClient(mqttServerHome, clientID);
    client.port = 1883;
    client.logging(on: true);
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.connectTimeoutPeriod = 2000;
    client.keepAlivePeriod = 20;

    final connectMessage = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce)
        .withWillTopic('NamCLoud/feeds/')
        .withWillMessage('Hi Nam')
        .authenticateAs(widget.username, widget.password);

    client.connectionMessage = connectMessage;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('MQTT client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('Socket exception - $e');
      client.disconnect();
    }
  }

  // Hàm được gọi khi kết nối thành công
  void onConnected() {
    print('Connected to the MQTT server');
    const topicMain = 'NamCLoud/feeds/';

    // Subscribe từng topic và lắng nghe cập nhật
    for (int i = 0; i < topicsSub.length; i++) {
      final currentTopic = topicMain + topicsSub[i];
      client.subscribe(currentTopic, MqttQos.atMostOnce);
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // Lọc giá trị từ payload và cập nhật vào danh sách values
      setState(() {
        for (int i = 0; i < topicsSub.length; i++) {
          final currentTopic = topicMain + topicsSub[i];
          if (c[0].topic == currentTopic) {
            values[i] = pt;
          }

        }
        if(isAutoOrManual) {
          if (values[11] == 'co2_on') { // led_control
            values[11] = '';
            isCO2 = true;
          }
          else if (values[11] == 'co2_off') {
            values[11] = '';
            print("gia tri radar la ${values[11]}");
            isCO2 = false;
          }
          else if (values[3].startsWith('01')) {
            values[3] = values[3].substring(3);
            isRadar = true;
          }
          else if (values[3].startsWith('00')) {
            values[3] = values[3].substring(3);
            isRadar = false;
          }
          else if (values[10] == 'Abnormal' || values[10] == 'Abnormal rapid') {
            isBreath = true;
          }
          else if (values[10] == 'none' || values[10] == 'normal' || values[10] == 'move') {
            isBreath = false;
          }
          else if (values[7] == 'Still' || values[7] == 'Active' || values[7] == 'None' || values[7] == 'someone' || values[7] == 'no one'){
            isFall = false;
          }
          else if (values[7] == 'falling'){
            isFall = true;
          }
        }
        else{
          if (values[3].startsWith('01')) {
          values[3] = values[3].substring(3);
          }
          else if (values[3].startsWith('00')) {
          values[3] = values[3].substring(3);
          }

          }
      });
    });
  }
  void publishMessage(String topic, String message) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      const topicMain = 'NamCLoud/feeds/';
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topicMain+topic, MqttQos.atMostOnce, builder.payload!);
    } else {
      print('Connection is not in the Connected state. Cannot publish message.');
    }
  }
  // Hàm được gọi khi mất kết nối
  void onDisconnected() {
    print('Disconnected from the MQTT server');
  }

  void publishValues(BuildContext context) async {
    Completer<void> completer = Completer<void>();
    setState(() {
      isProcessTerminated = false; // Bắt đầu hiển thị loading
    });
    progressDialog.show();

    publishTopicConfigure('cfco2', co2Threshold.toString().padLeft(4,'0')+co2Measurement.toString().padLeft(4,'0'));
    try {
      final subscription = subscribeTopic('c_cfco2');
      await subscription.timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Subscription timed out after 2 seconds.');
      // Xử lý theo nhu cầu của bạn khi quá thời gian chờ
    }
    setState(() {
      isProcessTerminated = true; // tắt hiển thị loading
    });
    if(isProcessTerminated) {

      progressDialog.hide();
      if(context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Thông báo'),
              content: Row(
                children: [
                  completedSub
                      ? const Icon(Icons.check_circle, color: Colors.green) // Icon khi hoàn thành
                      : const Icon(Icons.error, color: Colors.red), // Icon cảnh báo khi chưa hoàn thành
                  const SizedBox(width: 8), // Khoảng cách giữa icon và văn bản
                  Text(
                    completedSub ? 'Completed' : 'Incomplete\n Please try again',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if(completedSub){
                        completedSub = false;
                      }
                      isProcessTerminated = true;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
    return completer.future;
  }

  // Hàm giả định publish topic
  publishTopicConfigure(String topic, String message){
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      const topicMain = 'NamCLoud/feeds/';
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topicMain+topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      print('Connection is not in the Connected state. Cannot publish message.');
    }

  }

  // Hàm giả định subscribe topic
  Future<void> subscribeTopic(String topic) async {
    final Completer completer = Completer();

    const topicMain = 'NamCLoud/feeds/';
    final currentTopic = topicMain + topic;
    client.unsubscribe(topicMain+topic);
    client.subscribe(currentTopic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      if (pt == "ok") {
        setState(() {
          completedSub = true;
        });
        completer.complete();
        client.unsubscribe(topicMain+topic);
      }
    });
    return completer.future;
  }

}

