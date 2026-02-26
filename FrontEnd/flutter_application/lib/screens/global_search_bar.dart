import 'dart:async';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconColor;

  /// Full route pushed on tap, e.g. '/abc123/faculty/leave'
  final String route;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.route,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT DATA SOURCE  — implement once per screen
// ─────────────────────────────────────────────────────────────────────────────

abstract class SearchDataSource {
  Future<List<SearchResult>> search(String query);
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class GlobalSearchBar extends StatefulWidget {
  final SearchDataSource? dataSource;

  /// Called with the full route string when a result is tapped.
  /// Typically: (route) => context.push(route)
  final void Function(String route)? onNavigate;

  final String hintText;
  final bool isDarkMode;
  final double height;
  final double maxDropdownHeight;

  const GlobalSearchBar({
    super.key,
    this.dataSource,
    this.onNavigate,
    this.hintText = 'Search pages, courses, actions...',
    this.isDarkMode = false,
    this.height = 46,
    this.maxDropdownHeight = 420,
  });

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  bool _isLoading = false;
  bool _hasFocus = false;
  List<SearchResult> _results = [];
  String _lastQuery = '';

  // ── Theme helpers ─────────────────────────────────────────────────────────
  Color get _bgField =>
      widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  Color get _bgCard =>
      widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _textPrimary =>
      widget.isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _textSecondary =>
      widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _border =>
      widget.isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
  static const Color _accent = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty) _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
    }
  }

  void _onChanged(String raw) {
    final query = raw.trim();
    if (query == _lastQuery) return;
    _lastQuery = query;
    _debounce?.cancel();

    if (query.isEmpty) {
      _removeOverlay();
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _showOverlay();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    if (widget.dataSource == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await widget.dataSource!.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
      _refreshOverlay();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _controller.clear();
    _lastQuery = '';
    _removeOverlay();
    setState(() {
      _results = [];
      _isLoading = false;
    });
  }

  void _onResultTap(SearchResult result) {
    _removeOverlay();
    _focusNode.unfocus();
    _controller.clear();
    _lastQuery = '';
    setState(() => _results = []);
    widget.onNavigate?.call(result.route);
  }

  // ── Overlay ───────────────────────────────────────────────────────────────
  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _refreshOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else if (_isLoading || _results.isNotEmpty) {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(builder: (_) {
      final box = context.findRenderObject() as RenderBox?;
      final width = box?.size.width ?? 320;
      return Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, widget.height + 6),
          child: _SearchDropdown(
            isDarkMode: widget.isDarkMode,
            isLoading: _isLoading,
            results: _results,
            query: _lastQuery,
            maxHeight: widget.maxDropdownHeight,
            cardColor: _bgCard,
            borderColor: _border,
            textPrimary: _textPrimary,
            textSecondary: _textSecondary,
            onTap: _onResultTap,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: widget.height,
        decoration: BoxDecoration(
          color: _bgField,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFocus ? _accent : _border,
            width: _hasFocus ? 1.5 : 1.0,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isLoading
                  ? SizedBox(
                      key: const ValueKey('spinner'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _textSecondary,
                      ),
                    )
                  : Icon(
                      key: const ValueKey('icon'),
                      Icons.search_rounded,
                      color: _hasFocus ? _accent : _textSecondary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                style: TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: _textSecondary),
                ),
              )
            else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class _SearchDropdown extends StatelessWidget {
  final bool isDarkMode;
  final bool isLoading;
  final List<SearchResult> results;
  final String query;
  final double maxHeight;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final void Function(SearchResult) onTap;

  const _SearchDropdown({
    required this.isDarkMode,
    required this.isLoading,
    required this.results,
    required this.query,
    required this.maxHeight,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.13),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, size: 20, color: textSecondary),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'No results for "$query"',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // Group by category, preserving insertion order
    final grouped = <String, List<SearchResult>>{};
    for (final r in results) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      children: [
        for (final entry in grouped.entries) ...[
          _SectionHeader(label: entry.key, color: textSecondary),
          for (final r in entry.value)
            _ResultTile(
              result: r,
              query: query,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDarkMode: isDarkMode,
              onTap: () => onTap(r),
            ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final String query;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.query,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: result.iconColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: result.iconColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(result.icon, color: result.iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightText(
                      text: result.title,
                      query: query,
                      base: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      highlight: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                        backgroundColor: Color(0x194F46E5),
                      ),
                    ),
                    if (result.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Highlights every occurrence of [query] inside [text]
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle base;
  final TextStyle highlight;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: base, overflow: TextOverflow.ellipsis);
    }
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final spans = <TextSpan>[];
    int cursor = 0;
    while (cursor < text.length) {
      final idx = lower.indexOf(lowerQ, cursor);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(cursor), style: base));
        break;
      }
      if (idx > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: highlight,
      ));
      cursor = idx + query.length;
    }
    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}