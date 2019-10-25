# Open Camera

Open Camera is a flutter plugin, very light, nice and intuitive, which adds to your application the ability to take photos and record videos.

### Get started

It is very easy to use the plugin **Open Camera** in your project, it was thought to be like this ;)

`For Android systems the minimum version of SDK is 24 and IOS minimum version is 10.0.`

# Installation

Installing the plugin in your application is very simple, add in your file **pubspec.yaml** the plugin reference **OpenCamera**.

```
dependencies:
  open_camera: ...
  flutter:
    sdk: flutter
```

### Android

In the **AndroidManifest.xml** file add the following permissions.

```
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" android:required="true" />
<uses-permission android:name="android.permission.RECORD_AUDIO" android:required="true" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:required="true" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:required="true" />
```
###  IOS

In IOS it is necessary to edit the following files.

**ios/PodFile**

Change the line by uncommenting and changing the minimum version in the ios/PodFile.

```
platform :ios, '10.0'
```

**ios/Runner/Info.plist**

In the **Info.plist** file add the following permissions.

```
<key>NSCameraUsageDescription</key>
<string>Can I use the camera please?</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Camera App would like to save photos from the app to your gallery</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Camera App would like to access your photo gallery for uploading images to the app</string>
<key>NSAppTransportSecurity</key>
<dict>
   <key>NSAllowsArbitraryLoads</key>
   <true/>
</dict>
```
# How to use

### Settings

```
var settings = CameraSettings(
  limitRecord: 15,
  useCompression: true,
  resolutionPreset: ResolutionPreset.ultraHigh
);

```

|Parameter|Type|Description|
|--|--|--|
|limitRecord| int |Recording time limit in seconds.|
|useCompression|bool|Whether the plugin should compress the photo or video before returning|
|resolutionPreset|enum|Camera resolution quality|


### Taking a picture
```
File file = await openCamera(
  context,
  CameraMode.Photo,
  cameraSettings: CameraSettings(
    useCompression: true,
    resolutionPreset: ResolutionPreset.ultraHigh,
  ),
);

```
### Recording a video
```
File file = await openCamera(context,
                             CameraMode.Video,
                             cameraSettings: CameraSettings(
                                limitRecord: 15,
                                useCompression: true,
                                resolutionPreset: ResolutionPreset.ultraHigh,
                              ),
                            );
```

Authors.

Diogo Luiz Ponce (dlponce@gmail.com) / Joelson Santos Cunha (contato@joecorp.com.br)
