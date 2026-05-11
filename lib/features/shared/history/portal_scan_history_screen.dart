import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/animations/shimmer_box.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/risk_badge.dart';
import '../../../widgets/filter_bar.dart';

enum PortalHistoryMode { customer, restaurant, hotel }

class PortalScanHistoryScreen extends StatefulWidget {
  final PortalHistoryMode mode;

  const PortalScanHistoryScreen({super.key, required this.mode});

  @override
  State<PortalScanHistoryScreen> createState() =>
      _PortalScanHistoryScreenState();
}

class _PortalScanHistoryScreenState extends State<PortalScanHistoryScreen> {
  static const _pageSize = 30;

  FilterState _filters = const FilterState();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _loadedEntityId;

  bool get _isCustomer => widget.mode == PortalHistoryMode.customer;
  bool get _isRestaurant => widget.mode == PortalHistoryMode.restaurant;
  bool get _isHotel => widget.mode == PortalHistoryMode.hotel;

  Color get _primary => _isCustomer
      ? const Color(0xFFC4748A)
      : _isRestaurant
      ? const Color(0xFF5A7030)
      : const Color(0xFF4A7FA5);

  Color get _bg => _isCustomer
      ? const Color(0xFFFEFAFC)
      : _isRestaurant
      ? const Color(0xFFF5F8EE)
      : const Color(0xFFF0F5F8);

  String get _title => _isCustomer
      ? 'Scan history'
      : _isRestaurant
      ? 'Restaurant history'
      : 'Hotel history';

  String get _entityCollection => _isCustomer
      ? 'users'
      : _isRestaurant
      ? 'restaurants'
      : 'hotels';

  String _entityId(UserProvider userProvider) {
    final user = userProvider.currentUser;
    if (user == null) return '';
    if (_isRestaurant) {
      return user.entityId ?? user.restaurantId ?? user.id;
    }
    if (_isHotel) {
      return user.entityId ?? user.hotelId ?? user.id;
    }
    return user.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entityId = _entityId(context.watch<UserProvider>());
    if (entityId.isNotEmpty && entityId != _loadedEntityId) {
      _loadedEntityId = entityId;
      _reload(entityId);
    }
  }

  Query<Map<String, dynamic>> _baseQuery(String entityId) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(_entityCollection)
        .doc(entityId)
        .collection('scans');

    if (_isHotel && _filters.departmentId != null) {
      query = query.where('departmentId', isEqualTo: _filters.departmentId);
    }

    final descending = _filters.sort != HistorySort.oldest;
    return query.orderBy('timestamp', descending: descending).limit(_pageSize);
  }

  Future<void> _reload(String entityId) async {
    setState(() {
      _loading = true;
      _error = null;
      _docs.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _load(entityId, reset: true);
  }

  Future<void> _load(String entityId, {required bool reset}) async {
    if (entityId.isEmpty) return;
    try {
      var query = _baseQuery(entityId);
      if (!reset && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snap = await query.get();
      if (!mounted) return;
      setState(() {
        if (reset) _docs.clear();
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.isEmpty ? _lastDoc : snap.docs.last;
        _hasMore = snap.docs.length == _pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore(String entityId) async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _load(entityId, reset: false);
  }

  void _updateFilters(FilterState next, String entityId) {
    setState(() => _filters = next);
    _reload(entityId);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _visibleDocs {
    final query = _filters.search.trim().toLowerCase();
    var docs = query.isEmpty
        ? List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(_docs)
        : _docs
              .where(
                (doc) => _dishName(doc.data()).toLowerCase().contains(query),
              )
              .toList();

    if (_filters.sort == HistorySort.highestRisk) {
      docs.sort((a, b) => _riskRank(b.data()).compareTo(_riskRank(a.data())));
    }
    if (_filters.riskLevel != 'all') {
      docs = docs
          .where((doc) => _riskLevel(doc.data()) == _filters.riskLevel)
          .toList(growable: false);
    }
    return docs;
  }

  Future<void> _confirmDelete(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete scan?'),
            content: const Text('This scan will be removed from history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await doc.reference.delete();
    if (!mounted) return;
    setState(() => _docs.removeWhere((item) => item.id == doc.id));
  }

  void _openDetail(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (_isCustomer) {
      context.go(
        AppRoutes.customerResult,
        extra: {
          'readOnly': true,
          'dishName': _dishName(data),
          'result': data['result'] ?? data['results']?['nutrition'] ?? {},
          'imagePath': data['imagePath'],
          'imageUrl': data['imageUrl'],
        },
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _VenueScanDetails(data: data, mode: widget.mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entityId = _entityId(context.watch<UserProvider>());
    final docs = _visibleDocs;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: entityId.isEmpty
            ? Center(child: CircularProgressIndicator(color: _primary))
            : Column(
                children: [
                  _Header(title: _title, color: _primary),
                  _isHotel
                      ? _DepartmentFilterBar(
                          hotelId: entityId,
                          color: _primary,
                          filters: _filters,
                          onChanged: (next) => _updateFilters(next, entityId),
                        )
                      : FilterBar(
                          state: _filters,
                          color: _primary,
                          onChanged: (next) => _updateFilters(next, entityId),
                        ),
                  Expanded(
                    child: _error != null
                        ? _HistoryError(error: _error)
                        : _loading
                        ? const _HistorySkeleton()
                        : docs.isEmpty
                        ? const EmptyState(
                            icon: Icons.history_rounded,
                            title: 'No scans found',
                            subtitle: 'Try another search or filter.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: docs.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index == docs.length) {
                                return Center(
                                  child: OutlinedButton(
                                    onPressed: _loadingMore
                                        ? null
                                        : () => _loadMore(entityId),
                                    child: _loadingMore
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Load more'),
                                  ),
                                );
                              }
                              final doc = docs[index];
                              return _ScanCard(
                                data: doc.data(),
                                mode: widget.mode,
                                color: _primary,
                                onTap: () => _openDetail(doc),
                                onDelete: () => _confirmDelete(doc),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DepartmentFilterBar extends StatelessWidget {
  final String hotelId;
  final Color color;
  final FilterState filters;
  final ValueChanged<FilterState> onChanged;

  const _DepartmentFilterBar({
    required this.hotelId,
    required this.color,
    required this.filters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('hotels')
          .doc(hotelId)
          .collection('departments')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        final departments =
            snapshot.data?.docs.map((doc) {
              final data = doc.data();
              final name = (data['name'] ?? doc.id).toString();
              return FilterChipOption(id: doc.id, label: name);
            }).toList() ??
            const <FilterChipOption>[];
        return FilterBar(
          state: filters,
          color: color,
          departmentOptions: departments,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final Color color;

  const _Header({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ShimmerBox(width: 58, height: 58, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, radius: 8),
                SizedBox(height: 8),
                ShimmerBox(width: 180, height: 12, radius: 8),
                SizedBox(height: 8),
                ShimmerBox(width: 110, height: 12, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  final Object? error;

  const _HistoryError({required this.error});

  @override
  Widget build(BuildContext context) {
    final message =
        error is FirebaseException &&
            (error as FirebaseException).code == 'permission-denied'
        ? 'Access denied. Please sign in again.'
        : 'Could not load scans.';
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: message,
      subtitle: '$error',
    );
  }
}

class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final PortalHistoryMode mode;
  final Color color;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _ScanCard({
    required this.data,
    required this.mode,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = _timestamp(data);
    return Dismissible(
      key: ValueKey(data['id'] ?? data['scanId'] ?? '$timestamp'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF6B6B),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              _Thumb(url: data['imageUrl'], path: data['imagePath']),
              const SizedBox(width: 12),
              Expanded(
                child: mode == PortalHistoryMode.customer
                    ? _CustomerCardBody(data: data, timestamp: timestamp)
                    : _VenueCardBody(data: data, timestamp: timestamp),
              ),
              const SizedBox(width: 8),
              mode == PortalHistoryMode.customer
                  ? RiskBadge(_riskLevel(data))
                  : _PercentBadge(
                      value: _contaminationRisk(data),
                      color: color,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const _CustomerCardBody({required this.data, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dishName(data),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text('${_calories(data).toStringAsFixed(0)} kcal', style: _subStyle()),
        const SizedBox(height: 6),
        Text(_formatRelative(timestamp), style: _subStyle()),
      ],
    );
  }
}

class _VenueCardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const _VenueCardBody({required this.data, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final department = (data['departmentId'] ?? '').toString();
    final zone = (data['zone'] ?? 'Kitchen').toString();
    final staffName = (data['staffName'] ?? 'Staff').toString();
    final contaminationPct = _contaminationRisk(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dishName(data),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '$zone · $staffName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _subStyle(),
        ),
        const SizedBox(height: 6),
        Text(
          '${contaminationPct.toStringAsFixed(1)}% contamination · ${_formatRelative(timestamp)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _subStyle(),
        ),
        if (department.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DepartmentChip(label: department),
        ],
      ],
    );
  }
}

class _VenueScanDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final PortalHistoryMode mode;

  const _VenueScanDetails({required this.data, required this.mode});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['imageUrl'] as String?)?.trim() ?? '';
    final zone = (data['zone'] ?? 'Kitchen').toString();
    final staffName = (data['staffName'] ?? 'Staff').toString();
    final freshnessStatus = _freshnessStatus(data);
    final freshnessConfidence = _freshnessConfidence(data);
    final wasteKg = _wasteKg(data);
    final contaminationPct = _contaminationRisk(data);
    final cleanPct = _cleanPct(data);
    final riskLevel = _riskLevel(data);
    final compostablePct = (data['compostable_pct'] as double?) ?? 0.0;
    final nonCompostPct = (data['non_compostable_pct'] as double?) ?? 0.0;
    final compostableKg = (data['compostable_kg'] as double?) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiskBadge(riskLevel),
              const Spacer(),
              Text(zone, style: _subStyle()),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _dishName(data),
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            staffName,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B5A60),
            ),
          ),
          if (mode == PortalHistoryMode.hotel &&
              (data['departmentId'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _DepartmentChip(label: (data['departmentId'] ?? '').toString()),
          ],
          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerBox(
                  width: double.infinity,
                  height: 180,
                  radius: 14,
                ),
                errorWidget: (_, _, _) => Container(
                  height: 180,
                  color: const Color(0xFFF2F2F2),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Contamination',
            accent: contaminationPct > 50
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF06D6A0),
            rows: [
              _DetailRowData(
                'Risk level',
                '${contaminationPct.toStringAsFixed(1)}%',
              ),
              _DetailRowData('Clean', '${cleanPct.toStringAsFixed(1)}%'),
              _DetailRowData('Detections', '${_detectionCount(data)}'),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Freshness',
            accent: freshnessStatus == 'fresh'
                ? const Color(0xFF8FD14F)
                : const Color(0xFFFFD166),
            rows: [
              _DetailRowData('Status', _freshnessLabel(freshnessStatus)),
              _DetailRowData(
                'Confidence',
                '${freshnessConfidence.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailSection(
            title: 'Waste estimate',
            accent: const Color(0xFF5C7A3E),
            rows: [
              _DetailRowData(
                'Estimated waste',
                '${wasteKg.toStringAsFixed(3)} kg',
              ),
            ],
          ),
          if (compostablePct > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FAF0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF8FD14F).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF5C7A3E),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Compost Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C7A3E),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CompostChip(
                        label: 'Compostable',
                        value: '${compostablePct.toStringAsFixed(1)}%',
                        color: const Color(0xFF8FD14F),
                      ),
                      const SizedBox(width: 8),
                      _CompostChip(
                        label: 'Non-Compost.',
                        value: '${nonCompostPct.toStringAsFixed(1)}%',
                        color: const Color(0xFFFF6B6B),
                      ),
                      const SizedBox(width: 8),
                      _CompostChip(
                        label: 'Saved',
                        value: '${compostableKg.toStringAsFixed(2)} kg',
                        color: const Color(0xFF45C4B0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<_DetailRowData> rows;

  const _DetailSection({
    required this.title,
    required this.accent,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => _DetailRow(row: row)),
        ],
      ),
    );
  }
}

class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData(this.label, this.value);
}

class _DetailRow extends StatelessWidget {
  final _DetailRowData row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B5A60),
              ),
            ),
          ),
          Text(
            row.value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DepartmentChip extends StatelessWidget {
  final String label;

  const _DepartmentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F1FB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 10)),
      ),
    );
  }
}

class _CompostChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompostChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final dynamic url;
  final dynamic path;

  const _Thumb({this.url, this.path});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (url ?? '').toString().trim();
    final imagePath = (path ?? '').toString().trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 58,
        height: 58,
        color: const Color(0xFFEDE9FE),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ShimmerBox(width: 58, height: 58, radius: 12),
                errorWidget: (_, _, _) => const Icon(Icons.image_outlined),
              )
            : imagePath.isEmpty || kIsWeb
            ? const Icon(Icons.image_outlined)
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.image_outlined),
              ),
      ),
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final double value;
  final Color color;

  const _PercentBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${value.toStringAsFixed(0)}%',
        style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

TextStyle _subStyle() =>
    GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B5A60));

String _dishName(Map<String, dynamic> data) {
  final results = data['results'];
  if (results is Map &&
      (results['dishName'] as String?)?.trim().isNotEmpty == true) {
    return (results['dishName'] as String).trim();
  }
  final result = data['result'];
  if (result is Map &&
      (result['dishName'] as String?)?.trim().isNotEmpty == true) {
    return (result['dishName'] as String).trim();
  }
  final root = (data['dishName'] ?? data['name'] ?? '').toString().trim();
  return root.isEmpty ? 'Unknown dish' : root;
}

String _riskLevel(Map<String, dynamic> data) {
  final root = data['riskLevel'];
  final results = data['results'];
  final nested = results is Map ? results['riskLevel'] : null;
  final result = data['result'];
  final legacy = result is Map ? result['overallRisk'] : null;
  final risk = (root ?? nested ?? legacy ?? 'safe').toString().toLowerCase();
  if (risk == 'high') return 'danger';
  if (risk == 'moderate') return 'warning';
  if (risk == 'low') return 'safe';
  return risk;
}

int _riskRank(Map<String, dynamic> data) {
  switch (_riskLevel(data)) {
    case 'danger':
      return 3;
    case 'warning':
      return 2;
    case 'safe':
      return 1;
    default:
      return 0;
  }
}

DateTime _timestamp(Map<String, dynamic> data) {
  final raw = data['timestamp'];
  if (raw is Timestamp) return raw.toDate();
  final scanned = data['scannedAt'];
  if (scanned is Timestamp) return scanned.toDate();
  if (scanned is String) return DateTime.tryParse(scanned) ?? DateTime.now();
  return DateTime.now();
}

double _calories(Map<String, dynamic> data) {
  final results = data['results'];
  final nutrition = results is Map ? results['nutrition'] : null;
  if (nutrition is Map && nutrition['calories'] is num) {
    return (nutrition['calories'] as num).toDouble();
  }
  final result = data['result'];
  if (result is Map && result['calories'] is num) {
    return (result['calories'] as num).toDouble();
  }
  return 0;
}

double _contaminationRisk(Map<String, dynamic> data) {
  final flat = data['contamination_pct'];
  if (flat is num) return flat.toDouble();
  final results = data['results'];
  if (results is Map) {
    final contamination = results['contamination'];
    if (contamination is Map) {
      final pct = contamination['contaminatedPct'] ?? contamination['riskPct'];
      if (pct is num) return pct.toDouble();
    }
  }
  final root = data['contaminationPct'];
  if (root is num) return root.toDouble();
  return 0;
}

double _cleanPct(Map<String, dynamic> data) {
  final flat = data['clean_pct'];
  if (flat is num) return flat.toDouble();
  final results = data['results'];
  if (results is Map) {
    final contamination = results['contamination'];
    if (contamination is Map) {
      final value = contamination['clean_pct'] ?? contamination['cleanPct'];
      if (value is num) return value.toDouble();
    }
  }
  return 0;
}

String _freshnessStatus(Map<String, dynamic> data) {
  final flat = data['freshness_status'];
  if (flat is String && flat.trim().isNotEmpty) return flat;
  final results = data['results'];
  if (results is Map) {
    final freshness = results['freshness'];
    if (freshness is Map) {
      final value = freshness['status'];
      if (value is String && value.trim().isNotEmpty) return value;
    }
  }
  return 'unknown';
}

double _freshnessConfidence(Map<String, dynamic> data) {
  final flat = data['freshness_confidence'];
  if (flat is num) return flat.toDouble();
  final results = data['results'];
  if (results is Map) {
    final freshness = results['freshness'];
    if (freshness is Map) {
      final value = freshness['confidence'];
      if (value is num) return value.toDouble();
    }
  }
  return 0;
}

double _wasteKg(Map<String, dynamic> data) {
  final flat = data['waste_kg'];
  if (flat is num) return flat.toDouble();
  final results = data['results'];
  if (results is Map) {
    final waste = results['waste'];
    if (waste is Map) {
      final items = waste['detectedItems'];
      if (items is List) {
        return items.fold<double>(0.0, (sum, item) {
          if (item is Map) {
            return sum + ((item['quantityKg'] as num?)?.toDouble() ?? 0.0);
          }
          return sum;
        });
      }
      final value = waste['estimatedWasteKg'];
      if (value is num) return value.toDouble();
    }
  }
  return 0;
}

int _detectionCount(Map<String, dynamic> data) {
  final flat = data['detection_count'];
  if (flat is num) return flat.toInt();
  final results = data['results'];
  if (results is Map) {
    final contamination = results['contamination'];
    if (contamination is Map) {
      final value = contamination['detection_count'];
      if (value is num) return value.toInt();
      final detections = contamination['detections'];
      if (detections is List) return detections.length;
    }
  }
  return 0;
}

String _freshnessLabel(String status) {
  switch (status.toLowerCase()) {
    case 'fresh':
      return 'Fresh';
    case 'not_fresh':
    case 'spoiled':
      return 'Not fresh';
    case 'expiring':
      return 'Expiring soon';
    default:
      return 'Unknown';
  }
}

String _formatRelative(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today ${DateFormat.Hm().format(date)}';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}
