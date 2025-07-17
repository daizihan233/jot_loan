import 'package:flutter/material.dart';
import 'package:jot_loan/pages/add.dart';
import 'package:jot_loan/utils/sql.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:jot_loan/utils/models.dart';

import 'components/transfer_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase();
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
  String transferData = "加载中...";
  List<Transfer> transfers = [];
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
      setState(() {
        transfers = transfersList.reversed.toList();
        transferData = transfersList.isEmpty ? "没有转账记录" : "";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        transferData = "加载失败: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transfers.isEmpty
          ? Center(child: Text(transferData))
          : RefreshIndicator(
        onRefresh: _loadTransfers,
        child: ListView.builder(
          itemCount: transfers.length + 1, // 增加一项用于底部空白
          itemBuilder: (context, index) {
            if (index < transfers.length) {
              return TransferCard(
                transfer: transfers[index],
                onUpdate: _loadTransfers,
              );
            } else {
              // 添加一个透明的空容器作为底部空白
              return SizedBox(
                height: 100,
                child: Container(
                  // 可选：添加一些装饰让用户知道这是列表的底部
                  color: Colors.transparent,
                  // 如果希望更明显的视觉指示，可以添加:
                  child: Center(child: Icon(Icons.close, color: Colors.grey))
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MyAddPage())
          );
          _loadTransfers();
        },
        tooltip: '添加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

