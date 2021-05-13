import 'package:flutter/material.dart';
import 'package:super_editor/src/core/document.dart';
import 'package:super_editor/src/core/document_composer.dart';
import 'package:super_editor/src/core/document_editor.dart';
import 'package:super_editor/src/core/document_layout.dart';
import 'package:super_editor/src/default_editor/styles.dart';
import 'package:super_editor/src/infrastructure/_listenable_builder.dart';
import 'package:super_editor/src/infrastructure/attributed_text.dart';
import 'package:super_editor/super_editor.dart';

import 'document_interaction.dart';
import 'document_interaction_mobile.dart';

/// A viewer for [Document]
///
/// Similar to [Editor] with disabled editing functionality and behavior
/// (e.g. keyboard actions and showing a caret).
///
// Most of the code below was copied from Editor, mainly to avoid creating a lot of changes in this fork.
// For instance, EditorContext and DocumentEditor do not make sense in a Viewer. Counterparts for Viewer
// should be created but that will lead to changes in multiple places (e.g. layout, interactions, etc).
class Viewer extends StatefulWidget {
  const Viewer._({
    Key? key,
    required this.componentBuilders,
    required this.editor,
    this.composer,
    required this.textStyleBuilder,
    required this.selectionStyle,
    required this.keyboardActions,
    this.scrollController,
    this.focusNode,
    this.maxWidth = 600,
    this.padding = EdgeInsets.zero,
    this.showDebugPaint = false,
    this.ignoreInteractions = false,
  }) : super(key: key);

  factory Viewer({
    Key? key,
    // document editor only accepts mutable document..
    // once we can avoid using DocumentEditor or replace it
    // this should be a regular document.
    required MutableDocument document,
    DocumentComposer? composer,
    List<ComponentBuilder>? componentBuilders,
    AttributionStyleBuilder? textStyleBuilder,
    SelectionStyle? selectionStyle,
    List<DocumentKeyboardAction>? keyboardActions,
    ScrollController? scrollController,
    FocusNode? focusNode,
    double maxWidth = 600,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    bool showDebugPaint = false,
    bool ignoreInteractions = false,
  }) {
    return Viewer._(
      key: key,
      editor: DocumentEditor(document: document), // TODO: create DocumentViewer?
      composer: composer,
      componentBuilders: componentBuilders ?? defaultComponentBuilders,
      textStyleBuilder: textStyleBuilder ?? defaultStyleBuilder,
      selectionStyle: selectionStyle ?? defaultSelectionStyle,
      // in a view mode, only few commands are needed.
      keyboardActions: keyboardActions ?? const [copyWhenCmdVIsPressed, selectAllWhenCmdAIsPressed],
      scrollController: scrollController,
      focusNode: focusNode,
      maxWidth: maxWidth,
      padding: padding,
      showDebugPaint: showDebugPaint,
      ignoreInteractions: ignoreInteractions,
    );
  }

  /// Contains a `Document` and alters that document as desired.
  final DocumentEditor editor;
  final DocumentComposer? composer;
  final List<ComponentBuilder> componentBuilders;
  final AttributionStyleBuilder textStyleBuilder;
  final SelectionStyle selectionStyle;
  final List<DocumentKeyboardAction> keyboardActions;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool showDebugPaint;

  /// whether the viewer has interactions
  ///
  /// This is useful when a portion of the document is shown as a thumbnail where
  /// interactions are not needed. This will also prevent having multiple listeners
  /// for mouse/keyboard events when multiple thumbnails are shown.
  ///
  /// This effectively acts as [IgnorePointer] but also prevnts unncessary initialization
  /// for mouse/keyboard listeners.
  final bool ignoreInteractions;

  @override
  _ViewerState createState() => _ViewerState();
}

class _ViewerState extends State<Viewer> {
  // GlobalKey used to access the `DocumentLayoutState` to figure
  // out where in the document the user taps or drags.
  final _docLayoutKey = GlobalKey();

  late FocusNode _focusNode;
  late DocumentComposer _composer;

  @override
  void initState() {
    super.initState();

    _composer = widget.composer ?? DocumentComposer();

    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(Viewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.ignoreInteractions) {
      if (widget.composer != oldWidget.composer) {
        print('Composer changed!');

        _composer = widget.composer ?? DocumentComposer();
      }
      if (widget.editor != oldWidget.editor) {
        // The content displayed in this Editor was switched
        // out. Remove any content selection from the previous
        // document.
        _composer.selection = null;
      }
      if (widget.focusNode != oldWidget.focusNode) {
        _focusNode = widget.focusNode ?? FocusNode();
      }
    }
  }

  @override
  void dispose() {
    if (widget.composer == null) {
      _composer.dispose();
    }

    if (widget.focusNode == null) {
      // We are using our own private FocusNode. Dispose it.
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ignoreInteractions) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: SizedBox(
            width: widget.maxWidth,
            child: Padding(
              padding: widget.padding,
              child: DefaultDocumentLayout(
                key: _docLayoutKey,
                document: widget.editor.document,
                documentSelection: _composer.selection,
                componentBuilders: widget.componentBuilders,
                showCaret: false,
                extensions: {
                  textStylesExtensionKey: widget.textStyleBuilder,
                  selectionStylesExtensionKey: widget.selectionStyle,
                },
                showDebugPaint: widget.showDebugPaint,
              ),
            ),
          ),
        ),
      );
    }

    return DefaultDocumentInteractor(
      readOnly: true,
      focusNode: _focusNode,
      editContext: EditContext(
        editor: widget.editor,
        composer: _composer,
        getDocumentLayout: () => _docLayoutKey.currentState as DocumentLayout,
      ),
      keyboardActions: widget.keyboardActions,
      showDebugPaint: widget.showDebugPaint,
      document: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        child: Padding(
          padding: widget.padding,
          child: MultiListenableBuilder(
            listenables: {
              _focusNode,
              _composer,
              widget.editor.document,
            },
            builder: (context) {
              return DefaultDocumentLayout(
                key: _docLayoutKey,
                document: widget.editor.document,
                documentSelection: _composer.selection,
                componentBuilders: widget.componentBuilders,
                showCaret: false,
                extensions: {
                  textStylesExtensionKey: widget.textStyleBuilder,
                  selectionStylesExtensionKey: widget.selectionStyle,
                },
                showDebugPaint: widget.showDebugPaint,
              );
            },
          ),
        ),
      ),
    );
  }
}
