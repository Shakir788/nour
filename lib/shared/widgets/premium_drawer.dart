import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✨ Screens Imports
import '../../features/spiritual/presentation/names_of_allah_screen.dart';
import '../../features/spiritual/presentation/emotion_duas_screen.dart';
import '../../features/spiritual/presentation/adhkar_screen.dart'; 
import '../../features/spiritual/presentation/qibla_screen.dart'; 
import '../../features/habits/presentation/sleep_audio_screen.dart'; 

// ✨ About Screen & Update Service Import
import '../../features/about/about_screen.dart'; 
import '../../core/services/app_update_service.dart'; // 🔴 Dhyan rahe ye file wahan honi chahiye

import '../../core/theme/app_theme.dart';
import '../../core/providers/user_provider.dart';

// ─── NEW: Auto-Check Update Provider ──────────────────────────────
final updateCheckProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  return await AppUpdateService.checkForUpdate();
});
class PremiumDrawer extends ConsumerWidget {
  const PremiumDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    
    // ── NEW: Update Status Check ──
    final updateAsync = ref.watch(updateCheckProvider);
    final bool hasUpdate = updateAsync.value?['updateAvailable'] == true;
    final String apkUrl = updateAsync.value?['apkUrl'] ?? '';

    return Drawer(
      backgroundColor: AppColors.background.withValues(alpha: 0.95), 
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✨ PROFILE HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                      boxShadow: [
                        BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 12)
                      ],
                    ),
                    child: const Icon(CupertinoIcons.person_fill, color: AppColors.background, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName.isNotEmpty ? userName : 'Guest',
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 24, color: AppColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Spiritual Companion',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            
            const Divider(color: AppColors.divider, thickness: 1, endIndent: 24, indent: 24),
            
            // ✨ MENU ITEMS 
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.sun_max_fill, 
                    title: 'Morning & Evening Adhkar', 
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DailyAdhkarScreen()), 
                      );
                    }
                  ),
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.sparkles, 
                    title: '99 Names of Allah', 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NamesOfAllahScreen()),
                      );
                    }
                  ),
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.heart_fill, 
                    title: 'Duas & Emotions', 
                    onTap: () {
                      Navigator.pop(context); 
                      Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (context) => const EmotionDuasScreen()),
                      );
                    }
                  ),
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.compass_fill, 
                    title: 'Qibla Direction', 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QiblaScreen()),
                      );
                    }
                  ),
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.moon_stars_fill, 
                    title: 'Sleep & Peace Audios', 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (context) => const SleepAudioScreen()), 
                      );
                    }
                  ),
                  
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.heart_circle_fill,
                    title: 'About NOUR', 
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()), 
                      );
                    }
                  ),

                  // 🔥 NEW: App Update Button with Red Dot Magic 🔥
                  _buildDrawerItem(
                    context, 
                    icon: CupertinoIcons.cloud_download_fill,
                    title: 'App Update', 
                    trailing: hasUpdate 
                        ? Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.destructiveRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: CupertinoColors.destructiveRed, blurRadius: 6, spreadRadius: 1)
                              ]
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      if (hasUpdate) {
                        // Naya update hai, Popup dikhao!
                        showDialog(
                          context: context,
                          barrierDismissible: false, // Bahar click karke band nahi kar sakte
                          builder: (context) => _UpdateDownloadDialog(apkUrl: apkUrl),
                        );
                      } else {
                        // Pehle se hi latest hai
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('App is up to date! ✨'),
                            backgroundColor: AppColors.surfaceElevated,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  ),
                ],
              ),
            ),

            // ✨ FOOTER
            const Divider(color: AppColors.divider, thickness: 1, endIndent: 24, indent: 24),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.settings, color: AppColors.textSecondary, size: 22),
                    const SizedBox(width: 12),
                    Text('Settings', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.goldLight, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: trailing, // ── Red Dot Yahan Aayega ──
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
      splashColor: AppColors.gold.withValues(alpha: 0.1),
    );
  }
}


// ─── NEW: VIP Download Progress Dialog ─────────────────────────────
class _UpdateDownloadDialog extends StatefulWidget {
  final String apkUrl;
  const _UpdateDownloadDialog({required this.apkUrl});

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  double _progress = 0.0;
  String _status = "Starting download...";
  bool _isDownloading = true;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  void _startDownload() async {
    await AppUpdateService.downloadAndInstall(widget.apkUrl, (progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _status = "Downloading... ${(progress * 100).toStringAsFixed(0)}%";
        });
      }
    });

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _status = "Download Complete!";
      });
      // Dialog khud band ho jayega aur Installer khul jayega
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: AppColors.background.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.cloud_download_fill, color: AppColors.gold, size: 54),
            const SizedBox(height: 16),
            Text(
              'Updating App', 
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _isDownloading ? _progress : 1.0,
                minHeight: 10,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Text
            Text(
              _status, 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)
            ),
          ],
        ),
      ),
    );
  }
}