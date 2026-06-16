import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/bill/bill_bloc.dart';
import '../../blocs/bill/bill_event.dart';
import '../../blocs/bill/bill_state.dart';
import '../../widgets/common/bb_snackbar.dart';
import 'bill_form_page.dart';

class BillCapturePage extends StatefulWidget {
  const BillCapturePage({super.key});

  @override
  State<BillCapturePage> createState() => _BillCapturePageState();
}

class _BillCapturePageState extends State<BillCapturePage> {
  final _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _captureFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) BBSnackbar.showError(context, 'Camera permission denied');
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image != null && mounted) {
      _processImage(image.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image != null && mounted) {
      _processImage(image.path);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      final path = result.files.first.path;
      if (path != null) {
        context.read<BillBloc>().add(BillExtractOcrEvent(path, isPdf: true));
      }
    }
  }

  void _processImage(String path) {
    context.read<BillBloc>().add(BillExtractOcrEvent(path));
  }

  void _addManually() {
    context.push('/bill/form');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state is BillOcrExtractedState) {
          context.push('/bill/form', extra: state.data);
        } else if (state is BillErrorState) {
          BBSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Add Bill'),
        ),
        body: BlocBuilder<BillBloc, BillState>(
          builder: (context, state) {
            if (state is BillOcrProcessingState) {
              return const _OcrProcessingWidget();
            }
            return _buildContent(context);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like\nto add your bill?',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(
              'Our AI will automatically extract all details',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 40),

            _CaptureOptionCard(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Capture bill with your camera',
              color: AppColors.primary,
              delay: 150,
              onTap: _captureFromCamera,
            ),
            const SizedBox(height: 16),
            _CaptureOptionCard(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing photo',
              color: AppColors.accent,
              delay: 250,
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 16),
            _CaptureOptionCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Upload PDF',
              subtitle: 'Import PDF invoice or warranty',
              color: AppColors.error,
              delay: 350,
              onTap: _pickPdf,
            ),
            const SizedBox(height: 16),
            _CaptureOptionCard(
              icon: Icons.edit_note_rounded,
              title: 'Add Manually',
              subtitle: 'Enter bill details by hand',
              color: AppColors.warning,
              delay: 450,
              onTap: _addManually,
            ),

            const Spacer(),

            // AI Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Extraction',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Our OCR engine extracts product, price, warranty, and more automatically',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

class _CaptureOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _CaptureOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.2);
  }
}

class _OcrProcessingWidget extends StatelessWidget {
  const _OcrProcessingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 40),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: AppColors.primaryLight),
          const SizedBox(height: 24),
          Text('Processing your bill...', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'AI is extracting bill details',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}
