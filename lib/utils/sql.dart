import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:jot_loan/utils/models.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

dynamic transferDb;

Future<void> initDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    print("initDatabase");
  }
  // 关键：初始化 FFI 数据库工厂（针对桌面平台）
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化 FFI 绑定
    sqfliteFfiInit();

    // 设置数据库工厂
    databaseFactory = databaseFactoryFfi;
  }

  transferDb = openDatabase(
   join(await getDatabasesPath(), 'transfer.db'),
   onCreate: (db, version) {
    return db.execute(
     """CREATE TABLE transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    borrower TEXT NOT NULL,    -- 借款人
    lender TEXT NOT NULL,      -- 出借人
    amount TEXT NOT NULL,      -- 高精度金额字符串
    money TEXT NOT NULL,       -- 已还款数额
    start TIMESTAMP NOT NULL,  -- 借款日期 (second)
    stop TIMESTAMP,            -- 还款日期 (可为空)
    reason TEXT,               -- 借款原因
    
    -- 数据完整性约束
    CHECK (borrower != lender),
    CHECK (json_valid(amount) OR CAST(amount AS REAL) > 0), -- 金额有效性检查
    CHECK (json_valid(money) OR CAST(money AS REAL) >= 0)   -- 金额有效性检查
);""",
    );
   },
   // Set the version. This executes the onCreate function and provides a
   // path to perform database upgrades and downgrades.
   version: 1,
  );
}

Future<void> insertTransfer(Transfer transfer) async {
  final db = await transferDb;
  await db.insert(
    'transfers',
    transfer.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


// 现在在 sql.dart 文件中添加更新和删除方法
Future<void> updateTransfer(Transfer transfer) async {
  final db = await transferDb;
  await db.update(
    'transfers',
    transfer.toMap(),
    where: 'id = ?',
    whereArgs: [transfer.id],
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> deleteTransfer(int id) async {
  final db = await transferDb;
  await db.delete(
    'transfers',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// 修改 getTransfers 方法处理 Decimal 类型的空值情况
Future<List<Transfer>> getTransfers() async {
  final db = await transferDb;
  final List<Map<String, Object?>> transfers = await db.query('transfers');
  return [
    for (
      final {
        'id': id as int, 'borrower': borrower as String,
        'lender': lender as String, 'amount': amount as String,
        'money': money as String, 'start': start as int,
        'stop': stop as int?, 'reason': reason as String?
      } in transfers
    )
      Transfer(
        id: id,
        borrower: borrower,
        lender: lender,
        amount: amount.isNotEmpty ? Decimal.parse(amount) : Decimal.zero,
        money: money.isNotEmpty ? Decimal.parse(money) : Decimal.zero,
        start: start,
        stop: stop,
        reason: reason ?? '',
      )
  ];
}
