import 'package:flutter/material.dart';

import 'controller.dart';
import 'pane.dart';

class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    Key key,
    this.controller,
  }) : super(key: key);

  final RichTextController controller;

  @override
  _RichTextEditorState createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  RichTextController _controller;

  RichTextController get _effectiveController => widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    _controller = RichTextController();

    TextField a;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichTextPane();
  }
}
