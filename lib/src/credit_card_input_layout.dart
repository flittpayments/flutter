library cloudipsp_ui;

import 'package:flitt_mobile/src/cvv_utils.dart';
import 'package:flutter/widgets.dart';

import './credit_card_cvv_field.dart';
import './credit_card_exp_mm_field.dart';
import './credit_card_exp_yy_field.dart';
import './credit_card_number_field.dart';

import './credit_card.dart';

abstract class CreditCardInputLayout extends Widget {
  factory CreditCardInputLayout({Key? key, required Widget child}) =
      CreditCardInputLayoutImpl;
}

class CreditCardInputLayoutImpl extends StatefulWidget
    implements CreditCardInputLayout {
  final Widget _child;

  CreditCardInputLayoutImpl({Key? key, required Widget child})
      : _child = child,
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CreditCardInputLayoutState(_child);
  }
}

abstract class CreditCardInputState {
  CreditCard getCard();
}

class CreditCardInputLayoutState extends State<CreditCardInputLayoutImpl>
    implements CreditCardInputState {
  final Widget _child;
  final CreditCardNumberFieldImpl _number;
  final CreditCardExpMmFieldImpl _expMm;
  final CreditCardExpYyFieldImpl _expYy;
  final CreditCardCvvFieldImpl _cvv;

  CreditCardInputLayoutState(Widget child)
      : _child = child,
        _number = _findStrict(child, 'CreditCardNumberField'),
        _expMm = _findStrict(child, 'CreditCardExpMmField'),
        _expYy = _findStrict(child, 'CreditCardExpYyField'),
        _cvv = _findStrict(child, 'CreditCardCvvField') {
    _number.textEditingController.addListener(() {
      _cvv.setCvv4(CvvUtils.isCvv4Length(_number.textEditingController.text));
    });
  }

  void setHelpCard(String number, String expMm, String expYy, String cvv) {
    _number.textEditingController.text = number;
    _expMm.textEditingController.text = expMm;
    _expYy.textEditingController.text = expYy;
    _cvv.textEditingController.text = cvv;
  }

  @override
  CreditCard getCard() {
    return PrivateCreditCard(
        _number.textEditingController.text,
        int.tryParse(_expMm.textEditingController.text) ?? -1,
        int.tryParse(_expYy.textEditingController.text) ?? -1,
        _cvv.textEditingController.text);
  }

  @override
  Widget build(BuildContext context) {
    return _child;
  }

  static T _findStrict<T extends Widget>(Widget root, String name) {
    final result = _findNested<T>(root);
    if (result == null) {
      throw StateError('$name must exists in view tree');
    }
    return result;
  }

  static T? _findNested<T extends Widget>(Widget root) {
    if (root is T) {
      return root;
    }
    if (root is MultiChildRenderObjectWidget) {
      for (Widget child in root.children) {
        final fount = _findNested<T>(child);
        if (fount != null) {
          return fount;
        }
      }
    } else if (root is ProxyWidget) {
      return _findNested<T>(root.child);
    }
    return null;
  }
}
