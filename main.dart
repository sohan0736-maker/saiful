import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(TradingApp());
}

class TradingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trading Journal PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF1E1E1E),
        ),
      ),
      home: Dashboard(),
    );
  }
}

// Model
class Trade {
  String id;
  String symbol;
  String type;
  double entry;
  double exit;
  double profit;
  DateTime date;

  Trade({
    required this.id,
    required this.symbol,
    required this.type,
    required this.entry,
    required this.exit,
    required this.profit,
    required this.date,
  });
}

// Database / State Memory
class TradeDB {
  static List<Trade> trades = [];

  static void addTrade(Trade trade) {
    trades.add(trade);
  }

  static List<Trade> getAll() {
    return List.from(trades.reversed);
  }

  static List<Trade> getRecent() {
    List<Trade> reversedList = List.from(trades.reversed);
    return reversedList.length > 5 ? reversedList.sublist(0, 5) : reversedList;
  }
}

// Dashboard Screen
class Dashboard extends StatefulWidget {
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Trade> recent = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    recent = TradeDB.getRecent();
    setState(() {});
  }

  double totalProfit() {
    double total = 0;
    for (var t in TradeDB.getAll()) {
      total += t.profit;
    }
    return total;
  }

  int winRate() {
    var all = TradeDB.getAll();
    if (all.isEmpty) return 0;
    int wins = all.where((t) => t.profit > 0).length;
    return ((wins / all.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    double profit = totalProfit();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trading Journal PRO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddTrade()));
          load();
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Win Rate", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text("${winRate()}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Total Profit", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            profit >= 0 ? "+${profit.toStringAsFixed(2)}" : profit.toStringAsFixed(2), 
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: profit >= 0 ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Trades", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AllTrades())).then((_) => load());
                  },
                  child: const Text("More Trades →", style: TextStyle(color: Colors.amber)),
                )
              ],
            ),
            Expanded(
              child: recent.isEmpty
                  ? const Center(child: Text("No trades recorded yet.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: recent.length,
                      itemBuilder: (context, i) {
                        final t = recent[i];
                        bool isWin = t.profit >= 0;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isWin ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              child: Icon(isWin ? Icons.arrow_upward : Icons.arrow_downward, color: isWin ? Colors.green : Colors.red),
                            ),
                            title: Text("${t.symbol} [${t.type}]", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Entry: ${t.entry} → Exit: ${t.exit}", style: const TextStyle(color: Colors.grey)),
                            trailing: Text(
                              isWin ? "+${t.profit.toStringAsFixed(2)}" : t.profit.toStringAsFixed(2),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isWin ? Colors.green : Colors.red),
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

// Add Trade Screen
class AddTrade extends StatefulWidget {
  @override
  State<AddTrade> createState() => _AddTradeState();
}

class _AddTradeState extends State<AddTrade> {
  final symbolController = TextEditingController();
  final entryController = TextEditingController();
  final exitController = TextEditingController();
  String type = "Buy";

  void save() {
    if (symbolController.text.isEmpty || entryController.text.isEmpty || exitController.text.isEmpty) return;

    double? e = double.tryParse(entryController.text);
    double? x = double.tryParse(exitController.text);
    if (e == null || x == null) return;

    double profit = type == "Buy" ? (x - e) : (e - x);

    Trade trade = Trade(
      id: const Uuid().v4(),
      symbol: symbolController.text.toUpperCase().trim(),
      type: type,
      entry: e,
      exit: x,
      profit: profit,
      date: DateTime.now(),
    );

    TradeDB.addTrade(trade);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Trade")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: symbolController, decoration: const InputDecoration(labelText: "Symbol (e.g., EURUSD)", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: "Order Type", border: OutlineInputBorder()),
              items: ["Buy", "Sell"].map((e) => DropdownMenuItem(child: Text(e), value: e)).toList(),
              onChanged: (v) { setState(() { type = v!; }); },
            ),
            const SizedBox(height: 16),
            TextField(controller: entryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Entry Price", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: exitController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Exit Price", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("Save Trade"),
            )
          ],
        ),
      ),
    );
  }
}

// All Trades Screen
class AllTrades extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Trade> trades = TradeDB.getAll();
    return Scaffold(
      appBar: AppBar(title: const Text("All Trades History")),
      body: trades.isEmpty
          ? const Center(child: Text("No trades recorded yet.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trades.length,
              itemBuilder: (context, i) {
                final t = trades[i];
                bool isWin = t.profit >= 0;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isWin ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      child: Icon(isWin ? Icons.arrow_upward : Icons.arrow_downward, color: isWin ? Colors.green : Colors.red),
                    ),
                    title: Text("${t.symbol} (${t.type})", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Entry: ${t.entry} | Exit: ${t.exit}", style: const TextStyle(color: Colors.grey)),
                    trailing: Text(
                      isWin ? "+${t.profit.toStringAsFixed(2)}" : t.profit.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isWin ? Colors.green : Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}