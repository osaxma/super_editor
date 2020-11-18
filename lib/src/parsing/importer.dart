import 'package:petitparser/petitparser.dart' show Token;
import 'package:xml/xml.dart';

class BoldTag extends XmlElement {
  BoldTag(
    XmlName name, [
    Iterable<XmlAttribute> attributesIterable = const [],
    Iterable<XmlNode> childrenIterable = const [],
    bool isSelfClosing = true,
  ]) : super(
          name,
          attributesIterable,
          childrenIterable,
          isSelfClosing,
        );
}

class ItalicsTag extends XmlElement {
  ItalicsTag(
    XmlName name, [
    Iterable<XmlAttribute> attributesIterable = const [],
    Iterable<XmlNode> childrenIterable = const [],
    bool isSelfClosing = true,
  ]) : super(
          name,
          attributesIterable,
          childrenIterable,
          isSelfClosing,
        );
}

class TagParser extends XmlParserDefinition {
  TagParser() : super(const XmlDefaultEntityMapping.xml());

  @override
  XmlElement createElement(XmlName name, Iterable<XmlNode> attributes, Iterable<XmlNode> children,
      [bool isSelfClosing = true]) {
    final attrs = attributes.cast<XmlAttribute>();
    if (name.local == 'b') {
      return BoldTag(name, attrs, children, isSelfClosing);
    } else if (name.local == 'i') {
      return ItalicsTag(name, attrs, children, isSelfClosing);
    }
    return XmlElement(name, attrs, children, isSelfClosing);
  }
}

class DocumentImporter {
  DocumentImporter() {}

  static final parser = TagParser().build();

  XmlDocument import(String input) {
    final result = parser.parse(input);
    if (result.isFailure) {
      final lineAndColumn = Token.lineAndColumnOf(result.buffer, result.position);
      throw XmlParserException(result.message,
          buffer: result.buffer,
          position: result.position,
          line: lineAndColumn[0],
          column: lineAndColumn[1]);
    }
    return result.value;
  }
}
