import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:login_page/home.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState  extends State<LoginPage>{
  late MqttServerClient client;
  bool _showPass = true;
  final TextEditingController _mqttSeverController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _userNameErr = "Kiểm tra lại Username";
  final _passwordErr = "Kiểm tra lại Password";
  var _usernameInvalid = false;
  var _passwordInvalid = false;
  @override
  Widget build(BuildContext context){
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 350,
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/background.jpeg'),
                        fit: BoxFit.fill
                    )
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 10,
                      bottom: 10,
                      width: 80,
                      height: 80,
                      child: FadeInDown(duration: const Duration(seconds: 1), child: Container(
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/images/clock.png')
                            )
                        ),
                      )),
                    ),
                    Positioned(
                      top: 70,
                      right: 10,
                      width: 80,
                      height: 350,
                      child: FadeInUp(duration: const Duration(milliseconds: 1200), child: Container(
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/images/light-2.png')
                            )
                        ),
                      )),
                    ),

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: <Widget>[
                    FadeInUp(duration: const Duration(milliseconds: 1800), child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color.fromRGBO(92, 251, 107, 1)),
                          boxShadow: const [
                            BoxShadow(
                                color: Color.fromRGBO(92, 251, 107, .2),
                                blurRadius: 20.0,
                                offset: Offset(0, 10)
                            )
                          ]
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color:  Color.fromRGBO(92, 251, 107, 1)))
                            ),
                            child: TextField(
                              controller: _mqttSeverController,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Mqtt Server",
                                  hintStyle: TextStyle(color: Colors.grey[700])
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color:  Color.fromRGBO(92, 251, 107, 1)))
                            ),
                            child: TextField(
                              controller: _userController,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Username",
                                  errorText: _usernameInvalid ? _userNameErr : null,
                                  hintStyle: TextStyle(color: Colors.grey[700])
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _showPass,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      errorText: _passwordInvalid ? _passwordErr : null,
                                      hintText: "Password",
                                      hintStyle: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onToggleShowPass,
                                  child: Text(
                                    _showPass ? "Show" : "Hide",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )),
                    const SizedBox(height: 30,),
                    FadeInUp(duration: const Duration(milliseconds: 1900), child: ElevatedButton(
                      onPressed: onSignInClicked,
                      style: ElevatedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))
                        ),
                        fixedSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.greenAccent,
                      ),
                      child: const Center(
                        child: Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                      ),
                    )),
                  ],
                ),
              )
            ],
          ),
        )
    );
  }
  void onToggleShowPass(){
    setState(() {
      _showPass = !_showPass;
    });
  }
  void onSignInClicked() async {
    // Connect to the MQTT server
    await connectMqttServer();

    setState(() {
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        // Save the "remember" state and input values
        saveRememberState(true);
        saveInputValues();
        client.disconnect();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeConnectMqtt(
            mqttServer: _mqttSeverController.text,
            username: _userController.text,
            password: _passwordController.text,
          )),
        );
      } else {
        _usernameInvalid = true;
        _passwordInvalid = true;
      }
    });
  }
  Future<void> connectMqttServer()async {
    final String mqttServer = _mqttSeverController.text;
    final String clientID = _userController.text;
    client = MqttServerClient(mqttServer, clientID);
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
        .withWillTopic('NamCLoud/feeds/co2')
        .withWillMessage('Hi Nam')
        .authenticateAs(_userController.text, _passwordController.text);
    client.connectionMessage = connectMessage;
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }
    /// Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE:: Client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
    }


  }

  void onConnected() {
    _usernameInvalid = false;
    _passwordInvalid = false;
    print('Connected to the MQTT server');
    const topic = 'NamCLoud/feeds/mmwareradar'; // Not a wildcard topic
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print(
          'EXAMPLE::Change notification:: topic is <${c[0]
              .topic}>, payload is <-- $pt -->');
      print('');
    });
    // You can perform additional actions after a successful connection
  }

  void onDisconnected() {
    print('Disconnected from the MQTT server');

    // You can handle disconnection scenarios here
  }
  Future<void> saveRememberState(bool remember) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('remember', remember);
  }

  Future<void> saveInputValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('mqttServer', _mqttSeverController.text);
    prefs.setString('username', _userController.text);
    prefs.setString('password', _passwordController.text);
  }

  @override
  void initState() {
    super.initState();
    restoreRememberState();
  }

  Future<void> restoreRememberState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember') ?? false;

    if (remember) {
      _mqttSeverController.text = prefs.getString('mqttServer') ?? '';
      _userController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      setState(() {});
    }
  }
}

