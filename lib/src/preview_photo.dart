//
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_view/photo_view.dart';

import 'open_camera_widget.dart';

class PreviewPhoto extends StatefulWidget {
  final String location;
  final CameraSettings cameraSettings;

  PreviewPhoto(this.location, this.cameraSettings);

  @override
  _PreviewPhotoState createState() =>
      _PreviewPhotoState(this.location, this.cameraSettings);
}

class _PreviewPhotoState extends State<PreviewPhoto> {
  final String location;
  final CameraSettings cameraSettings;

  _PreviewPhotoState(this.location, this.cameraSettings);

  @override
  Widget build(BuildContext context) {
    //
    return previewPhoto(context);
  }

  //
  Widget previewPhoto(BuildContext context) {
    return MaterialApp(
      title: 'Photo Preview',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white12,
        body: SafeArea(
          child: Container(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: PhotoView(
                    imageProvider: FileImage(
                      File(this.location),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          color: Colors.green,
                          onPressed: () async {
                            //
                            var _fileOriginal = File(this.location);
                            //
                            if (this.cameraSettings.useCompression) {
                              //
                              var regExp = new RegExp(
                                r"[.][0-9a-z]{1,5}$",
                                caseSensitive: false,
                                multiLine: false,
                              );
                              //
                              var ext = regExp
                                  .stringMatch(_fileOriginal.path)
                                  .toString();
                              //
                              var _fileCompressed = await compressImage(
                                _fileOriginal,
                                _fileOriginal.path
                                    .replaceAll(ext, '_compressed' + ext),
                              );
                              //
                              File(this.location).delete(recursive: true);
                              _fileOriginal = _fileCompressed;
                            }
                            //
                            Navigator.pop(context, _fileOriginal.path);
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<File> compressImage(File file, String targetPath) async {
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
    );
    return result;
  }
}
