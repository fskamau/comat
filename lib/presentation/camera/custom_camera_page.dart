import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';

class CustomCameraPage extends StatefulWidget {
  const CustomCameraPage({super.key});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _isPermissionPermanentlyDenied = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(cameraController.description);
    }
  }

  // Request camera permissions and initialize if granted
  Future<void> _checkPermissionsAndInitialize() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      _setupCameras();
    } else if (status.isPermanentlyDenied) {
      setState(() => _isPermissionPermanentlyDenied = true);
    } else {
      setState(() => _isPermissionGranted = false);
    }
  }

  // Discover available cameras and initialize the back camera
  Future<void> _setupCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        await _initCamera(backCamera);
      }
    } catch (e) {
      debugPrint("Camera Setup Error: $e");
    }
  }

  // Initialize the selected camera controller
  Future<void> _initCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Initialization Error: $e");
    }
  }

  // Toggle flash/torch mode
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint("Flash Toggle Error: $e");
    }
  }

  // Capture a photo and return the file path
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile picture = await _controller!.takePicture();
      if (_isFlashOn) await _controller!.setFlashMode(FlashMode.off);
      if (mounted) Navigator.pop(context, picture.path);
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionPermanentlyDenied) return _buildPermissionDeniedState();
    if (!_isPermissionGranted) return _buildRequestPermissionState();

    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.mustGold)),
      );
    }

    // Calculate scaling to prevent preview distortion
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ClipRect(
            child: Center(
              child: Transform.scale(
                scale: scale,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? AppTheme.mustGold : Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: _buildCaptureButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Container(
      height: 80, width: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.mustGold, width: 4),
        color: Colors.white.withOpacity(0.2),
      ),
      child: Center(
        child: Container(
          height: 60, width: 60,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      ),
    );
  }

  // UI for requesting camera permissions
  Widget _buildRequestPermissionState() {
    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: AppTheme.mustGold, size: 80),
            const SizedBox(height: 20),
            const Text("Camera Access Required", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text("Access to the camera is required to take photos of your items.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mustGold, foregroundColor: Colors.black),
              onPressed: _checkPermissionsAndInitialize,
              child: const Text("GRANT PERMISSION"),
            )
          ],
        ),
      ),
    );
  }

  // UI for when permissions are permanently denied
  Widget _buildPermissionDeniedState() {
    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text("Permission Blocked", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text("Camera access is disabled. Please enable it in system settings.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mustGold, foregroundColor: Colors.black),
              onPressed: () => openAppSettings(),
              child: const Text("OPEN SETTINGS"),
            ),
          ],
        ),
      ),
    );
  }
}