import 'package:flutter/material.dart';
import 'package:jot_loan/pages/add.dart';
import 'package:jot_loan/utils/date.dart';
import 'package:jot_loan/utils/sql.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:jot_loan/utils/models.dart'; // 确保导入模型

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保绑定初始化
  await initDatabase(); // 等待数据库初始化完成
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '借有谱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '转账详情'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 状态变量
  String transferData = "加载中...";
  List<Transfer> transfers = []; // 存储获取的转账数据

  @override
  void initState() {
    super.initState();
    // 在 initState 中调用数据加载
    _loadTransfers();
  }

  // 异步加载数据的方法
  Future<void> _loadTransfers() async {
    try {
      // 获取数据
      final transfersList = await getTransfers();

      // 更新状态并刷新UI
      setState(() {
        transfers = transfersList;
        transferData = transfersList.isNotEmpty
            ? transfersList.toString()
            : "没有转账记录";
      });
    } catch (e) {
      // 处理错误
      setState(() {
        transferData = "加载失败: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadTransfers();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // 添加刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers,
          ),
        ],
      ),
      drawer: SidebarX(
        theme: const SidebarXTheme(width: 200, padding: EdgeInsets.all(8.0)),
        controller: SidebarXController(selectedIndex: 0, extended: true),
        items: const [
          SidebarXItem(icon: Icons.home, label: '转账详情'),
          SidebarXItem(icon: Icons.search, label: '别人欠我'),
          SidebarXItem(icon: Icons.search, label: '我欠别人'),
        ],
      ),
      body: Center(
        child: transfers.isEmpty
            ? Text(transferData) // 显示加载状态或错误信息
            : ListView.builder( // 显示转账列表
          itemCount: transfers.length,
          itemBuilder: (context, index) {
            final transfer = transfers[index];
            String startDate = convertToString(transfer.start);
            String stopDate = convertToString(transfer.stop);
            String displayDate = "自 $startDate 至 $stopDate";
            if (stopDate == "") {
              String displayDate = "自 $startDate 以来";
            }
            return Card(
              elevation: 3, // 阴影深度
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text("${transfer.borrower} → ${transfer.lender}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("已还 / 总额: ${transfer.money} / ${transfer.amount}"),
                    Text("未还: ${transfer.amount - transfer.money}"),
                    Text(displayDate),
                    if (transfer.reason.isNotEmpty) Text("事由: ${transfer.reason}"),
                  ],
                ),
                trailing: transfer.money < transfer.amount
                    ? Icon(Icons.pending, color: Colors.orange)
                    : Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 添加新记录后刷新数据
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MyAddPage())
          );
          _loadTransfers(); // 返回后刷新数据
        },
        tooltip: '添加',
        child: const Icon(Icons.add),
      ),
    );
  }
}