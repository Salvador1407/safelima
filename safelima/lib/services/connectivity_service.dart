import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  const ConnectivityService();

  Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final results = await Connectivity().checkConnectivity();

    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookupResult = await InternetAddress.lookup(
        'example.com',
      ).timeout(timeout);

      return lookupResult.isNotEmpty &&
          lookupResult.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
