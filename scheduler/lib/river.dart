import 'package:flutter/material.dart';
import 'package:win32_registry/win32_registry.dart';

class RegValues extends ChangeNotifier {
  String powerStatus = '';

  void getPowerStatus() {
    var keyPath = r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes';
    var key = Registry.openPath(RegistryHive.localMachine, path: keyPath);

    // print('Values:');
    // for (final value in key.values) {
    //   print(' - ${value.toString()}');
    // }
    final currentPowerScheme = key.getValueAsString('ActivePowerScheme');
    if (currentPowerScheme != null) {
      print('Windows build number: $currentPowerScheme');
    }
    powerStatus = currentPowerScheme ?? '';

    keyPath =
        'SYSTEM\\CurrentControlSet\\Control\\Power\\User\\PowerSchemes\\$currentPowerScheme';
// keyPath =
//     r'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\currentPowerScheme';
    key = Registry.openPath(RegistryHive.localMachine, path: keyPath);

    print('Values:');
    for (final value in key.values) {
      print(' - ${value.toString()}');
    }

    print('\n${'-' * 80}\n');

    print('Subkeys:');
    for (final subkey in key.subkeyNames) {
      print(' - $subkey');
    }

    key.close();
    notifyListeners();
  }
}
