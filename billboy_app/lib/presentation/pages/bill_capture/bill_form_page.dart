import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/bill/bill_bloc.dart';
import '../../blocs/bill/bill_event.dart';
import '../../blocs/bill/bill_state.dart';
import '../../widgets/common/bb_text_field.dart';
import '../../widgets/common/bb_button.dart';
import '../../widgets/common/bb_snackbar.dart';

class BillFormPage extends StatefulWidget {
  final OcrExtractedData? ocrData;
  final BillEntity? existingBill;

  const BillFormPage({super.key, this.ocrData, this.existingBill});

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _billNumberController;
  late final TextEditingController _amountController;
  late final TextEditingController _taxAmountController;
  late final TextEditingController _serialController;
  late final TextEditingController _imeiController;
  late final TextEditingController _modelController;
  late final TextEditingController _brandController;
  late final TextEditingController _storeController;
  late final TextEditingController _gstController;
  late final TextEditingController _notesController;
  late final TextEditingController _warrantyMonthsController;

  String _selectedCategory = 'Electronics';
  DateTime _purchaseDate = DateTime.now();
  int _currentStep = 0;

  bool get _isEditing => widget.existingBill != null;

  @override
  void initState() {
    super.initState();
    final ocr = widget.ocrData;
    final existing = widget.existingBill;

    _productNameController = TextEditingController(text: existing?.productName ?? ocr?.productName ?? '');
    _billNumberController = TextEditingController(text: existing?.billNumber ?? ocr?.billNumber ?? '');
    _amountController = TextEditingController(
        text: existing?.purchaseAmount.toString() ?? ocr?.purchaseAmount?.toString() ?? '');
    _taxAmountController = TextEditingController(
        text: existing?.taxAmount?.toString() ?? ocr?.taxAmount?.toString() ?? '');
    _serialController = TextEditingController(text: existing?.serialNumber ?? ocr?.serialNumber ?? '');
    _imeiController = TextEditingController(text: existing?.imeiNumber ?? ocr?.imeiNumber ?? '');
    _modelController = TextEditingController(text: existing?.modelNumber ?? ocr?.modelNumber ?? '');
    _brandController = TextEditingController(text: existing?.brandName ?? ocr?.brandName ?? '');
    _storeController = TextEditingController(text: existing?.storeName ?? ocr?.storeName ?? '');
    _gstController = TextEditingController(text: existing?.gstNumber ?? ocr?.gstNumber ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _warrantyMonthsController = TextEditingController(
        text: existing?.warrantyMonths?.toString() ?? ocr?.warrantyMonths?.toString() ?? '');

    _selectedCategory = existing?.category ?? ocr?.category ?? 'Electronics';
    _purchaseDate = existing?.purchaseDate ?? ocr?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    _taxAmountController.dispose();
    _serialController.dispose();
    _imeiController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _storeController.dispose();
    _gstController.dispose();
    _notesController.dispose();
    _warrantyMonthsController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) return;

    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticatedState ? authState.user.id : '';

    final bill = BillEntity(
      id: widget.existingBill?.id ?? const Uuid().v4(),
      userId: userId,
      productName: _productNameController.text.trim(),
      category: _selectedCategory,
      purchaseDate: _purchaseDate,
      billNumber: _billNumberController.text.trim().isNotEmpty ? _billNumberController.text.trim() : null,
      warrantyMonths: int.tryParse(_warrantyMonthsController.text),
      purchaseAmount: double.parse(_amountController.text.replaceAll(',', '')),
      taxAmount: double.tryParse(_taxAmountController.text),
      serialNumber: _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
      imeiNumber: _imeiController.text.trim().isNotEmpty ? _imeiController.text.trim() : null,
      modelNumber: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
      brandName: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      storeName: _storeController.text.trim().isNotEmpty ? _storeController.text.trim() : null,
      gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      warrantyStatus: WarrantyStatus.noWarranty,
      createdAt: widget.existingBill?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      context.read<BillBloc>().add(BillUpdateEvent(bill));
    } else {
      context.read<BillBloc>().add(BillCreateEvent(bill));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state is BillCreatedState || state is BillUpdatedState) {
          BBSnackbar.showSuccess(context, _isEditing ? 'Bill updated!' : 'Bill saved successfully!');
          context.go('/home');
        } else if (state is BillErrorState) {
          BBSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Bill' : 'New Bill'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (widget.ocrData != null)
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'AI Filled',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _onSave();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<BillBloc, BillState>(
                        builder: (ctx, state) {
                          return BBButton(
                            label: _currentStep == 2 ? (_isEditing ? 'Update Bill' : 'Save Bill') : 'Continue',
                            onPressed: details.onStepContinue ?? () {},
                            isLoading: state is BillLoadingState,
                          );
                        },
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Product Info'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildProductInfoStep(),
              ),
              Step(
                title: const Text('Bill Details'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildBillDetailsStep(),
              ),
              Step(
                title: const Text('Warranty & Notes'),
                isActive: _currentStep >= 2,
                content: _buildWarrantyStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoStep() {
    return Column(
      children: [
        BBTextField(
          controller: _productNameController,
          label: 'Product Name *',
          hint: 'e.g., Samsung Galaxy S24',
          prefixIcon: Icons.shopping_bag_outlined,
          validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category *',
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: AppConstants.categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _brandController,
          label: 'Brand Name',
          hint: 'e.g., Samsung',
          prefixIcon: Icons.branding_watermark_outlined,
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _modelController,
          label: 'Model Number',
          hint: 'e.g., SM-S928B',
          prefixIcon: Icons.confirmation_number_outlined,
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _serialController,
          label: 'Serial Number',
          hint: 'Device serial number',
          prefixIcon: Icons.qr_code_outlined,
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _imeiController,
          label: 'IMEI Number',
          hint: 'For mobile devices',
          prefixIcon: Icons.phonelink_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildBillDetailsStep() {
    return Column(
      children: [
        BBTextField(
          controller: _billNumberController,
          label: 'Bill / Invoice Number',
          hint: 'e.g., INV-2026-001',
          prefixIcon: Icons.receipt_outlined,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Purchase Date *',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(DateFormat('dd MMM yyyy').format(_purchaseDate)),
          ),
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _amountController,
          label: 'Purchase Amount (₹) *',
          hint: 'e.g., 45000',
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Amount is required';
            if (double.tryParse(v.replaceAll(',', '')) == null) return 'Enter valid amount';
            return null;
          },
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _taxAmountController,
          label: 'Tax / GST Amount (₹)',
          hint: 'e.g., 8100',
          prefixIcon: Icons.percent_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _storeController,
          label: 'Store / Seller Name',
          hint: 'e.g., Croma Electronics',
          prefixIcon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 16),
        BBTextField(
          controller: _gstController,
          label: 'Seller GST Number',
          hint: 'e.g., 29ABCDE1234F1Z5',
          prefixIcon: Icons.business_outlined,
        ),
      ],
    );
  }

  Widget _buildWarrantyStep() {
    return Column(
      children: [
        BBTextField(
          controller: _warrantyMonthsController,
          label: 'Warranty Period (months)',
          hint: 'e.g., 24 for 2 years',
          prefixIcon: Icons.verified_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        if (_warrantyMonthsController.text.isNotEmpty)
          Builder(builder: (context) {
            final months = int.tryParse(_warrantyMonthsController.text);
            if (months == null) return const SizedBox.shrink();
            final warrantyEnd = DateTime(
              _purchaseDate.year,
              _purchaseDate.month + months,
              _purchaseDate.day,
            );
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Warranty ends: ${DateFormat('dd MMM yyyy').format(warrantyEnd)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 16),
        BBTextField(
          controller: _notesController,
          label: 'Notes',
          hint: 'Any additional notes',
          prefixIcon: Icons.note_outlined,
          maxLines: 3,
        ),
      ],
    );
  }
}
