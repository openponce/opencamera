import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_camera/src/ffmpeg/flutter_ffmpeg.dart';
import 'package:video_player/video_player.dart';

import 'open_camera_widget.dart';

//
String formatRecordingTime(int seconds) {
  int hours = (seconds / 3600).truncate();
  seconds = (seconds % 3600).truncate();
  int minutes = (seconds / 60).truncate();

  String hoursStr = (hours).toString().padLeft(2, '0');
  String minutesStr = (minutes).toString().padLeft(2, '0');
  String secondsStr = (seconds % 60).toString().padLeft(2, '0');

  if (hours == 0) {
    return "$minutesStr:$secondsStr";
  }

  return "$hoursStr:$minutesStr:$secondsStr";
}

class VideoPreview extends StatefulWidget {
  //
  final String videoLocation;
  final CameraSettings cameraSettings;

  //
  VideoPreview(this.videoLocation, this.cameraSettings);

  //
  @override
  _VideoPreviewState createState() =>
      _VideoPreviewState(this.videoLocation, this.cameraSettings);
}

class _VideoPreviewState extends State<VideoPreview> with ChangeNotifier {
  //
  final String videoLocation;
  final CameraSettings cameraSettings;

  //
  String _timeRecord = "00:00";
  bool _initFlutterFFmpeg = false;
  String _ffmpegMessage = "Loading...";
  VideoPlayerController _controller;

  //
  _VideoPreviewState(this.videoLocation, this.cameraSettings);

  //
  @override
  void initState() {
    super.initState();
    _initVideoPlayerController();
  }

  //
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  //
  void _initVideoPlayerController() {
    _controller = VideoPlayerController.file(File(this.videoLocation))
      ..initialize().then((_) {
        _controller.addListener(() {
          setState(() {});
        });
        setState(() {});
      });
  }

  //
  @override
  Widget build(BuildContext context) {
    try {
      return MaterialApp(
        title: 'Video Preview',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white12,
          body: SafeArea(
            child: (_initFlutterFFmpeg) ? _addLoading() : _addVideoPlayer(),
          ),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  //
  Widget _addVideoPlayer() {
    return Column(
      children: <Widget>[
        _addVideoComponent(context),
        _addDivider(),
        _addActionButtons()
      ],
    );
  }

  //
  Widget _addVideoComponent(BuildContext context) {
    return Expanded(
      child: Center(
        child: _controller.value.initialized
            ? _initializeVideoComponent()
            : _awaitVideoComponent(context),
      ),
    );
  }

  //
  Widget _initializeVideoComponent() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: () {
          _playClick();
        },
        child: Stack(
          children: <Widget>[
            VideoPlayer(_controller),
            _addButtonPlay(),
            _addVideoProgressIndicator(),
            _addTimeWidget(context),
          ],
        ),
      ),
    );
  }

  //
  Widget _awaitVideoComponent(BuildContext context) {
    return Container(
      child: Center(
        child: CircularProgressIndicator(),
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
  Widget _addButtonPlay() {
    return !_controller.value.isPlaying
        ? Container(
            child: Center(
              child: Opacity(
                opacity: 0.4,
                child: IconButton(
                    icon: Icon(Icons.play_circle_outline),
                    iconSize: 150,
                    color: Colors.white,
                    onPressed: () {
                      _playClick();
                    }),
              ),
            ),
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
          )
        : Container();
  }

  //
  Widget _addActionButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              color: Colors.green,
              onPressed: () async {
                //
                if (_controller.value.isPlaying) {
                  await _controller.pause();
                }
                //
                String _videoLocation = this.videoLocation;
                //
                if (this.cameraSettings.useCompression) {
                  _videoLocation = await _performVideoCompression();
                }
                //
                Navigator.pop(context, _videoLocation);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RaisedButton(
              color: Colors.red,
              onPressed: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  //
  Widget _addVideoProgressIndicator() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: 0.8,
        child: _controller.value.initialized
            ? Container(
                height: 30,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.white,
                    backgroundColor: Colors.white12,
                    bufferedColor: Colors.black12,
                  ),
                ),
              )
            : Container(),
      ),
    );
  }

  //
  Widget _addTimeWidget(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _timeWidget(_timeRecord),
        ],
      );
    } catch (_) {
      rethrow;
    }
  }

  //
  Widget _timeWidget(String timeRecord) {
    try {
      return Padding(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            padding: EdgeInsets.all(6),
            child: SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  timeRecord,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      rethrow;
    }
  }

  //
  Widget _addLoading() {
    return Container(
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
  void _playClick() async {
    //

    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      //
      Timer.periodic(
        Duration(milliseconds: 500),
        (Timer timer) async {
          //
          if (_controller.value.duration.inSeconds ==
                  _controller.value.position.inSeconds &&
              timer.isActive) {
            //
            timer.cancel();
            _timeRecord = "00:00";
            _initVideoPlayerController();
          } else {
            //
            _timeRecord =
                formatRecordingTime(_controller.value.position.inSeconds + 1);
          }
          _controller.notifyListeners();
        },
      );
      //
      await _controller.play();
    }
  }

  //
  Future<String> _performVideoCompression() async {
    //
    setState(() {
      _initFlutterFFmpeg = true;
      _ffmpegMessage = "Wait for compression...";
    });
    //
    String videoLocation =
        this.videoLocation.replaceAll('.mp4', '_compressed.mp4');
    //
    final _compressVideo = new FlutterFFmpeg();
    //
    var arguments = [
      "-y",
      "-i",
      this.videoLocation,
      "-b:v",
      "512k",
      "-vcodec",
      "libx264",
      "-c:v",
      "mpeg4",
      videoLocation
    ];
    //
    await _compressVideo.executeWithArguments(arguments);
    File(this.videoLocation).delete(recursive: true);
    _controller.notifyListeners();
    //
    return videoLocation;
  }
}
