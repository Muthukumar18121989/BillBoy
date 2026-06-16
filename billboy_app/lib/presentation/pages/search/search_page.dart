import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/bill/bill_bloc.dart';
import '../../blocs/bill/bill_event.dart';
import '../../blocs/bill/bill_state.dart';
import '../../widgets/bill/bill_table.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    setState(() => _hasSearched = true);
    context.read<BillBloc>().add(BillSearchEvent(query.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search bills, products, stores...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondaryLight),
          ),
          onChanged: (v) {
            if (v.isEmpty) setState(() => _hasSearched = false);
          },
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _hasSearched = false);
              },
            ),
        ],
      ),
      body: !_hasSearched
          ? _buildSuggestions(context)
          : BlocBuilder<BillBloc, BillState>(
              builder: (context, state) {
                if (state is BillLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is BillSearchResultState) {
                  if (state.results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textSecondaryLight),
                          const SizedBox(height: 16),
                          Text('No results for "${state.query}"', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        '${state.results.length} result(s) for "${state.query}"',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      BillTable(bills: state.results),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    final tips = [
      ('product name', Icons.devices_rounded),
      ('serial number', Icons.qr_code_rounded),
      ('store name', Icons.storefront_outlined),
      ('GST number', Icons.business_outlined),
      ('bill number', Icons.receipt_outlined),
      ('category', Icons.category_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search by', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tips.asMap().entries.map((entry) {
              final (label, icon) = entry.value;
              return ActionChip(
                avatar: Icon(icon, size: 16, color: AppColors.primary),
                label: Text(label),
                onPressed: () {
                  _controller.text = label;
                  _search(label);
                },
              ).animate().fadeIn(delay: Duration(milliseconds: entry.key * 50));
            }).toList(),
          ),
        ],
      ),
    );
  }
}
