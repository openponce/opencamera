# Open Camera
 Open Camera é um plugin flutter, muito leve, agradável e intuitivo, que adiciona ao seu aplicativo a capacidade de tirar fotos e gravar vídeos.

### Comece a usar
É muito fácil utilizar o plugin o **Open Camera** em seu projeto, ele foi pensado para ser assim ;)

`Para sistemas Android a versão mínima do SDK é 24 e IOS versão mínima é 10.0.`

# Instalação
A instalação do plugin na sua aplicação é muito simples, adicione no seu arquivo **pubspec.yaml** a referência do plugin **OpenCamera**.
```
dependencies:
  open_camera: ...
  flutter:
    sdk: flutter
```

### Android
No arquivo **AndroidManifest.xml** adicione as seguintes permissões.
```
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" android:required="true" />
<uses-permission android:name="android.permission.RECORD_AUDIO" android:required="true" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:required="true" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:required="true" />
```
###  IOS
No IOS é necessário editar os seguintes arquivos.

**ios/PodFile**
Altere a linha removendo o comentário e trocando a versão miníma no arquivo PodFile.

```
platform :ios, '10.0'
```

**ios/Runner/Info.plist**
No arquivo **Info.plist** adicione as seguintes pemissões.

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
# Como usar

### Configurações

```
var settings = CameraSettings(
  limitRecord: 15,
  useCompression: true,
  resolutionPreset: ResolutionPreset.ultraHigh
);

```

|Parâmetro| Tipo |Descrição|
|--|--|--|
|limitRecord| int |Tempo limite de gravação em segundos.|
|useCompression|bool|Se o plugin deve comprimir a foto ou vídeo antes de retornar|
|resolutionPreset|enum|Qualidade de resolução da câmera|


### Tirando uma foto
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
### Gravando um vídeo
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

Autores.

Diogo Luiz Ponce (dlponce@gmail.com) / Joelson Santos Cunha (contato@joecorp.com.br)