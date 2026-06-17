import '../models/question.dart';

/// Dragged from the palette to add a new copy of a bank question.
class AddQuestionPayload {
  const AddQuestionPayload(this.source);
  final Question source;
}

/// Dragged on the page to move an already-placed question to a new spot.
class MoveQuestionPayload {
  const MoveQuestionPayload(this.id);
  final String id;
}
