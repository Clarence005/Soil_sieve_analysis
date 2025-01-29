import 'package:flutter/material.dart';
import 'page/sieve.dart';

class Homepage extends StatelessWidget {
  Homepage({super.key});

  final List<TestModel> tests = [
    TestModel(name: 'Sieve Analysis', page: SieveAnalysis(), icon: Icons.filter_alt),
    TestModel(name: 'Penetration Test', page: SieveAnalysis(), icon: Icons.water_drop),
    TestModel(name: 'Softening Test', page: SieveAnalysis(), icon: Icons.opacity),
    TestModel(name: 'Ductility', page: SieveAnalysis(), icon: Icons.arrow_downward),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Soil Tests',style: TextStyle(color: Colors.white),),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 4/ 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 60,
          ),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => test.page,
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      test.icon,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 8),
                    Text(
                      test.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TestModel {
  final String name;
  final Widget page;
  final IconData icon;

  TestModel({required this.name, required this.page, required this.icon});
}
