import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/constants/app_colors.dart';

/// Dialog untuk mengambil foto dokumentasi kegiatan pembelajaran langsung melalui
/// webcam laptop / kamera komputer dengan pratinjau live feed dan tombol shutter.
class CameraCaptureDialog extends StatefulWidget {
  const CameraCaptureDialog({super.key});

  /// Buka modal webcam capture. Mengembalikan `Uint8List?` foto yang diambil.
  static Future<Uint8List?> show(BuildContext context) async {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CameraCaptureDialog(),
    );
  }

  @override
  State<CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<CameraCaptureDialog> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;

  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;
  Uint8List? _capturedBytes;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage =
              'Tidak ditemukan webcam atau kamera pada perangkat ini. Pastikan webcam terhubung.';
          _isInitializing = false;
        });
        return;
      }

      _cameras = cameras;
      _selectedCameraIndex = cameraIndex.clamp(0, cameras.length - 1);

      final prevController = _controller;
      final newController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controller = newController;
      await prevController?.dispose();

      await newController.initialize();
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Tidak dapat mengakses webcam: $e\n\nPastikan izin akses kamera pada browser/laptop sudah diizinkan.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1 || _isCapturing) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCamera(nextIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();

      if (!mounted) return;
      setState(() {
        _capturedBytes = bytes;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedBytes = null;
    });
  }

  void _usePhoto() {
    if (_capturedBytes != null) {
      Navigator.of(context).pop(_capturedBytes);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 680 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Dark slate theme for camera preview
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar
              _buildHeader(context),

              // Viewfinder / Preview / Error Area
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCameraBody(),
                ),
              ),

              // Bottom Controls Bar
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.videocam_rounded, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _capturedBytes != null ? 'Pratinjau Foto' : 'Webcam',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (_cameras.length > 1 && _capturedBytes == null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
              tooltip: 'Ganti Kamera',
              onPressed: _switchCamera,
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            tooltip: 'Tutup',
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBody() {
    if (_isInitializing) {
      return Container(
        height: 340,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke webcam...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Dapat Mengakses Kamera',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _initCamera(_selectedCameraIndex),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF475569)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_capturedBytes != null) {
      // Photo captured preview
      return Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Image.memory(
            _capturedBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Live Camera Preview
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 340,
        child: Center(child: Text('Kamera belum siap', style: TextStyle(color: Colors.white70))),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Color(0xFF334155)),
        ),
      ),
      child: _capturedBytes != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Foto Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _retakePhoto,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Gunakan Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _usePhoto,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage == null && !_isInitializing) ...[
                  // Shutter button
                  GestureDetector(
                    onTap: _isCapturing ? null : _capturePhoto,
                    child: Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.grey : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
