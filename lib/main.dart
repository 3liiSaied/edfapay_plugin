import 'dart:io';

import 'package:edfapay_pg_plugin/edfapay_pg_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EdfaPgSdk.setEnableLogs(true);
  await EdfaPgSdk.initialize(apiKey: '', baseUrl: '');


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PaymentPage());
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const _applePayChannel = MethodChannel('edfapay_plugin/apple_pay');
  static const _applePayMerchantIdentifier =
      'merchant.com.example.edfapay';

  final TextEditingController _amountController = TextEditingController(text: '1.00');
  bool _busy = false;

  void _showMessage(String title, String msg) {
    final snack = SnackBar(content: Text('$title: $msg'));
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Future<void> _payWithCard() async {

    final text = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showMessage('Error', 'Enter a valid amount');
      return;
    }

    setState(() => _busy = true);
    try {

      final cardPay = EdfaPgSdk.cardPay()
        ..setOrder(EdfaPgSaleOrder(
          id: Uuid().v4(),
          amount: amount,
          currency: 'SAR',
          description: 'Sample order',
        ))
        ..setPayer(EdfaPgPayer(
          email: 'alisaied@gmail.com',
          phone: '+966551234567', firstName: '', lastName: '', address: '', country: '', city: '', zip: '', ip: '',
        ))

        ..setDesignType(EdfaPayDesignType.one)
        ..setAuth(true)
        ..onTransactionSuccess((result) => _showMessage('Success', 'Payment successful'))
        ..onTransactionFailure((error) => _showMessage('Failure', error.toString()));

      await cardPay.start();
    } catch (e) {
      _showMessage('Error', e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _payWithApple() async {
    if (!Platform.isIOS) {
      _showMessage('Info', 'Apple Pay is available only on iOS at runtime');
      return;
    }

    final text = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showMessage('Error', 'Enter a valid amount');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_applePayMerchantIdentifier == 'merchant.com.example.edfapay') {
        throw StateError(
          'Replace _applePayMerchantIdentifier with your Apple Pay Merchant ID.',
        );
      }

      final payment = await _applePayChannel.invokeMethod<Map<Object?, Object?>>(
        'start',
        {
          'amount': amount,
          'merchantIdentifier': _applePayMerchantIdentifier,
        },
      );
      final token = payment?['token'];
      if (token is! String || token.isEmpty) {
        throw StateError('Apple Pay did not return a payment token.');
      }

      final response = await EdfaPgSdk.applePay(
        ApplePayRequest(
          orderId: Uuid().v4(),
          amount: amount,
          currency: 'SAR',
          customer: ApplePayCustomer(
            name: 'John Doe',
            email: 'email@example.com',
            phone: '+966500000000',
          ),
          successUrl: '',
          failureUrl: ' ',
          card: ApplePayCard(token: token),
        ),
      );
      _showMessage('ApplePay result', response.toString());
    } catch (e) {
      _showMessage('ApplePay error', e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _payWithCheckout() async {

    final text = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showMessage('Error', 'Enter a valid amount');
      return;
    }
    final paymentAmount = amount.toInt();
    if (paymentAmount <= 0) {
      _showMessage('Error', 'Enter an amount of at least 1 SAR');
      return;
    }

    setState(() => _busy = true);
    try {

      final response = await EdfaPgSdk.externalPayment(
        ExternalPaymentRequest(
          orderId: Uuid().v4(),
          paymentMethod: ExternalPaymentMethod.tamara,
          amount: paymentAmount,
          currency: 'SAR',
          phoneNumber: '+966500000000',
          email: 'customer@example.com',
          invoice: InvoiceDto(
            shippingCharges: 0,
            extraCharges: 0,
            extraDiscount: 0,
            total: paymentAmount.toDouble(),
            lineItems: [
              LineItemDto(
                sku: 'checkout-order',
                description: 'Sample order',
                url: '',
                unitCost: paymentAmount.toDouble(),
                quantity: 1,
                netTotal: paymentAmount.toDouble(),
                discountRate: 0,
                discountAmount: 0,
                taxRate: 0,
                taxTotal: 0,
                total: paymentAmount.toDouble(),
              ),

            ],

          ),
        ),
      );
     // final checkoutUrl = response['checkoutDeeplink'];
      _showMessage('Checkout result ', response.toString());
     // debugPrint('Checkout URL: $checkoutUrl');

    } catch (e) {
      _showMessage('Checkout error', e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }
  Future<void> _void() async {


    setState(() => _busy = true);

    try {
      final response = await EdfaPgSdk.capture(transactionId: '' , amount: 100);

      debugPrint('REFUND: $response');
    } catch (e) {
      _showMessage('Error', e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EdfaPay Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Amount', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: 'SAR '),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _payWithCard,
              child: _busy ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Pay with Card'),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _payWithApple,
              child: const Text('Pay with Apple Pay'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}
