import 'package:flutter/material.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final List<String> _mockStatuses = List.generate(150, (index) {
    if (index == 4) return 'unpaid';
    if (index == 41) return 'active';
    if (index == 142) return 'temporary';
    return 'free';
  });

  void _schliesseGarderobeUndFeierabend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Garderobe schließen?'),
        content: const Text('Alle noch belegten Bügel werden als "VERGESSEN" markiert. Kunden erhalten automatisch eine Push-Benachrichtigung.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                for (int i = 0; i < _mockStatuses.length; i++) {
                  if (_mockStatuses[i] == 'active' || _mockStatuses[i] == 'temporary') _mockStatuses[i] = 'forgotten';
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Ja, Feierabend!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Checket - Garderoben-Manager'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [IconButton(icon: const Icon(Icons.nightlight_round, color: Colors.orangeAccent), onPressed: _schliesseGarderobeUndFeierabend)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: _mockStatuses.length,
        itemBuilder: (context, index) {
          final id = index + 1;
          final status = _mockStatuses[index];
          Color kachelFarbe = const Color(0xFF2C2C2C);
          if (status == 'unpaid') kachelFarbe = Colors.red.shade900;
          if (status == 'active') kachelFarbe = Colors.green.shade800;
          if (status == 'temporary') kachelFarbe = Colors.orange.shade900;
          if (status == 'forgotten') kachelFarbe = Colors.blueGrey.shade800;

          return InkWell(
            onTap: () => _zeigeAktionen(context, id, status, index),
            child: Container(
              decoration: BoxDecoration(color: kachelFarbe, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('$id', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            ),
          );
        },
      ),
    );
  }

  void _zeigeAktionen(BuildContext context, int id, String status, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bügel $id verwalten', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (status == 'free') ListTile(leading: const Icon(Icons.add_box, color: Colors.blue), title: const Text('Jacke einchecken'), onTap: () { setState(() => _mockStatuses[index] = 'unpaid'); Navigator.pop(context); }),
              if (status == 'unpaid') ...[
                ListTile(leading: const Icon(Icons.contactless_outlined, color: Colors.green), title: const Text('NFC Tap-to-Pay'), onTap: () { setState(() => _mockStatuses[index] = 'active'); Navigator.pop(context); }),
                ListTile(leading: const Icon(Icons.attach_money, color: Colors.amber), title: const Text('Bar bezahlt'), onTap: () { setState(() => _mockStatuses[index] = 'active'); Navigator.pop(context); }),
              ],
              if (status == 'active') ...[
                ListTile(leading: const Icon(Icons.pause, color: Colors.orange), title: const Text('Temporärer Ausgang'), onTap: () { setState(() => _mockStatuses[index] = 'temporary'); Navigator.pop(context); }),
                ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Endgültig auschecken'), onTap: () { setState(() => _mockStatuses[index] = 'free'); Navigator.pop(context); }),
              ],
              if (status == 'temporary') ListTile(leading: const Icon(Icons.play_arrow, color: Colors.green), title: const Text('Wieder zurück'), onTap: () { setState(() => _mockStatuses[index] = 'active'); Navigator.pop(context); }),
              if (status == 'forgotten') ListTile(leading: const Icon(Icons.assignment_turned_in, color: Colors.teal), title: const Text('Aus Fundbüro übergeben'), onTap: () { setState(() => _mockStatuses[index] = 'free'); Navigator.pop(context); }),
            ],
          ),
        );
      },
    );
  }
}