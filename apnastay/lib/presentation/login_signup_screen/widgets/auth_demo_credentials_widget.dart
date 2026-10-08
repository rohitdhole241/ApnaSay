import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AuthDemoCredentialsWidget extends StatelessWidget {
  const AuthDemoCredentialsWidget({super.key});

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBrandLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBrand.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.primaryBrand,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo Credentials',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CredentialRow(
            label: 'Phone',
            value: '9876543210',
            onCopy: () => _copyToClipboard(context, '9876543210'),
          ),
          const SizedBox(height: 6),
          _CredentialRow(
            label: 'OTP',
            value: '1234',
            onCopy: () => _copyToClipboard(context, '1234'),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        GestureDetector(
          onTap: onCopy,
          child: const Icon(
            Icons.copy_rounded,
            size: 15,
            color: AppTheme.primaryBrand,
          ),
        ),
      ],
    );
  }
}
