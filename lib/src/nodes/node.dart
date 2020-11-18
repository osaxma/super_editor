class Node<T> {

  Node({
    this.parent,
    List<Node<T>> children,
  }) {
    _children.addAll(children);
  }

  final Node<T> parent;
  final _children = <Node<T>>[];

  List<Node<T>> get children => _children;
}
