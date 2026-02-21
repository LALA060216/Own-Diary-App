import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../services/firestore_service.dart';

class ProfilePhotoCropPage extends StatefulWidget {
  final String userId;
  final File initialFile;

  const ProfilePhotoCropPage({
    super.key,
    required this.userId,
    required this.initialFile,
  });

  @override
  State<ProfilePhotoCropPage> createState() => _ProfilePhotoCropPageState();
}

class _ProfilePhotoCropPageState extends State<ProfilePhotoCropPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey _captureKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  late File _previewFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _previewFile = widget.initialFile;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<File?> _captureAdjustedImage() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List bytes = byteData.buffer.asUint8List();
      final file = File('${Directory.systemTemp.path}\\pfp_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveProfilePhoto() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final adjustedFile = await _captureAdjustedImage();
      if (adjustedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to adjust photo. Please try again.')),
          );
        }
        return;
      }
      await _firestoreService.updateProfilePhoto(widget.userId, adjustedFile);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black,
        title: const Text(
          'Adjust Photo',
          style: TextStyle(fontFamily: 'Lobstertwo', color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Move and zoom to adjust your profile photo',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final circleSize = constraints.maxWidth < 360 ? constraints.maxWidth - 24 : 320.0;
                      final imageCanvasSize = circleSize;

                      return Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RepaintBoundary(
                              key: _captureKey,
                              child: SizedBox(
                                width: imageCanvasSize,
                                height: imageCanvasSize,
                                child: ClipRect(
                                  child: InteractiveViewer(
                                    transformationController: _transformationController,
                                    minScale: 1,
                                    maxScale: 5,
                                    constrained: true,
                                    boundaryMargin: EdgeInsets.zero,
                                    clipBehavior: Clip.hardEdge,
                                    panEnabled: !_isSaving,
                                    scaleEnabled: !_isSaving,
                                    child: Image.file(
                                      _previewFile,
                                      width: imageCanvasSize,
                                      height: imageCanvasSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IgnorePointer(
                              child: SizedBox(
                                width: imageCanvasSize,
                                height: imageCanvasSize,
                                child: CustomPaint(
                                  painter: _CircleMaskPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfilePhoto,
                    icon: const Icon(Icons.check),
                    label: const Text('Use This Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: false,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Saving profile photo...',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final dimmed = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.58);
    canvas.drawPath(dimmed, paint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.95);

    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
