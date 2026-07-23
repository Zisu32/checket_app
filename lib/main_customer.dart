import 'package:flutter/material.dart';
import 'customer_app/views/webticket_view.dart';
import 'package:universal_html/html.dart' as html;

void main() { runApp(const ChecketCustomerWebApp()); }

class ChecketCustomerWebApp extends StatelessWidget {
  const ChecketCustomerWebApp({super.key});
  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(html.window.location.href);
    String ticketId = uri.queryParameters['id'] ?? '';
    String secret = uri.queryParameters['secret'] ?? '';

    if (ticketId.isEmpty || secret.isEmpty) {
      ticketId = html.window.localStorage['last_ticket_id'] ?? '';
      secret = html.window.localStorage['last_ticket_secret'] ?? '';
    } else {
      html.window.localStorage['last_ticket_id'] = ticketId;
      html.window.localStorage['last_ticket_secret'] = secret;
    }

    if (ticketId.isEmpty) return const MaterialApp(home: Scaffold(body: Center(child: Text('Kein aktives Ticket gefunden.'))));
    return MaterialApp(title: 'Checket Ticket', theme: ThemeData.dark(), home: CustomerWebTicketView(ticketId: int.parse(ticketId), status: 'active', secret: secret), debugShowCheckedModeBanner: false);
  }
}
