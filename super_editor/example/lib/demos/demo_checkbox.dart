import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:super_editor/super_editor.dart';

typedef NodeUpdater = void Function({required DocumentNode oldNode, required DocumentNode newNode});

class CheckBoxDemo extends StatefulWidget {
  @override
  _CheckBoxDemoState createState() => _CheckBoxDemoState();
}

class _CheckBoxDemoState extends State<CheckBoxDemo> {
  late MutableDocument _doc;
  late DocumentEditor _docEditor;
  late DocumentComposer _composer;

  @override
  void initState() {
    super.initState();
    _doc = _sampleDocument();
    _docEditor = DocumentEditor(document: _doc);
    _composer = DocumentComposer();
  }

  void replaceNode({required DocumentNode oldNode, required DocumentNode newNode}) {
    // ideally, this  should be converted into a command:
    // e.g.  _docEditor.executeCommand(UpdateCheckBoxCommand)
    final oldIndex = _doc.getNodeIndex(oldNode);
    _doc.deleteNodeAt(oldIndex);
    _doc.insertNodeAt(oldIndex, newNode);
  }

  @override
  Widget build(BuildContext context) {
    return Provider<NodeUpdater>.value(
      value: replaceNode,
      child: SafeArea(
              child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                maxLines: null,
              ),
            ),
            Expanded(
                        child: SuperEditor.custom(
                editor: _docEditor,
                composer: _composer,
                padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                componentBuilders: [
                  checkBoxBuilder,
                  ...defaultComponentBuilders,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _composer.dispose();
  }
}

/* -------------------------------------------------------------------------- */
/*                                CHECKBOX NODE                               */
/* -------------------------------------------------------------------------- */

class CheckBoxNode extends ParagraphNode {
  CheckBoxNode({
    required String id,
    required AttributedText text,
    this.isChecked = false,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          text: text,
          metadata: metadata,
        );

  final bool isChecked;

  CheckBoxNode copyWith({
    String? id,
    AttributedText? text,
    bool? isChecked,
    Map<String, dynamic>? metadata,
  }) {
    return CheckBoxNode(
        id: id ?? DocumentEditor.createNodeId(),
        text: text ?? this.text,
        isChecked: isChecked ?? this.isChecked,
        metadata: metadata ?? this.metadata);
  }
}

/* -------------------------------------------------------------------------- */
/*                             CheckBox Component                             */
/* -------------------------------------------------------------------------- */

class CheckBoxComponent extends StatelessWidget {
  const CheckBoxComponent({
    Key? key,
    required this.textKey,
    required this.text,
    required this.styleBuilder,
    required this.onClicked,
    this.isChecked = false,
  }) : super(key: key);

  final GlobalKey textKey;
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final bool isChecked;
  final VoidCallback onClicked;

  @override
  Widget build(BuildContext context) {
    (textKey.currentState as State<TextComponent>?);
    return Row(
      children: [
        GestureDetector(
          onTap: onClicked,
          child: isChecked //
              ? const Icon(Icons.check_box_outlined)
              : const Icon(Icons.check_box_outline_blank),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: TextComponent(
              key: textKey,
              text: text,
              textStyleBuilder: (attributions) {
                // apply default style.
                final style = styleBuilder(attributions);
                // apply checkbox item specific style
                return style.copyWith(
                  color: isChecked ? Colors.black : Colors.grey.shade600,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         CHECKBOX COMPONENT BUILDER                         */
/* -------------------------------------------------------------------------- */

Widget? checkBoxBuilder(ComponentContext componentContext) {
  final checkBoxNode = componentContext.documentNode;
  if (checkBoxNode is! CheckBoxNode) {
    return null;
  }

  final isChecked = checkBoxNode.isChecked;

  return CheckBoxComponent(
    textKey: componentContext.componentKey,
    text: checkBoxNode.text,
    styleBuilder: componentContext.extensions[textStylesExtensionKey],
    isChecked: isChecked,
    onClicked: () {
      final nodeUpdater = Provider.of<NodeUpdater>(componentContext.context, listen: false);
      nodeUpdater(
        oldNode: checkBoxNode,
        newNode: checkBoxNode.copyWith(isChecked: !isChecked),
      );
    },
  );
}

/* -------------------------------------------------------------------------- */
/*                               SAMPEL DOCUMENT                              */
/* -------------------------------------------------------------------------- */

MutableDocument _sampleDocument() {
  return MutableDocument(
    nodes: [
      ParagraphNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Check Box Example',
        ),
        metadata: {
          'blockType': header1Attribution,
        },
      ),
      CheckBoxNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Option 1',
        ),
      ),
      CheckBoxNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Option 2',
        ),
      ),
      CheckBoxNode(
        id: DocumentEditor.createNodeId(),
        text: AttributedText(
          text: 'Option 3',
        ),
      ),
    ],
  );
}
