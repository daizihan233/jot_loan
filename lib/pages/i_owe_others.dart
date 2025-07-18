import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:jot_loan/utils/sql.dart';

class IOweOthersPage extends StatefulWidget {
  const IOweOthersPage({super.key});

  @override
  State<IOweOthersPage> createState() => _IOweOthersPageState();
}

class _IOweOthersPageState extends State<IOweOthersPage> {
  List<Transfer> transfers = [];
  Map<String, Decimal> borrowerTotals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  Future<void> _loadTransfers() async {
    setState(() => isLoading = true);

    try {
      final transfersList = await getTransfers();

      // 过滤出别人欠我的记录（我是出借人）
      final filteredTransfers = transfersList.where((t) =>
      t.lender == "我" && t.borrower != "我" && t.money < t.amount
      ).toList();

      // 按借款人分组并计算总欠款
      final totals = <String, Decimal>{};
      for (var transfer in filteredTransfers) {
        totals.update(
            transfer.borrower,
                (value) => value + (transfer.amount - transfer.money),
            ifAbsent: () => transfer.amount - transfer.money
        );
      }

      setState(() {
        transfers = filteredTransfers;
        borrowerTotals = totals;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我欠别人'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : borrowerTotals.isEmpty
          ? const Center(child: Text('没有欠款记录'))
          : Column(
        children: [
          // 顶部统计卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '欠款统计',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总欠款人数:'),
                      Text(
                        borrowerTotals.length.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总欠款金额:'),
                      Text(
                        borrowerTotals.values
                            .fold(Decimal.zero, (sum, value) => sum + value)
                            .toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 借款人列表
          Expanded(
            child: ListView.builder(
              itemCount: borrowerTotals.length,
              itemBuilder: (context, index) {
                final borrower = borrowerTotals.keys.elementAt(index);
                final totalAmount = borrowerTotals[borrower]!;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(borrower),
                    subtitle: Text('欠款总额: $totalAmount 元'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // 跳转到该借款人的详细记录页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BorrowerDetailPage(
                            borrower: borrower,
                            transfers: transfers.where((t) => t.borrower == borrower).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 借款人详情页面
class BorrowerDetailPage extends StatelessWidget {
  final String borrower;
  final List<Transfer> transfers;

  const BorrowerDetailPage({
    super.key,
    required this.borrower,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = transfers.fold(
        Decimal.zero,
            (sum, transfer) => sum + transfer.amount
    );

    final paidAmount = transfers.fold(
        Decimal.zero,
            (sum, transfer) => sum + transfer.money
    );

    final remainingAmount = totalAmount - paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('我欠 $borrower'),
      ),
      body: Column(
        children: [
          // 顶部统计卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        borrower,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('总借款金额:'),
                      Text(
                        totalAmount.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('已还金额:'),
                      Text(
                        paidAmount.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('剩余欠款:'),
                      Text(
                        remainingAmount.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 借款记录列表
          Expanded(
            child: ListView.builder(
              itemCount: transfers.length,
              itemBuilder: (context, index) {
                final transfer = transfers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('借款金额: ${transfer.amount}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('已还: ${transfer.money}'),
                        Text('日期: ${convertToString(transfer.start)}'),
                        if (transfer.reason.isNotEmpty)
                          Text('事由: ${transfer.reason}'),
                      ],
                    ),
                    trailing: Text(
                      '剩余: ${transfer.amount - transfer.money}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}