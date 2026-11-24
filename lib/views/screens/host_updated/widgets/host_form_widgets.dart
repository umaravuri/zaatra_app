import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'host_components.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kBorder = Color(0xFFE2E2EC);
const Color _kMuted = Color(0xFFA0A0B2);

/// Shows a red error snackbar.
void showHostError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
  );
}

/// Standard page for the listing wizard: background, top bar, scrolling body
/// and a bottom button.
class HostFormPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String buttonText;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const HostFormPage({
    super.key,
    required this.title,
    required this.children,
    required this.onContinue,
    this.buttonText = 'Continue',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
              children: [
                HostTopBar(
                  title: title,
                  onBack: onBack ?? () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        ...children,
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: HostBottomButton(text: buttonText, onPressed: onContinue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bold question / section heading.
class HostQuestion extends StatelessWidget {
  final String text;
  final double topSpace;

  const HostQuestion(this.text, {super.key, this.topSpace = 22});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpace, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kInk,
          height: 1.35,
        ),
      ),
    );
  }
}

class HostRadioRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const HostRadioRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kPurple : _kMuted,
                  width: selected ? 7.0 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 14, color: _kInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostCheckRow extends StatelessWidget {
  final String title;
  final bool checked;
  final VoidCallback onTap;

  const HostCheckRow({
    super.key,
    required this.title,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: checked ? _kPurple : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: checked ? _kPurple : _kMuted, width: 1.5),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 14, color: _kInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A question answered with Yes / No.
class HostYesNo extends StatelessWidget {
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;

  const HostYesNo({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HostQuestion(question),
        HostRadioRow(title: 'Yes', selected: value, onTap: () => onChanged(true)),
        HostRadioRow(title: 'No', selected: !value, onTap: () => onChanged(false)),
      ],
    );
  }
}

/// A question where exactly one option is chosen. [selected] may be empty.
class HostSingleChoice extends StatelessWidget {
  final String? question;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const HostSingleChoice({
    super.key,
    this.question,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question != null) HostQuestion(question!),
        for (final o in options)
          HostRadioRow(title: o, selected: selected == o, onTap: () => onChanged(o)),
      ],
    );
  }
}

/// A question where any number of options can be ticked.
class HostMultiChoice extends StatelessWidget {
  final String? question;
  final List<String> options;
  final Set<String> selected;
  final VoidCallback onChanged; // call setState after the set changes

  const HostMultiChoice({
    super.key,
    this.question,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question != null) HostQuestion(question!),
        for (final o in options)
          HostCheckRow(
            title: o,
            checked: selected.contains(o),
            onTap: () {
              if (!selected.remove(o)) selected.add(o);
              onChanged();
            },
          ),
      ],
    );
  }
}

class HostTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const HostTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: numeric ? TextInputType.number : TextInputType.multiline,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: _kInk),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: _kMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(_kBorder),
        enabledBorder: border(_kBorder),
        focusedBorder: border(_kPurple, 1.5),
      ),
    );
  }
}


********************************************************************************
================================================================================
