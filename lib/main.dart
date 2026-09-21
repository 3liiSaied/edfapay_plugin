import 'dart:ffi';
import 'dart:io';

import 'package:edfapay_pg_plugin/edfapay_pg_sdk.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EdfaPgSdk.setEnableLogs(true);
  await EdfaPgSdk.initialize(apiKey: '574991A0E3817371784632FAA08B3EDB690877893FCE85A289869B354BA675CE', baseUrl: 'https://demo-api.edfapay.com');

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
          amount: 1000,
          currency: 'SAR',
          description: 'Sample order',
        ))
        ..setPayer(EdfaPgPayer(
          email: 'alisaied@gmail.com',
          phone: '+966551234567', firstName: '', lastName: '', address: '', country: '', city: '', zip: '', ip: '',
        ))
        ..setDesignType(EdfaPayDesignType.one)
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
      // Placeholder Apple Pay request. Fill required fields (merchantIdentifier, countryCode, etc.)
      // Update merchantIdentifier to your registered Apple Pay merchant id (e.g. 'merchant.com.example').

      final response = await EdfaPgSdk.applePay(ApplePayRequest(
        orderId: Uuid().v4(),
        amount: 0.11,
        currency: 'SAR',
        //merchantIdentifier: 'merchant.com.example',
        // <-- set your merchant id here
        customer: ApplePayCustomer(name: "John Doe", email: "email@example.com",
            phone: "+966500000000"),
        successUrl: '', failureUrl: '',

        card:ApplePayCard(token: "") , // optional per your Apple Pay configuration
      ));

      _showMessage('ApplePay result', response.toString());

    } catch (e) {
      _showMessage('ApplePay error', e.toString());
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
