import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class PhoneInputWidget extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final Color buttonColor;

  const PhoneInputWidget({
    super.key, 
    required this.onSubmit,
    this.buttonColor = AppTheme.primaryBrand,
  });

  @override
  State<PhoneInputWidget> createState() => _PhoneInputWidgetState();
}

class _PhoneInputWidgetState extends State<PhoneInputWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasError = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _controller.text.trim();
    if (phone.length < 10) {
      setState(() {
        _hasError = true;
        _errorText = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }
    setState(() => _hasError = false);
    widget.onSubmit(phone);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isFocused || _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasError
                  ? AppTheme.error
                  : _isFocused
                  ? AppTheme.primaryBrand
                  : AppTheme.outline,
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text('🇮🇳', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '+91',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: AppTheme.outline),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Floating label
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      top: isActive ? 6 : 18,
                      left: 0,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.outfit(
                          fontSize: isActive ? 10 : 14,
                          fontWeight: FontWeight.w400,
                          color: _isFocused
                              ? AppTheme.primaryBrand
                              : AppTheme.onSurfaceMuted,
                        ),
                        child: const Text('Mobile Number'),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 16,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() => _hasError = false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6),
          Text(
            _errorText,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.error,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Send OTP',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
