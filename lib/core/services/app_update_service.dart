import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateService {
  // 🔴 YAHAN APNI GITHUB JSON FILE KA RAW LINK DAALNA HOGA
  static const String updateJsonUrl = 'https://raw.githubusercontent.com/Shakir788/nour-update/main/update.json';

  /// Check karta hai ki koi naya update available hai ya nahi
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // 1. Current App Version nikalo
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; 
      // Example: "1.0.0"

      // 2. GitHub se Latest Version check karo
      final dio = Dio();
      final response = await dio.get(updateJsonUrl);
      
      if (response.statusCode == 200) {
        // Agar response string hai toh decode karo
        final data = response.data is String ? json.decode(response.data) : response.data;
        String latestVersion = data['version'];
        String apkUrl = data['apk_url'];

        // 3. Compare versions (Simple string comparison)
        if (latestVersion.compareTo(currentVersion) > 0) {
          // Naya update hai!
          return {
            'updateAvailable': true,
            'latestVersion': latestVersion,
            'apkUrl': apkUrl,
          };
        }
      }
      return {'updateAvailable': false};
    } catch (e) {
      debugPrint("Update Check Error: $e");
      return {'updateAvailable': false};
    }
  }

  /// APK Download aur Install karta hai
  static Future<void> downloadAndInstall(String apkUrl, Function(double) onProgress) async {
    try {
      // Permissions maango
      await Permission.storage.request();
      await Permission.requestInstallPackages.request();

      // Download kahan save karna hai?
      Directory? tempDir = await getExternalStorageDirectory();
      String savePath = "${tempDir!.path}/update_app.apk";

      // Download start
      final dio = Dio();
      await dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total);
            onProgress(progress); // UI me progress bar dikhane ke liye
          }
        },
      );

      // Download complete hone par Install popup open karo
      debugPrint("Download Complete. Opening Installer...");
      await OpenFilex.open(savePath);

    } catch (e) {
      debugPrint("Download/Install Error: $e");
    }
  }
}