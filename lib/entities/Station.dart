class Station{
  int codeUIC;
  String name;
  double lon;
  double lat;

  Station(this.codeUIC,this.name,this.lon,this.lat);

  String getName(){
    return name;
  }

  @override
  String toString() {
    return name;
  }
}