// ignore_for_file: unnecessary_new

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;
import 'package:http/http.dart' as http;
import 'package:sncf/entities/Stop.dart';
import 'package:sncf/entities/TypeTrain.dart';
import 'dart:convert';

import 'entities/Station.dart';
import 'entities/Train.dart';
import 'map.dart';

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
  List<Train> departures = [];

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
      parseDepartures(response.body, selected.codeUIC, token);
    }else{
      print("unable to fetch api ${response.body}");
    }
  }

  Future<void> parseDepartures(String response, int codeUic, String token) async{
    final departures = jsonDecode(response)['departures'] as List;
    final departuresList = <Train>[];

    departures.forEach((element) {
      final informations = element['display_informations'];
      final time = element['stop_date_time'];
      
      final direction = informations['direction'].toString().split('(')[0]; //Name of the arrival station
      final numero = informations['trip_short_name']; //Journey's number
      final typeTrain = getTypeTrain(informations['network']); //Type of train

      //Get the time of departure
      final hourDeparture = time['departure_date_time'].toString().substring(9,11);
      final minuteDeparture = time['departure_date_time'].toString().substring(11,13);

      final journeyId = element['links'][1]['id'];

      var train = Train(int.parse(numero), typeTrain, hourDeparture, minuteDeparture);

      train.to = Stop("", "", "", "", Station(codeUic,direction,0,0));
      train.from = null;

      fetchAndParseStops("https://api.sncf.com/v1/coverage/sncf/vehicle_journeys/$journeyId/vehicle_journeys?&key=$token", codeUic, train);

      departuresList.add(train);
      setState(() {
        this.departures = departuresList;
      });
    });
  }

  Future<void> fetchAndParseStops(String url,int codeUic,Train train) async{
    final response = await http.get(Uri.parse(url));

    if(response.statusCode == 200){
      final stopTimes = jsonDecode(response.body)['vehicle_journeys'][0]['stop_times'] as List;

      stopTimes.forEach((element) {
        //get departure and arrival time at the station
        final hourArrival = element['arrival_time'].substring(0,2);
        final minuteArrival = element['arrival_time'].substring(2,4);
        final hourDeparture = element['departure_time'].substring(0,2);
        final minuteDeparture = element['departure_time'].substring(2,4);

        //get the name and coord of the station
        final coord = element['stop_point']['coord'];
        final stationName = element['stop_point']['name'];
        final stationLat = double.parse(coord['lat']);
        final stationLon = double.parse(coord['lon']);

        final stop = Stop(hourArrival, minuteArrival, hourDeparture, minuteDeparture, Station(codeUic,stationName,stationLat,stationLon));

        // Handle if the stop is the start or end station
        final drop = element['drop_off_allowed'] as bool;
        final get = element['pickup_allowed'] as bool;

        if(get && !drop) train.addStop(stop, true, false);
        if(!get && drop) train.addStop(stop, false, true);
        if(get && drop) train.addStop(stop, false, false);
      });
    }else{
      print("unable to fetch api ${response.body}");
    }
  }

  TypeTrain getTypeTrain(String json){
    var typeTrain;
    switch(json.split(' ')[0]){
      case 'TER':{
        typeTrain = TypeTrain.TER;
      }
      break;
      case 'TGV':{
        typeTrain = TypeTrain.TGV;
      }
      break;
      case 'Intercites':{
        typeTrain = TypeTrain.Intercites;
      }
      break;
      case 'OUIGO':{
        typeTrain = TypeTrain.OUIGI;
      }
      break;
      default:{
        typeTrain = TypeTrain.UNDEFINED;
      }
    }

    return typeTrain;
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
      title: 'SNCF',
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
              child: ListView.builder(
                itemCount: departures.length,
                itemBuilder: (context, index){
                  final departure = departures[index];
                  return Container(
                    margin: EdgeInsets.only(left: 20, right: 20, bottom: 0, top: 10),
                    child: ListTile(
                      title: Text("${departure.to?.station.name}"),
                      subtitle: Text(departure.toString()),
                      shape:RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        side: BorderSide(color: Colors.black),
                      ),
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Map(departure))
                        );
                      },
                    )
                  );
                },
              )
            )
          ],
        ),
      ),
    );
  }
}
