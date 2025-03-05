import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  var statuses = await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.notification,
    Permission.systemAlertWindow,
  ].request();

  if (statuses[Permission.camera]!.isDenied ||
      statuses[Permission.microphone]!.isDenied ||
      statuses[Permission.systemAlertWindow]!.isDenied) {
    // Handle the case when the permission is denied.
  }
}
