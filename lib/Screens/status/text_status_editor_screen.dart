
import 'dart:io';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/status_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class TextStatusEditor extends StatefulWidget {
  final DateTime? scheduledAt;
  const TextStatusEditor({super.key,this.scheduledAt});

  @override
  State<TextStatusEditor> createState() => _TextStatusEditorState();
}

class _TextStatusEditorState extends State<TextStatusEditor> {
  final TextEditingController _controller = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  int gradientIndex = 0;
  double fontSize = 32;
  Color textColor = Colors.white;
  bool isSending = false;


  bool showColorPicker = false;
  bool showFontPicker = false;
  bool hideUiForScreenshot = false;

  int selectedFontIndex = 0;

  final List<List<Color>> gradients = [
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    [Color(0xFFF953C6), Color(0xFFB91D73)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFFF512F), Color(0xFFDD2476)],
    [Color(0xFF232526), Color(0xFF414345)],
  ];

  final List<Color> textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  final List<TextStyle Function(double, Color)> fonts = [
    (s, c) =>
        GoogleFonts.poppins(fontSize: s, color: c, fontWeight: FontWeight.w600),
    (s, c) => GoogleFonts.jetBrainsMono(
          fontSize: s,
          color: c,
          fontWeight: FontWeight.w500,
        ),
    (s, c) => GoogleFonts.bebasNeue(
          fontSize: s,
          color: c,
          letterSpacing: 1.2,
        ),
    (s, c) => GoogleFonts.comicNeue(
          fontSize: s,
          color: c,
          fontWeight: FontWeight.w600,
        ),
    (s, c) => GoogleFonts.playfairDisplay(
        fontSize: s, color: c, fontWeight: FontWeight.w600),
    (s, c) => GoogleFonts.dancingScript(
        fontSize: s, color: c, fontWeight: FontWeight.w600),
  ];

  void changeGradient() {
    if (hideUiForScreenshot) return;
    setState(() {
      gradientIndex = (gradientIndex + 1) % gradients.length;
    });
  }

  Future<void> sendStatus() async {
    if (_controller.text.trim().isEmpty || isSending) return;

    setState(() {
      isSending = true;
      hideUiForScreenshot = true;
      showColorPicker = false;
      showFontPicker = false;
    });

    await Future.delayed(const Duration(milliseconds: 120));

    final image = await _screenshotController.capture(pixelRatio: 2.5);

    if (image == null) {
      setState(() {
        isSending = false;
        hideUiForScreenshot = false;
      });
      return;
    }

    final file = File(
      '${(await getTemporaryDirectory()).path}/status.png',
    );
    await file.writeAsBytes(image);

    final controller = Get.find<StatusController>();

    final bool success ;

    if (widget.scheduledAt != null) {
     success = await controller.uploadScheduledMediaStatus(
        file: file,
        type: "IMAGE", // or VIDEO
        // caption: widget.caption,
        scheduledAt: widget.scheduledAt!,
      );

    } else {
      success =  await controller.uploadMediaStatus(
        file: file,
        type: "IMAGE",
        // caption: widget.caption,
      );

    }

    if (success) {
      controller.loadStatuses();
      controller.loadScheduledStatuses();
      Get.back(result: true);
    } else {
      setState(() {
        isSending = false;
        hideUiForScreenshot = false;
      });
      Get.snackbar("Error", "Failed to upload status",backgroundColor: Colors.red,colorText: AppColors.white);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: isSending
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.send),
            onPressed: isSending ? null : sendStatus,
          )

        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: changeGradient,
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradients[gradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _controller,
                      showCursor: !hideUiForScreenshot,
                      cursorColor: Colors.white,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      style: fonts[selectedFontIndex](fontSize, textColor),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: hideUiForScreenshot ? "" : "Type a status",
                        hintStyle: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// TEXT SIZE SLIDER
          if (!hideUiForScreenshot)
            Positioned(
              right: 8,
              top: Get.height * 0.2,
              bottom: Get.height * 0.2,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  value: fontSize,
                  min: 20,
                  max: 64,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                  onChanged: (v) => setState(() => fontSize = v),
                ),
              ),
            ),

          /// COLOR PICKER
          if (showColorPicker && !hideUiForScreenshot)
            Positioned(
              left: 10,
              bottom: 140,
              child: _colorPicker(),
            ),

          /// FONT PICKER
          if (showFontPicker && !hideUiForScreenshot)
            Positioned(
              left: 10,
              top: 120,
              child: _fontPicker(),
            ),
        ],
      ),
      bottomNavigationBar: hideUiForScreenshot ? null : bottomControls(),
    );
  }

  Widget _colorPicker() {
    return _floatingPanel(
      child: Column(
        children: textColors.map((color) {
          return GestureDetector(
            onTap: () {
              setState(() {
                textColor = color;
                showColorPicker = false;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _fontPicker() {
    return _floatingPanel(
      child: Column(
        children: List.generate(fonts.length, (i) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFontIndex = i;
                showFontPicker = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                "Aa",
                style: fonts[i](22, Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _floatingPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget bottomControls() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () {
              setState(() {
                showColorPicker = !showColorPicker;
                showFontPicker = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.font_download, color: Colors.white),
            onPressed: () {
              setState(() {
                showFontPicker = !showFontPicker;
                showColorPicker = false;
              });
            },
          ),
          const Spacer(),
          const Text(
            "Tap screen to change background",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
