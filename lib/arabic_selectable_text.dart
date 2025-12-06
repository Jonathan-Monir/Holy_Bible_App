// lib/arabic_selectable_text.dart

import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class _TextSpanEditingController extends TextEditingController {
  _TextSpanEditingController({required TextSpan textSpan})
    : _textSpan = textSpan,
      super(text: textSpan.toPlainText(includeSemanticsLabels: false));

  final TextSpan _textSpan;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(style: style, children: <TextSpan>[_textSpan]);
  }

  @override
  set text(String? newText) {
    throw UnimplementedError();
  }
}

/// A wrapper around SelectableText that fixes Arabic double-tap selection issues.
class FixedSelectableText extends StatefulWidget {
  const FixedSelectableText(
    String this.data, {
    super.key,
    this.focusNode,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.textScaler,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
    this.maxLines,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.selectionColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onTap,
    this.scrollPhysics,
    this.scrollBehavior,
    this.semanticsLabel,
    this.textHeightBehavior,
    this.textWidthBasis,
    this.onSelectionChanged,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.magnifierConfiguration,
  })  : textSpan = null,
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        );

  const FixedSelectableText.rich(
    TextSpan this.textSpan, {
    super.key,
    this.focusNode,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.textScaler,
    this.showCursor = false,
    this.autofocus = false,
    this.minLines,
    this.maxLines,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.selectionColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onTap,
    this.scrollPhysics,
    this.scrollBehavior,
    this.semanticsLabel,
    this.textHeightBehavior,
    this.textWidthBasis,
    this.onSelectionChanged,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.magnifierConfiguration,
  })  : data = null,
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        );

  final String? data;
  final TextSpan? textSpan;
  final FocusNode? focusNode;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextScaler? textScaler;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final bool showCursor;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Color? selectionColor;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final DragStartBehavior dragStartBehavior;
  final GestureTapCallback? onTap;
  final ScrollPhysics? scrollPhysics;
  final ScrollBehavior? scrollBehavior;
  final String? semanticsLabel;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis? textWidthBasis;
  final SelectionChangedCallback? onSelectionChanged;
  final EditableTextContextMenuBuilder? contextMenuBuilder;
  final TextMagnifierConfiguration? magnifierConfiguration;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
        editableTextState: editableTextState);
  }

  @override
  State<FixedSelectableText> createState() => _FixedSelectableTextState();
}

class _FixedSelectableTextState extends State<FixedSelectableText>
    implements TextSelectionGestureDetectorBuilderDelegate {
  EditableTextState? get _editableText => editableTextKey.currentState;
  late TextEditingController _controller;
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode(skipTraversal: true));
  bool _showSelectionHandles = false;
  late _FixedSelectableTextSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  late bool forcePressEnabled;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.enableInteractiveSelection;
  // End of API for TextSelectionGestureDetectorBuilderDelegate.

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _FixedSelectableTextSelectionGestureDetectorBuilder(state: this);
    _controller = widget.textSpan != null
        ? _TextSpanEditingController(textSpan: widget.textSpan!)
        : TextEditingController(text: widget.data ?? '');
    _controller.addListener(_onControllerChanged);
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(FixedSelectableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data ||
        widget.textSpan != oldWidget.textSpan) {
      _controller.dispose();
      _controller = widget.textSpan != null
          ? _TextSpanEditingController(textSpan: widget.textSpan!)
          : TextEditingController(text: widget.data ?? '');
      _controller.addListener(_onControllerChanged);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _focusNode)
          ?.removeListener(_handleFocusChanged);
      (widget.focusNode ?? _focusNode)?.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final bool showSelectionHandles =
        !_effectiveFocusNode.hasFocus || !_controller.selection.isCollapsed;
    if (showSelectionHandles == _showSelectionHandles) {
      return;
    }
    setState(() {
      _showSelectionHandles = showSelectionHandles;
    });
  }

  void _handleFocusChanged() {
    if (!_effectiveFocusNode.hasFocus &&
        SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      // Preserve selection on focus loss
    }
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
    widget.onSelectionChanged?.call(selection, cause);
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }
    if (_controller.selection.isCollapsed) return false;
    if (cause == SelectionChangedCause.keyboard) return false;
    if (cause == SelectionChangedCause.longPress) return true;
    if (_controller.text.isNotEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DefaultSelectionStyle selectionStyle =
        DefaultSelectionStyle.of(context);
    final FocusNode focusNode = _effectiveFocusNode;

    TextSelectionControls? textSelectionControls = widget.selectionControls;
    final bool paintCursorAboveText;
    final bool cursorOpacityAnimates;
    Offset? cursorOffset;
    final Color cursorColor;
    final Color selectionColor;
    Radius? cursorRadius = widget.cursorRadius;
    const int iOSHorizontalOffset = -2;

    switch (theme.platform) {
      case TargetPlatform.iOS:
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        forcePressEnabled = true;
        textSelectionControls ??= cupertinoTextSelectionHandleControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor = widget.cursorColor ??
            selectionStyle.cursorColor ??
            cupertinoTheme.primaryColor;
        selectionColor = selectionStyle.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context), 0);
        break;

      case TargetPlatform.macOS:
        final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context);
        forcePressEnabled = false;
        textSelectionControls ??= cupertinoDesktopTextSelectionHandleControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor = widget.cursorColor ??
            selectionStyle.cursorColor ??
            cupertinoTheme.primaryColor;
        selectionColor = selectionStyle.selectionColor ??
            cupertinoTheme.primaryColor.withOpacity(0.40);
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.devicePixelRatioOf(context), 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        forcePressEnabled = false;
        textSelectionControls ??= materialTextSelectionHandleControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor = widget.cursorColor ??
            selectionStyle.cursorColor ??
            theme.colorScheme.primary;
        selectionColor = selectionStyle.selectionColor ??
            theme.colorScheme.primary.withOpacity(0.40);
        break;
    }

  return _selectionGestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: EditableText(
        key: editableTextKey,
        controller: _controller,
        focusNode: focusNode,
        style: widget.style ?? theme.textTheme.bodyMedium!,
        readOnly: true,
        strutStyle: widget.strutStyle ?? StrutStyle(
          fontSize: (widget.style?.fontSize ?? theme.textTheme.bodyMedium!.fontSize ?? 14.0),
          height: 1.8,  // This controls the actual line spacing
          forceStrutHeight: true,  // This forces consistent line height
        ),
        textScaler: widget.textScaler ?? TextScaler.noScaling,
        textDirection: widget.textDirection,
        // strutStyle: widget.strutStyle,
        textAlign: widget.textAlign ?? TextAlign.start,
        // textScaler: widget.textScaler ?? TextScaler.noScaling,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        autofocus: widget.autofocus,
        showCursor: widget.showCursor,
        cursorWidth: widget.cursorWidth,
        cursorHeight: widget.cursorHeight,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        selectionColor: selectionColor,
        selectionControls:
            widget.enableInteractiveSelection ? textSelectionControls : null,
        onSelectionChanged: _handleSelectionChanged,
        rendererIgnoresPointer: true,
        cursorOffset: cursorOffset,
        paintCursorAboveText: paintCursorAboveText,
        backgroundCursorColor: CupertinoColors.inactiveGray,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        dragStartBehavior: widget.dragStartBehavior,
        scrollPhysics: widget.scrollPhysics,
        scrollBehavior: widget.scrollBehavior,
        selectionHeightStyle: widget.selectionHeightStyle,
        selectionWidthStyle: widget.selectionWidthStyle,
        contextMenuBuilder: widget.contextMenuBuilder,
        magnifierConfiguration: widget.magnifierConfiguration ??
            TextMagnifier.adaptiveMagnifierConfiguration,
      ),
    );
  }
}

// --- The Core Fix: Custom Gesture Detector Builder ---

class _FixedSelectableTextSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  _FixedSelectableTextSelectionGestureDetectorBuilder({
    required _FixedSelectableTextState state,
  })  : _state = state,
        super(delegate: state);

  final _FixedSelectableTextState _state;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    if (!delegate.selectionEnabled) {
      return;
    }
    super.onSingleTapUp(details);
    _state.widget.onTap?.call();
  }

  @override
  void onDoubleTapDown(TapDragDownDetails details) {
    if (delegate.selectionEnabled) {
      final renderEditable =
          _state.editableTextKey.currentState?.renderEditable;
      if (renderEditable != null) {
        // 1. Get the position of the tap in the text
        final textPosition =
            renderEditable.getPositionForPoint(details.globalPosition);
        final text = renderEditable.text?.toPlainText() ?? '';

        // 2. Check if the text at this position is likely Arabic (or RTL)
        // Arabic Unicode range: \u0600-\u06FF, \u0750-\u077F, etc.
        if (_isArabicOrRTL(text, textPosition.offset)) {
          // 3. Manually calculate word boundary to avoid "whole line" selection bug
          final wordRange = _getManualWordRange(text, textPosition.offset);
          
          if (wordRange.isValid) {
            // Fixed: Access the controller directly via the state object
            _state._controller.selection =
                TextSelection(
                    baseOffset: wordRange.start, extentOffset: wordRange.end);
            
            // Show toolbar immediately
            if (_state._shouldShowSelectionHandles(SelectionChangedCause.tap)) {
                 _state.editableTextKey.currentState?.showToolbar();
            }
            return; // Skip standard behavior
          }
        }
      }
    }
    // Fallback to standard behavior for non-Arabic text
    super.onDoubleTapDown(details);
  }

  bool _isArabicOrRTL(String text, int offset) {
    if (text.isEmpty || offset >= text.length || offset < 0) return false;
    // Check surrounding characters for Arabic block
    final int charCode = text.codeUnitAt(offset);
    return (charCode >= 0x0600 && charCode <= 0x06FF) || // Arabic
           (charCode >= 0x0750 && charCode <= 0x077F) || // Arabic Supplement
           (charCode >= 0x08A0 && charCode <= 0x08FF) || // Arabic Extended-A
           (charCode >= 0xFB50 && charCode <= 0xFDFF) || // Arabic Pres. Forms-A
           (charCode >= 0xFE70 && charCode <= 0xFEFF);   // Arabic Pres. Forms-B
  }

  TextRange _getManualWordRange(String text, int offset) {
    if (text.isEmpty) return TextRange.empty;
    
    // Safety check for offset
    int safeOffset = offset.clamp(0, text.length - 1);
    
    // If we landed on a space, try to snap to the previous or next word
    if (_isSeparator(text[safeOffset])) {
        if (safeOffset > 0 && !_isSeparator(text[safeOffset - 1])) {
            safeOffset--;
        } else if (safeOffset < text.length - 1 && !_isSeparator(text[safeOffset + 1])) {
            safeOffset++;
        }
    }

    int start = safeOffset;
    int end = safeOffset;

    // Expand Left
    while (start > 0 && !_isSeparator(text[start - 1])) {
      start--;
    }
    // Expand Right
    while (end < text.length && !_isSeparator(text[end])) {
      end++;
    }

    return TextRange(start: start, end: end);
  }

  bool _isSeparator(String char) {
    // Define separators: Spaces, Newlines, Tabs, and common Punctuation
    final RegExp separatorRegex = RegExp(r'[\s\p{P}]', unicode: true); 
    return separatorRegex.hasMatch(char);
  }
}
