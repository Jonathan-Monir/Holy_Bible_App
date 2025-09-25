// permission_helper.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  static const _platform = MethodChannel('com.example.holy_bible/permissions');
  
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) {
      return true; // Web doesn't need storage permissions
    }
    
    if (!Platform.isAndroid) {
      return true; // iOS and other platforms handle permissions differently
    }
    
    try {
      // For Android 11 and above, we need to handle scoped storage differently
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        
        // For Android 11+, also request manage external storage if needed
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus.isDenied) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        
        return status.isGranted || manageStatus.isGranted;
      }
      
      return true;
    } on PlatformException catch (e) {
      print("Failed to request permission: '${e.message}'.");
      return false;
    } catch (e) {
      print("Error requesting storage permission: $e");
      return false;
    }
  }
  
  static Future<bool> hasStoragePermission() async {
    if (kIsWeb) {
      return true; // Web doesn't need storage permissions
    }
    
    if (!Platform.isAndroid) {
      return true; // iOS and other platforms handle permissions differently
    }
    
    try {
      var status = await Permission.storage.status;
      var manageStatus = await Permission.manageExternalStorage.status;
      
      return status.isGranted || manageStatus.isGranted;
    } on PlatformException catch (e) {
      print("Failed to check permission: '${e.message}'.");
      return false;
    } catch (e) {
      print("Error checking storage permission: $e");
      return false;
    }
  }
}
