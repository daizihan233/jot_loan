import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:jot_loan/utils/sql.dart';

class EditTransferPage extends StatefulWidget {
  final Transfer transfer;
  final VoidCallback onUpdate;

  const EditTransferPage({
    super.key,
    required this.transfer,
    required this.onUpdate,
  });

  @override
  State<EditTransferPage> createState() => _EditTransferPageState();
}

class _EditTransferPageState extends State<EditTransferPage> {
  late TextEditingController borrowerController;
  late TextEditingController lenderController;
  late TextEditingController amountController;
  late TextEditingController startController;
  late TextEditingController stopController;
  late TextEditingController reasonController;

  @override
  void initState() {
    super.initState();
    final transfer = widget.transfer;

    // 使用当前值初始化控制器
    borrowerController = TextEditingController(text: transfer.borrower);
    lenderController = TextEditingController(text: transfer.lender);
    amountController = TextEditingController(text: transfer.amount.toString());
    startController = TextEditingController(
        text: convertToString(transfer.start)
    );
    stopController = TextEditingController(
        text: transfer.stop != null && transfer.stop != 0
            ? convertToString(transfer.stop!)
            : ""
    );
    reasonController = TextEditingController(text: transfer.reason);
  }

  @override
  void dispose() {
    // 清理所有控制器
    borrowerController.dispose();
    lenderController.dispose();
    amountController.dispose();
    startController.dispose();
    stopController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _updateTransfer() async {
    // 基本验证
    if (borrowerController.text.isEmpty || lenderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('借款人和出借人不能为空')),
      );
      return;
    }

    if (borrowerController.text == lenderController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('借款人和出借人不能相同')),
      );
      return;
    }

    final amount = Decimal.tryParse(amountController.text);
    if (amount == null || amount <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输有效的借款金额')),
      );
      return;
    }

    final startTimestamp = convertToTimestamp(startController.text);
    if (startTimestamp == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的借款日期')),
      );
      return;
    }

    // 检查还款日期
    int? stopTimestamp;
    if (stopController.text.isNotEmpty) {
      stopTimestamp = convertToTimestamp(stopController.text);
      if (stopTimestamp == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的还款日期')),
        );
        return;
      }

      // 还款日期必须晚于借款日期
      if (stopTimestamp <= startTimestamp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('还款日期必须晚于借款日期')),
        );
        return;
      }
    }

    // 创建更新后的Transfer对象
    final updatedTransfer = widget.transfer.copyWith(
      borrower: borrowerController.text,
      lender: lenderController.text,
      amount: amount,
      start: startTimestamp,
      stop: stopTimestamp,
      reason: reasonController.text,
    );

    // 更新数据库
    try {
      await updateTransfer(updatedTransfer);
      widget.onUpdate(); // 刷新上级页面
      if (mounted) Navigator.pop(context); // 返回上级页面
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
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
          title: const Text('修改借款记录'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
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
                    labelText: '借款人',
                    hintText: '谁借的钱？'
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: lenderController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '出借人',
                    hintText: '钱借给了谁？'
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '借款金额',
                    hintText: '请输入借款金额'
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: startController,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.fromMillisecondsSinceEpoch(
                        widget.transfer.start * 1000
                    ),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (date != null) {
                    startController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '借款日期',
                  hintText: '格式：YYYY-MM-DD',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: stopController,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: widget.transfer.stop != null
                        ? DateTime.fromMillisecondsSinceEpoch(widget.transfer.stop! * 1000)
                        : DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (date != null) {
                    stopController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '还款日期',
                  hintText: '格式：YYYY-MM-DD (可选)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '借款原因',
                    hintText: '请输入借款用途或备注'
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _updateTransfer,
          tooltip: '保存修改',
          child: const Icon(Icons.save),
        )
    );
  }
}