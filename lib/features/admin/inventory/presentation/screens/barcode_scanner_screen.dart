import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/scan_beep.dart';

/// Full-screen camera barcode/QR scanner. Pops with the scanned code as a
/// `String`, or `null` if the admin backs out without scanning.
///
/// Shared by two entry points — Admin Inventory's "Barcode Scanner" quick
/// action (look-up mode: caller matches the code against the already-loaded
/// product list) and the Add/Edit product form's Barcode field (prefill
/// mode: caller just fills the field). This screen doesn't know or care
/// which; it only ever returns a code, so both callers reuse it as-is.
///
/// Also has a manual-entry fallback below the camera view — needed for
/// devices/emulators with no usable camera, and generally useful when
/// scanning fails (poor lighting, damaged label).
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();
  final _manualController = TextEditingController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    playScanBeep();
    context.pop(code);
  }

  void _submitManual() {
    final code = _manualController.text.trim();
    if (code.isEmpty || _handled) return;
    _handled = true;
    context.pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // The app theme's AppBarTheme.titleTextStyle hard-codes a dark
        // color, which wins over foregroundColor for the title — override
        // it explicitly so "Scan barcode" is actually legible on black.
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                const _ScannerOverlay(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Or type the barcode manually',
                        hintStyle: TextStyle(color: Colors.white60),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                      onSubmitted: (_) => _submitManual(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Use this code',
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: _submitManual,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple centered viewfinder square over the camera preview — purely a
/// visual guide, doesn't constrain where `mobile_scanner` actually detects.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),
    );
  }
}
