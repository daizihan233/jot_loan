import 'package:flutter/material.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:decimal/decimal.dart';

import '../pages/edit.dart';
import '../utils/sql.dart';

class TransferCard extends StatefulWidget {
  final Transfer transfer;
  final VoidCallback onUpdate;

  const TransferCard({
    super.key,
    required this.transfer,
    required this.onUpdate,
  });

  @override
  State<TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<TransferCard> {
  bool isExpanded = false;

  // 计算还款进度 (0.0 - 1.0)
  double get _progress {
    if (widget.transfer.amount == Decimal.zero) return 0.0;
    return (widget.transfer.money / widget.transfer.amount).toDouble();
  }

  // 计算还款日进度 (0.0 - 1.0)
  double get _dateProgress {
    if (widget.transfer.stop == 0) return 0.0;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final start = widget.transfer.start;
    final stop = widget.transfer.stop;

    // 已逾期
    if (now > stop!) return 1.0;

    // 计算时间进度
    final totalDuration = stop - start;
    final elapsed = now - start;

    return elapsed / totalDuration;
  }

  // 是否逾期
  bool get _isOverdue {
    if (_progress >= 1.0) return false; // 已还清不算逾期

    final stop = widget.transfer.stop;
    if (stop == null || stop == 0) return false; // 未设置还款日期不算逾期

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now > stop;
  }

  // 是否已还清
  bool get _isFullyPaid {
    return _progress >= 1.0;
  }

  // 计算剩余天数
  int get _daysRemaining {
    if (widget.transfer.stop == 0) return 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = widget.transfer.stop! - now;
    return (remaining / 86400).ceil(); // 86400秒 = 1天
  }

  @override
  Widget build(BuildContext context) {
    final transfer = widget.transfer;
    final remainingAmount = transfer.amount - transfer.money;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => isExpanded = !isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transfer.borrower} → ${transfer.lender}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isFullyPaid)
                    const Icon(Icons.check_circle, color: Colors.green, size: 24)
                  else if (_isOverdue)
                    const Icon(Icons.warning, color: Colors.red, size: 24)
                ],
              ),

              const SizedBox(height: 12),

              // 金额信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '总金额: ${transfer.amount}元',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    '已还: ${transfer.money}元',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isFullyPaid ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 还款进度条
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isOverdue ? Colors.red : Colors.blue,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),

              const SizedBox(height: 8),

              // 进度百分比和剩余金额
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '还款进度: ${(_progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '剩余: $remainingAmount元',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 日期信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '自 ${convertToString(transfer.start)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (transfer.stop != null && transfer.stop != 0)
                    Text(
                      '至: ${convertToString(transfer.stop)}',
                      style: TextStyle(
                        color: _isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: _isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),

              // 还款日进度条（如果有还款日期）
              if (transfer.stop != null && transfer.stop != 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _dateProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isOverdue ? Colors.red : Colors.orange,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),

                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '时间进度',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      _isOverdue
                          ? '已逾期 ${-_daysRemaining} 天'
                          : (_isFullyPaid ? '已完成' : '剩余 $_daysRemaining 天'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOverdue ? Colors.red : Colors.orange,
                        fontWeight: _isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],

              // 借款原因
              if (transfer.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '事由: ${transfer.reason}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],

              // 可展开的操作区域
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Container(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: '修改',
                          color: Colors.blue,
                          onPressed: () => _editTransfer(context),
                        ),
                        _buildActionButton(
                          icon: Icons.payment,
                          label: '还款',
                          color: Colors.green,
                          onPressed: () => _addRepayment(context),
                        ),
                        _buildActionButton(
                          icon: Icons.check_circle,
                          label: '还清',
                          color: Colors.green,
                          onPressed: () => _markAsPaid(context),
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: '删除',
                          color: Colors.red,
                          onPressed: () => _deleteTransfer(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Future<void> _editTransfer(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTransferPage(
          transfer: widget.transfer,
          onUpdate: widget.onUpdate,
        ),
      ),
    );
  }

  void _addRepayment(BuildContext context) {
    final remaining = widget.transfer.amount - widget.transfer.money;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加还款'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '还款金额 (最大 $remaining 元)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = Decimal.tryParse(controller.text);
              if (value == null || value <= Decimal.zero) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效金额')),
                );
                return;
              }

              if (value > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('金额不能超过 $remaining 元')),
                );
                return;
              }

              await updateTransfer(
                  widget.transfer.copyWith(
                      money: widget.transfer.money + value
                  )
              );

              widget.onUpdate(); // 刷新UI
              Navigator.pop(context);
            },
            child: const Text('确认还款'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('标记为已还清'),
        content: const Text('确定要将此笔借款标记为已还清吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateTransfer(
                  widget.transfer.copyWith(
                    money: widget.transfer.amount,
                  )
              );

              widget.onUpdate(); // 刷新UI
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _deleteTransfer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这条转账记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await deleteTransfer(widget.transfer.id as int);
              widget.onUpdate(); // 刷新UI
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}