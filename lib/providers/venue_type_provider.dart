import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class VenueTypeProvider extends ChangeNotifier {
  VenueTypeProvider();

  String _venueType = '';

  String get venueType => _venueType;

  bool get isRestaurant => _venueType == 'restaurant';
  bool get isHotel => _venueType == 'hotel';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _venueType = prefs.getString(PrefKeys.venueType) ?? '';
    notifyListeners();
  }

  Future<void> setVenueType(String value) async {
    _venueType = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.venueType, value);
  }

  Future<void> clear() async {
    _venueType = '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.venueType);
  }
}
