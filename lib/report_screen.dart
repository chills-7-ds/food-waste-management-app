import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Map<String, dynamic>> items = [];

  double totalCost = 0;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();
    fetchReportData();
  }

  //////////////////////////////////////////////////////////
  // FETCH DATA
  //////////////////////////////////////////////////////////
  Future<void> fetchReportData() async {
    try {
      final response = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: '''
          query {
            listFoodItems {
              items {
                title
                quantity
                cost
                claimed
              }
            }
          }
          ''',
        ),
      ).response;

      final data = jsonDecode(response.data!);
      final List list = data["listFoodItems"]["items"] ?? [];

      double costSum = 0;
      int count = 0;

      List<Map<String, dynamic>> loaded = [];

      for (var item in list) {
        if (item == null) continue;

        double cost =
            double.tryParse(item["cost"].toString()) ?? 0;

        costSum += cost;
        count++;

        loaded.add({
          "title": item["title"],
          "quantity": item["quantity"],
          "cost": cost,
          "claimed": item["claimed"] == true ? "Yes" : "No",
        });
      }

      setState(() {
        items = loaded;
        totalCost = costSum;
        totalItems = count;
      });
    } catch (e) {
      print("REPORT ERROR: $e");
    }
  }

  //////////////////////////////////////////////////////////
  // PDF GENERATION
  //////////////////////////////////////////////////////////
  Future<void> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text("Food Donation Report",
                style: pw.TextStyle(fontSize: 20)),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ["Food", "Qty", "Cost", "Claimed"],
              data: items.map((e) {
                return [
                  e["title"],
                  e["quantity"].toString(),
                  "₹${e["cost"]}",
                  e["claimed"],
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Text("Total Items: $totalItems"),
            pw.Text("Total Cost: ₹$totalCost"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  //////////////////////////////////////////////////////////
  // EXCEL GENERATION
  //////////////////////////////////////////////////////////
  Future<void> generateExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Report'];

    sheet.appendRow(["Food", "Quantity", "Cost", "Claimed"]);

    for (var item in items) {
      sheet.appendRow([
        item["title"],
        item["quantity"],
        item["cost"],
        item["claimed"],
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow(["Total Items", totalItems]);
    sheet.appendRow(["Total Cost", totalCost]);

    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}/food_report.xlsx";

    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel saved at: $path")),
    );
  }

  //////////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donation Report"),
        backgroundColor: Colors.green,
      ),

      body: items.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 10),

                Text("Total Items: $totalItems",
                    style: TextStyle(fontSize: 16)),

                Text("Total Cost: ₹$totalCost",
                    style: TextStyle(fontSize: 16)),

                SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      var item = items[i];

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: ListTile(
                          title: Text(item["title"]),
                          subtitle: Text(
                              "Qty: ${item["quantity"]} | ₹${item["cost"]}"),
                          trailing: Text(item["claimed"]),
                        ),
                      );
                    },
                  ),
                ),

                //////////////////////////////////////////////////////
                // BUTTONS
                //////////////////////////////////////////////////////
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: generatePDF,
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text("Download PDF"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                    ),

                    ElevatedButton.icon(
                      onPressed: generateExcel,
                      icon: Icon(Icons.table_chart),
                      label: Text("Download Excel"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                  ],
                ),

                SizedBox(height: 15),
              ],
            ),
    );
  }
}