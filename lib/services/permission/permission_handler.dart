import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  // Helper to get Android SDK version
  static Future<int?> _getAndroidSdkInt() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return null;
  }

  static void showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$permissionName permission is required for this app to function properly. Please grant the permission in app settings.',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Future<bool> requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        showPermissionDeniedDialog(context, 'Location');
      }
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission(
    BuildContext context,
  ) async {
    final status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        showPermissionDeniedDialog(context, 'Notification');
      }
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        showPermissionDeniedDialog(context, 'Camera');
      }
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        showPermissionDeniedDialog(context, 'Microphone');
      }
      return false;
    }
    return status.isGranted;
  }

  static Future<Map<String, bool>> requestCameraAndMicPermissions(
    BuildContext context,
  ) async {
    // Request both permissions simultaneously
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    // Show dialog for denied permissions
    if (!cameraGranted && context.mounted) {
      showPermissionDeniedDialog(context, 'Camera');
    }
    if (!micGranted && context.mounted) {
      showPermissionDeniedDialog(context, 'Microphone');
    }

    return {'camera': cameraGranted, 'microphone': micGranted};
  }

  // Gallery Permission (Fixed for Android 14+ and 15)
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    print('🔍 Starting gallery permission request...');
    try {
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSdkInt();
        print('📱 Android SDK: $sdkInt');
        if (sdkInt != null && sdkInt >= 34) {
          print('🔄 Using Android 14+ permissions (photos, videos)');
          // Android 14+ (API 34+) - Request granular permissions
          final List<Permission> permissions = [
            Permission.photos,
            Permission.videos,
          ];

          // First check current status
          bool alreadyGranted = false;
          for (Permission permission in permissions) {
            final status = await permission.status;
            if (status.isGranted) {
              alreadyGranted = true;
              break;
            }
          }

          if (alreadyGranted) return true;

          // Request permissions
          final Map<Permission, PermissionStatus> statuses = await permissions.request();

          // Check if we got at least partial access
          final bool hasPhotos = statuses[Permission.photos]?.isGranted ?? false;
          final bool hasVideos = statuses[Permission.videos]?.isGranted ?? false;
          final bool granted = hasPhotos || hasVideos;

          // Check if permanently denied
          final bool permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

          if (!granted && context.mounted) {
            if (permanentlyDenied) {
              showPermissionDeniedDialog(context, 'Gallery');
            }
          }
          return granted;
        } else if (sdkInt != null && sdkInt >= 33) {
          print('🔄 Using Android 13 permissions (photos, videos)');
          // Android 13 (API 33) - Request granular permissions
          // Check current status first
          final photosStatus = await Permission.photos.status;
          final videosStatus = await Permission.videos.status;
          
          if (photosStatus.isGranted && videosStatus.isGranted) return true;

          final Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
          ].request();

          final bool hasPhotos = statuses[Permission.photos]?.isGranted ?? false;
          final bool hasVideos = statuses[Permission.videos]?.isGranted ?? false;
          final bool granted = hasPhotos && hasVideos;

          // Check if permanently denied
          final bool permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);

          if (!granted && context.mounted) {
            if (permanentlyDenied) {
              showPermissionDeniedDialog(context, 'Gallery');
            }
          }
          return granted;
        } else {
          print('🔄 Using Android 12- permissions (storage)');
          // Android 12 and below - Use legacy storage permission
          final currentStatus = await Permission.storage.status;
          if (currentStatus.isGranted) return true;

          final status = await Permission.storage.request();

          if (!status.isGranted && context.mounted) {
            if (status.isPermanentlyDenied) {
              showPermissionDeniedDialog(context, 'Gallery');
            }
          }
          return status.isGranted;
        }
      } else {
        print('🔄 Using iOS permissions (photos)');
        // iOS
        final currentStatus = await Permission.photos.status;
        if (currentStatus.isGranted) return true;

        final status = await Permission.photos.request();

        if (!status.isGranted && context.mounted) {
          if (status.isPermanentlyDenied) {
            showPermissionDeniedDialog(context, 'Gallery');
          }
        }
        return status.isGranted;
      }
    } catch (e) {
      print('Error requesting gallery permission: $e');
      if (context.mounted) {
        showPermissionDeniedDialog(context, 'Gallery');
      }
      return false;
    }
  }
}
