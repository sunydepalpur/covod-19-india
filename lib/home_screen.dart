import 'package:covid_19/constant.dart';
import 'package:covid_19/widgets/counter.dart';
import 'package:covid_19/widgets/my_header.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:fcharts/fcharts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:rflutter_alert/rflutter_alert.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = ScrollController();
  double offset = 0;
  String globalFilterValue = "Total";
  String currentFilterValue = "Total";
  bool logDataLoaded = false;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics();
  var chartData = [0.0, -0.2, -0.9, -0.5, 0.0, 0.5, 0.6, 0.9, 0.8, 1.2, 0.5, 0.0];
  bool firstAPiCallFinish = false;
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller.addListener(onScroll);
    getDataFromAPI();
    getLogNewsDataAPI();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        // _showItemDialog(message);
        showAlertPopup(message);
      },
      // onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        showAlertPopup(message);
        // _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        showAlertPopup(message);
        // _navigateToItemDetail(message);
      },
    );

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
          print("Settings registered: $settings");
    });
    _firebaseMessaging.getToken().then((String token) {
      assert(token != null);
      setState(() {
        // _homeScreenText = "Push Messaging token: $token";
      });
      print(token);
    });

    _firebaseMessaging.subscribeToTopic('all');

    _firebaseAnalytics.setAnalyticsCollectionEnabled(true);
    _firebaseAnalytics.setCurrentScreen(screenName: "Home Page Open Count");
    // _firebaseAnalytics.setUserProperty(name: "user_country", value: 'india');

  }

  Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
    print(data);
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
    print(notification);
  }
  // Or do other work.
}

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }

  showAlertPopup(text) {
    print('object');
    var alertStyle = AlertStyle(
      animationType: AnimationType.grow,
      isCloseButton: false,
      isOverlayTapDismiss: false,
      descStyle: TextStyle(fontWeight: FontWeight.normal),
      animationDuration: Duration(milliseconds: 400),
      alertBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
        side: BorderSide(
          color: Colors.grey,
        ),
      ),
      titleStyle: TextStyle(
        color: kPrimaryColor,
      ),
    );

     Alert(
      context: context,
      style: alertStyle,
      type: AlertType.info,
      title: "Notification Alert",
      desc: text,
      buttons: [
        DialogButton(
          child: Text(
            "Close",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          color: kPrimaryColor,
          radius: BorderRadius.circular(0.0),
        ),
      ],
    ).show();
    print('object');

  }

  getDataFromAPI() async {
    // var url = 'https://api.covid19india.org/raw_data.json';
    var url = 'https://api.covid19india.org/data.json';

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(url);
    if (response.statusCode == 200) {
      GlobalData.jsonResponse = convert.jsonDecode(response.body);
      print('API Call success');
      firstAPiCallFinish = true;
      // print(GlobalData.jsonResponse);
      print(GlobalData.jsonResponse['cases_time_series'].length);
      processGlobalData("Total");
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    
  }

  getLogNewsDataAPI() async {
    var url = 'https://api.covid19india.org/updatelog/log.json';

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(url);
    if (response.statusCode == 200) {
      GlobalData.logDataResponse = convert.jsonDecode(response.body);
      print('API Call success ${response.statusCode}');
      // print(GlobalData.logDataResponse);
      logDataLoaded = true;
      // print(GlobalData.jsonResponse['cases_time_series'].length);
      // processGlobalData("Total");
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
    
  }

  List<List<String>>myData = [];

  processGlobalData(stateFilter) async {
      GlobalData.totalInfected = 0;
      GlobalData.totalActive = 0;
      GlobalData.totalRecovered = 0;
      GlobalData.totalDeaths = 0;
      currentFilterValue = stateFilter;


      for (var item in GlobalData.jsonResponse['cases_time_series']) {
        myData.add([item['dailyconfirmed'], item['date']]);
        if(!(item['date'].contains("Jan") || item['date'].contains("Feb") || item['date'].contains("Mar"))) {
          chartData.add(double.parse(item['dailyconfirmed'] ?? 0));
        } else {
          chartData.add(double.parse(item['dailyconfirmed'] ?? 0));
        }
        // if(stateFilter == "") {
        //   GlobalData.totalInfected += int.parse(item['dailyconfirmed']) ?? 0;
        //   GlobalData.totalRecovered += int.parse(item['dailyrecovered']) ?? 0;
        //   GlobalData.totalDeaths += int.parse(item['dailydeceased']) ?? 0;
        // } else if(stateFilter != ""){
        //   GlobalData.totalInfected += int.parse(item['dailyconfirmed']) ?? 0;
        //   GlobalData.totalRecovered += int.parse(item['dailyrecovered']) ?? 0;
        //   GlobalData.totalDeaths += int.parse(item['dailydeceased']) ?? 0;
        // }
      }
      // GlobalData.totalActive = GlobalData.totalInfected - GlobalData.totalRecovered - GlobalData.totalDeaths;

      print(chartData);

      for (var item in GlobalData.jsonResponse['statewise']) {
        GlobalData.stateList.add(item['state']);

        if(stateFilter == item['state']) {
          GlobalData.totalInfected = int.parse(item['confirmed']) ?? 0;
          GlobalData.totalRecovered = int.parse(item['recovered']) ?? 0;
          GlobalData.totalDeaths = int.parse(item['deaths']) ?? 0;
          GlobalData.totalActive = int.parse(item['active']) ?? 0;
          GlobalData.lastupdatedtime = item['lastupdatedtime'] ?? '';
        }
        
      }
      var date = DateTime.parse(GlobalData.lastupdatedtime.replaceAll("/", '-').split(" ")[0].split('-').reversed.join('-') + ' ' +GlobalData.lastupdatedtime.replaceAll("/", '-').split(" ")[1]);
      GlobalData.lastupdatedtime = "${date.day} ${date.month==4 ? 'Apr': date.month} ${date.hour}:${date.minute} ${date.timeZoneName}";
      // print(GlobalData.stateList);
      setState(() {
        
      });
  }

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
  }

  checkForValueChnage() async {
    if(currentFilterValue != globalFilterValue) {
      processGlobalData(globalFilterValue);
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: <Widget>[
            MyHeader(
              image: "assets/icons/Drcorona.svg",
              textTop: "All you need",
              textBottom: "is stay at home.",
              offset: offset,
              show: true,
            ),
            firstAPiCallFinish ? Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Color(0xFFE5E5E5),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SvgPicture.asset("assets/icons/maps-and-flags.svg"),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: SvgPicture.asset("assets/icons/dropdown.svg"),
                      value: globalFilterValue,
                      items: GlobalData.stateList.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setState(() {
                          globalFilterValue = value;
                        });
                        processGlobalData(globalFilterValue);
                        // globalFilterValue = value;
                        
                      },
                    ),
                  ),
                ],
              ),
            ) : Container(
              height: MediaQuery.of(context).size.height/2,
              child: Center(child: CircularProgressIndicator(),),
            ),
            SizedBox(height: 20),
            firstAPiCallFinish ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Case Update\n",
                              style: kTitleTextstyle,
                            ),
                            TextSpan(
                              text: "Newest update ${GlobalData.lastupdatedtime}",
                              style: TextStyle(
                                color: Colors.red, //kTextLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context){
                                return AlertDialog(
                                  title: Text("Updates"),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: getLogDataWidgets(),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    MaterialButton(
                                      child: Text("Close", style: TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      }
                                    )
                                  ],
                                );
                            }
                          );
                        },
                        child: Text(
                          "See details",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 4),
                          blurRadius: 30,
                          color: kShadowColor,
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        // Padding(padding: EdgeInsets.only(bottom: 5), child: Text("Last Update " + GlobalData.lastupdatedtime.toString(), style: TextStyle(color: Colors.red),),),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                               Counter(
                                color: kPrimaryColor,
                                number: GlobalData.totalActive,
                                title: "Active",
                              ),
                              // Counter(
                              //   color: kDeathColor,
                              //   number: GlobalData.totalInfected,
                              //   title: "Confirmed",
                              // ),
                              Counter(
                                color: kRecovercolor,
                                number: GlobalData.totalRecovered,
                                title: "Recovered",
                              ),
                              Counter(
                                color: kTextLightColor,
                                number: GlobalData.totalDeaths,
                                title: "Deaths",
                              ),
                              
                            ],
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.all(6),
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kDeathColor.withOpacity(.26),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color: kDeathColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10, width: 20,),
                              Text(
                                GlobalData.totalInfected.toString(),
                                style: TextStyle(
                                  fontSize: 30,
                                  color: kDeathColor,
                                ),
                              ),
                              SizedBox(height: 10, width: 20,),
                              Text('Total Confirmed', style: TextStyle(color: kDeathColor, fontSize: 16)),
                            ],
                          ),
                          new AspectRatio(
                                aspectRatio: 4.0,
                                child: new LineChart(
                                  lines: [
                                    new Sparkline(
                                      data: chartData,
                                      stroke: new PaintOptions.stroke(
                                        color: kDeathColor,
                                        strokeWidth: 2.0,
                                      ),
                                      marker: new MarkerOptions(
                                        paint: new PaintOptions.fill(color: kDeathColor),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                      ],
                    )
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Spread of Virus",
                        style: kTitleTextstyle,
                      ),
                      GestureDetector(
                      child:  Text(
                          "See details",
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          showAlertPopup("snvvsiubBIUBV");
                        },
                      )
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(20),
                    height: 178,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 10),
                          blurRadius: 30,
                          color: kShadowColor,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/map.png",
                      fit: BoxFit.contain,
                    ),
                    // child: new AspectRatio(
                    //             aspectRatio: 4.0,
                    //             // child: new BarChart(
                    //               // data: chartData,
                    //               // bars: [
                    //               //   new Bar<int>(
                    //               //     xFn: (sales) => sales,
                    //               //     // valueFn: (sales) => sales.chocolate,
                    //               //     fill: new PaintOptions.fill(color: Colors.brown),
                    //               //     // stack: barStack1,
                    //               //   ),
                    //                 // new Sparkline(
                    //                 //   data: chartData,
                    //                 //   stroke: new PaintOptions.stroke(
                    //                 //     color: kDeathColor,
                    //                 //     strokeWidth: 2.0,
                    //                 //   ),
                    //                 //   marker: new MarkerOptions(
                    //                 //     paint: new PaintOptions.fill(color: kDeathColor),
                    //                 //   ),
                    //                 // ),
                    //               ],
                    //             ),
                    //           )
                  ),
                ],
              ),
            ) : Container(),
          ],
        ),
      ),
    );
  }

  getLogDataWidgets() {
    List<Widget> list = new List();
    List<dynamic> data = GlobalData.logDataResponse;
    int index = 0;
    

    for (var item in data.reversed) {
      print(DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(item['timestamp'])));
      var date = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(item['timestamp'] * 1000));
      var dateText = date.inHours == 0 ? "${date.inMinutes} minutes ago" : "about ${date.inHours} hour ago";

      if(index < 5){
        list.add(
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              border: Border(
                // bottom: BorderSide(width: 1, color: Colors.grey.shade300)
              )
            ),
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                Padding(padding: EdgeInsets.all(10), child: Icon(Icons.new_releases, color: kPrimaryColor, size: 35,),),
                Column(
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width -183,
                      
                      child: Text(dateText, style: TextStyle(color: Colors.grey),maxLines: 1,overflow: TextOverflow.ellipsis, textAlign: TextAlign.left,),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width -183,
                      child: Text(item['update'], maxLines: 3,overflow: TextOverflow.ellipsis,),
                    ),
                    
                  ],
                )
              ],
            )
          )
        );
      }
      index+=1;
    }
    return list;
  }
}

class SalesData {
  SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
