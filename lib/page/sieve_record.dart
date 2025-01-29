import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class SieveRecord extends StatefulWidget {
  const SieveRecord({super.key});

  @override
  State<SieveRecord> createState() => _SieveRecordState();
}

class _SieveRecordState extends State<SieveRecord> {
  List<Map<String, dynamic>> sieveRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sieve_analysis')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        sieveRecords = snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "sample_number": doc['sample_number'],
            "name_of_work": doc['name_of_work'],
            "weight_of_sample": doc['weight_of_sample'],
            "location": doc['location'],
            "description": doc['description'],
            "timestamp": (doc['timestamp'] as Timestamp).toDate(),
            "data": List<Map<String, dynamic>>.from(doc['data']),
          };
        }).toList();
        filteredRecords = List.from(sieveRecords); // Initialize filtered list
      });
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void viewDetails(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SieveDetailsPage(record: record),
      ),
    );
  }

  Future<void> downloadDetails(Map<String, dynamic> record) async {
    final pdf = pw.Document();

    final sampleNumber = record['sample_number'] ?? 'N/A';
    final nameOfWork = record['name_of_work'] ?? 'N/A';
    final weightOfSample = record['weight_of_sample'] ?? 'N/A';
    final location = record['location'] ?? 'N/A';
    final description = record['description'] ?? 'N/A';
    final timestamp = record['timestamp'];
    final data = record['data'] as List<dynamic>? ?? [];

    // Replace with actual name

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
              pw.Text(
                "Highways Department",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Highways Research Station, Soils Laboratory, Chennai - 25",
                style: pw.TextStyle(fontSize: 16),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Sieve Analysis for Soil - IS 2720 (PART-IV)",
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ]),

            pw.SizedBox(height: 15),
            // Metadata
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Name of Work: $nameOfWork"),
                pw.Text("Sample Number: $sampleNumber"),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Weight of Sample: ${double.tryParse(weightOfSample.toString())?.toStringAsFixed(2) ?? weightOfSample} g"),
                pw.Text("Location: $location"),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Description: $description"),
                pw.Text("Date: ${DateFormat('dd/MM/yyyy').format(timestamp)}"),
              ],
            ),

            pw.SizedBox(height: 20),
            // Table
            pw.Expanded(
              child: pw.Table.fromTextArray(
                headers: [
                  "S.No",
                  "Sieve Size (mm)",
                  "Weight Retained (T1) (g)",
                  "Weight Retained (T2) (g)",
                  "% of Weight Retained(T1)",
                  "% of Weight Retained(T2)",
                  "Cumulative % Retained (T1)",
                  "Cumulative % Retained (T2)",
                  "% Passing (T1)",
                  "% Passing (T2)",
                  "Average % Passing",
                  "% Passing Total",
                ],
                data: data.map((entry) {
                  return [
                    entry["Serial Number"]?? 'N/A',
                    entry['Sieve Size'] ?? 'N/A',
                    entry['Weight Retained Trial 1'] ?? 'N/A',
                    entry['Weight Retained Trial 2'] ?? 'N/A',
                    entry['% of Weight Retained Trial 1'] ?? 'N/A',
                    entry['% of Weight Retained Trial 2'] ?? 'N/A',
                    entry['Cumulative % Retained Trial 1'] ?? 'N/A',
                    entry['Cumulative % Retained Trial 2'] ?? 'N/A',
                    entry['% of Passing Trial 1'] ?? 'N/A',
                    entry['% of Passing Trial 2'] ?? 'N/A',
                    entry['Average % of Passing'] ?? 'N/A',
                    entry['% of Passing (Total)'] ?? 'N/A',
                  ];
                }).toList(),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 25,
                cellAlignment: pw.Alignment.center,
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(2),
                  5: pw.FlexColumnWidth(2),
                  6: pw.FlexColumnWidth(2),
                  7: pw.FlexColumnWidth(2),
                  8: pw.FlexColumnWidth(2),
                  9: pw.FlexColumnWidth(2),
                  10: pw.FlexColumnWidth(2),
                  11:pw.FlexColumnWidth(2),
                },
              ),
            ),
            pw.SizedBox(height: 50),
            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text("Conducted by"),
                pw.SizedBox(width:90),
                pw.Text("Checked by"),
              ],
            ),
          ],
        ),
      ),
    );

    // Save the PDF locally
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Sieve_Analysis_Sample_$sampleNumber.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the PDF file
    await OpenFile.open(file.path);
  }

  void filterRecordsByDate(DateTime selectedDate) {
    setState(() {
      filteredRecords = sieveRecords
          .where((record) => isSameDay(record['timestamp'], selectedDate))
          .toList();
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sieve Analysis Records",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: Colors.white,
            onPressed: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selectedDate != null) {
                filterRecordsByDate(selectedDate);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRecords.isEmpty
          ? const Center(child: Text("No data found"))
          : ListView.builder(
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          final record = filteredRecords[index];
          final DateTime timestamp = record['timestamp'];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 10.0, vertical: 5.0),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sample Number: ${record['sample_number']}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Name of Work: ${record['name_of_work']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Weight of Sample: ${double.tryParse(record['weight_of_sample'].toString())?.toStringAsFixed(2) ?? record['weight_of_sample']} g",

                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Location: ${record['location']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Description: ${record['description']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Date: ${DateFormat('dd/MM/yyyy').format(timestamp)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => viewDetails(record),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("View",style: TextStyle(color: Colors.white),),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => downloadDetails(record),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text("Download",style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SieveDetailsPage extends StatelessWidget {
  final Map<String, dynamic> record;

  const SieveDetailsPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> data = record['data'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Details of Sample ${record['sample_number']}"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(10.0),
        children: [
          Text(
            "Sample Number: ${record['sample_number']}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Name of Work: ${record['name_of_work']}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Weight of Sample: ${double.tryParse(record['weight_of_sample'].toString())?.toStringAsFixed(2) ?? record['weight_of_sample']} g",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Location: ${record['location']}",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Description: ${record['description']}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          const Divider(),
          ...data.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Serial Number : ${entry['Serial Number']}"),
                  Text("Sieve Size: ${entry['Sieve Size']}"),
                  Text(
                      "Weight Retained Trial 1: ${entry['Weight Retained Trial 1']} g"),
                  Text(
                      "Weight Retained Trial 2: ${entry['Weight Retained Trial 2']} g"),
                  Text("% of Weight Retained Trial 1 ${entry['% of Weight Retained Trial 1'] }g"),
                    Text("% of Weight Retained Trial 2${entry['% of Weight Retained Trial 2'] }g"),
                    Text("Cumulative % Retained Trial 1 ${entry['Cumulative % Retained Trial 1']}g" ),
                    Text("Cumulative % Retained Trial 2 ${entry['Cumulative % Retained Trial 2']}g" ),
                  Text("% Passing Trial 1: ${entry['% of Passing Trial 1']}%"),
                  Text("% Passing Trial 2: ${entry['% of Passing Trial 2']}%"),
                  Text("Average % of Passing : ${entry['Average % of Passing'] } g"),
                  Text("% of Passing (Total) : ${entry['% of Passing (Total)'] }g"),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
