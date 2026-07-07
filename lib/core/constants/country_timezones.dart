class CountryTimezones {
  static const Map<String, int> offsets = {
    'Egypt': 3,
    'Saudi Arabia': 3,
    'UAE': 4,
    'Morocco': 1,
    'Algeria': 1,
    'Tunisia': 1,
    'Jordan': 3,
    'Lebanon': 3,
    'Kuwait': 3,
    'Qatar': 3,
    'Oman': 4,
    'Bahrain': 3,
    'Iraq': 3,
  };

  static DateTime convertToCountryTime(DateTime utcTime, String country) {
    final offset = offsets[country] ?? 0;
    return utcTime.add(Duration(hours: offset));
  }
}
