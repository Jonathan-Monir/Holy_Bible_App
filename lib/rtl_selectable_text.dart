// lib/rtl_selectable_text.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class RTLSelectableRichText extends StatefulWidget {
  final TextSpan textSpan;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Function(String selectedText, TextSelection selection)? onHighlightRangeSelected;
  final Function(String selectedText, TextSelection selection)? onUnderlineRangeSelected;
  final Function(String selectedText, TextSelection selection)? onSelectionChanged;
  final Widget Function(BuildContext, String selectedText, VoidCallback onCopy, VoidCallback onHighlight, VoidCallback onUnderline, VoidCallback closeMenu)? contextMenuBuilder;

  const RTLSelectableRichText({
    super.key,
    required this.textSpan,
    this.textAlign,
    this.textDirection,
    this.onHighlightRangeSelected,
    this.onUnderlineRangeSelected,
    this.onSelectionChanged,
    this.contextMenuBuilder,
  });

  @override
  State<RTLSelectableRichText> createState() => _RTLSelectableRichTextState();
}

class _RTLSelectableRichTextState extends State<RTLSelectableRichText> {
  TextSelection _selection = const TextSelection.collapsed(offset: 0);
  bool _isSelecting = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _textKey = GlobalKey();
  
  late TextPainter _textPainter;
  late String _fullText;
  
  @override
  void initState() {
    super.initState();
    _updateTextPainter();
  }
  
  @override
  void didUpdateWidget(RTLSelectableRichText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textSpan != widget.textSpan) {
      _updateTextPainter();
    }
  }
  
  void _updateTextPainter() {
    _fullText = widget.textSpan.toPlainText();
    _textPainter = TextPainter(
      text: widget.textSpan,
      textDirection: widget.textDirection ?? TextDirection.rtl,
      textAlign: widget.textAlign ?? TextAlign.right,
    );
  }
  
  @override
  void dispose() {
    _removeOverlay();
    _textPainter.dispose();
    super.dispose();
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  Offset _getOffsetFromPosition(Offset globalPosition) {
    final RenderBox? renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.globalToLocal(globalPosition);
  }
  
  int _getTextPositionFromOffset(Offset localOffset) {
    final Size size = _textKey.currentContext?.size ?? Size.zero;
    _textPainter.layout(maxWidth: size.width);
    
    final TextPosition position = _textPainter.getPositionForOffset(localOffset);
    return position.offset;
  }
  
  void _handleTapDown(TapDownDetails details) {
    final localOffset = _getOffsetFromPosition(details.globalPosition);
    final textPosition = _getTextPositionFromOffset(localOffset);
    
    setState(() {
      _selection = TextSelection.collapsed(offset: textPosition);
      _isSelecting = false;
    });
    
    _removeOverlay();
  }
  
  void _handleLongPressStart(LongPressStartDetails details) {
    final localOffset = _getOffsetFromPosition(details.globalPosition);
    final textPosition = _getTextPositionFromOffset(localOffset);
    
    // Select word at position
    final wordBoundary = _getWordBoundary(textPosition);
    
    setState(() {
      _selection = wordBoundary;
      _isSelecting = true;
    });
    
    _showContextMenu(details.globalPosition);
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }
  
  void _handlePanStart(DragStartDetails details) {
    if (!_isSelecting) return;
    
    final localOffset = _getOffsetFromPosition(details.globalPosition);
    final textPosition = _getTextPositionFromOffset(localOffset);
    
    setState(() {
      _selection = TextSelection(
        baseOffset: _selection.baseOffset,
        extentOffset: textPosition,
      );
    });
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isSelecting) return;
    
    final localOffset = _getOffsetFromPosition(details.globalPosition);
    final textPosition = _getTextPositionFromOffset(localOffset);
    
    setState(() {
      _selection = TextSelection(
        baseOffset: _selection.baseOffset,
        extentOffset: textPosition,
      );
    });
    
    final selectedText = _getSelectedText();
    widget.onSelectionChanged?.call(selectedText, _selection);
  }
  
  void _handlePanEnd(DragEndDetails details) {
    if (!_isSelecting || _selection.isCollapsed) return;
    
    // Show context menu at the end of selection
    final RenderBox? renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Size size = _textKey.currentContext?.size ?? Size.zero;
      _textPainter.layout(maxWidth: size.width);
      
      final selectionEnd = _textPainter.getOffsetForCaret(
        TextPosition(offset: _selection.extentOffset),
        Rect.zero,
      );
      final globalPosition = renderBox.localToGlobal(selectionEnd);
      _showContextMenu(globalPosition);
    }
  }
  
  TextSelection _getWordBoundary(int position) {
    final text = _fullText;
    
    // Find word start
    int start = position;
    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }
    
    // Find word end
    int end = position;
    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }
    
    return TextSelection(baseOffset: start, extentOffset: end);
  }
  
  bool _isWordBoundary(String char) {
    return char == ' ' || char == '\n' || char == '\t' || 
           char == '.' || char == ',' || char == '!' || char == '?' ||
           char == '؟' || char == '،' || char == '؛'; // Arabic punctuation
  }
  
  String _getSelectedText() {
    if (_selection.isCollapsed) return '';
    final start = math.min(_selection.start, _selection.end);
    final end = math.max(_selection.start, _selection.end);
    return _fullText.substring(start, end);
  }
  
  void _showContextMenu(Offset globalPosition) {
    if (_selection.isCollapsed) return;
    
    _removeOverlay();
    
    final selectedText = _getSelectedText();
    if (selectedText.isEmpty) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: globalPosition.dx - 100,
        top: globalPosition.dy - 60,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: widget.contextMenuBuilder?.call(
            context,
            selectedText,
            _handleCopy,
            _handleHighlight,
            _handleUnderline,
            _clearSelection,
          ) ?? _buildDefaultContextMenu(selectedText),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  Widget _buildDefaultContextMenu(String selectedText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _handleCopy,
            child: const Text('نسخ'),
          ),
          TextButton(
            onPressed: _handleHighlight,
            child: const Text('تمييز'),
          ),
          TextButton(
            onPressed: _handleUnderline,
            child: const Text('تسطير'),
          ),
        ],
      ),
    );
  }
  
  void _handleCopy() {
    final selectedText = _getSelectedText();
    if (selectedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: selectedText));
    }
    _clearSelection();
  }
  
  void _handleHighlight() {
    final selectedText = _getSelectedText();
    widget.onHighlightRangeSelected?.call(selectedText, _selection);
    _clearSelection();
  }
  
  void _handleUnderline() {
    final selectedText = _getSelectedText();
    widget.onUnderlineRangeSelected?.call(selectedText, _selection);
    _clearSelection();
  }
  
  void _clearSelection() {
    setState(() {
      _selection = const TextSelection.collapsed(offset: 0);
      _isSelecting = false;
    });
    _removeOverlay();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onLongPressStart: _handleLongPressStart,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        key: _textKey,
        width: double.infinity,
        child: CustomPaint(
          painter: _RTLTextPainter(
            textSpan: widget.textSpan,
            selection: _selection,
            textDirection: widget.textDirection ?? TextDirection.rtl,
            textAlign: widget.textAlign ?? TextAlign.right,
          ),
        ),
      ),
    );
  }
}

class _RTLTextPainter extends CustomPainter {
  final TextSpan textSpan;
  final TextSelection selection;
  final TextDirection textDirection;
  final TextAlign textAlign;
  
  late final TextPainter _textPainter;
  
  _RTLTextPainter({
    required this.textSpan,
    required this.selection,
    required this.textDirection,
    required this.textAlign,
  }) {
    _textPainter = TextPainter(
      text: textSpan,
      textDirection: textDirection,
      textAlign: textAlign,
    );
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    _textPainter.layout(maxWidth: size.width);
    
    // Draw selection background
    if (!selection.isCollapsed) {
      final List<TextBox> boxes = _textPainter.getBoxesForSelection(selection);
      final Paint selectionPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3);
      
      for (final box in boxes) {
        canvas.drawRect(box.toRect(), selectionPaint);
      }
    }
    
    // Draw text
    _textPainter.paint(canvas, Offset.zero);
  }
  
  @override
  bool shouldRepaint(_RTLTextPainter oldDelegate) {
    return oldDelegate.textSpan != textSpan ||
           oldDelegate.selection != selection;
  }
}
