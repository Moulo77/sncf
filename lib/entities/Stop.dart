import 'package:sncf/entities/Station.dart';

class Stop{
  String hourArrival;
  String minuteArrival;
  String hourDeparture;
  String minuteDeparture;
  Station station;

  Stop(this.hourArrival,this.minuteArrival,this.hourDeparture,this.minuteDeparture,this.station);

  Station getStation(){
    return station;
  }
}