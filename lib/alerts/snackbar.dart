import 'package:flutter/material.dart';

class OverlaySnackbar extends StatefulWidget {
  final int? milliseconds;
  final String message;
  final Color? color;
  const OverlaySnackbar(
      {super.key, required this.message, this.color, this.milliseconds});

  @override
  State<OverlaySnackbar> createState() => _OverlaySnackbarState();
}

class _OverlaySnackbarState extends State<OverlaySnackbar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOverlaySnackbar(context);
    });
    _doProcess();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _doProcess() {}

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  void showOverlaySnackbar(BuildContext context) {
    OverlayState? overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: widget.color ??
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainer
                      .withAlpha((255 * 0.75).toInt()),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              widget.message,
            ),
          ),
        ),
      ),
    );

    // Adiciona o overlay à tela
    overlay.insert(overlayEntry);

    // Remove o overlay após a duração especificada
    Future.delayed(Duration(milliseconds: widget.milliseconds ?? 2000), () {
      overlayEntry.remove();
    });
  }
}
