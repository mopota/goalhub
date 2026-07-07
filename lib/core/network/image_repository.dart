import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ImageType { player, team, league }

class ImageRepository {
  final Dio _dio;
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  
  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  static const String _cachePrefix = 'tsdb_cache_';

  ImageRepository(this._dio, this._prefs);

  Future<String?> getPlayerImage(String name, {String? team, String? nationality}) async {
    final cacheKey = '${_cachePrefix}player_${name}_${team ?? ''}_${nationality ?? ''}'.toLowerCase().replaceAll(' ', '_');
    
    final cached = _prefs.getString(cacheKey);
    if (cached != null) {
      _logger.i('[ImageRepo] Cache Hit: Player $name -> $cached');
      return cached.isEmpty ? null : cached;
    }

    _logger.i('[ImageRepo] Cache Miss: Searching Player $name (Team: $team)');
    try {
      // Search with as much info as possible
      final query = '$name ${team ?? ''} ${nationality ?? ''}'.trim();
      final response = await _dio.get('$_baseUrl/searchplayers.php', queryParameters: {'p': query});
      
      String? imageUrl;
      if (response.statusCode == 200 && response.data != null) {
        final players = response.data['player'] as List?;
        if (players != null && players.isNotEmpty) {
          final p = players[0];
          imageUrl = p['strCutout']?.toString() ?? p['strThumb']?.toString();
        }
      }

      await _prefs.setString(cacheKey, imageUrl ?? '');
      if (imageUrl != null) {
        _logger.i('[ImageRepo] Image Loaded: Player $name -> $imageUrl');
      } else {
        _logger.w('[ImageRepo] Image Not Found: Player $name');
      }
      return imageUrl;
    } catch (e) {
      _logger.e('[ImageRepo] Search Error (Player $name): $e');
      return null;
    }
  }

  Future<String?> getTeamLogo(String name, {String? league, String? country}) async {
    final cacheKey = '${_cachePrefix}team_${name}_${league ?? ''}_${country ?? ''}'.toLowerCase().replaceAll(' ', '_');
    
    final cached = _prefs.getString(cacheKey);
    if (cached != null) {
      _logger.i('[ImageRepo] Cache Hit: Team $name -> $cached');
      return cached.isEmpty ? null : cached;
    }

    _logger.i('[ImageRepo] Cache Miss: Searching Team $name (League: $league)');
    try {
      final query = name.trim();
      final response = await _dio.get('$_baseUrl/searchteams.php', queryParameters: {'t': query});
      
      String? imageUrl;
      if (response.statusCode == 200 && response.data != null) {
        final teams = response.data['teams'] as List?;
        if (teams != null && teams.isNotEmpty) {
          // Attempt to find the best match if multiple results
          var team = teams[0];
          if (league != null || country != null) {
             for (var t in teams) {
               final tLeague = t['strLeague']?.toString().toLowerCase() ?? '';
               final tCountry = t['strCountry']?.toString().toLowerCase() ?? '';
               if (tLeague.contains(league?.toLowerCase() ?? '') || tCountry.contains(country?.toLowerCase() ?? '')) {
                 team = t;
                 break;
               }
             }
          }
          imageUrl = team['strBadge']?.toString() ?? team['strLogo']?.toString();
        }
      }

      await _prefs.setString(cacheKey, imageUrl ?? '');
      if (imageUrl != null) {
        _logger.i('[ImageRepo] Image Loaded: Team $name -> $imageUrl');
      } else {
        _logger.w('[ImageRepo] Image Not Found: Team $name');
      }
      return imageUrl;
    } catch (e) {
      _logger.e('[ImageRepo] Search Error (Team $name): $e');
      return null;
    }
  }

  Future<String?> getLeagueLogo(String name) async {
    final cacheKey = '${_cachePrefix}league_${name}'.toLowerCase().replaceAll(' ', '_');
    
    final cached = _prefs.getString(cacheKey);
    if (cached != null) {
      _logger.i('[ImageRepo] Cache Hit: League $name -> $cached');
      return cached.isEmpty ? null : cached;
    }

    _logger.i('[ImageRepo] Cache Miss: Searching League $name');
    try {
      // search_all_leagues.php returns a list of all leagues, we search locally
      final response = await _dio.get('$_baseUrl/search_all_leagues.php', queryParameters: {'s': 'Soccer'});
      
      String? imageUrl;
      if (response.statusCode == 200 && response.data != null) {
        final countries = response.data['countries'] as List?;
        if (countries != null) {
          final normalizedSearch = name.toLowerCase();
          final league = countries.firstWhere(
            (l) => l['strLeague']?.toString().toLowerCase() == normalizedSearch ||
                   l['strLeagueAlternate']?.toString().toLowerCase().contains(normalizedSearch) == true,
            orElse: () => null,
          );
          if (league != null) {
            imageUrl = league['strBadge']?.toString() ?? league['strLogo']?.toString();
          }
        }
      }

      await _prefs.setString(cacheKey, imageUrl ?? '');
      if (imageUrl != null) {
        _logger.i('[ImageRepo] Image Loaded: League $name -> $imageUrl');
      } else {
        _logger.w('[ImageRepo] Image Not Found: League $name');
      }
      return imageUrl;
    } catch (e) {
      _logger.e('[ImageRepo] Search Error (League $name): $e');
      return null;
    }
  }
}
