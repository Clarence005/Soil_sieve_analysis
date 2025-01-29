import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soil/page/sieve_record.dart';

class SieveAnalysis extends StatefulWidget {
  const SieveAnalysis({super.key});

  @override
  State<SieveAnalysis> createState() => _SieveAnalysisState();
}

class _SieveAnalysisState extends State<SieveAnalysis> {
  double sampleWeight = 0.0;
  bool isLoading = false;

  final TextEditingController nameOfWorkController = TextEditingController();
  final TextEditingController sampleNumberController = TextEditingController();
  final TextEditingController weightOfSampleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<Map<String, dynamic>> datas = [
    {"Sieve Size": "12.5 mm"},
    {"Sieve Size": "9.50 mm"},
    {"Sieve Size": "6.30 mm"},
    {"Sieve Size": "4.75 mm"},
    {"Sieve Size": "3.35 mm"},
    {"Sieve Size": "2.36 mm"},
    {"Sieve Size": "1.10 mm"},
    {"Sieve Size": "0.600 mm"},
    {"Sieve Size": "0.425 mm"},
    {"Sieve Size": "0.300 mm"},
    {"Sieve Size": "0.212 mm"},
    {"Sieve Size": "0.150 mm"},
    {"Sieve Size": "0.075 mm"},
  ].asMap().entries.map((entry) {
    return {
      "Serial Number": entry.key + 1,
      "Sieve Size": entry.value["Sieve Size"],
      "Weight Retained Trial 1": 0.0,
      "Weight Retained Trial 2": 0.0,
      "% of Weight Retained Trial 1": 0.0,
      "% of Weight Retained Trial 2": 0.0,
      "Cumulative % Retained Trial 1": 0.0,
      "Cumulative % Retained Trial 2": 0.0,
      "% of Passing Trial 1": 100.0,
      "% of Passing Trial 2": 100.0,
      "Average % of Passing": 100.0,
      "% of Passing (Total)": 100.0,
    };
  }).toList();

  void calculateApp() {
    if (sampleWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid sample weight"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      double cumulativeTrial1 = 0.0;
      double cumulativeTrial2 = 0.0;

      for (var row in datas) {
        double trial1 = row["Weight Retained Trial 1"];
        double trial2 = row["Weight Retained Trial 2"];

        row["% of Weight Retained Trial 1"] = (trial1 / sampleWeight) * 100;
        row["% of Weight Retained Trial 2"] = (trial2 / sampleWeight) * 100;

        cumulativeTrial1 += row["% of Weight Retained Trial 1"];
        cumulativeTrial2 += row["% of Weight Retained Trial 2"];

        row["Cumulative % Retained Trial 1"] = cumulativeTrial1;
        row["Cumulative % Retained Trial 2"] = cumulativeTrial2;

        row["% of Passing Trial 1"] = 100 - cumulativeTrial1;
        row["% of Passing Trial 2"] = 100 - cumulativeTrial2;

        row["% of Passing Trial 1"] = row["% of Passing Trial 1"] < 0 ? 0.0 : row["% of Passing Trial 1"];
        row["% of Passing Trial 2"] = row["% of Passing Trial 2"] < 0 ? 0.0 : row["% of Passing Trial 2"];

        row["Average % of Passing"] = (row["% of Passing Trial 1"] + row["% of Passing Trial 2"]) / 2;
        row["Average % of Passing"] = row["Average % of Passing"] < 0 ? 0.0 : row["Average % of Passing"];

        row["% of Weight Retained Trial 1"] = double.parse(row["% of Weight Retained Trial 1"].toStringAsFixed(2));
        row["% of Weight Retained Trial 2"] = double.parse(row["% of Weight Retained Trial 2"].toStringAsFixed(2));
        row["Cumulative % Retained Trial 1"] = double.parse(row["Cumulative % Retained Trial 1"].toStringAsFixed(2));
        row["Cumulative % Retained Trial 2"] = double.parse(row["Cumulative % Retained Trial 2"].toStringAsFixed(2));
        row["% of Passing Trial 1"] = double.parse(row["% of Passing Trial 1"].toStringAsFixed(2));
        row["% of Passing Trial 2"] = double.parse(row["% of Passing Trial 2"].toStringAsFixed(2));
        row["Average % of Passing"] = double.parse(row["Average % of Passing"].toStringAsFixed(2));

        row["% of Passing (Total)"] = row["Average % of Passing"].roundToDouble();

        row["% of Passing (Total)"] =
        row["% of Passing (Total)"] < 0 ? 0.0 : row["% of Passing (Total)"];
      }
    });
  }

  Future<void> submitData() async {
    if (nameOfWorkController.text.isEmpty ||
        sampleNumberController.text.isEmpty ||
        weightOfSampleController.text.isEmpty ||
        locationController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all the fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isDataComplete = datas.every((row) {
      return row["Weight Retained Trial 1"] > 0 &&
          row["Weight Retained Trial 2"] > 0;
    });

    if (!isDataComplete || sampleWeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid data in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('sieve_analysis').add({
        "name_of_work": nameOfWorkController.text,
        "sample_number": sampleNumberController.text,
        "weight_of_sample": sampleWeight,
        "location": locationController.text,
        "description": descriptionController.text,
        "data": datas,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sieve Analysis for Soil",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SieveRecord(),
                ),
              );
            },
            icon: const Icon(
              Icons.storage,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "HIGHWAYS DEPARTMENT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  " Highways Research Station, Soils Laboratory, Chennai - 25",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(
                  height: 15,
                ),
                const Text(
                  "Sieve Analysis for Soil - IS 2720 (PART-IV)",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First row: Name of the Work
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameOfWorkController,
                              decoration: const InputDecoration(
                                labelText: "Name of the Work",
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2.0), // When focused
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0), // When not focused
                                ),
                                floatingLabelStyle: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Second row: Sample Number and Weight of the Sample
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sampleNumberController,
                              decoration: const InputDecoration(
                                labelText: "Sample Number",
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2.0), // When focused
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0), // When not focused
                                ),
                                floatingLabelStyle: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: weightOfSampleController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                setState(() {
                                  sampleWeight = double.tryParse(value) ?? 0.0;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: "Weight of the Sample (grams)",
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2.0), // When focused
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0), // When not focused
                                ),
                                floatingLabelStyle: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Third row: Description and Location
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: "Description",
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2.0), // When focused
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0), // When not focused
                                ),
                                floatingLabelStyle: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: "Location",
                                border: OutlineInputBorder(),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.green, width: 2.0), // When focused
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.0), // When not focused
                                ),
                                floatingLabelStyle: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),

                // DataTable
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Serial Number')),
                      DataColumn(label: Text('IS Sieve size (mm)')),
                      DataColumn(label: Text('Weight Retained Trial 1 (g)')),
                      DataColumn(label: Text('Weight Retained Trial 2 (g)')),
                      DataColumn(label: Text('% of Weight Retained Trial 1')),
                      DataColumn(label: Text('% of Weight Retained Trial 2')),
                      DataColumn(label: Text('Cumulative % Retained Trial 1')),
                      DataColumn(label: Text('Cumulative % Retained Trial 2')),
                      DataColumn(label: Text('% of Passing Trial 1')),
                      DataColumn(label: Text('% of Passing Trial 2')),
                      DataColumn(label: Text('Average % of Passing')),
                      DataColumn(label: Text('% of Passing (Total)')), // New Column
                    ],
                    rows: datas.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row["Serial Number"].toString())),
                          DataCell(Text(row["Sieve Size"])),
                          DataCell(TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                row["Weight Retained Trial 1"] =
                                    double.tryParse(value) ?? 0.0;
                              });
                            },
                            decoration: const InputDecoration(hintText: "Enter Trial 1"),
                          )),
                          DataCell(TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                row["Weight Retained Trial 2"] =
                                    double.tryParse(value) ?? 0.0;
                              });
                            },
                            decoration: const InputDecoration(hintText: "Enter Trial 2"),
                          )),
                          DataCell(Text(row["% of Weight Retained Trial 1"]
                              .toStringAsFixed(2))),
                          DataCell(Text(row["% of Weight Retained Trial 2"]
                              .toStringAsFixed(2))),
                          DataCell(Text(row["Cumulative % Retained Trial 1"]
                              .toStringAsFixed(2))),
                          DataCell(Text(row["Cumulative % Retained Trial 2"]
                              .toStringAsFixed(2))),
                          DataCell(Text(
                              row["% of Passing Trial 1"].toStringAsFixed(2))),
                          DataCell(Text(
                              row["% of Passing Trial 2"].toStringAsFixed(2))),
                          DataCell(Text(row["Average % of Passing"]
                              .toStringAsFixed(2))),
                          DataCell(Text(row["% of Passing (Total)"]
                              .toStringAsFixed(2))), // Total Column
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // Buttons
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: calculateApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button background color
                        ),

                        child: const Text("Calculate",style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: isLoading ? null : submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Button background color
                        ),

                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.green,
                        )
                            : const Text("Submit",style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
