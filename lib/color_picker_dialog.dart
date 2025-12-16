import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerBottomSheet extends StatefulWidget {
  final String title;
  final Color currentColor;
  
  const ColorPickerBottomSheet({
    super.key,
    required this.title,
    required this.currentColor,
  });

  @override
  State<ColorPickerBottomSheet> createState() => _ColorPickerBottomSheetState();
}

class _ColorPickerBottomSheetState extends State<ColorPickerBottomSheet> {
  late Color selectedColor;
  
  // Main preset colors
  final List<Color> presetColors = [
    Colors.yellow,
    Colors.lightGreen.shade300,
    Colors.lightBlue.shade300,
    Colors.pink.shade200,
    Colors.orange.shade300,
  ];
  
  @override
  void initState() {
    super.initState();
    selectedColor = widget.currentColor;
  }
  
  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = selectedColor;
        
        return AlertDialog(
          title: const Text('Pick a custom color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedColor = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Preset colors in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: presetColors.map((color) {
              final isSelected = selectedColor.value == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Custom color button
          OutlinedButton.icon(
            onPressed: _showCustomColorPicker,
            icon: const Icon(Icons.palette),
            label: const Text('Custom Color'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Preview',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Apply button
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedColor),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Apply Color'),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
