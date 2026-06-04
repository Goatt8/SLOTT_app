import 'package:flutter/material.dart';
import 'package:bababam_app/Helper/ui_presets.dart';

class PostTextStylePickerDialog extends StatefulWidget {
  const PostTextStylePickerDialog({super.key, required this.initialSelection});

  final PostTextStyleSelection initialSelection;

  @override
  State<PostTextStylePickerDialog> createState() =>
      _PostTextStylePickerDialogState();
}

class _PostTextStylePickerDialogState extends State<PostTextStylePickerDialog> {
  late PostTextStyleSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppAccentColor.fromColorId(_selection.colorId);

    return Dialog(
      backgroundColor: const Color(0xD6242428),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(label: '시간 폰트 선택하기'),
              const SizedBox(height: 10),
              _buildHourFontGrid(),
              const SizedBox(height: 20),
              _SectionTitle(label: '폰트 선택하기'),
              const SizedBox(height: 10),
              _buildFontGrid(),
              const SizedBox(height: 20),
              _SectionTitle(label: '색상 선택하기'),
              const SizedBox(height: 10),
              _buildColorGrid(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(_selection),
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontGrid() {
    final accentColor = AppAccentColor.fromColorId(_selection.colorId);

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 9,
      mainAxisSpacing: 9,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: AppTypography.postFontPresets.map((preset) {
        final isSelected = _selection.fontId == preset.id;
        return _PickerTile(
          isSelected: isSelected,
          selectedColor: accentColor,
          onTap: () {
            setState(() {
              _selection = _selection.copyWith(fontId: preset.id);
            });
          },
          child: Text(
            'Gg',
            style: AppTypography.postCommentOverlay(
              selection: _selection.copyWith(fontId: preset.id),
              fontSize: 23,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorGrid() {
    final accentColor = AppAccentColor.fromColorId(_selection.colorId);

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: AppTypography.postColorPresets.map((preset) {
        final isSelected = _selection.colorId == preset.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selection = _selection.copyWith(colorId: preset.id);
            });
          },
          child: Container(
            width: 44,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? accentColor : Colors.white10,
                width: isSelected ? 1.4 : 1,
              ),
              gradient: preset.colors.length > 1
                  ? LinearGradient(colors: preset.colors)
                  : null,
              color: preset.colors.length == 1 ? preset.colors.first : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHourFontGrid() {
    final accentColor = AppAccentColor.fromColorId(_selection.colorId);

    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 9,
      mainAxisSpacing: 9,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: AppTypography.hourFontPresets.map((preset) {
        final isSelected = _selection.hourFontId == preset.id;
        return _PickerTile(
          isSelected: isSelected,
          selectedColor: accentColor,
          onTap: () {
            setState(() {
              _selection = _selection.copyWith(hourFontId: preset.id);
            });
          },
          child: Text(
            preset.label,
            style: AppTypography.hourOverlay(
              fontId: preset.id,
              fontSize: 18,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.child,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final Widget child;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xB32B2B30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white10,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
