import 'package:sncf/entities/Stop.dart';
import 'package:sncf/entities/TypeTrain.dart';

class Train{
  int num;
  TypeTrain typeTrain;
  late Stop? from;
  late Stop? to;
  late List<Stop> stops;
  String localHour;
  String localMinute;

  Train(this.num, this.typeTrain, this.localHour, this.localMinute){
    this.stops = [];
  }

  void addStop(Stop stop, bool departureStation, bool arrivalStation){
    if(departureStation && !arrivalStation)from = stop;
    if(!departureStation && arrivalStation)to = stop;
    stops.add(stop);
  }



  @override
  String toString() {
    String? stationName = to?.getStation().getName();
    
    return "$localHour\h$localMinute\n${typeTrain.name} $num";
  }
}