import 'package:decimal/decimal.dart';

class Transfer {
  final int? id;
  final String borrower;  // 借方（谁借）
  final String lender;  // 贷方（借谁）
  final Decimal amount;  // 总计金额
  final Decimal money;  // 已还款金额
  final int start;  // 借款日
  final int? stop;  // 还款日
  final String reason;  // 原因 / 备注

  const Transfer({
    this.id, required this.borrower, required this.lender, required this.amount,
    required this.money, required this.start, this.stop, required this.reason
  });

  Map<String, Object?> toMap() {
    return {
      'id': id, 'borrower': borrower, 'lender': lender,
      'amount': amount.toString(), 'money': money.toString(), 'start': start,
      'stop': stop, 'reason': reason
    };
  }

  @override
  String toString() {
    return 'Transfer{id: $id, borrower: $borrower, lender: $lender, '
        'amount: $amount, money: $money, start: $start, stop: $stop, '
        'reason: $reason}';
  }

  Transfer copyWith({
    int? id,
    String? borrower,
    String? lender,
    Decimal? amount,
    Decimal? money,
    int? start,
    int? stop,
    String? reason,
  }) {
    return Transfer(
      id: id ?? this.id,
      borrower: borrower ?? this.borrower,
      lender: lender ?? this.lender,
      amount: amount ?? this.amount,
      money: money ?? this.money,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      reason: reason ?? this.reason,
    );
  }
}