import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_travel_budget/widgets/provider_widget.dart';
import 'package:flutter_travel_budget/models/Trip.dart';
import 'package:flutter_travel_budget/widgets/calculator_widget.dart';
import 'detail_trip_view.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeView extends StatefulWidget {

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future _nextTrip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nextTrip = _getNextTrip();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          FutureBuilder(
            future: _nextTrip,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CalculatorWidget(trip: snapshot.data);
              } else {
                return Text("Loading...");
              }
            },
          ),
          Expanded(
            child: StreamBuilder(
              stream: getUsersTripsStreamSnapshots(context),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("Loading...");
                return new ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (BuildContext context, int index) =>
                    buildTripCard(context, snapshot.data.documents[index])
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> getUsersTripsStreamSnapshots(
      BuildContext context) async* {
    final uid = await Provider
      .of(context)
      .auth
      .getCurrentUID();
    yield* Firestore.instance.collection('userData').document(uid).collection(
      'trips').orderBy('startDate').snapshots();
  }

  _getNextTrip() async {
    final uid = await Provider.of(context).auth.getCurrentUID();
    var snapshot = await Firestore.instance.collection('userData')
        .document(uid)
        .collection('trips')
        .orderBy('startDate')
        .limit(1)
        .getDocuments();
    return Trip.fromSnapshot(snapshot.documents.first);
  }

  Widget buildTripCard(BuildContext context, DocumentSnapshot document) {
    final trip = Trip.fromSnapshot(document);
    final tripType = trip.types();

    return new Container(
      child: Card(
        child: InkWell(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Row(children: <Widget>[
                    Text(
                      trip.title, 
                      style: GoogleFonts.seymourOne(fontSize: 14.0)
                    ),
                    Spacer(),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 80.0),
                  child: Row(children: <Widget>[
                    Text(
                      "${DateFormat('MM/dd/yyyy')
                        .format(trip.startDate)
                       .toString()} - ${DateFormat('MM/dd/yyyy').format(
                        trip.endDate).toString()}"
                    ),
                    Spacer(),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: <Widget>[
                      Text("\$${(trip.budget == null) ? "n/a" : trip.budget
                        .toStringAsFixed(2)}",
                        style: new TextStyle(
                          fontSize: 35.0
                        ),
                      ),
                      Spacer(),
                      (tripType.containsKey(trip.travelType)) ? tripType[trip
                        .travelType] : tripType["other"],
                    ],
                  ),
                )
              ],
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailTripView(trip: trip)
              ),
            );
          },
        ),
      ),
    );
  }
}