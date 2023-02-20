class Station{
  int codeUIC;
  String name;
  double lat;
  double lon;

  Station(this.codeUIC,this.name,this.lat,this.lon);

  String getName(){
    return name;
  }

  @override
  String toString() {
    return name;
  }
}