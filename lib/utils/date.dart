import 'package:intl/intl.dart';


int convertToTimestamp(String dateStr) {
  // 创建日期格式化器（指定格式）
  final format = DateFormat("yyyy-MM-dd");

  // 解析为本地时区时间（直接）
  DateTime localDate = format.parse(dateStr, true).toLocal();

  // 返回时间戳（秒）
  return localDate.millisecondsSinceEpoch ~/ 1000;
}

int? convertToTimestampSafe(String? dateStr) {
  if (dateStr == null || dateStr == "") {
    return null;
  }
  // 创建日期格式化器（指定格式）
  final format = DateFormat("yyyy-MM-dd");

  // 解析为本地时区时间（直接）
  DateTime localDate = format.parse(dateStr, true).toLocal();

  // 返回时间戳（秒）
  return localDate.millisecondsSinceEpoch ~/ 1000;
}

String convertToString(int? timestamp) {
  if (timestamp == null) return "";
  DateTime localDate = DateTime.fromMicrosecondsSinceEpoch(timestamp * 1000);
  return "${localDate.year}-${localDate.month}-${localDate.day}";
}