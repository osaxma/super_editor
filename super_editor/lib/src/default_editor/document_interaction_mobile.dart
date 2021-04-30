// ignore_for_file: omit_local_variable_types
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectableText;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:super_editor/src/core/document.dart';
import 'package:super_editor/src/core/document_layout.dart';
import 'package:super_editor/src/core/document_selection.dart';
import 'package:super_editor/src/core/edit_context.dart';
import 'package:super_editor/src/infrastructure/_logging.dart';
import 'package:super_editor/src/infrastructure/multi_tap_gesture.dart';
import 'package:super_editor/super_editor.dart';

import 'document_interaction.dart' show DocumentInteractor, DocumentKeyboardAction, ExecutionInstruction, SelectionType;
import 'text_tools.dart';

final _log = Logger(scope: 'softkeyboard_document_interaction.dart');

final isSoftKeyboard = (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// An Interactor Selector based on the platform.
class DefaultDocumentInteractor extends StatelessWidget {
  const DefaultDocumentInteractor({
    Key? key,
    required this.editContext,
    required this.keyboardActions,
    this.scrollController,
    this.focusNode,
    required this.document,
    this.showDebugPaint = false,
    this.readOnly = false,
  }) : super(key: key);

  final EditContext editContext;
  final List<DocumentKeyboardAction> keyboardActions;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final Widget document;
  final showDebugPaint;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (isSoftKeyboard) {
      return SoftKeyboardDocumentInteractor(
        editContext: editContext,
        keyboardActions: keyboardActions,
        scrollController: scrollController,
        focusNode: focusNode,
        document: document,
        readOnly: readOnly,
      );
    } else {
      return DocumentInteractor(
        editContext: editContext,
        keyboardActions: keyboardActions,
        scrollController: scrollController,
        focusNode: focusNode,
        document: document,
        showDebugPaint: showDebugPaint,
      );
    }
  }
}

// General Notes:
//
//
// ### Interactor + Layout:
// - documentInteractor contains documentLayout which contains the actual document
// - the documentInteractor can take the entire available width while the document layout is limited to the max width
//   that is set by the editor.
// - the documentLayout also has a padding around it.
// - when calling _getDocOffset, we get the x,y coordinates inside in the document/layout coordinates which
//   does not account for padding since it's outside the document and its layout.
// - When we want to place the drag handles or show the floating cursor, we cannot place them inside the document since
//   the document layout is passed as a child to the interactor with the padding around it.
// - So technically, the drag handles and floating cursor are placed above the layout + padding
//   (ie document wrapper which is a SizedBox).
// - To place the drag handles correctly, we need to know the topLeft position of the layout as well as the wrapper
//   (i.e. in global coordinates, wrapperTopLeft - layoutTopLeft == layoutPadding)
// - here's a simplified view of the situation.
//
//            _________________________ toolbar/appbar _____________________
//            |                                                            |
//            |________________________   interactor   ____________________|
//            |     ___________________     wrapper    ________________    |
//            |    |                                                   |   |
//            |    |    _______________ documentlayout  ____________   |   |
//            |    |   |                                            |  |   |
//            |    |   ┤~~~~~~~~~~   minWidth ~ maxWidth ~~~~~~~~~~~├  |   |
//            |    |   |                                            |  |   |
//            ┤~~~~~~~~~~~~~~~~~~~~   screen width ~~~~~~~~~~~~~~~~~~~~~~~~├
//
//    As seen above, the interactor can take whatever avaialble width and height.
//    Typically the top padding has the same `top` position as the interactor.
//    On the other hand, assuming the layout max width < screen width, the `left`
//    position of the padding will be greater than that of the interactor.
//
//    Since the document, its layout and padding are given as a child to the interactor,
//    placing drag handles relies on the padding's topLeft as origin.
//    Hence whenever we're getting coordinates from the document (ie _getDocOffset), we need to
//    account for the padding offset.
//
//    The good thing is that in a mobile application, the screen width is constant, so most
//    of these values can be computed in the initState. While in Mobile, it's most likely that
//    the padding x,y will be equal to the interactors x,y, the case can be different for tablets.
//
//    Since we're placing draghandles directly on the widget containing the padding/layout,
//    the scroll offset is ignored when positining the handles. Though the scroll offset must
//    be taken into account when dealing global position*.
//
//    * global position is preferred to avoid a converting mess between the different coordinates.
//
//    to summarize:
//    - draghandles uses document coordinates with padding's as an offset (ie padding's coordinates)
//    - selection controls can use either screen coordinates or can be enclosed in interactor's coordinates.
//
// #### Selection Controls
// for selection controls widget/painter, see:
// - material: flutter/lib/src/material/text_selection.dart -- MaterialTextSelectionControls
// - cupertino: flutter/lib/src/cupertino/text_selection.dart -- CupertinoTextSelectionControls
//
// For floating cursor and other behavior, see EditableText implementation:
// - flutter/lib/src/widgets/editable_text.dart
//
// ### TODOs:
//  - selection of text with header has an issue
//     => double tap a header word to be selected, drag the handle left or right and selection gets lost.
//  - Understand the TextInputClient for different platformts to implement autocorrect/suggestion
//  - Replace RawKeyEvent wrappers with commands since we don't really need to mimic keyboard events
//    (initially i didn't know better)
//  - resolve conflict between scroll gesture and vertical drag of draghandle.
//    => when dragging a drag handle vertically, it'll scroll while it shouldn't.
//  - floating cursor height should adapt based on the selection height or caret height.
//  - add logging in a similar approach to the rest of this code base
//  - add any necessary testing in a similar approach to the rest of this code base.
//
// waiting from upstream:
//  - provide text height when calling `_layout.getRectForPosition`
//    => this is important since we're currently placing both extent and base drag handles at the same level
//       ideally the left handle should be on the top left of the selection while the right handle should be
//       on the button right of the selection. Also, in iOS at least, the drag handle has a line that extends
//       to the other end.
//
//
// to keep in mind:
//  - a lot of functionalities here were copied from documentInteractor so they should be consolidated if this
//    is will get merged.

// Unlike io.Platform, TargetPlatform, from the foundation library, detects the operating system on web.
// hence, a softkeyboard is only true when the device is iOS or Android whether it's a native app or a Web app.

/// a document interactor for touch devices with softkeyboard
class SoftKeyboardDocumentInteractor extends StatefulWidget {
  const SoftKeyboardDocumentInteractor({
    Key? key,
    required this.editContext,
    required this.keyboardActions,
    this.scrollController,
    this.focusNode,
    required this.document,
    this.readOnly = false,
  }) : super(key: key);

  final EditContext editContext;
  final List<DocumentKeyboardAction> keyboardActions;
  final ScrollController? scrollController;

  final FocusNode? focusNode;
  final Widget document;
  final bool readOnly;

  @override
  _SoftKeyboardDocumentInteractorState createState() => _SoftKeyboardDocumentInteractorState();
}

class _SoftKeyboardDocumentInteractorState extends State<SoftKeyboardDocumentInteractor> {
  final _documentWrapperKey = GlobalKey();

  late FocusNode _focusNode;

  late ScrollController _scrollController;

  late TextInputConnection _textInputConnection;

  // the top left position of the interactor in the global coordinate space
  late final Offset _interactorTopLeft;
  // the top left position of the wrapper in the global coordinate space
  late final Offset _wrapperTopLeft;
  // the top left position of the document in the global coordinate space
  late final Offset _documentTopLeft;

  // helper functions
  Offset get _documentPadding => (_documentTopLeft - _wrapperTopLeft);
  Offset _convertFromGlobalToDocument(Offset offset) => offset - _documentTopLeft + Offset(0, _scrollController.offset);
  Offset _convertFromWrapperToDocument(Offset offset) => offset - _documentPadding;
  Offset _convertFromWrapperToGlobal(Offset offset) => offset + _wrapperTopLeft;
  Offset _convertFromDocumentToWrapper(Offset offset) => offset + _documentPadding;

  // the height and width of the document layout.
  //
  // this value is only used to determine the bottom boundry for scrolling
  // This value should be updated at the start of any activity that needs it
  // such as scrolling or floating cursor since it'll computing it for every
  // selection change is unncessary.
  //
  // i.e. This value is used to prevent auto scrolling near the bottom boundry
  //      caused by dragging selection or floating cursor updates when the bottom
  //      is already visible.
  //
  // the value is updated by calling `_computeDocumentSize`.
  late Size _documentSize;

  /// the visible portion of the document in the document's coordinate space.
  ///
  /// this value is computed by _computeDocumentViewPort and it's influenced by
  /// both the scrollOffset and whether the virtual keyboard is visible or not.
  late Rect _documentViewportRect;

  Offset? _currentCursorPosition;
  // the position and dimension of the base drag handles in the wrapper coordinates
  Rect? _baseDragHandleRect;
  // the position and dimension of the extent drag handles in the wrapper coordinates
  Rect? _extentDragHandleRect;

  final dragHandleSize = 20.0;

  // indicates if the drag handle is being dragged.
  bool _isDragging = false;

  // the initial position is used to update the floating cursor position since all the floating cursor updates
  // are relative to the initial position from where the folating cursor started
  // (i.e. _currentCursorPosition at the start of floatingCursor activity).
  Offset? _floatingCursorInitialPosition;
  Offset? _floatingCursorPosition;

  DocumentLayout get _layout => widget.editContext.documentLayout;

  final selectionControls = SelectionControlsOverlay();

  bool get _isSelectionCollapsed => widget.editContext.composer.selection?.isCollapsed ?? true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _scrollController =
        _scrollController = (widget.scrollController ?? ScrollController())..addListener(_computeDocumentViewPort);

    widget.editContext.composer.addListener(_onSelectionChange);

    if (!widget.readOnly) {
      _attachTextInputClientForSoftKeyboard();
      _focusNode.addListener(_onFocusChange);
      // needed when selection == null to hide the soft keyboard
      widget.editContext.composer.addListener(_onFocusChange);
    }
    _setDocumentOffset();
  }

  @override
  void didUpdateWidget(SoftKeyboardDocumentInteractor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editContext.composer != oldWidget.editContext.composer) {
      oldWidget.editContext.composer.removeListener(_onSelectionChange);
      widget.editContext.composer.addListener(_onSelectionChange);
    }
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_computeDocumentViewPort);
      if (oldWidget.scrollController == null) {
        _scrollController.dispose();
      }
      _scrollController = (widget.scrollController ?? ScrollController())..addListener(_computeDocumentViewPort);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
      if (!widget.readOnly) {
        _focusNode.addListener(_onFocusChange);
      }
    }
  }

  @override
  void dispose() {
    widget.editContext.composer.removeListener(_onSelectionChange);
    _scrollController.removeListener(_computeDocumentViewPort);

    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (!widget.readOnly) {
      _textInputConnection.close();
    }

    selectionControls.hide();

    super.dispose();
  }

  void _setDocumentOffset() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      // get the top left position of the layout
      // dx is usually zero, and dy will account for anything above the layout such as a toolbar.
      final interactorBox = context.findRenderObject() as RenderBox;
      _interactorTopLeft = interactorBox.localToGlobal(Offset.zero);
      final documentTopLeftInInteractor = _layout.getDocumentOffsetFromAncestorOffset(Offset.zero, interactorBox) * -1;
      _documentTopLeft = documentTopLeftInInteractor + _interactorTopLeft;

      final wrapperBox = _documentWrapperKey.currentContext!.findRenderObject() as RenderBox;
      _wrapperTopLeft = wrapperBox.localToGlobal(Offset.zero);

      _computeDocumentSize();
    });
  }

  // This function should be call upon the start of an activity that requires auto scrolling
  // such as floating cursor or drag handles. This will ensure we've the latest documentSize
  // and documentViewportRect.
  void _computeDocumentSize() {
    final wrapperBox = _documentWrapperKey.currentContext!.findRenderObject() as RenderBox;
    _documentSize = (wrapperBox.size - _documentPadding * 2) as Size;
    _computeDocumentViewPort();
  }

  // This function should update the viewport upon scrolling and when a documentSize changes.
  void _computeDocumentViewPort() {
    // note: everything is initially computed in wrapper's coordinate space then
    // it's converted to document coordinate space for easier logic.

    // the scroll controller already computes the viewport dimension and it accounts for any
    // inset/padding such as the virtual keyboard height.
    final portHeight = _scrollController.position.viewportDimension;

    final scrollOffset = _scrollController.offset;

    // the top padding is only visible when scroll offset == 0, so the top padding will vary
    // in height and it will reach zero when the scrollOffset >= the top documentPadding
    final topPadding = max(0.0, _documentPadding.dy - scrollOffset);

    final top = topPadding + scrollOffset;

    final bottom = min(top + portHeight - topPadding, _documentSize.height + _documentPadding.dy);

    _documentViewportRect = Rect.fromLTRB(
      _documentPadding.dx,
      top,
      _documentSize.width,
      bottom,
    ).shift(_convertFromWrapperToDocument(Offset.zero));
  }

  void _attachTextInputClientForSoftKeyboard() {
    _textInputConnection = TextInput.attach(
      TextInputClientForMobile(
        onEvent: _onSoftKeyPressed,
        onFloatingCursorStart: _onFloatingCursorStart,
        onFloatingCursorUpdate: _onFloatingCursorUpdate,
        onFloatingCursorEnd: _onFloatingCursorEnd,
      ),
      TextInputConfiguration(
        inputAction: TextInputAction.newline,
        inputType: TextInputType.text,
        keyboardAppearance: Brightness.light,
        enableSuggestions: false,
        autocorrect: false,
      ),
    );
    // set the initial value as zwsp to detect backspace
    _textInputConnection.setEditingState(const TextEditingValue(
      text: _zwsp,
      selection: TextSelection(baseOffset: 1, extentOffset: 1),
    ));
  }

  void _onSoftKeyPressed(RawKeyEvent event) {
    _textInputConnection.setEditingState(const TextEditingValue(
      text: _zwsp,
      selection: TextSelection(baseOffset: 1, extentOffset: 1),
    ));
    _onKeyPressed(event);
  }

  void _onFloatingCursorStart() {
    setState(() {
      _floatingCursorInitialPosition = _convertFromDocumentToWrapper(_currentCursorPosition!);
      // necessary to show the floating cursor before any updates.
      _floatingCursorPosition = _floatingCursorInitialPosition;
      _computeDocumentSize();
    });
  }

  void _onFloatingCursorUpdate(Offset offset) {
    setState(() {
      _floatingCursorPosition = _floatingCursorInitialPosition! + offset;
      final documentOffset = _convertFromWrapperToDocument(_floatingCursorPosition!);
      _moveCaretTo(documentOffset);
      _scrollIfNearBoundries(documentOffset);
    });
  }

  void _onFloatingCursorEnd() {
    setState(() {
      _floatingCursorInitialPosition = null;
      _floatingCursorPosition = null;
    });
  }

  void _moveCaretTo(Offset documentOffset) {
    final docPosition = _layout.getDocumentPositionNearestToOffset(documentOffset);
    if (docPosition != null) {
      _selectPosition(docPosition);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.editContext.composer.selection != null) {
      if (!_textInputConnection.attached) {
        _attachTextInputClientForSoftKeyboard();
        _showSoftKeyboard();
      }
    } else {
      selectionControls.hide();
      _hideSoftKeyboard();
    }
  }

  void _showSoftKeyboard() async {
    try {
      _textInputConnection.show();
    } catch (e) {
      _log.log('showSoftKeyboard', 'failed to show soft keyboard $e');
    }
  }

  void _hideSoftKeyboard() async {
    try {
      _textInputConnection.close();
    } catch (e) {
      _log.log('hideSoftKeyboard', 'failed to hide soft keyboard $e');
    }
  }

  void _onSelectionChange() {
    _log.log('_onSelectionChange', 'EditableDocument: _onSelectionChange()');

    // while most cases do not require a post frame call back, there are two cases that's requires
    // calling `_updateDragHandles` in a post frame to place drag handles appropriately:
    //   1- when a text node changes alignment while there's a selection.
    //   2- when a node is transformed (e.g. paragraph => blockquote) where the node id will also change,
    //      hence a post frame call back will prevent calling the old node.
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() {
        _updateDragHandles();
      });
    });
  }

  KeyEventResult _onKeyPressed(RawKeyEvent keyEvent) {
    _log.log('_onKeyPressed', 'keyEvent: ${keyEvent.character}');
    if (keyEvent is! RawKeyDownEvent) {
      _log.log('_onKeyPressed', ' - not a "down" event. Ignoring.');
      return KeyEventResult.handled;
    }

    ExecutionInstruction instruction = ExecutionInstruction.continueExecution;
    int index = 0;
    while (instruction == ExecutionInstruction.continueExecution && index < widget.keyboardActions.length) {
      instruction = widget.keyboardActions[index](
        editContext: widget.editContext,
        keyEvent: keyEvent,
      );
      index += 1;
    }

    return instruction == ExecutionInstruction.haltExecution ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  void _onTapDown(TapDownDetails details) {
    if (_isInsideDragHandle(details.globalPosition)) return;
    _log.log('_onTapDown', 'EditableDocument: onTapDown()');
    // _clearSelection();
    // _selectionType = SelectionType.position;

    final docOffset = _getDocOffset(details.localPosition);
    _log.log('_onTapDown', ' - document offset: $docOffset');
    final docPosition = _layout.getDocumentPositionAtOffset(docOffset);
    _log.log('_onTapDown', ' - tapped document position: $docPosition');

    if (docPosition != null) {
      // Place the document selection at the location where the
      // user tapped.
      _selectPosition(docPosition);
    }

    _focusNode.requestFocus();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_isInsideDragHandle(details.globalPosition)) return;
    // _selectionType = SelectionType.word;

    _log.log('_onDoubleTapDown', 'EditableDocument: onDoubleTap()');
    _clearSelection();

    final docOffset = _getDocOffset(details.localPosition);
    final docPosition = _layout.getDocumentPositionAtOffset(docOffset);
    _log.log('_onDoubleTapDown', ' - tapped document position: $docPosition');

    if (docPosition != null) {
      final didSelectWord = _selectWordAt(
        docPosition: docPosition,
        docLayout: _layout,
      );
      if (!didSelectWord) {
        // Place the document selection at the location where the
        // user tapped.
        _selectPosition(docPosition);
      }
    }

    _focusNode.requestFocus();
  }

  void _onDoubleTap() {
    // _selectionType = SelectionType.position;
  }

  void _onTripleTapDown(TapDownDetails details) {
    if (_isInsideDragHandle(details.globalPosition)) return;
    // _selectionType = SelectionType.paragraph;

    _log.log('_onTripleTapDown', 'EditableDocument: onTripleTapDown()');
    _clearSelection();

    final docOffset = _getDocOffset(details.localPosition);
    final docPosition = _layout.getDocumentPositionAtOffset(docOffset);
    _log.log('_onTripleTapDown', ' - tapped document position: $docPosition');

    if (docPosition != null) {
      final didSelectParagraph = _selectParagraphAt(
        docPosition: docPosition,
        docLayout: _layout,
      );
      if (!didSelectParagraph) {
        // Place the document selection at the location where the
        // user tapped.
        _selectPosition(docPosition);
      }
    }

    _focusNode.requestFocus();
  }

  void _onTripleTap() {
    // _selectionType = SelectionType.position;
  }

  void _onLongPress() {
    showSelectionControls();
  }

  bool _selectWordAt({
    required DocumentPosition docPosition,
    required DocumentLayout docLayout,
  }) {
    final newSelection = getWordSelection(docPosition: docPosition, docLayout: docLayout);
    if (newSelection != null) {
      widget.editContext.composer.selection = newSelection;
      return true;
    } else {
      return false;
    }
  }

  bool _selectParagraphAt({
    required DocumentPosition docPosition,
    required DocumentLayout docLayout,
  }) {
    final newSelection = getParagraphSelection(docPosition: docPosition, docLayout: docLayout);
    if (newSelection != null) {
      widget.editContext.composer.selection = newSelection;
      return true;
    } else {
      return false;
    }
  }

  void _selectPosition(DocumentPosition position) {
    _log.log('_selectPosition', 'Setting document selection to $position');
    widget.editContext.composer.selection = DocumentSelection.collapsed(
      position: position,
    );
  }

  void _selectRegion({
    required DocumentLayout documentLayout,
    required Offset baseOffset,
    required Offset extentOffset,
    required SelectionType selectionType,
  }) {
    _log.log('_selectionRegion', 'Composer: selectionRegion(). Mode: $selectionType');
    var selection = documentLayout.getDocumentSelectionInRegion(baseOffset, extentOffset);
    var basePosition = selection?.base;
    var extentPosition = selection?.extent;
    _log.log('_selectionRegion', ' - base: $basePosition, extent: $extentPosition');
    if (basePosition == null || extentPosition == null) {
      widget.editContext.composer.selection = null;
      return;
    }

    if (selectionType == SelectionType.paragraph) {
      final baseParagraphSelection = getParagraphSelection(
        docPosition: basePosition,
        docLayout: documentLayout,
      );
      if (baseParagraphSelection == null) {
        widget.editContext.composer.selection = null;
        return;
      }
      basePosition = baseOffset.dy < extentOffset.dy ? baseParagraphSelection.base : baseParagraphSelection.extent;

      final extentParagraphSelection = getParagraphSelection(
        docPosition: extentPosition,
        docLayout: documentLayout,
      );
      if (extentParagraphSelection == null) {
        widget.editContext.composer.selection = null;
        return;
      }
      extentPosition =
          baseOffset.dy < extentOffset.dy ? extentParagraphSelection.extent : extentParagraphSelection.base;
    } else if (selectionType == SelectionType.word) {
      _log.log('_selectionRegion', ' - selecting a word');
      final baseWordSelection = getWordSelection(
        docPosition: basePosition,
        docLayout: documentLayout,
      );
      if (baseWordSelection == null) {
        widget.editContext.composer.selection = null;
        return;
      }
      basePosition = baseWordSelection.base;

      final extentWordSelection = getWordSelection(
        docPosition: extentPosition,
        docLayout: documentLayout,
      );
      if (extentWordSelection == null) {
        widget.editContext.composer.selection = null;
        return;
      }
      extentPosition = extentWordSelection.extent;
    }

    widget.editContext.composer.selection = (DocumentSelection(
      base: basePosition,
      extent: extentPosition,
    ));
    _log.log('_selectionRegion', 'Region selection: ${widget.editContext.composer.selection}');
  }

  void _clearSelection() {
    widget.editContext.composer.clearSelection();
  }

  // Converts the given [offset] from the [DocumentInteractor]'s coordinate
  // space to the [DocumentLayout]'s coordinate space.
  Offset _getDocOffset(Offset offset) {
    return _layout.getDocumentOffsetFromAncestorOffset(offset, context.findRenderObject()!);
  }

  bool _isInsideDragHandle(Offset offset) {
    // when selection is collapsed, drag handles are not shown.
    if (_isSelectionCollapsed) return false;

    if (_baseDragHandleRect != null) {
      if (_baseDragHandleRect!
          .shift(_documentTopLeft - _documentPadding)
          .translate(0, -_scrollController.offset)
          .contains(offset)) {
        return true;
      }
    }

    if (_extentDragHandleRect != null) {
      if (_extentDragHandleRect!
          .shift(_documentTopLeft - _documentPadding)
          .translate(0, -_scrollController.offset)
          .contains(offset)) {
        return true;
      }
    }
    return false;
  }

  void _updateDragHandles() {
    final selection = widget.editContext.composer.selection;
    if (selection == null) {
      _baseDragHandleRect = null;
      _extentDragHandleRect = null;
      if (selectionControls.isVisible) {
        selectionControls.hide();
      }
      return;
    }

    // in document coordinates..
    _currentCursorPosition = _layout.getRectForPosition(selection.extent)?.topLeft;
    // this return the offset within the component
    // text is still not factoring line height (see default_deitor/text.dart#_TextComponentState#getRectForPosition)
    late final Offset? selectionTopLeft;
    late final Offset? selectionBottomRight;

    if (selection.isCollapsed) {
      selectionTopLeft = _currentCursorPosition;
      selectionBottomRight = _currentCursorPosition;
    } else {
      selectionTopLeft = _layout.getRectForPosition(selection.base)?.topLeft;
      selectionBottomRight = _layout.getRectForPosition(selection.extent)?.bottomRight;
    }

    _baseDragHandleRect = Rect.fromCenter(
      center: _convertFromDocumentToWrapper(selectionTopLeft!),
      width: dragHandleSize,
      height: dragHandleSize,
    );

    _extentDragHandleRect = Rect.fromCenter(
      center: _convertFromDocumentToWrapper(selectionBottomRight!),
      width: dragHandleSize,
      height: dragHandleSize,
    );

    if (!_isDragging && !selection.isCollapsed) {
      showSelectionControls();
    } else {
      if (selectionControls.isVisible) {
        selectionControls.hide();
      }
    }
  }

  void showSelectionControls() {
    if (_baseDragHandleRect == null || _extentDragHandleRect == null) return;
    final baseOffset = _convertFromWrapperToGlobal(_baseDragHandleRect!.center);
    final extentOffset = _convertFromWrapperToGlobal(_extentDragHandleRect!.center);

    // find the center point where the selection controls pointer will point at..
    // there are three cases:
    // - base and extent on the same line
    // - base before extent in multiline
    // - base after extent in multiline

    late final double dx;
    late final double dy;
    final screenWidth = MediaQuery.of(context).size.width;

    if (baseOffset.dy == extentOffset.dy) {
      dy = baseOffset.dy - _scrollController.offset;
      dx = baseOffset.dx + ((extentOffset.dx - baseOffset.dx) / 2) + _interactorTopLeft.dx;
    } else if (baseOffset.dy < extentOffset.dy) {
      dy = baseOffset.dy - _scrollController.offset;
      // in a multi line selection, place selection controls in the center unless
      // the base handle > the center, then place it above the selected portion.
      dx = max(screenWidth / 2, baseOffset.dx + _interactorTopLeft.dx + 20);
      // alternatively:
      // dx = baseOffset.dx + layoutTopLeft.dx + 20;
    } else {
      dy = extentOffset.dy - _scrollController.offset;
      // in a multi line selection, place selection controls in the center unless
      // the extent handle > the center, then place it above the selected portion.
      dx = max(screenWidth / 2, extentOffset.dx + _interactorTopLeft.dx + 20);
      // alternatively:
      // dx = extentOffset.dx + layoutTopLeft.dx + 20;
    }

    selectionControls.show(
      context,
      Offset(
        dx,
        max(dy, _interactorTopLeft.dy),
      ),
      onCopy: _isSelectionCollapsed
          ? null
          : () {
              copyWhenCmdVIsPressed(editContext: widget.editContext, keyEvent: copyKeyEvent);
              selectionControls.hide();
            },
      onSelectAll: () {
        selectAllWhenCmdAIsPressed(editContext: widget.editContext, keyEvent: selectAllKeyEvent);

        // to move the selection controls in the new proper position.
        selectionControls.hide();
        showSelectionControls();
      },
      onCut: widget.readOnly || _isSelectionCollapsed
          ? null
          : () {
              // copy the text
              copyWhenCmdVIsPressed(editContext: widget.editContext, keyEvent: copyKeyEvent);
              // delete the text
              deleteExpandedSelectionWhenCharacterOrDestructiveKeyPressed(
                  editContext: widget.editContext, keyEvent: backspaceKeyEvent);
              selectionControls.hide();
            },
      onPaste: widget.readOnly
          ? null
          : () {
              pasteWhenCmdVIsPressed(editContext: widget.editContext, keyEvent: pasteKeyEvent);
            },
    );
  }

  // pass the document offset to scroll if necessary.
  //
  // This is mainly used by the drag handles and floating cursor when either the
  // selection or floating curosr is near the upper or lower boundries.
  void _scrollIfNearBoundries(Offset documentOffset) {
    final scrollOffset = _scrollController.offset;
    if (documentOffset.dy - 20 < _documentViewportRect.top) {
      // don't scroll beyond begining
      if (scrollOffset <= 0) return;
      _scrollController.animateTo(
        scrollOffset - 40,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
      return;
    }
    if (documentOffset.dy > _documentViewportRect.bottom - 20) {
      // don't scroll beyond end
      if (scrollOffset >= _scrollController.position.maxScrollExtent) return;
      _scrollController.animateTo(
        scrollOffset + 40,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildFocusAndGesture(
      child: SizedBox.expand(
        child: Stack(
          children: [
            _buildDocumentContainer(
              document: widget.document,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAndGesture({
    required Widget child,
  }) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: _buildRawGestureDetector(child: child),
    );
  }

  Widget _buildRawGestureDetector({
    required Widget child,
  }) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        TapSequenceGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapSequenceGestureRecognizer>(
          () => TapSequenceGestureRecognizer(),
          (TapSequenceGestureRecognizer recognizer) {
            recognizer
              ..onTapDown = _onTapDown
              ..onDoubleTapDown = _onDoubleTapDown
              ..onDoubleTap = _onDoubleTap
              ..onTripleTapDown = _onTripleTapDown
              ..onTripleTap = _onTripleTap;
          },
        ),
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(), (LongPressGestureRecognizer recognizer) {
          recognizer.onLongPress = _onLongPress;
        }),
      },
      child: child,
    );
  }

  Widget buildDragHandle(Rect rect, bool isBase, [Color color = Colors.blue]) {
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _isDragging = true;
          _computeDocumentSize();
        },
        onPanUpdate: (details) {
          // not sure why this value becomes null when: - select the word 'Example' on header, drag the extent handle right or left
          if (_extentDragHandleRect == null || _baseDragHandleRect == null) {
            print(
                'ISNULL: extentDragHandleRect! = $_extentDragHandleRect! && baseDragHandleRect! $_baseDragHandleRect!');
            return;
          }
          // use global since we need to take scroll offset into account.
          final documentOffset = _convertFromGlobalToDocument(details.globalPosition);
          if (isBase) {
            _selectRegion(
              documentLayout: _layout,
              baseOffset: documentOffset,
              extentOffset: _convertFromWrapperToDocument(_extentDragHandleRect!.center),
              selectionType: SelectionType.position,
            );
          } else {
            _selectRegion(
              documentLayout: _layout,
              baseOffset: _convertFromWrapperToDocument(_baseDragHandleRect!.center),
              extentOffset: documentOffset,
              selectionType: SelectionType.position,
            );
          }

          _scrollIfNearBoundries(documentOffset);
        },
        onPanCancel: () {
          // this can be cancelled by a scroll event multiple time so we avoid setting state when is dragging is already
          // false
          if (_isDragging) {
            setState(() {
              _isDragging = false;
              _updateDragHandles();
            });
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
            // to remove drag handles if selection is cancelled & collapsed
            _updateDragHandles();
          });
        },
        child: Container(
          height: dragHandleSize,
          width: dragHandleSize,
          child: Icon(
            Icons.circle,
            color: color,
            size: 15,
          ),
        ),
      ),
    );
  }

  // TODO: match the height of the carret which can be based on the fontSize for TextComponent,
  //       box size for BoxComponent, and so on.
  final floatingCursorHeight = 15.0;
  Widget _buildFloatingCursor() {
    // limit vertical movement inside the document
    final topBound = _documentPadding.dy;
    final bottomBound = topBound + _documentSize.height - floatingCursorHeight;
    final top = max(topBound, min(bottomBound, _floatingCursorPosition!.dy));

    // limit horizontal movement inside the document
    final leftBound = _documentPadding.dx;
    final rightBound = leftBound + _documentSize.width;
    final left = max(leftBound, min(rightBound, _floatingCursorPosition!.dx));

    return Positioned(
      top: top,
      left: left,
      child: Container(
        height: floatingCursorHeight,
        width: 3,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildDocumentContainer({
    required Widget document,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      primary: false, // it conflicts with panning the draghandles
      child: Center(
        child: Stack(
          children: [
            SizedBox(
              key: _documentWrapperKey,
              child: document,
            ),
            if (_baseDragHandleRect != null && !_isSelectionCollapsed) buildDragHandle(_baseDragHandleRect!, true),
            if (_extentDragHandleRect != null && !_isSelectionCollapsed) buildDragHandle(_extentDragHandleRect!, false),
            if (_floatingCursorPosition != null) _buildFloatingCursor(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          SOFT KEYBOARD CLIENT                              */
/* -------------------------------------------------------------------------- */
// The implementation below was made in a way to satisfy the current API without making any changes.
//
// In other words, input data and actions from the softkeyboard are converted into a RawKeyEvent.
// Since soft keyboards events are not triggered by `RawKeyboardListener` (because they are not really 'events'),
// the following TextInputClient is used to transform the input data and actions into.
//
// TODO: add this implementation to the state similar to EditibaleText.
class TextInputClientForMobile extends TextInputClient {
  final ValueChanged<RawKeyEvent> onEvent;
  final VoidCallback? onFloatingCursorStart;
  final ValueChanged<Offset> onFloatingCursorUpdate;
  final VoidCallback? onFloatingCursorEnd;

  TextInputClientForMobile({
    required this.onEvent,
    required this.onFloatingCursorUpdate,
    this.onFloatingCursorStart,
    this.onFloatingCursorEnd,
  });

  // TODO need to clean current client connection
  // see implementation in EditableText
  @override
  void connectionClosed() {}

  @override
  // TODO: implement currentAutofillScope
  AutofillScope? get currentAutofillScope {
    return null;
  }

  @override
  TextEditingValue? get currentTextEditingValue {
    return TextEditingValue.empty;
  }

  // the action here depends on how [TextInputConfiguration] is configured.
  // for example, if TextInputConfiguration.textInputAction == TextInputAction.newline,
  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.none:
      case TextInputAction.unspecified:
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.search:
      case TextInputAction.send:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.continueAction:
      case TextInputAction.join:
      case TextInputAction.route:
      case TextInputAction.emergencyCall:
      case TextInputAction.newline:
        onEvent.call(newLineKeyEvent);
        break;
    }
  }

  // this looks like to be an android specific method
  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  // TODO: figure out how to integrate this or if it's even needed.
  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  // this does not support voice input since things come in chunks and may need some sort of feedback
  @override
  void updateEditingValue(TextEditingValue value) {
    if (value.text.contains('\n')) {
      if (value.text.length == 2) {
        // it's handled by the performAction
        return;
      } else {
        // for some reason the newline gets carried to the next event
        // and it's not being reset by the texteditingvalue that onEvent does
        value = value.copyWith(text: value.text.replaceAll('\n', ''));
      }
    }

    // for some reason after the a backspace event (length == 1 and value == zwsp), an empty event is sent.
    // similarly, when the spacebar is hold for updateFloatingCursor, an empty value event is called
    // (it could be different for when there's a selection though)
    if (value.text == _zwsp) {
      return;
    }

    // this means there's only the zwsp character and it's an indicator of a backspace event
    // the second condition is to ensure that it was a deletion event and not hold-press on spacebar
    if (value.text.isEmpty) {
      // another option:  (value.text.length == 1 && value.selection.base != value.selection.extent)
      onEvent.call(backspaceKeyEvent);
    } else if (value.text.length > 1) {
      // since we are adding zwsp, any string with 2 chars or more (emojis and whatnot) means a character input
      final text = value.text.replaceAll(_zwsp, '');
      final event = SoftRawKeyDownEvent(data: CharacterKeyEventData(text));
      onEvent.call(event);
    }
  }

  // in iOS, this will give the location of the floating cursor*.
  //
  // * the floating cursor appears in iOS when a user press and hold on the space bar and move the cursor
  // not sure if there is anything similar in Android.
  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        onFloatingCursorStart?.call();
        break;
      case FloatingCursorDragState.Update:
        if (point.offset != null) {
          onFloatingCursorUpdate(point.offset!);
        }
        break;
      case FloatingCursorDragState.End:
        onFloatingCursorEnd?.call();
        break;
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                      Soft Keyboard Raw Event and Keys                      */
/* -------------------------------------------------------------------------- */
// mimicking keyboard events is easier than trying to reimplement all the functionalities that were already implemented
// for the keyboard events such as: copy, paste, select all, delete char, insert char, etc.
//
// Ideally, we should execute the commands directly using widget.editContext.editor.executeCommand(...command...).
// Though, most of existing public functions require a `RawKeyDownEvent` as an argument while the functions that accepts
// commands are private and cannot be reached from here.
//
//
// the following section has three implementations to mimic a `RawKeyDownEvent`:
//  - LogicalKeyboardKey  <=>   SoftKeyboardKey
//  - RawKeyEventData     <=>   SoftKeyRawEventData
//  - RawKeyDownEvent     <=>   SoftRawKeyDownEvent

class SoftKeyboardKey extends LogicalKeyboardKey {
  // See `insertCharacterInTextComposable` in default_editor/text.dart,
  //
  // It uses keyEvent.logicalKey.keyLabel to check if the key label is a character
  // then it uses `keyEvent.character` to insert that character.
  //
  // In the case below (and maybe in all cases) both values are equal.
  //
  // for now, a SoftKeyboardKey is created as a LogicalKeyboardKey where it only holds
  // the character from CharacterKeyEventData as a keyLabel.
  const SoftKeyboardKey(String keyLabel)
      : super(0x00000000, keyLabel: keyLabel); // zero since soft keyboard doesn't really have a keyId
}

abstract class SoftKeyRawEventData extends RawKeyEventData {
  const SoftKeyRawEventData();
  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    return null;
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    return false;
  }

  // this does not seem to be used anywhere in the package
  @override
  PhysicalKeyboardKey get physicalKey => PhysicalKeyboardKey.none;

  // these two requires implementation
  @override
  String get keyLabel;

  @override
  LogicalKeyboardKey get logicalKey;
}

// this is necessary override for any SoftKeyboardRawEventData that needs to mimic `isMetaPressed`.
// for some reason RawKeyDownEvent(CopyKeyEvent()) returns false for isMetaPressed even though
// CopyKeyEvent.isMetaPressed == true.

const copyKeyEvent = SoftRawKeyDownEvent(data: CopyKeyEvent());
const selectAllKeyEvent = SoftRawKeyDownEvent(data: SelectAllKeyEvent());
const pasteKeyEvent = SoftRawKeyDownEvent(data: PasteKeyEvent());
const backspaceKeyEvent = RawKeyDownEvent(data: BackspaceKeyEventData());
const newLineKeyEvent = RawKeyDownEvent(data: NewLineKeyEventData());
// final deleteSelectionKey = const SoftRawKeyDownEvent(data: SelectAllKeyEvent());

class SoftRawKeyDownEvent extends RawKeyDownEvent {
  const SoftRawKeyDownEvent({
    required RawKeyEventData data,
  }) : super(data: data);

  @override
  bool get isMetaPressed => data.isMetaPressed;

  // for this use case, we're using the label as the character.
  @override
  String get character => data.keyLabel;
}

class CopyKeyEvent extends SoftKeyRawEventData {
  const CopyKeyEvent();
  @override
  String get keyLabel => 'c';

  @override
  bool get isMetaPressed => true;

  @override
  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey.keyC;
}

class PasteKeyEvent extends SoftKeyRawEventData {
  const PasteKeyEvent();
  @override
  String get keyLabel => 'v';

  @override
  bool get isMetaPressed => true;

  @override
  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey.keyC;
}

class SelectAllKeyEvent extends SoftKeyRawEventData {
  const SelectAllKeyEvent();
  @override
  String get keyLabel => 'a';

  @override
  bool get isMetaPressed => true;

  @override
  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey.keyC;
}

class NewLineKeyEventData extends SoftKeyRawEventData {
  const NewLineKeyEventData();
  @override
  String get keyLabel => 'Enter';

  @override
  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey.enter;
}

class BackspaceKeyEventData extends SoftKeyRawEventData {
  const BackspaceKeyEventData();
  @override
  String get keyLabel => 'Backspace';

  @override
  LogicalKeyboardKey get logicalKey => LogicalKeyboardKey.backspace;
}

class CharacterKeyEventData extends SoftKeyRawEventData {
  final String character;

  const CharacterKeyEventData(this.character);

  @override
  String get keyLabel => character;

  @override // cannot be const because each character is different
  LogicalKeyboardKey get logicalKey => SoftKeyboardKey(character);
}

/* -------------------------------------------------------------------------- */
/*                                    UTIL                                    */
/* -------------------------------------------------------------------------- */
/// zero-width space character
///
/// This is used in the soft keyboard where it's added to indicate
/// backspace events since they keyboard doesn't emit such events.
const _zwsp = '\u200b';

/* -------------------------------------------------------------------------- */
/*                             SELECTION CONTROLS                             */
/* -------------------------------------------------------------------------- */

// todo:
// fix how the triangle is positioned...
class SelectionControlsOverlay {
  OverlayEntry? _overlayEntry;

  bool isVisible = false;

  // passing callbacks here because if they're null, it means they cannot be invoked
  // instead of having canCopy, canPaste, etc.
  // also passing this here instead of the constructor because the selection controls
  // might be different based on the selection...
  void show(
    BuildContext context,
    Offset topCenter, {
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
  }) {
    hide();
    _overlayEntry = buildEntry(
      topCenter,
      context,
      onCopy: onCopy,
      onCut: onCut,
      onPaste: onPaste,
      onSelectAll: onSelectAll,
    );

    isVisible = true;
    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    isVisible = false;
  }

  final pointerHeight = 10.0;
  OverlayEntry buildEntry(
    Offset topCenter,
    BuildContext context, {
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
  }) {
    final height = 50.0;
    final width = MediaQuery.of(context).size.width;
    return OverlayEntry(builder: (context) {
      return Positioned(
        top: max(0.0, topCenter.dy - height),
        left: 0.0,
        child: Container(
          height: height,
          width: width,
          child: Stack(
            children: [
              SelectionControls(
                centerPoint: topCenter.dx,
                maxHeight: height - 10,
                onCopy: onCopy,
                onCut: onCut,
                onPaste: onPaste,
                onSelectAll: onSelectAll,
              ),
              Positioned(
                bottom: 0.0,
                left: topCenter.dx,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(10, 10),
                    painter: _PointerPainter(
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}

class SelectionControls extends StatefulWidget {
  /// the center point based on the screen width
  final double centerPoint;
  final double maxHeight;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSelectAll;

  const SelectionControls({
    Key? key,
    required this.centerPoint,
    this.onCut,
    this.onCopy,
    this.onPaste,
    this.onSelectAll,
    required this.maxHeight,
  }) : super(key: key);

  @override
  _SelectionControlsState createState() => _SelectionControlsState();
}

class _SelectionControlsState extends State<SelectionControls> {
  final style = const TextStyle(color: Colors.white);

  Size? size;
  double? left;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final myBox = context.findRenderObject() as RenderBox;
      size = myBox.size;
      computeOffset();
    });
  }

  void computeOffset() {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      left = widget.centerPoint - size!.width / 2;
      if (left! < 0) {
        left = 0;
      } else if (left! + size!.width > screenWidth) {
        left = screenWidth - size!.width;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0.0,
      // we are computing the size of this widget, in the initial frame, we don't want to show the
      // widget since it'll move after the first frame. We paint the widget off stage to get its size
      // and then bring it to the screen once the left positioned is determined. Setting the left to 0
      // will cause the widget to paint first at position 0 then move rapidly to the new position (no good)
      left: left ?? MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (widget.onCut != null) ...[
                TextButton(
                  onPressed: widget.onCut,
                  child: Text('cut', style: style),
                ),
                Container(width: 1, height: 20, color: Colors.white)
              ],
              if (widget.onCopy != null) ...[
                TextButton(
                  onPressed: widget.onCopy,
                  child: Text('copy', style: style),
                ),
                Container(width: 1, height: 20, color: Colors.white)
              ],
              if (widget.onPaste != null) ...[
                TextButton(
                  onPressed: widget.onPaste,
                  child: Text('paste', style: style),
                ),
                Container(width: 1, height: 20, color: Colors.white)
              ],
              if (widget.onSelectAll != null)
                TextButton(
                  onPressed: widget.onSelectAll,
                  child: Text('select all', style: style),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  Color color;

  _PointerPainter({this.color = Colors.black});

  final path = Path();
  late Paint painter = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.fill
    ..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    path.moveTo(0.0, -1.0);
    path.lineTo(size.width, -1.0);
    path.lineTo(size.width / 2.0, size.height);

    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(CustomPainter customPainter) {
    return false;
  }
}
