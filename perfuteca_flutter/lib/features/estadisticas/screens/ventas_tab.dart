import 'package:flutter/material.dart';
import 'package:perfuteca/features/ventas/screens/historial_screen.dart';

class VentasTab extends StatefulWidget {
  const VentasTab({super.key});

  @override
  State<VentasTab> createState() => _VentasTabState();
}

class _VentasTabState extends State<VentasTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const HistorialScreen();
  }
}
