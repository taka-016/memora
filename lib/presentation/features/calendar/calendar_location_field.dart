import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/location_providers.dart';

class CalendarLocationField extends ConsumerStatefulWidget {
  const CalendarLocationField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  ConsumerState<CalendarLocationField> createState() =>
      _CalendarLocationFieldState();
}

class _CalendarLocationFieldState extends ConsumerState<CalendarLocationField> {
  bool _searching = false;
  String? _message;
  List<LocationCandidateDto> _candidates = [];

  Future<void> _search() async {
    final keyword = widget.controller.text;
    if (_searching || !widget.enabled || keyword.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _message = null;
      _candidates = [];
    });
    try {
      final candidates = await ref
          .read(searchLocationsUsecaseProvider)
          .execute(keyword);
      if (!mounted || widget.controller.text != keyword) return;
      setState(() {
        _candidates = candidates;
        _message = candidates.isEmpty ? '検索結果がありません' : null;
      });
    } catch (_) {
      if (!mounted || widget.controller.text != keyword) return;
      setState(() => _message = '場所を検索できませんでした。再検索してください');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = ref
        .watch(appCapabilitiesProvider)
        .availability(AppFeature.locationSearch)
        .isAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          textInputAction: canSearch ? TextInputAction.search : null,
          decoration: InputDecoration(
            labelText: '場所名',
            border: const OutlineInputBorder(),
            suffixIcon: canSearch
                ? IconButton(
                    tooltip: '場所を検索',
                    icon: const Icon(Icons.search),
                    onPressed:
                        widget.enabled &&
                            !_searching &&
                            widget.controller.text.trim().isNotEmpty
                        ? _search
                        : null,
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _candidates = [];
              _message = null;
            });
            widget.onChanged(value);
          },
          onFieldSubmitted: canSearch ? (_) => _search() : null,
        ),
        if (_searching) const LinearProgressIndicator(),
        if (_message != null) Text(_message!),
        for (final candidate in _candidates)
          ListTile(
            title: Text(candidate.name),
            subtitle: Text(candidate.address),
            onTap: !widget.enabled
                ? null
                : () {
                    setState(() {
                      widget.controller.text = candidate.name;
                      _candidates = [];
                      _message = null;
                    });
                    widget.onChanged(candidate.name);
                  },
          ),
      ],
    );
  }
}
