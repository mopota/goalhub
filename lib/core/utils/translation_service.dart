import 'package:dio/dio.dart';

class TranslationService {
  final Dio _dio = Dio();

  // Local map for common football terms to avoid API calls for simple UI text
  static const Map<String, String> _footballTerms = {
    'LIVE': 'مباشر',
    'FT': 'نهاية المباراة',
    'HT': 'بين الشوطين',
    'Final': 'نهاية المباراة',
    'Postponed': 'مؤجلة',
    'Cancelled': 'ملغاة',
    'Scheduled': 'مجدولة',
    'Upcoming': 'قادمة',
    'In Progress': 'جارية',
    'Half Time': 'بين الشوطين',
    'Full Time': 'نهاية المباراة',
    'First Half': 'الشوط الأول',
    'Second Half': 'الشوط الثاني',
    'Extra Time': 'وقت إضافي',
    'Penalties': 'ركلات ترجيح',
    'Possession': 'الاستحواذ',
    'Shots': 'التسديدات',
    'Shots on Goal': 'التسديدات على المرمى',
    'Fouls': 'الأخطاء',
    'Corner Kicks': 'الضربات الركنية',
    'Offsides': 'التسلل',
    'Goalkeeper Saves': 'تصديات الحارس',
    'Yellow Cards': 'البطاقات الصفراء',
    'Red Cards': 'البطاقات الحمراء',
    'Total Passes': 'إجمالي التمريرات',
    'Attacking': 'الهجوم',
    'Defending': 'الدفاع',
    'Passes': 'التمريرات',
    'Pass %': 'دقة التمرير',
    'Fouls Committed': 'الأخطاء المرتكبة',

    'Corners': 'ركنيات',
    'Saves': 'تصديات',

    'Accurate Passes': 'تمريرات صحيحة',
    'Total Shots': 'إجمالي التسديدات',
    'Shot %': 'دقة التسديد',
    'Tackles': 'تاكلينج',
    'Interceptions': 'اعتراض الكرة',
    'Clearances': 'إبعاد الكرة',
    'possessionPercentage': 'الاستحواذ',
    'totalShots': 'إجمالي التسديدات',
    'shotsOnTarget': 'التسديدات على المرمى',
    'foulsCommitted': 'الأخطاء المرتكبة',
    'totalCorners': 'الركلات الركنية',
    'totalOffsides': 'التسلل',
    'goalkeeperSaves': 'تصديات الحارس',
    'totalPasses': 'إجمالي التمريرات',
    'passPercentage': 'دقة التمرير',
    'yellowCards': 'البطاقات الصفراء',
    'redCards': 'البطاقات الحمراء',
    'GK': 'حارس مرمى',
    'DF': 'مدافع',
    'MF': 'لاعب وسط',
    'FW': 'مهاجم',
    'Goalkeeper': 'حارس مرمى',
    'Defender': 'مدافع',
    'Midfielder': 'لاعب وسط',
    'Forward': 'مهاجم',
  };

  static String? translateTerm(String term) {
    if (term.isEmpty) return null;
    // Try exact match
    if (_footballTerms.containsKey(term)) return _footballTerms[term];
    // Try case-insensitive match
    final lowerTerm = term.toLowerCase();
    for (var entry in _footballTerms.entries) {
      if (entry.key.toLowerCase() == lowerTerm) return entry.value;
    }
    return null;
  }

  Future<String> translate(String text, {String sourceLang = 'en', String targetLang = 'ar'}) async {
    if (text.isEmpty) return text;
    if (targetLang != 'ar') return text;

    final localMatch = _footballTerms[text];
    if (localMatch != null) return localMatch;

    try {
      final url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}';
      
      final response = await _dio.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty && data[0] is List) {
          final List<dynamic> translations = data[0];
          return translations.map((t) => t[0].toString()).join();
        }
      }
      return text;
    } catch (e) {
      print('[GoalHub Debug] Translation error for "$text": $e');
      return text;
    }
  }

  Future<List<String>> translateList(List<String> texts, {String sourceLang = 'en', String targetLang = 'ar'}) async {
    if (texts.isEmpty) return [];
    if (targetLang != 'ar') return texts;

    final List<String> result = List.from(texts);
    
    try {
      // Process in small chunks to avoid hanging and URL length limits
      // Using Future.wait with individual requests for reliability, 
      // but we can chunk them to not overwhelm the API.
      const int chunkSize = 5;
      for (int i = 0; i < texts.length; i += chunkSize) {
        final chunk = texts.sublist(i, i + chunkSize > texts.length ? texts.length : i + chunkSize);
        final translatedChunk = await Future.wait(
          chunk.map((t) => translate(t, sourceLang: sourceLang, targetLang: targetLang))
        );
        for (int j = 0; j < chunk.length; j++) {
          result[i + j] = translatedChunk[j];
        }
      }
      return result;
    } catch (e) {
      print('[GoalHub Debug] Batch translation error: $e');
      return result;
    }
  }
}
