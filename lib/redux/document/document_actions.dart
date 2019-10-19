import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class ViewDocumentList implements PersistUI {
  ViewDocumentList(this.context);

  final BuildContext context;
}

class ViewDocument implements PersistUI {
  ViewDocument({this.documentId, this.context});

  final String documentId;
  final BuildContext context;
}

class EditDocument implements PersistUI {
  EditDocument({
    this.document,
    this.context,
    this.completer,
  });

  final DocumentEntity document;
  final BuildContext context;
  final Completer completer;
}

class UpdateDocument implements PersistUI {
  UpdateDocument(this.document);

  final DocumentEntity document;
}

class LoadDocument {
  LoadDocument({this.completer, this.documentId, this.loadActivities = false});

  final Completer completer;
  final String documentId;
  final bool loadActivities;
}

class LoadDocumentActivity {
  LoadDocumentActivity({this.completer, this.documentId});

  final Completer completer;
  final String documentId;
}

class LoadDocuments {
  LoadDocuments({this.completer, this.force = false});

  final Completer completer;
  final bool force;
}

class LoadDocumentRequest implements StartLoading {}

class LoadDocumentFailure implements StopLoading {
  LoadDocumentFailure(this.error);

  final dynamic error;

  @override
  String toString() {
    return 'LoadDocumentFailure{error: $error}';
  }
}

class LoadDocumentSuccess implements StopLoading, PersistData {
  LoadDocumentSuccess(this.document);

  final DocumentEntity document;

  @override
  String toString() {
    return 'LoadDocumentSuccess{document: $document}';
  }
}

class LoadDocumentsRequest implements StartLoading {}

class LoadDocumentsFailure implements StopLoading {
  LoadDocumentsFailure(this.error);

  final dynamic error;

  @override
  String toString() {
    return 'LoadDocumentsFailure{error: $error}';
  }
}

class LoadDocumentsSuccess implements StopLoading, PersistData {
  LoadDocumentsSuccess(this.documents);

  final BuiltList<DocumentEntity> documents;

  @override
  String toString() {
    return 'LoadDocumentsSuccess{documents: $documents}';
  }
}

class SaveDocumentRequest implements StartSaving {
  SaveDocumentRequest({this.completer, this.document});

  final Completer completer;
  final DocumentEntity document;
}

class SaveDocumentSuccess implements StopSaving, PersistData, PersistUI {
  SaveDocumentSuccess(this.document);

  final DocumentEntity document;
}

class AddDocumentSuccess implements StopSaving, PersistData, PersistUI {
  AddDocumentSuccess(this.document);

  final DocumentEntity document;
}

class SaveDocumentFailure implements StopSaving {
  SaveDocumentFailure(this.error);

  final Object error;
}

class ArchiveDocumentRequest implements StartSaving {
  ArchiveDocumentRequest(this.completer, this.documentId);

  final Completer completer;
  final String documentId;
}

class ArchiveDocumentSuccess implements StopSaving, PersistData {
  ArchiveDocumentSuccess(this.document);

  final DocumentEntity document;
}

class ArchiveDocumentFailure implements StopSaving {
  ArchiveDocumentFailure(this.document);

  final DocumentEntity document;
}

class DeleteDocumentRequest implements StartSaving {
  DeleteDocumentRequest(this.completer, this.documentId);

  final Completer completer;
  final String documentId;
}

class DeleteDocumentSuccess implements StopSaving, PersistData {
  DeleteDocumentSuccess(this.document);

  final DocumentEntity document;
}

class DeleteDocumentFailure implements StopSaving {
  DeleteDocumentFailure(this.document);

  final DocumentEntity document;
}

class RestoreDocumentRequest implements StartSaving {
  RestoreDocumentRequest(this.completer, this.documentId);

  final Completer completer;
  final String documentId;
}

class RestoreDocumentSuccess implements StopSaving, PersistData {
  RestoreDocumentSuccess(this.document);

  final DocumentEntity document;
}

class RestoreDocumentFailure implements StopSaving {
  RestoreDocumentFailure(this.document);

  final DocumentEntity document;
}

class FilterDocuments {
  FilterDocuments(this.filter);

  final String filter;
}

class SortDocuments implements PersistUI {
  SortDocuments(this.field);

  final String field;
}

class FilterDocumentsByState implements PersistUI {
  FilterDocumentsByState(this.state);

  final EntityState state;
}

class FilterDocumentsByCustom1 implements PersistUI {
  FilterDocumentsByCustom1(this.value);

  final String value;
}

class FilterDocumentsByCustom2 implements PersistUI {
  FilterDocumentsByCustom2(this.value);

  final String value;
}

class FilterDocumentsByEntity implements PersistUI {
  FilterDocumentsByEntity({this.entityId, this.entityType});

  final String entityId;
  final EntityType entityType;
}

void handleDocumentAction(
    BuildContext context, List<DocumentEntity> documents, EntityAction action) {
  assert(
  [
    EntityAction.restore,
    EntityAction.archive,
    EntityAction.delete,
    EntityAction.toggleMultiselect
  ].contains(action) ||
      documents.length == 1,
  'Cannot perform this action on more than one document');
  
  final store = StoreProvider.of<AppState>(context);
  final localization = AppLocalization.of(context);
  final document = documents.first;

  switch (action) {
    case EntityAction.edit:
      store.dispatch(EditDocument(context: context, document: document));
      break;
    case EntityAction.restore:
      store.dispatch(RestoreDocumentRequest(
          snackBarCompleter(context, localization.restoredDocument),
          document.id));
      break;
    case EntityAction.archive:
      store.dispatch(ArchiveDocumentRequest(
          snackBarCompleter(context, localization.archivedDocument),
          document.id));
      break;
    case EntityAction.delete:
      store.dispatch(DeleteDocumentRequest(
          snackBarCompleter(context, localization.deletedDocument),
          document.id));
      break;
    case EntityAction.toggleMultiselect:
      if (!store.state.documentListState.isInMultiselect()) {
        store.dispatch(StartDocumentMultiselect(context: context));
      }

      if (documents.isEmpty) {
        break;
      }

      for (final document in documents) {
        if (!store.state.documentListState.isSelected(document)) {
          store.dispatch(
              AddToDocumentMultiselect(context: context, entity: document));
        } else {
          store.dispatch(
              RemoveFromDocumentMultiselect(context: context, entity: document));
        }
      }
      break;
  }
}


class StartDocumentMultiselect {
  StartDocumentMultiselect({@required this.context});

  final BuildContext context;
}

class AddToDocumentMultiselect {
  AddToDocumentMultiselect({@required this.context, @required this.entity});

  final BuildContext context;
  final BaseEntity entity;
}

class RemoveFromDocumentMultiselect {
  RemoveFromDocumentMultiselect({@required this.context, @required this.entity});

  final BuildContext context;
  final BaseEntity entity;
}

class ClearDocumentMultiselect {
  ClearDocumentMultiselect({@required this.context});

  final BuildContext context;
}