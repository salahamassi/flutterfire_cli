/*
 * Copyright (c) 2020-present Invertase Limited & Contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this library except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import 'dart:io';

import 'common/exception.dart';
import 'common/package.dart';
import 'common/platform.dart';
import 'common/utils.dart';

class FlutterApp {
  FlutterApp({
    required this.package,
  });

  /// The underlying dart package representation for this Flutter Apps
  /// pubspec.yaml.
  final Package package;

  /// Loads the Flutter app located in the [appDirectory]
  static Future<FlutterApp> load(Directory appDirectory) async {
    if (!File(pubspecPathForDirectory(appDirectory)).existsSync()) {
      throw FlutterAppRequiredException();
    }
    final package = await Package.load(appDirectory);
    if (!package.isFlutterApp) {
      throw FlutterAppRequiredException();
    }
    return FlutterApp(
      package: package,
    );
  }

  // Cached Android package name if available.
  String? _androidApplicationId;

  // Cached iOS bundle identifier if available.
  String? _iosBundleId;

  String? get iosBundleId {
    if (!ios) return null;
    if (_iosBundleId != null) {
      return _iosBundleId;
    }
    // TODO
  }

  /// The Android Application (or Package Name) for this Flutter
  /// application, or null if one could not be detected or the app
  /// does not target Android as a supported platform.
  String? get androidApplicationId {
    if (!android) return null;
    if (_androidApplicationId != null) {
      return _androidApplicationId;
    }

    String? applicationId;

    // Try extract via android/app/build.gradle
    final appGradleFile = File(
      androidAppBuildGradlePathForAppDirectory(
        Directory(package.path),
      ),
    );
    if (appGradleFile.existsSync()) {
      final fileContents = appGradleFile.readAsStringSync();
      final appIdRegex = RegExp(
        r'''applicationId\s['"]{1}(?<applicationId>([A-Za-z]{1}[A-Za-z\d_]*\.)+[A-Za-z][A-Za-z\d_]*)['"]{1}''',
      );
      final match = appIdRegex.firstMatch(fileContents);
      if (match != null) {
        applicationId = match.namedGroup('applicationId');
      }
    }

    // Try extract via android/app/src/main/AndroidManifest.xml
    if (applicationId == null) {
      final androidManifestFile = File(
        androidManifestPathForAppDirectory(
          Directory(package.path),
        ),
      );
      if (androidManifestFile.existsSync()) {
        final fileContents = androidManifestFile.readAsStringSync();
        final appIdRegex = RegExp(
          r'''package="(?<applicationId>([A-Za-z]{1}[A-Za-z\d_]*\.)+[A-Za-z][A-Za-z\d_]*)"''',
        );
        final match = appIdRegex.firstMatch(fileContents);
        if (match != null) {
          applicationId = match.namedGroup('applicationId');
        }
      }
    }

    return _androidApplicationId = applicationId;
  }

  /// Returns whether this Flutter app can run on Android.
  bool get android {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kAndroid);
  }

  /// Returns whether this Flutter app can run on Web.
  bool get web {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kWeb);
  }

  /// Returns whether this Flutter app can run on Windows.
  bool get windows {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kWindows);
  }

  /// Returns whether this Flutter app can run on MacOS.
  bool get macos {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kMacos);
  }

  /// Returns whether this Flutter app can run on iOS.
  bool get ios {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kIos);
  }

  /// Returns whether this Flutter app can run on Linux.
  bool get linux {
    if (!package.isFlutterApp) return false;
    return _supportsPlatform(kLinux);
  }

  bool _supportsPlatform(String platform) {
    assert(
      platform == kIos ||
          platform == kAndroid ||
          platform == kWeb ||
          platform == kMacos ||
          platform == kWindows ||
          platform == kLinux,
    );

    return Directory(
      '${package.path}${currentPlatform.pathSeparator}$platform',
    ).existsSync();
  }
}