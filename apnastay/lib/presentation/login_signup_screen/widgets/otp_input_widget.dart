import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class OtpInputWidget extends StatefulWidget {
  final String phoneNumber;
  final ValueChanged<String> onVerified;
  final VoidCallback onBack;
  final bool isLoading;

  const OtpInputWidget({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
    required this.onBack,
    required this.isLoading,
  });

  @override
  State<OtpInputWidget> createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _resendSeconds = 30;
  bool _canResend = false;
  String _inputError = '';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
        }
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (_inputError.isNotEmpty) setState(() => _inputError = '');
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      // Auto-submit after all four demo OTP digits are entered.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !widget.isLoading &&
            _controllers.map((controller) => controller.text).join() == otp) {
          widget.onVerified(otp);
        }
      });
    }
  }

  void _submit() {
    if (widget.isLoading) return;
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != 4) {
      setState(() => _inputError = 'Enter the 4-digit demo OTP.');
      return;
    }
    widget.onVerified(otp);
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone =
        '+91 ${widget.phoneNumber.substring(0, 2)}****${widget.phoneNumber.substring(widget.phoneNumber.length - 2)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify OTP',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  'Sent to $maskedPhone',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                Text(
                  'Demo OTP: 1234 (no SMS is sent)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.primaryBrand,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBrand,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.primaryBrandLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBrand,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.outline),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onOtpDigitChanged(index, v),
              ),
            );
          }),
        ),
        if (_inputError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _inputError,
            style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.error),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Verify & Continue',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Center(
          child: _canResend
              ? TextButton(
                  onPressed: () {
                    setState(() {
                      _resendSeconds = 30;
                      _canResend = false;
                    });
                    _startResendTimer();
                  },
                  child: Text(
                    'Resend OTP',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.primaryBrand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  'Resend in ${_resendSeconds}s',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.onSurfaceMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ],
    );
  }
}
