import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

class ExampleViewerListView extends StatefulWidget {
  @override
  _ExampleViewerListViewState createState() => _ExampleViewerListViewState();
}

class _ExampleViewerListViewState extends State<ExampleViewerListView> {
  late List<MutableDocument> docs;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    docs = List.generate(40, (index) {
      sampleNodes.shuffle();
      
      final nodes = sampleNodes.sublist(
        0,
        rand.nextInt(3), // small number to show how short document appear.  
      );
      return _createSampleDoc(nodes);
    });
  }

  @override
  void dispose() {
    docs.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // const SizedBox(height: 100),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              padding: const EdgeInsets.all(50.0),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    navigateToViewer(docs[index]);
                  },
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 200, minHeight: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(width: 2.0),
                    ),
                    margin: const EdgeInsets.all(10.0),
                    child: Viewer(
                      document: docs[index],
                      maxWidth: 600,
                      ignoreInteractions: true,
                      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                      keyboardActions: const [copyWhenCmdCIsPressed, selectAllWhenCmdAIsPressed],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void navigateToViewer(MutableDocument doc) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return Scaffold(
        appBar: AppBar(),
        body: Viewer(
          document: doc,
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          keyboardActions: const [copyWhenCmdCIsPressed, selectAllWhenCmdAIsPressed],
        ),
      );
    }));
  }
}

MutableDocument _createSampleDoc(List<DocumentNode> nodes) {
  return MutableDocument(
    nodes: nodes,
  );
}

final sampleNodes = [
  ImageNode(
    id: DocumentEditor.createNodeId(),
    imageUrl: 'https://i.ytimg.com/vi/fq4N0hgOWzU/maxresdefault.jpg',
  ),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'Example Document',
    ),
    metadata: {
      'blockType': header1Attribution,
    },
  ),
  HorizontalRuleNode(id: DocumentEditor.createNodeId()),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus sed sagittis urna. Aenean mattis ante justo, quis sollicitudin metus interdum id. Aenean ornare urna ac enim consequat mollis. In aliquet convallis efficitur. Phasellus convallis purus in fringilla scelerisque. Ut ac orci a turpis egestas lobortis. Morbi aliquam dapibus sem, vitae sodales arcu ultrices eu. Duis vulputate mauris quam, eleifend pulvinar quam blandit eget.',
    ),
  ),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'This is a blockquote!',
    ),
    metadata: {
      'blockType': blockquoteAttribution,
    },
  ),
  ListItemNode.unordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'This is an unordered list item',
    ),
  ),
  ListItemNode.unordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'This is another list item',
    ),
  ),
  ListItemNode.unordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'This is a 3rd list item',
    ),
  ),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
        text:
            'Cras vitae sodales nisi. Vivamus dignissim vel purus vel aliquet. Sed viverra diam vel nisi rhoncus pharetra. Donec gravida ut ligula euismod pharetra. Etiam sed urna scelerisque, efficitur mauris vel, semper arcu. Nullam sed vehicula sapien. Donec id tellus volutpat, eleifend nulla eget, rutrum mauris.'),
  ),
  ListItemNode.ordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'First thing to do',
    ),
  ),
  ListItemNode.ordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'Second thing to do',
    ),
  ),
  ListItemNode.ordered(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text: 'Third thing to do',
    ),
  ),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text:
          'Nam hendrerit vitae elit ut placerat. Maecenas nec congue neque. Fusce eget tortor pulvinar, cursus neque vitae, sagittis lectus. Duis mollis libero eu scelerisque ullamcorper. Pellentesque eleifend arcu nec augue molestie, at iaculis dui rutrum. Etiam lobortis magna at magna pellentesque ornare. Sed accumsan, libero vel porta molestie, tortor lorem eleifend ante, at egestas leo felis sed nunc. Quisque mi neque, molestie vel dolor a, eleifend tempor odio.',
    ),
  ),
  ParagraphNode(
    id: DocumentEditor.createNodeId(),
    text: AttributedText(
      text:
          'Etiam id lacus interdum, efficitur ex convallis, accumsan ipsum. Integer faucibus mollis mauris, a suscipit ante mollis vitae. Fusce justo metus, congue non lectus ac, luctus rhoncus tellus. Phasellus vitae fermentum orci, sit amet sodales orci. Fusce at ante iaculis nunc aliquet pharetra. Nam placerat, nisl in gravida lacinia, nisl nibh feugiat nunc, in sagittis nisl sapien nec arcu. Nunc gravida faucibus massa, sit amet accumsan dolor feugiat in. Mauris ut elementum leo.',
    ),
  ),
];
