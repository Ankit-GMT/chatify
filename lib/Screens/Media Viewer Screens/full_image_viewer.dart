import 'dart:io';

import 'package:flutter/material.dart';

class FullImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullImageViewer({super.key, required this.imageUrl});

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails!.localPosition;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 1.8, -position.dy * 1.8)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        behavior: HitTestBehavior.translucent, // receive gestures anywhere
        onPointerSignal: (_) {},
        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // full-screen gesture area
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _handleDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1,
            maxScale: 4,
            clipBehavior: Clip.none,
            panEnabled: true,
            scaleEnabled: true,
            child: Center(
              child: Hero(
                tag:
                widget.imageUrl,
                child: Image.file(
                  File(widget.imageUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),

      /// Back button
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}

