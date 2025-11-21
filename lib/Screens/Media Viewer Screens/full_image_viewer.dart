import 'package:flutter/material.dart';

class FullImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullImageViewer({super.key, required this.imageUrl});

  @override
  State<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {

  double currentScale = 1.0;
  double doubleTapScale = 2.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {
                  currentScale = currentScale == 1 ? doubleTapScale : 1;
                });
              },
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                scaleEnabled: true,
                child: AnimatedScale(
                  duration: Duration(milliseconds: 300),
                  scale: currentScale,
                  child: Hero(
                    tag: 'https://picsum.photos/400/400',
                    child: Image.network(
                      // widget.imageUrl,
                      'https://picsum.photos/800/700',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
