// ignore_for_file: unnecessary_new

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'entities/Station.dart';

Future main() async{
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SNCF'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Station> stations = []; //List of all stations in France
  List<List<dynamic>> csv = []; //List to store the csv file

  Future<List<List<dynamic>>> loadCsv() async {
    final String data = await DefaultAssetBundle.of(context)
        .loadString('assets/gares.csv');
    List<List<dynamic>> csvTable = CsvToListConverter().convert(data, eol: '\n', fieldDelimiter: ';');
    setState(() {
      csv = csvTable;
    });

    return csvTable;
  }

  //Create a list of Station objects from the csv list
  void setStation(){
    for (int i = 1; i < csv.length; i++) {
      stations.add(Station(
          csv[i][0], csv[i][1], csv[i][2], csv[i][3]));
    }
  }

  Future<void> fetchDepartures(Station selected) async{
    final codeUic = selected.codeUIC.toString();
    final dotenv = env.DotEnv();
    await dotenv.load();
    final token = dotenv.env['SNCF_KEY']!;
    final response = await http.get(Uri.parse("https://api.sncf.com/v1/coverage/sncf/stop_areas/stop_area%3ASNCF%3A$codeUic\/departures?&key=$token"));

    if(response.statusCode == 200){
      print(response.body);
    }else{
      print(response.body);
    }
  }

  @override
  void initState() {
    loadCsv().then((value) => setStation()); //Load the csv file and create the list of stations
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    GlobalKey<AutoCompleteTextFieldState<Station>> key = GlobalKey();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SNCF'),
        ),
        body: new Column(
          children: [
            new Container(
              margin: const EdgeInsets.all(20),
              child:Align(
                alignment: Alignment.topCenter,
                child: AutoCompleteTextField<Station>(
                  key: key,
                  itemSubmitted: (item) {
                    fetchDepartures(item);
                  },
                  suggestions: stations, //link the list of stations to the autocomplete textfield
                  itemBuilder: (context, suggestion) => ListTile( //display the list of stations by their name
                    title: Text(suggestion.name),
                  ),
                  itemFilter: (suggestion, query) { //search in the list of stations by their name
                    return suggestion.name
                        .toLowerCase()
                        .startsWith(query.toLowerCase());
                  },
                  itemSorter: (a, b) { //compare the stations by their name
                    return a.name.compareTo(b.name);
                  },
                  clearOnSubmit: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Ville',
                  ),
                ),
              )
            ),
            new Text(
              'Prochains départs',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            new Expanded(
              child: ListView(
                children: <Widget>[
                  Container(
                    child: Text("1"),
                  ),
                  Container(
                    child: Text("2"),
                  )
                ]
              )
            )
          ],
        ),
      ),
    );
  }
}
