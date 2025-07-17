import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:jot_loan/utils/sql.dart';

Future<void> importData (
    String borrower, String lender, Decimal amount, int start, int? stop,
    String reason
) async {
  Transfer transfer = Transfer(
      borrower: borrower, lender: lender, amount: amount, money: Decimal.zero,
      start: start, stop: stop, reason: reason
  );
  if (kDebugMode) {
    print(transfer.toString());
  }
  await insertTransfer(transfer);
}

class MyAddPage extends StatefulWidget {
  const MyAddPage({super.key});

  @override
  State<MyAddPage> createState() => _MyAddPageState();
}

class _MyAddPageState extends State<MyAddPage> {
  final borrowerController = TextEditingController();
  final lenderController = TextEditingController();
  final amountController = TextEditingController();
  final startController = TextEditingController();
  final stopController = TextEditingController();
  final reasonController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    borrowerController.dispose();
    lenderController.dispose();
    amountController.dispose();
    startController.dispose();
    stopController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('添加数据'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), onPressed: (){
            Navigator.pop(context);
          }
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: borrowerController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '谁借？',
                hintText: '借别人钱请填写“我”'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: lenderController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '借谁？',
                hintText: '别人借钱请填写“我”'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: amountController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '借多少？',
                hintText: '借款数额，支持小数'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: startController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '什么时候借的？',
                hintText: '格式：YYYY-MM-DD，如 2025-06-08'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: stopController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '什么时候还清？',
                hintText: '格式：YYYY-MM-DD，如 2025-06-08'
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '为什么要借？',
                hintText: '用途或备注'
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          importData(
            borrowerController.text, lenderController.text,
            Decimal.parse(amountController.text),
            convertToTimestamp(startController.text),
            convertToTimestampSafe(stopController.text), reasonController.text
          );
          Navigator.pop(context);
        },
        tooltip: '导入',
        child: const Icon(Icons.import_export),
      )
    );
  }
}
