import 'doc_element.dart';
import 'page_size.dart';

/// One page holds an ordered list of elements (list order == z-order, the
/// last element is drawn on top).
class DocPage {
  final List<DocElement> elements = [];
}

/// The whole design document: a page size plus one or more pages.
class TestDocument {
  PaperSize size = PaperSize.a4;
  String title = 'My Test Paper';
  final List<DocPage> pages = [DocPage()];
}
