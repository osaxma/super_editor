import 'package:flutter/material.dart';

import 'pane.dart';

/// Read-only viewer of Rich Text output.
///
/// This allows the result of the editor to be placed with little to no-changes to source data.
///
class RichTextViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichTextPane();
  }
}
