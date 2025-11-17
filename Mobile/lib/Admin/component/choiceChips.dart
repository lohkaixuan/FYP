import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable Choice Chips widget similar to FlutterFlowChoiceChips.
/// - options: list of labels
/// - multiselect: allow multiple selections (default false)
/// - initialSelected: initial selected labels
/// - onChanged: returns current List<String> selected values
class SimpleChoiceChips extends StatefulWidget {
  final List<String> options;
  final bool multiselect;
  final List<String>? initialSelected;
  final ValueChanged<List<String>>? onChanged;
  final double chipSpacing;

  const SimpleChoiceChips({
    Key? key,
    required this.options,
    this.multiselect = false,
    this.initialSelected,
    this.onChanged,
    this.chipSpacing = 8.0,
  }) : super(key: key);

  @override
  State<SimpleChoiceChips> createState() => _SimpleChoiceChipsState();
}

class _SimpleChoiceChipsState extends State<SimpleChoiceChips> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected != null
        ? List<String>.from(widget.initialSelected!)
        : <String>[];
    // If not multiselect and no initial, choose first as fallback to mimic your controller default
    if (!widget.multiselect && _selected.isEmpty && widget.options.isNotEmpty) {
      _selected = [widget.options.first];
    }
  }

  void _onTap(String value) {
    setState(() {
      if (widget.multiselect) {
        if (_selected.contains(value)) {
          _selected.remove(value);
        } else {
          _selected.add(value);
        }
      } else {
        if (_selected.contains(value)) {
          // keep it selected (or optionally deselect)
          // we'll keep it selected to match your initial behaviour
        } else {
          _selected = [value];
        }
      }
    });
    widget.onChanged?.call(List<String>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.chipSpacing,
      runSpacing: 6,
      alignment: WrapAlignment.start,
      children: widget.options.map((label) {
        final bool selected = _selected.contains(label);

        // Styles (match your original design)
        final Color selectedBg = const Color(0xFF105DFB);
        final Color unselectedBg = Colors.white;
        final TextStyle selectedTextStyle = GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
        final TextStyle unselectedTextStyle = GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5A5C60),
        );

        return ChoiceChip(
          label: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Text(
              label,
              style: selected ? selectedTextStyle : unselectedTextStyle,
            ),
          ),
          selected: selected,
          onSelected: (_) => _onTap(label),
          selectedColor: selectedBg,
          backgroundColor: unselectedBg,
          elevation: 0,
          pressElevation: 0,
          padding: EdgeInsets.zero, // we used label padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? selectedBg : const Color(0xFFE6E6E6),
            ),
          ),
        );
      }).toList(),
    );
  }
}
