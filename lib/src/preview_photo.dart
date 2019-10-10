//
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PreviewPhoto extends StatefulWidget {
  final String location;

  PreviewPhoto(this.location);

  @override
  _PreviewPhotoState createState() => _PreviewPhotoState(this.location);
}

class _PreviewPhotoState extends State<PreviewPhoto> {
  final String location;

  _PreviewPhotoState(this.location);

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
                          onPressed: () {
                            Navigator.pop(context, this.location);
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
}
