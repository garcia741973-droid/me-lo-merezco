import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../../core/services/auth_service.dart';

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {

  bool loading = true;

  Map<String,dynamic>? summary;
  List<dynamic> monthlySales = [];

  /// NUEVO
  DateTime? dateFrom;
  DateTime? dateTo;
  String selectedReport = "orders-status";
  List reportData = [];

  final reports = {
    "orders-status":"Pedidos",
    "payments":"Pagos",
    "payment-operations":"Compras / Entregas",
    "performance":"Rendimiento",
    "top-clients":"Clientes activos",
    "sales-by-seller":"Ventas por vendedor",
    "sales-by-source":"Ventas por origen",
    "clients":"Listado clientes"  
  };


  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    try {

      final token = await AuthService().getToken();

      final summaryRes = await http.get(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/reports/summary'
        ),
        headers: {
          'Authorization':'Bearer $token'
        }
      );

      final salesRes = await http.get(
        Uri.parse(
          'https://me-lo-merezco-backend.onrender.com/admin/reports/sales-by-month'
        ),
        headers: {
          'Authorization':'Bearer $token'
        }
      );

      if(summaryRes.statusCode == 200){

        summary = jsonDecode(summaryRes.body);

      }

      if(salesRes.statusCode == 200){

        monthlySales = jsonDecode(salesRes.body);

      }

      setState(() {
        loading = false;
      });

    } catch(e){

      setState(() {
        loading = false;
      });

    }

  }

  String money(num value){

    return '\$${value.toDouble().toStringAsFixed(2)}';

  }

  /// SELECTOR FECHA
  Future<void> pickDate(bool isFrom) async {

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if(picked == null) return;

    setState(() {

      if(isFrom){
        dateFrom = picked;
      }else{
        dateTo = picked;
      }

    });

  }

  /// CARGAR INFORME
  Future<void> loadReport() async {

    if(dateFrom == null || dateTo == null){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seleccione rango de fechas"))
      );

      return;

    }

    final token = await AuthService().getToken();

    final url =
    "https://me-lo-merezco-backend.onrender.com/admin/reports/$selectedReport"
    "?date_from=${dateFrom!.toIso8601String().split('T')[0]}"
    "&date_to=${dateTo!.toIso8601String().split('T')[0]}";

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization":"Bearer $token"
      }
    );

    if(res.statusCode == 200){

      final decoded = jsonDecode(res.body);

      setState(() {
        reportData = decoded["rows"] ?? [];
      });

    }

  }

  /// DESCARGAR ARCHIVOS
Future<void> download(String type) async {
  if (dateFrom == null || dateTo == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Seleccione rango de fechas")),
    );
    return;
  }

  final token = await AuthService().getToken();

  final fromStr = dateFrom!.toIso8601String().split('T')[0];
  final toStr = dateTo!.toIso8601String().split('T')[0];

  final url =
      "https://me-lo-merezco-backend.onrender.com/admin/reports/$selectedReport.$type"
      "?date_from=$fromStr&date_to=$toStr";

  // Carpeta de documentos de la app (en iPhone aparece en Files > On My iPhone)
    final Directory dir = await getApplicationDocumentsDirectory();

    final fileName =
        "reporte_${selectedReport}_${fromStr}_a_${toStr}.$type";
    final filePath = "${dir.path}/$fileName";

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Descargando $fileName...")),
      );

      final dio = Dio();

      await dio.download(
        url,
        filePath,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      // Abrir el archivo con la app correspondiente (Excel/Files/Acrobat/etc.)
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        // Si no pudo abrir, al menos mostramos la ruta (para buscarlo en Files)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Descargado en: $filePath")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error descargando: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          )
        ],
      ),

      body: loading
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            dashboardCards(),

            const SizedBox(height: 30),

            salesChart(),

            const SizedBox(height: 40),

            const Text(
              "Informes operativos",
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height:20),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    onPressed: ()=>pickDate(true),
                    child: Text(
                      dateFrom == null
                      ? "Fecha inicio"
                      : dateFrom.toString().split(" ")[0]
                    ),
                  ),
                ),

                const SizedBox(width:10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: ()=>pickDate(false),
                    child: Text(
                      dateTo == null
                      ? "Fecha fin"
                      : dateTo.toString().split(" ")[0]
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height:10),

            DropdownButtonFormField(

              value: selectedReport,

              items: reports.entries.map((e){

                return DropdownMenuItem(
                  value:e.key,
                  child: Text(e.value),
                );

              }).toList(),

              onChanged:(v){

                setState(() {
                  selectedReport = v!;
                });

              },

            ),

            const SizedBox(height:10),

            Row(

              children: [

                Expanded(
                  child: ElevatedButton(
                    onPressed: loadReport,
                    child: const Text("Ver informe"),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: ()=>download("xlsx"),
                ),

                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: ()=>download("pdf"),
                )

              ],

            ),

            const SizedBox(height:20),

            ListView.builder(

              shrinkWrap:true,
              physics: const NeverScrollableScrollPhysics(),

              itemCount: reportData.length,

              itemBuilder:(c,i){

                final row = reportData[i];

                return Card(
                  child: ListTile(
                    title: Text(row.toString()),
                  ),
                );

              }

            )

          ],

        ),

      ),

    );

  }

  Widget dashboardCards(){

    return GridView.count(

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      crossAxisCount: 2,

      crossAxisSpacing: 16,

      mainAxisSpacing: 16,

      childAspectRatio: 0.75,

      children: [

        card(
          'Ventas comprometidas',
          money(summary!['total_sales']),
          Icons.attach_money,
          Colors.green,
        ),

        card(
          'Ingresos confirmados',
          money(summary!['verified_payments']),
          Icons.account_balance_wallet,
          Colors.teal,
        ),

        card(
          'Pedidos totales',
          summary!['total_orders'].toString(),
          Icons.shopping_cart,
          Colors.blue,
        ),

        card(
          'Pedidos aprobados',
          summary!['approved_orders'].toString(),
          Icons.check_circle,
          Colors.orange,
        ),

        card(
          'Pedidos entregados',
          summary!['delivered_orders'].toString(),
          Icons.local_shipping,
          Colors.indigo,
        ),

        card(
          'Pagos pendientes',
          money(summary!['pending_payments']),
          Icons.pending_actions,
          Colors.redAccent,
        ),

      ],

    );

  }

  Widget card(String title,String value,IconData icon,Color color){

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(icon,size:28,color:color),

          const SizedBox(height:8),

          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize:12),
            ),
          ),

          const SizedBox(height:6),

          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.bold,
                color: color
              ),
            ),
          ),

        ],

      ),

    );

  }

  Widget salesChart(){

    if(monthlySales.isEmpty){

      return const SizedBox();

    }

    List<FlSpot> spots = [];

    for(int i=0;i<monthlySales.length;i++){

      final total = double.parse(monthlySales[i]['total'].toString());

      spots.add(FlSpot(i.toDouble(), total));

    }

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(
          'Ventas por mes',
          style: TextStyle(
            fontSize:18,
            fontWeight: FontWeight.bold
          ),
        ),

        const SizedBox(height:20),

        SizedBox(

          height:250,

          child: LineChart(

            LineChartData(

              gridData: FlGridData(show:true),

              borderData: FlBorderData(show:false),

              lineBarsData: [

                LineChartBarData(

                  spots: spots,

                  isCurved: true,

                  color: Colors.green,

                  barWidth: 4,

                  dotData: FlDotData(show:true),

                )

              ],

            ),

          ),

        )

      ],

    );

  }

}