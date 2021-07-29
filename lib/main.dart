import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pedantic/pedantic.dart';
import 'package:progress_loader_overlay/progress_loader_overlay.dart';
import 'package:state_rebuilder_issue_206/helpers.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Issue 206',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StateRebuilderIssue206Widget(isFront: true),
    );
  }
}

// TODO: 2 issues in here:
// - ISSUE #1: A stream (given to rm.setState()) never resuming after a yield statement).
// - ISSUE #2: A call to rm.setState() (with a future as argument) never completing.
// How to reproduce the issue:
//    Comment/uncomment the code in [buildGalleryButton], then tap the gallery button right of the round button.
//    Select a file from your device and observe the prints to see the futures/stream not completing.
//    Do a Restart between each test as the code will be in a broken state.

// Here is a copy of my `flutter doctor`:
//  [✓] Flutter (Channel stable, 2.2.1, on macOS 11.4 20F71 darwin-x64, locale en-GB)
//  [!] Android toolchain - develop for Android devices (Android SDK version 29.0.2)
//  ✗ Android license status unknown.
//  Run `flutter doctor --android-licenses` to accept the SDK licenses.
//  See https://flutter.dev/docs/get-started/install/macos#android-setup for more details.
//  [✓] Xcode - develop for iOS and macOS
//  [✗] Chrome - develop for the web (Cannot find Chrome executable at /Applications/Google Chrome.app/Contents/MacOS/Google Chrome)
//  ! Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.
//  [✓] Android Studio (version 4.2)
//  [✓] VS Code (version 1.58.0)
//  [✓] Connected device (2 available)

// Tested on:
//   - Android MI 9 with android-arm64 and Android 10 (API 29)
//   - iPhone with iOS 13.3
// And with states_rebuilder: 4.0.0+1

// This example uses   file_picker: 3.0.3 and camera: 0.8.1+4 because I wanted to keep the conditions as close as what I had in my actual app.
class StateRebuilderIssue206Widget extends StatelessWidget with WidgetsBindingObserver, RouteAware {
  /// The camera preview height will be this ratio of its width.
  static const double cameraPreviewAspectRatio = 0.6;

  final bool isFront;
  final Injected<_State> injectedState;

  StateRebuilderIssue206Widget({
    Key key,
    @required this.isFront,
  })  : injectedState = RM.inject<_State>(
          () => _State(isFront),
          autoDisposeWhenNotUsed: false,
        ),
        super(key: key);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      injectedState.setState((s) => s.didChangeAppLifecycleState(state));

  @override
  void didPushNext() => injectedState.setState((s) => s.didPushNext());

  @override
  void didPopNext() => injectedState.setState((s) => s.didPopNext());

  Widget buildPositionCardText(BuildContext context, ReactiveModel<_State> rm) => Text(
        rm.state.isCameraPermissionDenied || rm.state.isPictureTaken ? '' : 'Position card in frame',
        style: TextStyle(color: Colors.white),
      );

  Widget buildCardFaceText(BuildContext context) => Text(
        isFront ? 'Front' : 'Back',
        style: TextStyle(color: Colors.white),
      );

  Widget buildUploadButton(BuildContext context, ReactiveModel<_State> rm) => BaseButton(
        text: 'Accept',
        onTap: () => rm.setState((s) => s.onUploadButtonTapped(context)),
        minWidth: 140,
      );

  Widget buildUndoButton(BuildContext context, ReactiveModel<_State> rm) => BaseButton(
        text: 'Undo',
        onTap: () => rm.setState((s) => s.clearSelectedPicture()),
        minWidth: 140,
      );

  Widget buildAcceptAndUndoButtons(BuildContext context, ReactiveModel<_State> rm) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildUndoButton(context, rm),
          buildUploadButton(context, rm),
        ],
      );

  Widget buildGalleryButton(BuildContext context, ReactiveModel<_State> rm) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        // TODO: ISSUE #1
        onTap: () => rm.setState((s) => s.openFilePicker1(context)),

        // TODO: ISSUE #2
        // onTap: () async {
        //   print('>>> openFilePicker2 >>> BEFORE SET STATE');
        //   await rm.setState((s) async {
        //     print('>>> openFilePicker2 >>> BEFORE FUN');
        //     await s.openFilePicker2(context);
        //     print('>>> openFilePicker2 >>> AFTER FUN');
        //   });
        //   // TODO
        //   // >>> ISSUE #2: THE CODE NEVER GOES THERE <<<
        //   // NOTE: On iOS it seems to still refresh the UI (the picture appears), but on Android it does not.
        //   // setState still never completes in both cases.
        //   print('>>> openFilePicker2 >>> AFTER SET STATE');
        // },

        // TODO: This works as expected
        // onTap: () => rm.state.openFilePicker3(context, rm),

        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.photo_library,
            size: 33,
            color: Colors.white,
          ),
        ),
      );

  Widget buildCameraPreviewCardTarget(BuildContext context, ReactiveModel<_State> rm) => Center(
        child: FractionallySizedBox(
          alignment: Alignment.center,
          widthFactor: 0.85,
          child: AspectRatio(
            aspectRatio: 1 / cameraPreviewAspectRatio,
            child: Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );

  Widget buildCameraPermissionDeniedText(BuildContext context, ReactiveModel<_State> rm) => Text(
        'You denied access to your camera\n\nPlease pick a picture from your phone gallery or enter your details manually',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      );

  Widget buildCameraPreview(BuildContext context, ReactiveModel<_State> rm) => rm.state.isCameraPermissionDenied
      ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: buildCameraPermissionDeniedText(context, rm),
          ),
        )
      : ClipRect(
          child: Transform.scale(
            scale: rm.state.cameraAspectRatio / cameraPreviewAspectRatio,
            child: Center(
              child: rm.state.isCameraOpen
                  ? CameraPreview(
                      rm.state.cameraController,
                      child: buildCameraPreviewCardTarget(context, rm),
                    )
                  : Container(),
            ),
          ),
        );

  Widget buildPictureView(BuildContext context, ReactiveModel<_State> rm) => rm.state.picturePath == null
      ? Container()
      : Image.file(
          File(rm.state.picturePath),
        );

  Widget buildCameraPreviewOrPictureView(BuildContext context, ReactiveModel<_State> rm) => Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 1 / cameraPreviewAspectRatio,
          child: rm.state.isProcessingPicture
              ? Center(child: CircularProgressIndicator())
              : rm.state.isPictureTaken
                  ? buildPictureView(context, rm)
                  : buildCameraPreview(context, rm),
        ),
      );

  Widget buildTakePictureButton(BuildContext context, ReactiveModel<_State> rm) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: rm.state.isCameraPermissionDenied
            ? null
            : () {
                if (!rm.state.isProcessingPicture) {
                  rm.setState((s) => s.takePicture());
                }
              },
        child: Opacity(
          opacity: rm.state.isCameraPermissionDenied ? 0.1 : 1,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      );

  Widget buildTakePictureAndGalleryButtons(BuildContext context, ReactiveModel<_State> rm) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 48),
          buildTakePictureButton(context, rm),
          buildGalleryButton(context, rm),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Color(0xFF001226),
        body: StateBuilder<_State>(
          observe: () => injectedState,
          initState: (context, rm) async {
            WidgetsBinding.instance.addObserver(this);
            // TODO: BUG: The first time the camera permission is granted the UI does not refresh
            // It looks like the call to rm.setState never completed, and thus never refreshes the UI.
            // This is likely the same as ISSUE #2
            await rm.setState((s) => s.initState(context, rm));
          },
          dispose: (context, rm) {
            WidgetsBinding.instance.removeObserver(this);
            routeObserver.unsubscribe(this);
            rm.state.dispose(context);
          },
          didChangeDependencies: (context, rm) {
            routeObserver.subscribe(this, ModalRoute.of(context));
          },
          builder: (context, rm) => SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(height: 16),
                  buildCameraPreviewOrPictureView(context, rm),
                  Container(height: 16),
                  buildPositionCardText(context, rm),
                  Container(height: 24),
                  buildCardFaceText(context),
                  Container(height: 24),
                  Container(height: 24),
                  if (rm.state.isPictureTaken) buildAcceptAndUndoButtons(context, rm),
                  if (!rm.state.isPictureTaken) ...[
                    Container(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: buildTakePictureAndGalleryButtons(context, rm),
                    ),
                  ],
                  Container(height: 36),
                ],
              ),
            ),
          ),
        ),
      );
}

class _State {
  static const String pictureFrontFileName = 'insurance_card_front';
  static const String pictureBackFileName = 'insurance_card_back';
  final bool isFrontPicture;

  CameraController cameraController;
  bool isUploading = false;
  bool isProcessingPicture = false;
  bool isCameraOpen = false;
  bool isOpeningCamera = false;
  bool isPickingFile = false;
  bool isAppInBackground = false;
  bool isTopRoute = true;
  bool isCameraPermissionDenied = false;
  String picturePath;
  String picturesFolderPath;
  String pictureFileExtension;

  String get pictureFileName => isFrontPicture ? pictureFrontFileName : pictureBackFileName;

  bool get isCameraInitialized => cameraController?.value?.isInitialized ?? false;

  bool get isPictureTaken => !isEmptyOrNull(picturePath);

  double get cameraAspectRatio => isCameraInitialized ? cameraController.value.aspectRatio : 1;

  /// Used to know when to veto opening the camera.
  /// Only true when the camera is on or should be turned on.
  bool get isCameraPreviewVisible => isTopRoute && !isAppInBackground && !isPictureTaken && !isPickingFile;

  _State(this.isFrontPicture);

  // TODO: passing rm and calling rm.setState((s) {}) is a work around the issue in StateBuilder initState.
  // This is likely the same as ISSUE #2
  Future<void> initState(BuildContext context, ReactiveModel<_State> rm) async {
    await openCamera();
    await rm.setState((s) {});
  }

  void dispose(BuildContext context) {
    cameraController?.dispose();
    deletePictures();
  }

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive && isCameraInitialized) {
      isAppInBackground = true;
      await closeCamera();
    } else if (state == AppLifecycleState.resumed) {
      isAppInBackground = false;
      await openCamera();
    }
  }

  Future<void> didPushNext() async {
    /// The route is not visible anymore because another route was pushed on top.
    if (isCameraInitialized) {
      isTopRoute = false;
      await closeCamera();
    }
  }

  Future<void> didPopNext() async {
    /// The route is visible again because the route above was popped.
    isTopRoute = true;
    if (!isPictureTaken && !isPickingFile) {
      await openCamera();
    }
  }

  Future<void> moveToNextPage(BuildContext context) async {
    /// Do nothing
  }

  void onUploadButtonTapped(BuildContext context) async {
    if (!isUploading) {
      isUploading = true;
      unawaited(ProgressLoader().show(context));
      await Future<void>.delayed(Duration(seconds: 1));
      unawaited(ProgressLoader().dismiss());
      isUploading = false;
    }
  }

  Future<void> loadCamera({CameraDescription cameraDescription}) async {
    if (cameraController != null) {
      await cameraController.dispose();
    }

    if (cameraDescription == null) {
      final List<CameraDescription> cameras = await availableCameras();

      if (isEmptyOrNull(cameras)) {
        showSnackBar(message: 'Could not open the camera.');
        return;
      }

      cameraDescription = cameras[0];
    }

    cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      /// On iOS, if the camera permission is not granted we get a "e.code == 'Error -11852'" apparently.
      if (e.code == 'cameraPermission' || e.code == 'Error -11852') {
        isCameraPermissionDenied = true;
        return;
      }
      rethrow;
    }

    await cameraController.lockCaptureOrientation(DeviceOrientation.portraitUp);
  }

  Future<void> openCamera() async {
    if (isCameraPreviewVisible && !isCameraOpen && !isOpeningCamera) {
      isOpeningCamera = true;
      await loadCamera(cameraDescription: cameraController?.description);
      isCameraOpen = true;
      isOpeningCamera = false;
    }
  }

  Future<void> closeCamera() async {
    if (isCameraOpen) {
      await cameraController?.dispose();
      isCameraOpen = false;
    }
  }

  Stream<void> takePicture() async* {
    isProcessingPicture = true;
    yield null;

    File file;
    bool isSuccess = await showSnackBarOnError(
      () async {
        final XFile xFile = await cameraController.takePicture();
        file = File(xFile?.path);
      },
    );
    if (!isSuccess) {
      isProcessingPicture = false;
      yield null;
      return;
    }

    picturesFolderPath = file.folderPath;
    pictureFileExtension = file.extension;

    File renamedFile;
    isSuccess = await showSnackBarOnError(
      () async => renamedFile = await file.updateName(
        pictureFileName,
      ),
    );
    if (!isSuccess) {
      isProcessingPicture = false;
      yield null;
      return;
    }

    picturePath = renamedFile.path;

    /// The [Image] widget caches the images (in the global var [imageCache]), and since all our images have the same
    /// name it will always load the cached copy, which we don't want.
    /// Evicting the file like this will allow us to   always show the right image.
    await FileImage(renamedFile).evict();

    await closeCamera();

    isSuccess = await showSnackBarOnError(
      () async {
        // await compute(cropPicture, renamedFile);
        await Future<void>.delayed(Duration(milliseconds: 500));

        /// The size should be already under the target size because we don't take picture with max quality setting.
        /// Adding that in case some devices still produce big pictures.
        // await compute(reducePictureFileSize, renamedFile);
        await Future<void>.delayed(Duration(milliseconds: 500));
      },
    );

    if (!isSuccess) {
      await clearSelectedPicture();
    }

    isProcessingPicture = false;
    yield null;
  }

  Future<void> clearSelectedPicture() async {
    if (picturePath != null) {
      picturePath = null;
      await openCamera();
    }
  }

  Future<void> uploadPictures() => Future<void>.delayed(Duration(seconds: 1));

  Future<void> saveUserData(BuildContext context) => Future<void>.delayed(Duration(seconds: 1));

  Future<void> reducePictureFileSize(File file) => Future<void>.delayed(Duration(milliseconds: 500));

  /// We don't want ot keep any local file, delete them when the page is popped.
  Future<void> deletePictures() async {
    await FilePicker.platform.clearTemporaryFiles();

    if (isEmptyOrNull(picturesFolderPath) || isEmptyOrNull(pictureFileExtension)) {
      return;
    }

    final String pictureFrontPath = picturesFolderPath + pictureFileName + pictureFileExtension;
    final File pictureFrontFile = File(pictureFrontPath);
    final String pictureBackPath = picturesFolderPath + pictureBackFileName + pictureFileExtension;
    final File pictureBackFile = File(pictureBackPath);

    try {
      if (await pictureFrontFile.exists()) {
        await pictureFrontFile.delete();
      }
    } catch (e) {
      /// Fail silently
    }

    try {
      if (await pictureBackFile.exists()) {
        await pictureBackFile.delete();
      }
    } catch (e) {
      /// Fail silently
    }
  }

  // TODO: Function to test ISSUE #1
  // Version where the function updates UI between intermediate states.
  // Does not work as expected, the stream never resumes after the 2nd yield.
  Stream<void> openFilePicker1(BuildContext context) async* {
    print('>>> openFilePicker1 >>> 1');
    isPickingFile = true;
    await closeCamera();
    print('>>> openFilePicker1 >>> 2');
    yield null;
    print('>>> openFilePicker1 >>> 3');

    FilePickerResult result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        showSnackBar(message: 'We cannot open your gallery because you denied access.');
      } else {
        rethrow;
      }
    }

    if (result == null) {
      /// Canceled by user.
      isPickingFile = false;
      await openCamera();
      yield null;
      return;
    }

    isProcessingPicture = true;
    picturePath = result.files.single.path;
    print('>>> openFilePicker1 >>> 4');
    yield null;
    // TODO:
    // >>> ISSUE #1: THE CODE NEVER GOES THERE <<<
    print('>>> openFilePicker1 >>> 5');

    bool isSuccess;
    isSuccess = await showSnackBarOnError(
      () => reducePictureFileSize(File(result.files.single.path)),
    );

    if (!isSuccess) {
      await clearSelectedPicture();
    }

    isProcessingPicture = false;
    isPickingFile = false;
    print('>>> openFilePicker1 >>> 6');
    yield null;
    print('>>> openFilePicker1 >>> 7');
  }

  // TODO: Function to test ISSUE #2
  // Version where the function does not update UI between intermediate states (only updates at the end of the function).
  // Does not work as expected, rm.setState() never completes.
  Future<void> openFilePicker2(BuildContext context) async {
    print('>>> openFilePicker2 >>> 1');
    isPickingFile = true;
    await closeCamera();

    FilePickerResult result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        showSnackBar(message: 'We cannot open your gallery because you denied access.');
      } else {
        rethrow;
      }
    }

    if (result == null) {
      /// Canceled by user.
      isPickingFile = false;
      await openCamera();
      return;
    }

    isProcessingPicture = true;
    picturePath = result.files.single.path;

    bool isSuccess;
    isSuccess = await showSnackBarOnError(
      () => reducePictureFileSize(File(result.files.single.path)),
    );

    if (!isSuccess) {
      await clearSelectedPicture();
    }

    isProcessingPicture = false;
    isPickingFile = false;
    print('>>> openFilePicker2 >>> 2');
  }

// Version where the ReactiveModel is given to the function.
// The end result is the same as what [openFilePicker1] would do if it was working.
// IMPORTANT: Don't call this function with rm.setState.
  Future<void> openFilePicker3(BuildContext context, ReactiveModel<_State> rm) async {
    await rm.setState((s) async {
      s.isPickingFile = true;
      await s.closeCamera();
    });

    FilePickerResult result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
    } on PlatformException catch (e) {
      if (e.code == 'read_external_storage_denied') {
        showSnackBar(message: 'We cannot open your gallery because you denied access.');
      } else {
        rethrow;
      }
    }

    if (result == null) {
      /// Canceled by user.
      await rm.setState((s) async {
        s.isPickingFile = false;
        await s.openCamera();
      });
      return;
    }

    await rm.setState((s) {
      s.isProcessingPicture = true;
      s.picturePath = result.files.single.path;
    });

    bool isSuccess;
    isSuccess = await showSnackBarOnError(
      () => Future<void>.delayed(Duration(milliseconds: 500)),
      // () => compute(reducePictureFileSize, File(result.files.single.path)),
    );

    if (!isSuccess) {
      await rm.setState((s) => s.clearSelectedPicture());
    }

    await rm.setState((s) {
      s.isProcessingPicture = false;
      s.isPickingFile = false;
    });
  }
}
