import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:jot_loan/utils/sql.dart';
import 'package:intl/intl.dart';

class MyAddPage extends StatefulWidget {
  final VoidCallback onUpdate;
  const MyAddPage({super.key, required this.onUpdate});

  @override
  State<MyAddPage> createState() => _MyAddPageState();
}

class _MyAddPageState extends State<MyAddPage> {
  final _formKey = GlobalKey<FormState>();
  final borrowerController = TextEditingController();
  final lenderController = TextEditingController();
  final amountController = TextEditingController();
  final startController = TextEditingController();
  final stopController = TextEditingController();
  final reasonController = TextEditingController();

  @override
  void dispose() {
    borrowerController.dispose();
    lenderController.dispose();
    amountController.dispose();
    startController.dispose();
    stopController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _importData() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final borrower = borrowerController.text;
      final lender = lenderController.text;
      final amount = Decimal.parse(amountController.text);
      final start = convertToTimestamp(startController.text);
      final stop = stopController.text.isNotEmpty
          ? convertToTimestamp(stopController.text)
          : null;
      final reason = reasonController.text;

      final transfer = Transfer(
        borrower: borrower,
        lender: lender,
        amount: amount,
        money: Decimal.zero,
        start: start,
        stop: stop,
        reason: reason,
      );

      await insertTransfer(transfer);
      widget.onUpdate(); // 刷新上级页面

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加成功')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('添加借款记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // 借款人
            TextFormField(
              controller: borrowerController,
              decoration: const InputDecoration(
                labelText: '借款人',
                hintText: '谁借的钱？',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入借款人';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 出借人
            TextFormField(
              controller: lenderController,
              decoration: const InputDecoration(
                labelText: '出借人',
                hintText: '钱借给了谁？',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入出借人';
                }
                if (value == borrowerController.text) {
                  return '借款人和出借人不能相同';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 借款金额
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '借款金额',
                hintText: '请输入借款金额',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入借款金额';
                }
                final amount = Decimal.tryParse(value);
                if (amount == null || amount <= Decimal.zero) {
                  return '请输入有效的金额';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 借款日期
            TextFormField(
              controller: startController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '借款日期',
                hintText: '选择借款日期',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (date != null) {
                  startController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择借款日期';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 还款日期
            TextFormField(
              controller: stopController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '还款日期',
                hintText: '选择还款日期 (可选)',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              onTap: () async {
                final initialDate = DateTime.now().add(const Duration(days: 30));
                final date = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );

                if (date != null) {
                  stopController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 16),

            // 借款原因
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '借款原因',
                hintText: '请输入借款用途或备注',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),

            // 提交按钮
            ElevatedButton(
              onPressed: _importData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('添加借款记录', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}