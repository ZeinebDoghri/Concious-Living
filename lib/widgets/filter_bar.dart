import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum HistorySort { newest, oldest, highestRisk }

class FilterState {
  final String search;
  final String riskLevel;
  final HistorySort sort;
  final String? departmentId;

  const FilterState({
    this.search = '',
    this.riskLevel = 'all',
    this.sort = HistorySort.newest,
    this.departmentId,
  });

  FilterState copyWith({
    String? search,
    String? riskLevel,
    HistorySort? sort,
    String? departmentId,
    bool clearDepartment = false,
  }) {
    return FilterState(
      search: search ?? this.search,
      riskLevel: riskLevel ?? this.riskLevel,
      sort: sort ?? this.sort,
      departmentId: clearDepartment ? null : departmentId ?? this.departmentId,
    );
  }
}

class FilterBar extends StatefulWidget {
  final FilterState state;
  final ValueChanged<FilterState> onChanged;
  final Color color;
  final List<FilterChipOption> departmentOptions;

  const FilterBar({
    super.key,
    required this.state,
    required this.onChanged,
    required this.color,
    this.departmentOptions = const [],
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.search);
  }

  @override
  void didUpdateWidget(covariant FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.search != _controller.text) {
      _controller.text = widget.state.search;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setSearch(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onChanged(widget.state.copyWith(search: value));
      }
    });
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<HistorySort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SortTile(
              icon: Icons.south_rounded,
              label: 'Newest',
              selected: widget.state.sort == HistorySort.newest,
              onTap: () => Navigator.of(context).pop(HistorySort.newest),
            ),
            _SortTile(
              icon: Icons.north_rounded,
              label: 'Oldest',
              selected: widget.state.sort == HistorySort.oldest,
              onTap: () => Navigator.of(context).pop(HistorySort.oldest),
            ),
            _SortTile(
              icon: Icons.priority_high_rounded,
              label: 'Highest risk',
              selected: widget.state.sort == HistorySort.highestRisk,
              onTap: () => Navigator.of(context).pop(HistorySort.highestRisk),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      widget.onChanged(widget.state.copyWith(sort: selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: _setSearch,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search scans',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged(widget.state.copyWith(search: ''));
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in const [
                  FilterChipOption(id: 'all', label: 'All'),
                  FilterChipOption(id: 'safe', label: 'Safe'),
                  FilterChipOption(id: 'warning', label: 'Warning'),
                  FilterChipOption(id: 'danger', label: 'Danger'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: widget.state.riskLevel == option.id,
                      selectedColor: widget.color.withValues(alpha: 0.18),
                      onSelected: (_) => widget.onChanged(
                        widget.state.copyWith(riskLevel: option.id),
                      ),
                    ),
                  ),
                IconButton.filledTonal(
                  tooltip: 'Sort',
                  onPressed: _showSortSheet,
                  icon: Icon(_sortIcon(widget.state.sort)),
                ),
              ],
            ),
          ),
          if (widget.departmentOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All departments'),
                      selected: widget.state.departmentId == null,
                      selectedColor: widget.color.withValues(alpha: 0.18),
                      onSelected: (_) => widget.onChanged(
                        widget.state.copyWith(clearDepartment: true),
                      ),
                    ),
                  ),
                  for (final department in widget.departmentOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(department.label),
                        selected: widget.state.departmentId == department.id,
                        selectedColor: widget.color.withValues(alpha: 0.18),
                        onSelected: (_) => widget.onChanged(
                          widget.state.copyWith(departmentId: department.id),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _sortIcon(HistorySort sort) {
    switch (sort) {
      case HistorySort.newest:
        return Icons.south_rounded;
      case HistorySort.oldest:
        return Icons.north_rounded;
      case HistorySort.highestRisk:
        return Icons.priority_high_rounded;
    }
  }
}

class FilterChipOption {
  final String id;
  final String label;

  const FilterChipOption({required this.id, required this.label});
}

class _SortTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      onTap: onTap,
    );
  }
}
