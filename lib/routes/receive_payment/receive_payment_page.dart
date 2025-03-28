import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class ReceivePaymentPage extends StatefulWidget {
  static const String routeName = '/receive_payment';
  final int initialPageIndex;

  const ReceivePaymentPage({required this.initialPageIndex, super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  static const List<StatefulWidget> pages = <StatefulWidget>[
    ReceiveLightningPaymentPage(),
    ReceiveLightningAddressPage(),
    ReceiveBitcoinAddressPaymentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(_getTitle()),
        actions: widget.initialPageIndex == ReceiveLightningPaymentPage.pageIndex ||
                widget.initialPageIndex == ReceiveLightningAddressPage.pageIndex
            ? <Widget>[
                IconButton(
                  alignment: Alignment.center,
                  icon: Image(
                    image: const AssetImage('assets/icons/qr_scan.png'),
                    color: themeData.iconTheme.color,
                    fit: BoxFit.contain,
                    width: 24.0,
                    height: 24.0,
                  ),
                  tooltip: texts.lnurl_withdraw_scan_toolip,
                  onPressed: () => _scanBarcode(),
                ),
              ]
            : <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: pages.elementAt(widget.initialPageIndex),
      ),
    );
  }

  String _getTitle() {
    final BreezTranslations texts = context.texts();
    switch (widget.initialPageIndex) {
      case ReceiveLightningPaymentPage.pageIndex:
      case ReceiveLightningAddressPage.pageIndex:
        // TODO(erdemyerebasmaz): Add message to Breez-Translations
        return 'Receive with Lightning';
      case ReceiveBitcoinAddressPaymentPage.pageIndex:
        return texts.invoice_btc_address_title;
      default:
        return texts.invoice_lightning_title;
    }
  }

  void _scanBarcode() {
    final BreezTranslations texts = context.texts();
    final BuildContext currentContext = context;

    Focus.maybeOf(currentContext)?.unfocus();
    Navigator.pushNamed<String>(currentContext, QRScanView.routeName).then((String? barcode) async {
      if (barcode == null || barcode.isEmpty) {
        if (currentContext.mounted) {
          showFlushbar(
            currentContext,
            message: texts.payment_info_dialog_error_qrcode,
          );
        }
        return;
      }

      await _validateAndProcessInput(barcode);
    });
  }

  Future<void> _validateAndProcessInput(String barcode) async {
    final BreezTranslations texts = context.texts();
    final InputCubit inputCubit = context.read<InputCubit>();

    try {
      final InputType inputType = await inputCubit.parseInput(input: barcode);
      if (mounted) {
        if (inputType is InputType_LnUrlWithdraw) {
          handleWithdrawRequest(context, inputType.data);
        } else {
          showFlushbar(
            context,
            message: texts.payment_info_dialog_error_unsupported_input,
          );
        }
      }
    } catch (error) {
      final String errorMessage = error.toString().contains('Unrecognized')
          ? texts.payment_info_dialog_error_unsupported_input
          : error.toString();
      if (mounted) {
        showFlushbar(context, message: errorMessage);
      }
    }
  }
}
