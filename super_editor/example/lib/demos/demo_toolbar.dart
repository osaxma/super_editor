import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

<<<<<<< HEAD
// temp for migrating to the new Attribution API. 
const noAttribution = NamedAttribution('');

=======
>>>>>>> 385830e (merged mobile branch)
class ToolbarDemo extends StatefulWidget {
  @override
  _ToolbarDemoState createState() => _ToolbarDemoState();
}

class _ToolbarDemoState extends State<ToolbarDemo> {
<<<<<<< HEAD
  late MutableDocument _doc;
  late DocumentEditor _docEditor;
  late DocumentComposer composer;
  late SelectionController controller;
=======
  Document _doc;
  DocumentEditor _docEditor;
  DocumentComposer composer;
  SelectionController controller;
>>>>>>> 385830e (merged mobile branch)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
<<<<<<< HEAD
    _doc = _createSimpleDocument();
=======
>>>>>>> 385830e (merged mobile branch)
=======
    _doc = _createSimpleDocument();
>>>>>>> 31aac63 (preliminary support for autocorrect & suggestions (from mobile))
    _doc = _createSampleDocument();
    _docEditor = DocumentEditor(document: _doc);
    composer = DocumentComposer();
    controller = SelectionController(composer, _docEditor, _doc);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = Container(
      height: 40,
      color: const Color.fromARGB(255, 214, 216, 220),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 12),
        scrollDirection: Axis.horizontal,
        child: Toolbar(controller: controller),
      ),
    );
    return SafeArea(
      child: Column(
        children: [
          if (!isSoftKeyboard) toolbar,
          Expanded(
<<<<<<< HEAD
            child: SuperEditor.custom(
=======
            child: Editor.custom(
>>>>>>> 385830e (merged mobile branch)
              editor: controller.documentEditor,
              composer: controller.composer,
              maxWidth: 800,
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              // showDebugPaint: true,
              textStyleBuilder: customStyleBuilder,
              componentBuilders: [
                customBlockQuoteBuilder, // don't insert at bottom since uknown builder is the last one
                ...defaultComponentBuilders,
              ],
              keyboardActions: defaultKeyboardActions,
            ),
          ),
          if (isSoftKeyboard) toolbar,
        ],
      ),
    );
  }
}

/// deals with the current selection
class SelectionController with ChangeNotifier {
  final DocumentComposer composer;
  final DocumentEditor documentEditor;
  final Document document;

  // list holding the nodes of the current selection
  // this list is updated on every selection change
  final selectedNodes = <DocumentNode>[];

  SelectionController(
    this.composer,
    this.documentEditor,
    this.document,
  ) {
    composer.addListener(onSelectionChange);
    ensureMetadataIsSet();
  }

  // todo add fontSize, textColor, maybe background Text Color
  void ensureMetadataIsSet() {
    document.nodes.forEach((element) {
      if (element is TextNode) {
        final alignment = element.metadata['textAlign'] ?? '';
<<<<<<< HEAD
        final heading = element.metadata['blockType'] ?? noAttribution;
=======
        final heading = element.metadata['blockType'] ?? '';
>>>>>>> 385830e (merged mobile branch)
        if (alignment.isEmpty) {
          // for now we assume it's left
          element.metadata['textAlign'] = 'left';
        }
<<<<<<< HEAD
        if (heading.id.isEmpty) {
          element.metadata['blockType'] = header3Attribution;
=======
        if (heading.isEmpty) {
          element.metadata['blockType'] = 'header3';
>>>>>>> 385830e (merged mobile branch)
        }
      }
    });
  }

  @override
  void dispose() {
    composer.removeListener(onSelectionChange);
    super.dispose();
  }

  void onSelectionChange() {
    selectedNodes.clear();

    if (composer.selection != null) {
<<<<<<< HEAD
      selectedNodes.addAll(document.getNodesInside(composer.selection!.base, composer.selection!.extent));
=======
      selectedNodes.addAll(document.getNodesInside(composer.selection.base, composer.selection.extent));
>>>>>>> 385830e (merged mobile branch)
    }

    _hasTextNode = selectedNodes.any((element) => element is TextNode);
    setCurrentMetaData();
    notifyListeners();
  }

  // meta data can be heading, alignment and any other property that applies for an entire TextNode such as a paragraph
  // this function sets the data based on the major selection, if only one, its default, if any differs, it's empty.
  void setCurrentMetaData() {
    if (selectedNodes.isEmpty) {
      _currentAlignment = '';
<<<<<<< HEAD
      _currentHeading = noAttribution;
      return;
    } else {
      _currentAlignment = getMetadataForSelectedTextNodes<String>('textAlign', 'left') ?? 'left';
      _currentHeading = getMetadataForSelectedTextNodes<Attribution>('blockType', header3Attribution) ?? header3Attribution;
=======
      _currentHeading = '';
      return;
    } else {
      _currentAlignment = getMetadataForSelectedTextNodes<String>('textAlign', 'left') ?? 'left';
      _currentHeading = getMetadataForSelectedTextNodes<String>('blockType', 'header3') ?? 'header3';
>>>>>>> 385830e (merged mobile branch)
    }
  }

  /// get a metadata property of one or multiple nodes:
  /// - if all nodes share the same property, it'll return that property.
  /// - if any node has a different property, it'll return the given default value.
  /// - if no property is set or none of the nodes is a TextNode, it'll return null.
<<<<<<< HEAD
  T? getMetadataForSelectedTextNodes<T>(String key, T defaultProperty) {
=======
  T getMetadataForSelectedTextNodes<T>(String key, T defaultProperty) {
>>>>>>> 385830e (merged mobile branch)
    dynamic property;
    var foundFirst = false;
    for (var node in selectedNodes) {
      if (node is! TextNode) continue;
      if (!foundFirst) {
        property = (node as TextNode).metadata[key];
        foundFirst = true;
        continue;
      }

      if ((node as TextNode).metadata[key] != property) {
        return defaultProperty;
      }
    }
    return property;
  }

  // can apply bold, italic, strikethroug.
  bool _hasTextNode = false;
  bool get hasTextNode => _hasTextNode;

  // bool get isMultiSelection => selectedNodes.length > 1;

  // helper functions
<<<<<<< HEAD
  void _setAttributions(Set<Attribution> attributions) {
    // if selection is collapsed or == null, skip.
    if (composer.selection?.isCollapsed ?? true) return;
    final command = ToggleTextAttributionsCommand(
      documentSelection: composer.selection!,
      attributions: attributions,
    );
    documentEditor.executeCommand(command);
    // toggling attribution doesn't update selection, so it's done manually
    composer.notifyListeners();
=======
  void _setAttributions(Set<String> attributions) {
    // if selection is collapsed or == null, skip.
    if (composer?.selection?.isCollapsed ?? true) return;
    final command = ToggleTextAttributionsCommand(
      documentSelection: composer.selection,
      attributions: attributions,
    );
    documentEditor.executeCommand(command);
>>>>>>> 385830e (merged mobile branch)
  }

  void _setMetadata(TextNode node, String key, dynamic value) {
    node.metadata[key] = value;
  }

  void boldIt() {
<<<<<<< HEAD
    _setAttributions({boldAttribution});
  }

  void italicizeIt() {
    _setAttributions({italicsAttribution});
  }

  void strikethroughIt() {
    _setAttributions({strikethroughAttribution});
=======
    _setAttributions({'bold'});
  }

  void italicizeIt() {
    _setAttributions({'italics'});
  }

  void strikethroughIt() {
    _setAttributions({'strikethrough'});
>>>>>>> 385830e (merged mobile branch)
  }

  /* -------------------------------------------------------------------------- */
  /*                         HEADING  AND ALIGNMENT                             */
  /* -------------------------------------------------------------------------- */

  // ------------------------------ heading
<<<<<<< HEAD
  Attribution _currentHeading = noAttribution;

  Attribution? get currentHeading => _currentHeading;

  void updateHeading(Attribution? heading) {
=======
  String _currentHeading = '';

  String get currentHeading => _currentHeading;

  void updateHeading(String heading) {
>>>>>>> 385830e (merged mobile branch)
    final node = selectedNodes.first;
    if (node is TextNode) {
      _setMetadata(node, 'blockType', heading);
      composer.notifyListeners();
    }
  }

  // ------------------------------ alignment
  String _currentAlignment = '';

  String get currentAlignment => _currentAlignment;

  // for now allow toggle alignment for one node only
  bool get canToggleAlignment => hasTextNode;

  void toggleAlignment() {
    var newAlignment = '';
    for (var node in selectedNodes) {
      // TODO: there's handy method to update meta data
      if (node is TextNode) {
        if (currentAlignment == null || currentAlignment.isEmpty || currentAlignment == 'left') {
          newAlignment = 'center';
        } else if (currentAlignment == 'center') {
          newAlignment = 'right';
        } else if (currentAlignment == 'right') {
          newAlignment = 'justify';
        } else if (currentAlignment == 'justify') {
          newAlignment = 'left';
        }
        _setMetadata(node, 'textAlign', newAlignment);
      }
    }
    // the way we are updating the meta data does not trigger any event so we manually do it.
    // until we figure out a better approch
    composer.notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                                  QUOTE                                     */
  /* -------------------------------------------------------------------------- */

  bool isAllSelectedNodesOfType<T extends DocumentNode>() =>
      selectedNodes.whereType<T>().length == selectedNodes.length;

  // for now allow toggle alignment for one node only
  bool get canToggleQuote => hasTextNode;

  void toggleQuote() {
    if (isAllSelectedNodesOfType<BlockQuoteNode>()) {
      transformAllTextNodes((previousNode) => previousNode.toParagraph(generateId()));
    } else {
      transformAllTextNodes((previousNode) => previousNode.toBlockQuote(generateId()));
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                  LIST                                      */
  /* -------------------------------------------------------------------------- */

  // for now allow toggle alignment for one node only
  bool get canToggleList => hasTextNode;

  void toggleUnorderedList() {
    if (isAllSelectedNodesOfType<ListItemNode>()) {
      transformAllTextNodes(transofrmToParagraph);
    } else {
      transformAllTextNodes(
        (node) => ListItemNode.unordered(
          id: generateId(),
          text: node.text,
          metadata: node.metadata,
        ),
      );
    }
  }

  void toggleOrderedList() {
    if (isAllSelectedNodesOfType<ListItemNode>()) {
      transformAllTextNodes(transofrmToParagraph);
    } else {
      transformAllTextNodes(
        (node) => ListItemNode.ordered(
          id: generateId(),
          text: node.text,
          metadata: node.metadata,
        ),
      );
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                    UTIL                                    */
  /* -------------------------------------------------------------------------- */
  ParagraphNode transofrmToParagraph(TextNode node) => ParagraphNode(
        id: generateId(),
        text: node.text,
        metadata: node.metadata,
      );

  void transformAllTextNodes(
    TextNode Function(TextNode previousNode) transformer,
  ) {
<<<<<<< HEAD
    late DocumentPosition base;
    late DocumentPosition extent;
=======
    DocumentPosition base;
    DocumentPosition extent;
>>>>>>> 385830e (merged mobile branch)

    // final isCollapsed = composer.selection.isCollapsed;
    final previousSelection = composer.selection;
    final previousNodes = List.from(selectedNodes);

    for (var i = 0; i < previousNodes.length; i++) {
      final previousNode = previousNodes[i];
      final index = document.getNodeIndex(previousNode);
      final newNode = (previousNode is TextNode) ? transformer(previousNode) : previousNode;

      if (i == 0) {
        composer.clearSelection();
<<<<<<< HEAD
        base = DocumentPosition(nodeId: newNode.id, nodePosition: previousSelection!.base.nodePosition);
      }

      if (i == previousNodes.length - 1) {
        extent = DocumentPosition(nodeId: newNode.id, nodePosition: previousSelection!.extent.nodePosition);
=======
        base = DocumentPosition(nodeId: newNode.id, nodePosition: previousSelection.base.nodePosition);
      }

      if (i == previousNodes.length - 1) {
        extent = DocumentPosition(nodeId: newNode.id, nodePosition: previousSelection.extent.nodePosition);
>>>>>>> 385830e (merged mobile branch)
      }

      replaceNode(index, newNode);
    }

    // reapply selection
    composer.selection = DocumentSelection(base: base, extent: extent);
  }

<<<<<<< HEAD
  void executeAll([bool Function(TextNode node)? shouldSkip]) {
    for (var node in selectedNodes) {
      if (shouldSkip != null && shouldSkip.call(node as TextNode)) continue;
=======
  void executeAll([bool Function(TextNode node) shouldSkip]) {
    for (var node in selectedNodes) {
      if (shouldSkip != null && shouldSkip(node)) continue;
>>>>>>> 385830e (merged mobile branch)
    }
  }

  void replaceNode(int index, DocumentNode newNode) {
    documentEditor.executeCommand(EditorCommandFunction((doc, transation) {
      transation
        ..deleteNodeAt(index)
        ..insertNodeAt(index, newNode);
    }));
  }

  /* -------------------------------------------------------------------------- */
  /*                                   DIVIDER                                  */
  /* -------------------------------------------------------------------------- */

  //  can insert divider only when it's colappsed (if no selection, no insert)
  bool get canInsertDivider => composer.selection?.isCollapsed ?? false;

  void insertDivider() {
    final node = selectedNodes.first;
    final index = document.getNodeIndex(node);
<<<<<<< HEAD
    int? insertionIndex;
=======
    int insertionIndex;
>>>>>>> 385830e (merged mobile branch)

    if (node is TextNode) {
      // insert the horizontal line based on the cursor position.
      // if it's closer to the beginning, insert above.
      // if it's closer to the end, insert below.
<<<<<<< HEAD
      final begin = (composer.selection!.base.nodePosition as TextPosition).offset;
      final end = (composer.selection!.extent.nodePosition as TextPosition).offset;
=======
      final begin = (composer.selection.base.nodePosition as TextPosition).offset;
      final end = (composer.selection.extent.nodePosition as TextPosition).offset;
>>>>>>> 385830e (merged mobile branch)
      final distanceFrombeginning = begin - node.beginningPosition.offset;
      final distanceToEnd = node.endPosition.offset - end;
      if (distanceToEnd < distanceFrombeginning) {
        insertionIndex = index + 1;
      }
    }
    // TODO handle other cases ...

    documentEditor.executeCommand(EditorCommandFunction((doc, transation) {
      transation.insertNodeAt(insertionIndex ?? index, HorizontalRuleNode(id: generateId()));
    }));
  }
}

/* -------------------------------------------------------------------------- */
/*                                   TOOLBAR                                  */
/* -------------------------------------------------------------------------- */

class Toolbar extends StatelessWidget {
  final SelectionController controller;

<<<<<<< HEAD
  const Toolbar({Key? key, required this.controller}) : super(key: key);
=======
  const Toolbar({Key key, @required this.controller}) : super(key: key);
>>>>>>> 385830e (merged mobile branch)

  IconData alignmentIcon(SelectionController controller) {
    switch (controller.currentAlignment) {
      case 'left':
        return Icons.format_align_left;
      case 'right':
        return Icons.format_align_right;
      case 'justify':
        return Icons.format_align_justify;
      case 'center':
      default:
        return Icons.format_align_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (context, snapshot) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextHeading(controller: controller),
              ToolbarButton(
                icon: Icons.format_bold,
                enabled: controller.hasTextNode,
                onPressed: controller.boldIt,
              ),
              ToolbarButton(
                icon: Icons.format_italic,
                enabled: controller.hasTextNode,
                onPressed: controller.italicizeIt,
              ),
              ToolbarButton(
                icon: Icons.format_strikethrough,
                enabled: controller.hasTextNode,
                onPressed: controller.strikethroughIt,
              ),
              ToolbarButton(
                icon: alignmentIcon(controller),
                enabled: controller.canToggleAlignment, // until we figure the command out
                onPressed: controller.toggleAlignment,
              ),
              Center(child: Container(width: 1, height: 30, color: Colors.black)),
              ToolbarButton(
                icon: Icons.format_quote_outlined,
                enabled: controller.canToggleQuote, // until we figure the command out
                onPressed: controller.toggleQuote,
              ),
              ToolbarButton(
                icon: Icons.format_list_numbered,
                enabled: controller.canToggleList,
                onPressed: controller.toggleOrderedList,
              ),
              ToolbarButton(
                icon: Icons.format_list_bulleted,
                enabled: controller.canToggleList,
                onPressed: controller.toggleUnorderedList,
              ),
              Center(child: Container(width: 1, height: 30, color: Colors.black)),
              ToolbarButton(
                icon: Icons.horizontal_rule,
                enabled: controller.canInsertDivider, // until we figure the command out
                onPressed: controller.insertDivider,
              ),
              ToolbarButton(
                  icon: Icons.image,
                  enabled: false, // until we figure the command out
                  onPressed: null),
              ToolbarButton(
                icon: Icons.link,
                enabled: false, // until we figure the command out
                onPressed: null,
              ),
            ],
          );
        });
  }
}

class ToolbarButton extends StatelessWidget {
  final IconData icon;
<<<<<<< HEAD
  final VoidCallback? onPressed;
  final bool enabled;
  final iconSize = 24.0;
  const ToolbarButton({Key? key, required this.icon, this.onPressed, this.enabled = true}) : super(key: key);
=======
  final VoidCallback onPressed;
  final bool enabled;
  final iconSize = 24.0;
  const ToolbarButton({Key key, this.icon, this.onPressed, this.enabled = true}) : super(key: key);
>>>>>>> 385830e (merged mobile branch)

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      splashRadius: iconSize,
      onPressed: enabled ? onPressed : null,
    );
  }
}

<<<<<<< HEAD
// class HeaderMenu extends StatelessWidget {
//   final SelectionController controller;

//   final items = <String>['H1', 'H2', 'H3'].map<DropdownMenuItem<String>>((String value) {
//     return DropdownMenuItem<String>(
//       value: value.replaceAll('H', 'header'),
//       child: Text(value),
//     );
//   }).toList();

//   List<DropdownMenuItem> getItems() {
//     // TODO insert an empty item for multi selection
//     return items;
//   }

//   HeaderMenu({Key? key, required this.controller}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     final currentHeader = controller.currentHeading;
//     return DropdownButton<Attribution>(
//       value: currentHeader,
//       iconSize: 12,
//       elevation: 16,
//       disabledHint: Icon(
//         Icons.horizontal_rule,
//         color: Colors.grey,
//       ),
//       style: TextStyle(color: Colors.black),
//       onChanged: (Attribution? newValue) {
//         controller.updateHeading(newValue);
//       },
//       items: currentHeader.id.isNotEmpty ? getItems() : null,
//     );
//   }
// }
=======
class HeaderMenu extends StatelessWidget {
  final SelectionController controller;

  final items = <String>['H1', 'H2', 'H3'].map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
      value: value.replaceAll('H', 'header'),
      child: Text(value),
    );
  }).toList();

  List<DropdownMenuItem> getItems() {
    // TODO insert an empty item for multi selection
    return items;
  }

  HeaderMenu({Key key, this.controller}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final currentHeader = controller.currentHeading;
    return DropdownButton<String>(
      value: currentHeader,
      iconSize: 12,
      elevation: 16,
      disabledHint: Icon(
        Icons.horizontal_rule,
        color: Colors.grey,
      ),
      style: TextStyle(color: Colors.black),
      onChanged: (String newValue) {
        controller.updateHeading(newValue);
      },
      items: currentHeader.isNotEmpty ? getItems() : null,
    );
  }
}
>>>>>>> 385830e (merged mobile branch)

class TextHeading extends StatelessWidget {
  final SelectionController controller;

<<<<<<< HEAD
  TextHeading({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var currentHeading = controller.currentHeading?.id;
=======
  TextHeading({Key key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var currentHeading = controller.currentHeading;
>>>>>>> 385830e (merged mobile branch)
    if (currentHeading == null || currentHeading.isEmpty || currentHeading == 'header3') {
      currentHeading = 'H3';
    } else if (currentHeading.startsWith('header')) {
      currentHeading = currentHeading.replaceAll('header', 'H');
    }

    return GestureDetector(
      onTap: () {
        if (currentHeading == 'H3') {
<<<<<<< HEAD
          controller.updateHeading(header1Attribution);
        } else if (currentHeading == 'H1') {
          controller.updateHeading(header2Attribution);
        } else {
          controller.updateHeading(header3Attribution);
=======
          controller.updateHeading('header1');
        } else if (currentHeading == 'H1') {
          controller.updateHeading('header2');
        } else {
          controller.updateHeading('header3');
>>>>>>> 385830e (merged mobile branch)
        }
      },
      child: Container(
        height: 24,
        width: 24,
        child: FittedBox(
          child: Text(
            currentHeading,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                STYLE BUILDER                               */
/* -------------------------------------------------------------------------- */

final defaultStyle = TextStyle(
  color: Colors.black,
  fontSize: 13,
  height: 1.4,
);

// copied from [Editor]
/// Creates `TextStyles` for the standard `Editor`.
<<<<<<< HEAD
TextStyle customStyleBuilder(Set<Attribution> attributions) {
  var newStyle = defaultStyle;

  for (final attribution in attributions) {
    if (attribution == header1Attribution) {
      newStyle = newStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );
    } else if (attribution == header2Attribution) {
      newStyle = newStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF888888),
        height: 1.0,
      );
    } else if (attribution == blockquoteAttribution) {
      newStyle = newStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.4,
        color: Colors.grey,
      );
    } else if (attribution == boldAttribution) {
      newStyle = newStyle.copyWith(
        fontWeight: FontWeight.bold,
      );
    } else if (attribution == italicsAttribution) {
      newStyle = newStyle.copyWith(
        fontStyle: FontStyle.italic,
      );
    } else if (attribution == strikethroughAttribution) {
      newStyle = newStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      );
    } else if (attribution is LinkAttribution) {
      newStyle = newStyle.copyWith(
        color: Colors.lightBlue,
        decoration: TextDecoration.underline,
      );
    }
  }

=======
TextStyle customStyleBuilder(Set<dynamic> attributions) {
  var newStyle = defaultStyle;

  for (final attribution in attributions) {
    if (attribution is! String) {
      continue;
    }

    switch (attribution) {
      case 'header1':
        newStyle = newStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.0,
        );
        break;
      case 'header2':
        newStyle = newStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          // color: const Color(0xFF888888),
          height: 1.0,
        );
        break;
      case 'blockquote':
        newStyle = newStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
          color: Colors.grey,
        );
        break;
      case 'bold':
        newStyle = newStyle.copyWith(
          fontWeight: FontWeight.bold,
        );
        break;
      case 'italics':
        newStyle = newStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
        break;
      case 'strikethrough':
        newStyle = newStyle.copyWith(
          decoration: TextDecoration.lineThrough,
        );
        break;
    }
  }
>>>>>>> 385830e (merged mobile branch)
  return newStyle;
}

/* -------------------------------------------------------------------------- */
/*                                  EXTENSION                                 */
/* -------------------------------------------------------------------------- */

extension TextNodeEx on TextNode {
  TextNode copyWith({
<<<<<<< HEAD
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
=======
    String id,
    AttributedText text,
    Map<String, dynamic> metadata,
>>>>>>> 385830e (merged mobile branch)
  }) {
    return TextNode(
      id: id ?? this.id,
      text: text ?? this.text,
      metadata: metadata ?? this.metadata,
    );
  }

  // handy transformers ...
  BlockQuoteNode toBlockQuote(String newId) {
    return BlockQuoteNode(id: newId, text: text, metadata: metadata);
  }

  ParagraphNode toParagraph(String newId) {
    return ParagraphNode(id: newId, text: text, metadata: metadata);
  }

  ListItemNode toListItem(String newId, ListItemType itemType, [int indent = 0]) {
    return ListItemNode(id: newId, text: text, metadata: metadata, itemType: itemType, indent: indent);
  }
}

/* -------------------------------------------------------------------------- */
/*                               BLOCKQUOTE NODE                              */
/* -------------------------------------------------------------------------- */

// extends paragraph node so BlockQuoteNode inherits all its keyboardActions
// for this reason, when this is inserted in the editor componentBuilders, make sure it's above the paragraphBuilder!
class BlockQuoteNode extends ParagraphNode {
  BlockQuoteNode({
<<<<<<< HEAD
    required String id,
    required AttributedText text,
    Map<String, dynamic>? metadata,
=======
    String id,
    AttributedText text,
    Map<String, dynamic> metadata,
>>>>>>> 385830e (merged mobile branch)
    int indent = 0,
  })  : _indent = indent,
        super(
          id: id,
          text: text,
          metadata: metadata,
        );

  int _indent;
  int get indent => _indent;
  set indent(int newIndent) {
    if (newIndent != _indent) {
      _indent = newIndent;
      notifyListeners();
    }
  }
}

class BlockQuoteComponent extends StatelessWidget {
  const BlockQuoteComponent({
<<<<<<< HEAD
    Key? key,
    required this.textKey,
    required this.text,
    required this.styleBuilder,
=======
    Key key,
    @required this.textKey,
    @required this.text,
    @required this.styleBuilder,
>>>>>>> 385830e (merged mobile branch)
    this.indent = 0,
    this.textSelection,
    this.selectionColor = Colors.lightBlueAccent,
    this.showCaret = false,
    this.caretColor = Colors.black,
    this.showDebugPaint = false,
    this.textAlign = TextAlign.left,
    this.textDirection = TextDirection.ltr,
    this.showLeftQuoteMark = true,
    this.showRightQuoteMark = true,
  }) : super(key: key);

  final GlobalKey textKey;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final int indent;
<<<<<<< HEAD
  final TextSelection? textSelection;
=======
  final TextSelection textSelection;
>>>>>>> 385830e (merged mobile branch)
  final TextDirection textDirection;
  final TextAlign textAlign;
  final Color selectionColor;
  final bool showCaret;
  final Color caretColor;
  final bool showDebugPaint;
  final bool showLeftQuoteMark;
  final bool showRightQuoteMark;

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    (textKey.currentState as State<TextComponent>?);
=======
    (textKey.currentState as State<TextComponent>);
>>>>>>> 385830e (merged mobile branch)
    return Container(
      // color: Colors.grey.shade300,
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisSize: MainAxisSize.max,
        children: [
          if (showLeftQuoteMark)
            RotatedBox(quarterTurns: 2, child: Icon(Icons.format_quote))
          else
            const SizedBox(width: 24.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 4.0),
              child: TextComponent(
                key: textKey,
                text: text,
                textStyleBuilder: (attributions) {
                  // apply default styling of bold/italic/etc.
                  final style = styleBuilder(attributions);
                  // apply the quote style
                  return style.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade600);
                },
                textSelection: textSelection,
                selectionColor: selectionColor,
                showCaret: showCaret,
                caretColor: caretColor,
                showDebugPaint: showDebugPaint,
                textAlign: textAlign,
              ),
            ),
          ),
          if (showRightQuoteMark) Icon(Icons.format_quote) else const SizedBox(width: 24.0),
        ],
      ),
    );
  }
}

// since BlockQuoteNode is also a ParagraphNode and TextNode, make sure this inserted above both of them in the
// editor's componentBuilders
<<<<<<< HEAD
Widget? customBlockQuoteBuilder(ComponentContext componentContext) {
=======
Widget customBlockQuoteBuilder(ComponentContext componentContext) {
>>>>>>> 385830e (merged mobile branch)
  final listItemNode = componentContext.documentNode;
  if (listItemNode is! BlockQuoteNode) {
    return null;
  }

  TextAlign textAlign = TextAlign.left;
  final textAlignName = (componentContext.documentNode as TextNode).metadata['textAlign'];
  switch (textAlignName) {
    case 'left':
      textAlign = TextAlign.left;
      break;
    case 'center':
      textAlign = TextAlign.center;
      break;
    case 'right':
      textAlign = TextAlign.right;
      break;
    case 'justify':
      textAlign = TextAlign.justify;
      break;
  }

<<<<<<< HEAD
  final textSelection = componentContext.nodeSelection?.nodeSelection as TextSelection?;
=======
  final textSelection = componentContext.nodeSelection?.nodeSelection as TextSelection;
>>>>>>> 385830e (merged mobile branch)
  final showCaret = componentContext.showCaret && (componentContext.nodeSelection?.isExtent ?? false);

  final isPreviousBlockQuote = componentContext.document.getNodeBefore(componentContext.documentNode) is BlockQuoteNode;
  final isNextBlockQuote = componentContext.document.getNodeAfter(componentContext.documentNode) is BlockQuoteNode;

  return BlockQuoteComponent(
    textKey: componentContext.componentKey,
    text: (listItemNode as BlockQuoteNode).text,
    textAlign: textAlign,
    styleBuilder: componentContext.extensions[textStylesExtensionKey],
    indent: (listItemNode as BlockQuoteNode).indent,
    textSelection: textSelection,
    selectionColor: (componentContext.extensions[selectionStylesExtensionKey] as SelectionStyle).selectionColor,
    showCaret: showCaret,
    caretColor: (componentContext.extensions[selectionStylesExtensionKey] as SelectionStyle).textCaretColor,
    showLeftQuoteMark: !isPreviousBlockQuote,
    showRightQuoteMark: !isNextBlockQuote,
  );
}

/* -------------------------------------------------------------------------- */
/*                               SAMPLE DOCUMENT                              */
/* -------------------------------------------------------------------------- */

<<<<<<< HEAD
<<<<<<< HEAD
MutableDocument _createSimpleDocument() {
=======
Document _createSimpleDocument() {
>>>>>>> 31aac63 (preliminary support for autocorrect & suggestions (from mobile))
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: generateId(),
        text: AttributedText(
          text: 'One word.',
        ),
      ),
      ParagraphNode(
        id: generateId(),
        text: AttributedText(
          text: 'This is a simple paragraph with one sentence.',
        ),
      ),
      ParagraphNode(
        id: generateId(),
        text: AttributedText(
          text:
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus sed sagittis urna. Aenean mattis ante justo, quis sollicitudin metus interdum id. Aenean ornare urna ac enim consequat mollis. In aliquet convallis efficitur. Phasellus convallis purus in fringilla scelerisque. Ut ac orci a turpis egestas lobortis. Morbi aliquam dapibus sem, vitae sodales arcu ultrices eu. Duis vulputate mauris quam, eleifend pulvinar quam blandit eget.',
        ),
      ),
    ],
  );
}

<<<<<<< HEAD
MutableDocument _createSampleDocument() {
=======
=======
>>>>>>> 31aac63 (preliminary support for autocorrect & suggestions (from mobile))
Document _createSampleDocument() {
>>>>>>> 385830e (merged mobile branch)
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: generateId(),
        text: AttributedText(
          text: 'Example Document',
        ),
        metadata: {
<<<<<<< HEAD
          'blockType': header1Attribution,
=======
          'blockType': 'header1',
>>>>>>> 385830e (merged mobile branch)
        },
      ),
      HorizontalRuleNode(id: generateId()),
      ParagraphNode(
        id: generateId(),
        text: AttributedText(
          text:
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus sed sagittis urna. Aenean mattis ante justo, quis sollicitudin metus interdum id. Aenean ornare urna ac enim consequat mollis. In aliquet convallis efficitur. Phasellus convallis purus in fringilla scelerisque. Ut ac orci a turpis egestas lobortis. Morbi aliquam dapibus sem, vitae sodales arcu ultrices eu. Duis vulputate mauris quam, eleifend pulvinar quam blandit eget.',
        ),
      ),
      ListItemNode.unordered(
        id: generateId(),
        text: AttributedText(
          text: 'This is an unordered list item',
        ),
      ),
      ListItemNode.unordered(
        id: generateId(),
        text: AttributedText(
          text: 'This is another list item',
        ),
      ),
      ListItemNode.unordered(
        id: generateId(),
        text: AttributedText(
          text: 'This is a 3rd list item',
        ),
      ),
      BlockQuoteNode(
        id: generateId(),
        text: AttributedText(
          text:
              'Cras vitae sodales nisi. Vivamus dignissim vel purus vel aliquet. Sed viverra diam vel nisi rhoncus pharetra. Donec gravida ut ligula euismod pharetra. Etiam sed urna scelerisque, efficitur mauris vel, semper arcu. Nullam sed vehicula sapien. Donec id tellus volutpat, eleifend nulla eget, rutrum mauris.',
        ),
      ),
      ImageNode(
        id: generateId(),
        imageUrl: 'https://i.ytimg.com/vi/fq4N0hgOWzU/maxresdefault.jpg',
      ),
      ListItemNode.ordered(
        id: generateId(),
        text: AttributedText(
          text: 'First thing to do',
        ),
      ),
      ListItemNode.ordered(
        id: generateId(),
        text: AttributedText(
          text: 'Second thing to do',
        ),
      ),
      ListItemNode.ordered(
        id: generateId(),
        text: AttributedText(
          text: 'Third thing to do',
        ),
      ),
      ParagraphNode(
          id: generateId(),
          text: AttributedText(
            text:
                'Nam hendrerit vitae elit ut placerat. Maecenas nec congue neque. Fusce eget tortor pulvinar, cursus neque vitae, sagittis lectus. Duis mollis libero eu scelerisque ullamcorper. Pellentesque eleifend arcu nec augue molestie, at iaculis dui rutrum. Etiam lobortis magna at magna pellentesque ornare. Sed accumsan, libero vel porta molestie, tortor lorem eleifend ante, at egestas leo felis sed nunc. Quisque mi neque, molestie vel dolor a, eleifend tempor odio.',
          ),
          metadata: {
<<<<<<< HEAD
            'blockType': header2Attribution,
=======
            'blockType': 'header2',
>>>>>>> 385830e (merged mobile branch)
          }),
    ],
  );
}

/* -------------------------------------------------------------------------- */
/*                                    UTIL                                    */
/* -------------------------------------------------------------------------- */

String generateId() {
  return shortHash(Object());
}

final isSoftKeyboard = (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
