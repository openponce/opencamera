import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:open_camera/open_camera.dart';

Future<void> main() async {
  try {
    await _portraitModeOnly();
    return runApp(Home());
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String fileName = "";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Take Photo",
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(),
        body: FutureBuilder<List<CameraDescription>>(
          future: availableCameras(),
          builder: (BuildContext ctx, snap) {
            if (snap.connectionState == ConnectionState.done) {
              return NativeDeviceOrientationReader(
                builder: (context) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(10.0),
                          color: Colors.black26,
                          child: Text(fileName),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(3.0),
                        child: RaisedButton(
                          onPressed: () async {
                            var file = await openCamera(
                              ctx,
                              CameraMode.Photo,
                              cameraSettings:
                                  CameraSettings(useCompression: true),
                            );
                            setState(() {
                              fileName = file?.path ?? "";
                            });
                          },
                          child: Text("Take Photo"),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(3.0),
                        child: RaisedButton(
                          onPressed: () async {
                            var file = await openCamera(
                              ctx,
                              CameraMode.Video,
                              cameraSettings: CameraSettings(
                                limitRecord: 15,
                                useCompression: true,
                                resolutionPreset: ResolutionPreset.ultraHigh,
                              ),
                            );
                            setState(() {
                              fileName = file?.path ?? "";
                            });
                          },
                          child: Text("Video Recording"),
                        ),
                      ),
                    ],
                  );
                },
                useSensor: true,
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

///
void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

/// blocks rotation; sets orientation to: portrait
Future _portraitModeOnly() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}
