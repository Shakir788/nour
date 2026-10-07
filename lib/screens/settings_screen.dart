import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../shared/widgets/glass_card.dart';
import '../shared/widgets/premium_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cityController.text = prefs.getString('user_city') ?? 'London';
      _countryController.text = prefs.getString('user_country') ?? 'United Kingdom';
    });
  }

  Future<void> _saveLocation() async {
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();

    if (city.isEmpty || country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both City and Country')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_city', city);
    await prefs.setString('user_country', country);

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location updated successfully! ✨'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 13, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        GlassCard(
          opacity: 0.4,
          padding: EdgeInsets.zero,
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.gold,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(CupertinoIcons.back, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.gear_alt_fill, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Global Settings',
                style: AppTextStyles.bodyLarge.copyWith(fontSize: 18, letterSpacing: 1.0),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location & Prayer Configuration', style: AppTextStyles.displayMedium.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  'Set your current city and country to receive accurate local prayer schedules worldwide.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                ),
                const SizedBox(height: 30),

                _buildInputField(
                  label: 'CITY',
                  controller: _cityController,
                  hint: 'e.g. London, Dubai, Mumbai',
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'COUNTRY',
                  controller: _countryController,
                  hint: 'e.g. United Kingdom, UAE, India',
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _saveLocation,
                    child: _isLoading
                        ? CircularProgressIndicator(color: AppColors.background)
                        : const Text(
                            'Save Configuration',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}