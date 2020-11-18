import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExampleApp());
}

/// Demonstration app to show how to implement
/// the RichTextEditor in a simple case.
class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
    return MaterialApp(
      theme: theme.copyWith(
        canvasColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      title: 'Example',
      home: RichTextEditorExample(),
    );
  }
}

/// Demonstration screen for RichTextEditor.
/// This currently us used to test the focus handling within the view.
class RichTextEditorExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Focus(
              onFocusChange: (bool hasFocus) {
                print('focus other $hasFocus');
              },
              child: Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () => Focus.of(context).requestFocus(),
                    child: TextField(
                      decoration: InputDecoration(
                        // fillColor: Colors.red,
                        filled: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: RichTextEditor(),
            ),
          ],
        ),
      ),
    );
  }
}
