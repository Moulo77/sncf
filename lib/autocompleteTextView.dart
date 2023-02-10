import 'dart:io';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:sncf/entities/Station.dart';

class AutoCompleteText extends StatefulWidget {
  const AutoCompleteText({super.key});

  @override
  _AutoCompleteTextState createState() => _AutoCompleteTextState();
}

class _AutoCompleteTextState extends State<AutoCompleteText> {
  List<Station> stations = []; //List of all stations in France
  List<List<dynamic>> csv = []; //List to store the csv file
  
  //Load the csv file and store it in the csv list
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

  @override
  void initState() {
    loadCsv().then((value) => setStation()); //Load the csv file and create the list of stations
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    GlobalKey<AutoCompleteTextFieldState<Station>> key = GlobalKey();

    return AutoCompleteTextField<Station>(
      key: key,
      itemSubmitted: (item){

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
    );
  }
}

