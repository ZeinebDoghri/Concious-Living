import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../core/models/restaurant.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  static Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radiusMeters'
      '&type=restaurant'
      '&key=$googlePlacesApiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final places = results
              .map((r) => Restaurant.fromGooglePlaces(r as Map<String, dynamic>))
              .toList();
          return await _overlayOrkaData(places);
        }
      }
    } catch (_) {}

    return await _getFirestoreRestaurants();
  }

  static Future<List<Restaurant>> _getFirestoreRestaurants() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();
      return snap.docs
          .map((d) => Restaurant.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Restaurant>> _overlayOrkaData(List<Restaurant> places) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('verified_restaurants')
          .get();
      final verifiedIds = {for (final d in snap.docs) d.id: d.data()};

      return places.map((p) {
        if (verifiedIds.containsKey(p.id)) {
          final data = verifiedIds[p.id]!;
          return Restaurant(
            id: p.id,
            name: p.name,
            address: p.address,
            rating: p.rating,
            lat: p.lat,
            lng: p.lng,
            photoReference: p.photoReference,
            cuisineType: p.cuisineType,
            priceLevel: p.priceLevel,
            isOpenNow: p.isOpenNow,
            isOrkaVerified: true,
            menuAllergens: List<String>.from(data['allergens'] ?? []),
          );
        }
        return p;
      }).toList();
    } catch (_) {
      return places;
    }
  }

  static String getPhotoUrl(String photoReference) {
    return '$_baseUrl/place/photo'
        '?maxwidth=400'
        '&photoreference=$photoReference'
        '&key=$googlePlacesApiKey';
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,opening_hours,rating,photos,website,formatted_phone_number'
      '&key=$googlePlacesApiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> geocodeAndSaveLocation(String city, String uid) async {
    final url = Uri.parse(
      '$_baseUrl/geocode/json'
      '?address=${Uri.encodeComponent(city)}'
      '&key=$googlePlacesApiKey',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final location = (data['results'] as List?)?.firstOrNull?['geometry']?['location'];
        if (location != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'location': GeoPoint(
              (location['lat'] as num).toDouble(),
              (location['lng'] as num).toDouble(),
            ),
            'city': city,
          });
        }
      }
    } catch (_) {}
  }

  static Future<List<MenuItem>> getRestaurantMenu(String restaurantId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('verified_restaurants')
          .doc(restaurantId)
          .collection('menu')
          .get();
      return snap.docs.map((d) => MenuItem.fromFirestore(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }
}
