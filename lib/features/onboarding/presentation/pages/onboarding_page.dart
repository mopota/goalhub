import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/settings/settings_cubit.dart';
import 'package:goalhub/features/navigation/main_navigation_page.dart';
import 'package:geolocator/geolocator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _arabicCountries = [
    'Egypt', 'Saudi Arabia', 'UAE', 'Morocco', 'Algeria', 'Tunisia', 
    'Jordan', 'Lebanon', 'Kuwait', 'Qatar', 'Oman', 'Bahrain', 'Iraq'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsCubit = context.watch<SettingsCubit>();
    final isArabic = settingsCubit.state.language == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(theme, isArabic),
                  _buildPermissionsAndSettingsPage(theme, colorScheme, settingsCubit, isArabic),
                  _buildPrivacyPage(theme, isArabic),
                  _buildLoginPage(theme, isArabic),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(isArabic ? 'السابق' : 'Back'),
                    )
                  else
                    const SizedBox(width: 80),
                  Row(
                    children: List.generate(4, (index) => _buildDot(index, colorScheme)),
                  ),
                  if (_currentPage < 3)
                    FilledButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(isArabic ? 'التالي' : 'Next'),
                    )
                  else
                    FilledButton(
                      onPressed: () {
                        context.read<SettingsCubit>().completeOnboarding();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainNavigationPage()),
                        );
                      },
                      child: Text(isArabic ? 'ابدأ الآن' : 'Get Started'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, size: 100, color: Colors.green),
          const SizedBox(height: 32),
          Text(
            isArabic ? 'مرحباً بك في GoalHub' : 'Welcome to GoalHub',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isArabic 
              ? 'تطبيقك المفضل لمتابعة نتائج المباريات والأخبار الرياضية بلمسة عصرية.' 
              : 'Your go-to app for live scores and sports news with a modern touch.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsAndSettingsPage(ThemeData theme, ColorScheme colorScheme, SettingsCubit settingsCubit, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الإعدادات واللغة' : 'Settings & Language',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(isArabic ? 'اختر اللغة:' : 'Choose Language:'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'ar', label: Text('العربية')),
            ],
            selected: {settingsCubit.state.language},
            onSelectionChanged: (val) => settingsCubit.updateLanguage(val.first),
          ),
          const SizedBox(height: 24),
          Text(isArabic ? 'اختر الدولة (لضبط الوقت):' : 'Choose Country (to set time):'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: settingsCubit.state.country,
            items: _arabicCountries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => settingsCubit.updateCountry(val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
              }
            },
            icon: const Icon(Icons.location_on),
            label: Text(isArabic ? 'تفعيل الموقع الجغرافي' : 'Enable Location Services'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage(ThemeData theme, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'الخصوصية والشروط' : 'Privacy & Terms',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic 
              ? 'نحن نحترم خصوصيتك. باستمرارك في استخدام التطبيق، فإنك توافق على سياسة الخصوصية وشروط الاستخدام الخاصة بنا.'
              : 'We respect your privacy. By continuing, you agree to our Privacy Policy and Terms of Service.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: Text(isArabic ? 'قراءة الشروط الكاملة' : 'Read Full Terms'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPage(ThemeData theme, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            isArabic ? 'تسجيل الدخول' : 'Login',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          Text(
            isArabic ? '(خاصية تسجيل الدخول ستعمل قريباً)' : '(Login feature coming soon)',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? colorScheme.primary : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
