import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sncf/entities/Train.dart';

class Map extends StatefulWidget{
  final Train departure;

  const Map(this.departure, {super.key});

  State<Map> createState() => _MapState();
}

class _MapState extends State<Map>{

  @override
  Widget build(BuildContext context) {
    final departure = widget.departure;
    final bounds = LatLngBounds();
    final List<Marker> markers = [];
    final List<LatLng> points = [];
    final marker = Container(key: Key('blue'), child: Icon(Icons.location_on, color: Colors.red, size: 30));

    for(int i=0;i<departure.stops.length;i++){
      var latlng = LatLng(departure.stops[i].station.lat,departure.stops[i].station.lon);
      bounds.extend(latlng);
      points.add(latlng);
      markers.add(Marker(point: latlng, builder: ((context) => marker)));
    }


    


    return Scaffold(
      appBar: AppBar(
        title: const Text("Trajet"),
      ),
      body: FlutterMap(
          options: MapOptions(
              bounds: bounds
          ),
          nonRotatedChildren: [
              AttributionWidget.defaultWidget(
                  source: 'OpenStreetMap contributors',
                  onSourceTapped: null,
              ),
          ],
          children: [
              TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: markers
              ),
              PolylineLayer(
                polylineCulling: false,
                polylines: [
                  Polyline(
                    points: points,
                    color: Colors.blue,
                    strokeWidth: 3.5
                  )
                ],
              )
          ],
      )
    );
  }
}