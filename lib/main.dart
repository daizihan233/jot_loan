import 'package:flutter/material.dart';
import 'package:jot_loan/pages/add.dart';
import 'package:jot_loan/pages/others_owe_me.dart';
import 'package:jot_loan/pages/i_owe_others.dart';
import 'package:jot_loan/utils/sql.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:jot_loan/utils/models.dart';

import 'components/transfer_card.dart';

Function? transferPageState;

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
      home: const MyHomePage(title: '借有谱'),
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
  // 添加页面控制器
  final _pageController = PageController();
  int _currentIndex = 0;

  // 页面列表
  final List<Widget> _pages = [
    const TransferListPage(), // 转账详情页面
    const OthersOweMePage(), // 别人欠我页面
    const IOweOthersPage(), // 我欠别人页面
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    await transferPageState!();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_currentIndex == 0) IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransfers
          ),
        ],
      ),
      drawer: SidebarX(
        theme: const SidebarXTheme(width: 200, padding: EdgeInsets.all(8.0)),
        controller: SidebarXController(selectedIndex: _currentIndex, extended: true),
        items: [
          SidebarXItem(
              icon: Icons.home, label: '转账详情',
              onTap: () {
                setState(() => _currentIndex = 0);
                _pageController.jumpToPage(0);
              }
          ),
          SidebarXItem(
              icon: Icons.people, label: '别人欠我',
              onTap: () {
                setState(() => _currentIndex = 1);
                _pageController.jumpToPage(1);
              }
          ),
          SidebarXItem(
              icon: Icons.person, label: '我欠别人',
              onTap: () {
                setState(() => _currentIndex = 2);
                _pageController.jumpToPage(2);
              }
          ),
        ]
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MyAddPage(onUpdate: _loadTransfers,))
          );
          _loadTransfers();
        },
        tooltip: '添加',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

// 将原有的 MyHomePage 重构为 TransferListPage
class TransferListPage extends StatefulWidget {
  const TransferListPage({super.key});

  @override
  State<TransferListPage> createState() => _TransferListPageState();
}

class _TransferListPageState extends State<TransferListPage> {
  String transferData = "加载中...";
  List<Transfer> transfers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransfers();
    transferPageState = _loadTransfers;
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : transfers.isEmpty
        ? Center(child: Text(transferData))
        : RefreshIndicator(
      onRefresh: _loadTransfers,
      child: ListView.builder(
        itemCount: transfers.length + 1,
        itemBuilder: (context, index) {
          if (index < transfers.length) {
            return TransferCard(
              transfer: transfers[index],
              onUpdate: _loadTransfers,
            );
          } else {
            return const SizedBox(height: 100);
          }
        },
      ),
    );
  }
}