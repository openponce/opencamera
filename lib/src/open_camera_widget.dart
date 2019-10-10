import 'dart:async';
import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:open_camera/src/ffmpeg/flutter_ffmpeg.dart';
import 'package:open_camera/src/preview_photo.dart';
import 'package:open_camera/src/preview_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

//
enum CameraMode { Photo, Video }

class CameraSettings {
  //
  final int limitRecord;
  final bool useCompression;
  final ResolutionPreset resolutionPreset;

  //
  CameraSettings({
    this.limitRecord = -1,
    this.useCompression = false,
    this.resolutionPreset = ResolutionPreset.medium,
  });
}

Future<File> openCamera(
  BuildContext buildContext,
  CameraMode cameraMode, {
  CameraSettings cameraSettings,
}) async {
  //
  try {
    //
    await PermissionHandler().requestPermissions(
      [
        PermissionGroup.camera,
        PermissionGroup.microphone,
        PermissionGroup.storage,
        PermissionGroup.photos
      ],
    );
    //
    List<CameraDescription> cameras = await availableCameras();
    //
    var permissionCamera =
        await PermissionHandler().checkPermissionStatus(PermissionGroup.camera);
    var permissionMicrophone = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.microphone);
    var permissionStorage = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);
    var permissionPhotos =
        await PermissionHandler().checkPermissionStatus(PermissionGroup.photos);
    //
    bool hasPermission = false;
    //
    if (Platform.isAndroid) {
      hasPermission = (permissionCamera == PermissionStatus.granted &&
          permissionMicrophone == PermissionStatus.granted &&
          permissionStorage == PermissionStatus.granted &&
          permissionPhotos == PermissionStatus.granted);
    } else if (Platform.isIOS) {
      hasPermission = (permissionCamera == PermissionStatus.granted &&
          permissionMicrophone == PermissionStatus.granted &&
          permissionPhotos == PermissionStatus.granted);
    }
    //
    if (hasPermission) {
      //
      final resultCamera = await Navigator.push(
        buildContext,
        MaterialPageRoute(
          builder: (context) {
            return OpenCamera(
              cameras,
              cameraMode,
              cameraSettings ?? CameraSettings(),
            );
          },
        ),
      );
      //
      return resultCamera != null ? File(resultCamera) : null;
    }
    return null;
  } catch (_) {
    rethrow;
  }
}

class OpenCamera extends StatefulWidget {
  //
  final CameraMode cameraMode;
  final CameraSettings cameraOptions;
  final List<CameraDescription> cameraDescription;

  //
  OpenCamera(
    this.cameraDescription,
    this.cameraMode,
    this.cameraOptions,
  );

  //
  @override
  _OpenCameraState createState() => _OpenCameraState(
        this.cameraDescription,
        this.cameraMode,
        this.cameraOptions,
      );
}

class _OpenCameraState extends State<OpenCamera> with WidgetsBindingObserver {
  //
  var _initRecord = false;
  var _timeRecord = "00:00";
  var _ffmpegMessage = "Loading...";
  var _initFlutterFFmpeg = false;

  //
  String _fileLocation;
  CameraController controller;
  CameraDescription cameraSelected;

  //
  final CameraMode cameraMode;
  final CameraSettings cameraSettings;
  final List<CameraDescription> cameraDescription;

  //
  _OpenCameraState(
    this.cameraDescription,
    this.cameraMode,
    this.cameraSettings,
  );

  //
  @override
  void initState() {
    //
    super.initState();
    //
    WidgetsBinding.instance.addObserver(this);
    this.cameraSelected = cameraDescription.first;
    //
    _initCamera();
  }

  //
  void _initCamera() {
    //
    AutoOrientation.fullAutoMode();
    //
    controller = CameraController(
      this.cameraSelected,
      this.cameraSettings.resolutionPreset,
      enableAudio: true,
    );
    //
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  //
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  //
  @override
  void dispose() {
    controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //
  @override
  Widget build(BuildContext context) {
    //
    if (!controller.value.isInitialized) {
      return Container();
    }
    //
    return Scaffold(
      body: NativeDeviceOrientationReader(
        builder: (BuildContext context) {
          //
          return SafeArea(
            child: (_initFlutterFFmpeg)
                ? _addLoading()
                : Stack(
                    children: <Widget>[
                      _addScreen(context),
                      _addCameraTools(context),
                    ],
                  ),
          );
        },
        useSensor: true,
      ),
    );
  }

  //
  Future<String> _takeCamera() async {
    //
    if (!controller.value.isInitialized) {
      return null;
    }
    //
    final Directory dirApp = await getApplicationDocumentsDirectory();
    //
    final String dirPathApp = this.cameraMode == CameraMode.Photo
        ? '${dirApp.path}/photos'
        : '${dirApp.path}/videos';
    //
    final String filePathApp = this.cameraMode == CameraMode.Photo
        ? '$dirPathApp/${_timestamp()}.jpg'
        : '$dirPathApp/${_timestamp()}.mp4';
    //
    await Directory(dirPathApp).create(recursive: true);
    //
    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    //
    try {
      //
      if (this.cameraMode == CameraMode.Photo) {
        await controller.takePicture(filePathApp);
      } else if (this.cameraMode == CameraMode.Video) {
        await controller.startVideoRecording(filePathApp);
      } else {
        return null;
      }
    } on CameraException catch (_) {
      return null;
    }
    return filePathApp;
  }

  //------------------------
  // WIDGETS
  //------------------------
  //
  Widget _addScreen(BuildContext context) {
    //
    return Container(
      decoration: _screenBorderDecoration(),
      child: RotatedBox(
        quarterTurns: _turnsDeviceOrientation(context),
        child: Center(
          child: Stack(
            children: <Widget>[
              Center(
                child: ClipRect(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
              _addTimeCount(context)
            ],
          ),
        ),
      ),
    );
  }

  //
  Widget _addTimeCount(BuildContext context) {
    try {
      //
      NativeDeviceOrientation orientation =
          NativeDeviceOrientationReader.orientation(context);
      //
      if (orientation == NativeDeviceOrientation.portraitUp ||
          orientation == NativeDeviceOrientation.portraitDown) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _addTimeWidget(_timeRecord),
          ],
        );
      } else {
        return Row(
          children: <Widget>[
            //
            orientation == NativeDeviceOrientation.landscapeRight
                ? RotatedBox(
                    quarterTurns: 3,
                    child: _addTimeWidget(_timeRecord),
                  )
                : Container(),
            //
            Expanded(
                child: Divider(
              color: Colors.transparent,
            )),
            //
            orientation == NativeDeviceOrientation.landscapeLeft
                ? RotatedBox(
                    quarterTurns: 1,
                    child: _addTimeWidget(_timeRecord),
                  )
                : Container(),
          ],
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  //
  Widget _addCameraTools(BuildContext context) {
    //
    final size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 0,
      child: Opacity(
        opacity: 1,
        child: Container(
          width: size.width,
          height: 80.0,
          decoration: BoxDecoration(
            color: Colors.black12,
          ),
          child: Row(
            children: <Widget>[
              _addSwitchCamera(context),
              _addCentralButton(this.cameraMode, context),
              _addThumb(context),
            ],
          ),
        ),
      ),
    );
  }

  //
  Widget _addCentralButton(CameraMode mode, BuildContext context) {
    if (mode == CameraMode.Photo) {
      return _addPhotoButton(context);
    } else {
      return _addRecordButton(context);
    }
  }

  //
  Widget _addRecordButton(BuildContext context) {
    return Expanded(
      child: SizedBox(
        width: 60.0,
        height: 60.0,
        child: FloatingActionButton(
          heroTag: "recordButton",
          backgroundColor: Colors.white,
          child: Icon(
            _initRecord ? Icons.stop : Icons.fiber_manual_record,
            color: Colors.red,
            size: 50.0,
          ),
          onPressed: () async {
            await _recordButtonPressed(context);
          },
        ),
      ),
    );
  }

  //
  Widget _addPhotoButton(BuildContext context) {
    return Expanded(
      child: SizedBox(
        width: 60.0,
        height: 60.0,
        child: FloatingActionButton(
          heroTag: "photoButton",
          backgroundColor: Colors.white,
          child: Icon(
            Icons.camera,
            size: 50.0,
            color: Colors.grey,
          ),
          onPressed: () async {
            await _photoButtonPressed(context);
          },
        ),
      ),
    );
  }

  //
  Widget _addThumb(BuildContext context) {
    int turns = _turnsDeviceOrientation(context);
    return Expanded(
      child: RotatedBox(
        quarterTurns: turns,
        child: SizedBox(
          width: 80.0,
          height: 80.0,
          child: Container(),
        ),
      ),
    );
  }

  //
  Widget _addSwitchCamera(BuildContext context) {
    //
    return Expanded(
      child: SizedBox(
        width: 40.0,
        height: 40.0,
        child: !_initRecord
            ? FloatingActionButton(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.switch_camera,
                  size: 30.0,
                  color: Colors.grey,
                ),
                onPressed: () {
                  if (this.cameraSelected.lensDirection ==
                      CameraLensDirection.front) {
                    this.cameraSelected = this.cameraDescription.firstWhere(
                        (cam) => cam.lensDirection == CameraLensDirection.back);
                  } else {
                    this.cameraSelected = this.cameraDescription.firstWhere(
                        (cam) =>
                            cam.lensDirection == CameraLensDirection.front);
                  }
                  //
                  _initCamera();
                },
              )
            : Container(),
      ),
    );
  }

  //
  Widget _addLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            _addDivider(),
            Text(
              _ffmpegMessage,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  //
  Widget _addDivider() {
    return Divider(
      color: Colors.transparent,
    );
  }

  //
  Widget _addTimeWidget(String timeRecord) {
    try {
      return _initRecord
          ? Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                ),
                padding: EdgeInsets.all(6),
                child: Center(
                  child: SizedBox(
                    width: 100,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.fiber_manual_record,
                          color: Colors.red,
                        ),
                        Text(
                          timeRecord,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container();
    } catch (_) {
      rethrow;
    }
  }

  //------------------------
  // EVENTS
  //------------------------
  //
  Future _recordButtonPressed(BuildContext context) async {
    //
    if (_initRecord) {
      _stopVideoRecording(context);
    } else {
      _initializeChronometer(context);
      _fileLocation = await _takeCamera();
    }
  }

  //
  Future _photoButtonPressed(BuildContext context) async {
    //
    _fileLocation = await _takeCamera();
    //
    String fileLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PreviewPhoto(_fileLocation);
        },
      ),
    );
    //
    Navigator.pop(context, fileLocation);
  }

  //
  void _initializeChronometer(BuildContext context) {
    //
    Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      //
      setState(() {
        _initRecord = controller.value.isRecordingVideo;
      });

      if (!_initRecord) {
        return;
      } else if (_initRecord && timer.isActive) {
        timer.cancel();
      }
      //
      Timer.periodic(Duration(seconds: 1), (Timer timer2) {
        //
        setState(() {
          _initRecord = controller.value.isRecordingVideo;
        });
        //
        if (!_initRecord && timer2.isActive) {
          timer2.cancel();
          return;
        }
        //
        if (_initRecord) {
          setState(() {
            //
            _timeRecord = formatRecordingTime(timer2.tick);
            //
            if (this.cameraSettings.limitRecord > -1 &&
                timer2.tick >= this.cameraSettings.limitRecord) {
              timer2.cancel();
              _stopVideoRecording(context);
            }
          });
        } else {
          setState(() {
            timer2.cancel();
            _timeRecord = "00:00";
          });
        }
      });
    });
  }

  //
  void _stopVideoRecording(BuildContext context) async {
    //
    _initRecord = false;
    _timeRecord = "00:00";
    //
    await controller.stopVideoRecording();
    //
    _fileLocation = await _adjustVideoOrientation(_fileLocation, context);
    //
    setState(() {
      _ffmpegMessage = "";
      _initFlutterFFmpeg = false;
    });
    //
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return VideoPreview(_fileLocation, this.cameraSettings);
        },
      ),
    );
    //
    if (result == null) {
      await File(_fileLocation).delete(recursive: true);
      return;
    }
    //
    Navigator.pop(context, result);
  }

  //------------------------
  // FUNCTIONS
  //------------------------

  //
  Future<Widget> _invalidOrientation() async {
    //
    if (_initRecord) {
      _initRecord = false;
      await controller.stopVideoRecording();
    }
    //
    return Container(
      color: Colors.red,
    );
  }

  //
  int _turnsDeviceOrientation(BuildContext context) {
    //
    NativeDeviceOrientation orientation =
        NativeDeviceOrientationReader.orientation(context);
    //
    int turns;
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        turns = -1;
        break;
      case NativeDeviceOrientation.landscapeRight:
        turns = 1;
        break;
      case NativeDeviceOrientation.portraitDown:
        turns = 2;
        break;
      default:
        turns = 0;
        break;
    }

    return turns;
  }

  //
  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  //
  BoxDecoration _screenBorderDecoration() {
    if (_initRecord) {
      return BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.red,
          style: BorderStyle.solid,
          width: 3,
        ),
      );
    } else {
      return BoxDecoration(
        color: Colors.black,
      );
    }
  }

  //
  Future<String> _adjustVideoOrientation(
      String videoLocation, BuildContext context) async {
    try {
      //
      setState(() {
        _ffmpegMessage = "Processing...";
        _initFlutterFFmpeg = true;
      });
      NativeDeviceOrientation orientation =
          NativeDeviceOrientationReader.orientation(context);
      //
      int turns = 0;
      switch (orientation) {
        case NativeDeviceOrientation.landscapeLeft:
          if (Platform.isIOS) {
            turns = 2;
          } else {
            turns = 0;
          }
          break;
        case NativeDeviceOrientation.landscapeRight:
          if (Platform.isIOS) {
            turns = 1;
          } else {
            turns = 4;
          }
          break;
        case NativeDeviceOrientation.portraitDown:
          turns = 0;
          break;
        default:
          turns = 0;
          break;
      }

      if (turns > 0) {
        //
        final _compressVideo = new FlutterFFmpeg();
        //
        String videoLocationAdjust =
            videoLocation.replaceAll('.mp4', '_ajust.mp4');
        //
        await _compressVideo.execute(
            "-y -i $videoLocation -preset ultrafast -vf \"transpose=$turns\" $videoLocationAdjust");
        //
        await File(videoLocation).delete(recursive: true);
        return videoLocationAdjust;
      }
      //
      return videoLocation;
    } catch (ex) {
      rethrow;
    }
  }
}
