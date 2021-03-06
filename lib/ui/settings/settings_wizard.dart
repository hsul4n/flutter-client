import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/static/static_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/entity_dropdown.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_form.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class SettingsWizard extends StatefulWidget {
  @override
  _SettingsWizardState createState() => _SettingsWizardState();
}

class _SettingsWizardState extends State<SettingsWizard> {
  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_settingsWizard');
  final FocusScopeNode _focusNode = FocusScopeNode();
  bool _autoValidate = false;
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _currencyId = kCurrencyUSDollar;
  String _languageId = kLanguageEnglish;

  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();

    _controllers = [
      _nameController,
      _firstNameController,
      _lastNameController,
    ];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controllers.forEach((dynamic controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _onSavePressed() {
    final bool isValid = _formKey.currentState.validate();

    setState(() {
      _autoValidate = !isValid;
    });

    if (!isValid) {
      return;
    }

    
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;

    return AlertDialog(
      title: Text(localization.settings),
      content: AppForm(
        focusNode: _focusNode,
        formKey: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedFormField(
                autofocus: true,
                label: localization.companyName,
                autovalidate: _autoValidate,
                controller: _nameController,
                validator: (value) =>
                    value.isEmpty ? localization.pleaseEnterAValue : null,
              ),
              DecoratedFormField(
                label: localization.firstName,
                autovalidate: _autoValidate,
                controller: _firstNameController,
                validator: (value) =>
                    value.isEmpty ? localization.pleaseEnterAValue : null,
              ),
              DecoratedFormField(
                label: localization.lastName,
                autovalidate: _autoValidate,
                controller: _lastNameController,
                validator: (value) =>
                    value.isEmpty ? localization.pleaseEnterAValue : null,
              ),
              EntityDropdown(
                key: ValueKey('__currency_${_currencyId}__'),
                allowClearing: true,
                entityType: EntityType.currency,
                entityList: memoizedCurrencyList(state.staticState.currencyMap),
                labelText: localization.currency,
                entityId: _currencyId,
                onSelected: (SelectableEntity currency) =>
                    setState(() => _currencyId = currency?.id),
                validator: (dynamic value) =>
                    value.isEmpty ? localization.pleaseEnterAValue : null,
              ),
              EntityDropdown(
                key: ValueKey('__language_${_languageId}__'),
                allowClearing: true,
                entityType: EntityType.language,
                entityList: memoizedLanguageList(state.staticState.languageMap),
                labelText: localization.language,
                entityId: _languageId,
                onSelected: (SelectableEntity language) =>
                    setState(() => _languageId = language?.id),
                validator: (dynamic value) =>
                    value.isEmpty ? localization.pleaseEnterAValue : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FlatButton(
            onPressed: _onSavePressed,
            child: Text(localization.save.toUpperCase()))
      ],
    );
  }
}
