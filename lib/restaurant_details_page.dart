import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cxapp/survey_type_page.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final String restaurantId;
  const RestaurantDetailsPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final ref =
        FirebaseDatabase.instance.ref().child("restaurants/$restaurantId");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurant Details"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.network(
                  data["imageUrl"],
                  height: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                Text(
                  data["name"],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  data["location"],
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SurveyTypePage(restaurantId: restaurantId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.poll),
                  label: const Text("Take a Survey"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
