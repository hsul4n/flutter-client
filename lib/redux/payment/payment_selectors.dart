import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:memoize/memoize.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';

var memoizedPaymentsByInvoice = memo3((String invoiceId,
        BuiltMap<String, PaymentEntity> paymentMap,
        BuiltList<String> paymentList) =>
    paymentsByInvoiceSelector(invoiceId, paymentMap, paymentList));

List<PaymentEntity> paymentsByInvoiceSelector(String invoiceId,
    BuiltMap<String, PaymentEntity> paymentMap, BuiltList<String> paymentList) {
  return paymentList
      .map((paymentId) => paymentMap[paymentId])
      .where((payment) => payment.invoiceId == invoiceId && !payment.isDeleted)
      .toList();
}

InvoiceEntity paymentInvoiceSelector(String paymentId, AppState state) {
  final payment =
      state.paymentState.map[paymentId] ?? PaymentEntity(id: paymentId);
  return state.invoiceState.map[payment.invoiceId] ??
      InvoiceEntity(id: payment.invoiceId);
}

ClientEntity paymentClientSelector(String paymentId, AppState state) {
  final invoice = paymentInvoiceSelector(paymentId, state);
  return state.clientState.map[invoice.clientId] ??
      ClientEntity(id: invoice.clientId);
}

var memoizedDropdownPaymentList = memo2(
    (BuiltMap<String, PaymentEntity> paymentMap,
            BuiltList<String> paymentList) =>
        dropdownPaymentsSelector(paymentMap, paymentList));

List<String> dropdownPaymentsSelector(
    BuiltMap<String, PaymentEntity> paymentMap, BuiltList<String> paymentList) {
  final list =
      paymentList.where((paymentId) => paymentMap[paymentId].isActive).toList();

  list.sort((paymentAId, paymentBId) {
    final paymentA = paymentMap[paymentAId];
    final paymentB = paymentMap[paymentBId];
    return paymentA.compareTo(paymentB, PaymentFields.paymentDate, true);
  });

  return list;
}

var memoizedFilteredPaymentList = memo5(
    (BuiltMap<String, PaymentEntity> paymentMap,
            BuiltList<String> paymentList,
            BuiltMap<String, InvoiceEntity> invoiceMap,
            BuiltMap<String, ClientEntity> clientMap,
            ListUIState paymentListState) =>
        filteredPaymentsSelector(
            paymentMap, paymentList, invoiceMap, clientMap, paymentListState));

List<String> filteredPaymentsSelector(
    BuiltMap<String, PaymentEntity> paymentMap,
    BuiltList<String> paymentList,
    BuiltMap<String, InvoiceEntity> invoiceMap,
    BuiltMap<String, ClientEntity> clientMap,
    ListUIState paymentListState) {
  final list = paymentList.where((paymentId) {
    final payment = paymentMap[paymentId];
    if (!payment.matchesStates(paymentListState.stateFilters)) {
      return false;
    }

    final invoice =
        invoiceMap[payment.invoiceId] ?? InvoiceEntity(id: payment.invoiceId);
    final client =
        clientMap[invoice.clientId] ?? ClientEntity(id: invoice.clientId);

    if (paymentListState.filterEntityId != null) {
      if (paymentListState.filterEntityType == EntityType.client &&
          invoice.clientId != paymentListState.filterEntityId) {
        return false;
      } else if (paymentListState.filterEntityType == EntityType.invoice &&
          payment.invoiceId != paymentListState.filterEntityId) {
        return false;
      }
    } else if (invoice.isDeleted || !client.isActive) {
      return false;
    }

    return payment.matchesFilter(paymentListState.filter);
  }).toList();

  list.sort((paymentAId, paymentBId) {
    final paymentA = paymentMap[paymentAId];
    final paymentB = paymentMap[paymentBId];
    return paymentA.compareTo(
        paymentB, paymentListState.sortField, paymentListState.sortAscending);
  });

  return list;
}

var memoizedPaymentStatsForClient = memo5((String clientId,
        BuiltMap<String, PaymentEntity> paymentMap,
        BuiltMap<String, InvoiceEntity> invoiceMap,
        String activeLabel,
        String archivedLabel) =>
    invoiceStatsForClient(
        clientId, paymentMap, invoiceMap, activeLabel, archivedLabel));

String invoiceStatsForClient(
    String clientId,
    BuiltMap<String, PaymentEntity> paymentMap,
    BuiltMap<String, InvoiceEntity> invoiceMap,
    String activeLabel,
    String archivedLabel) {
  int countActive = 0;
  int countArchived = 0;
  paymentMap.forEach((paymentId, payment) {
    if (invoiceMap.containsKey(payment.invoiceId) &&
        invoiceMap[payment.invoiceId].clientId == clientId) {
      if (payment.isActive) {
        countActive++;
      } else if (payment.isArchived) {
        countArchived++;
      }
    }
  });

  String str = '';
  if (countActive > 0) {
    str = '$countActive $activeLabel';
    if (countArchived > 0) {
      str += ' • ';
    }
  }
  if (countArchived > 0) {
    str += '$countArchived $archivedLabel';
  }

  return str;
}

bool hasPaymentChanges(
        PaymentEntity payment, BuiltMap<String, PaymentEntity> paymentMap) =>
    payment.isNew ? payment.isChanged : payment != paymentMap[payment.id];
