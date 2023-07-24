import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(CRUDTableApp());
}

class Person {
  String name;
  int age;

  Person(this.name, this.age);
}

class CRUDTableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD Table',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CRUDTableScreen(),
    );
  }
}

class CRUDTableScreen extends StatefulWidget {
  @override
  _CRUDTableScreenState createState() => _CRUDTableScreenState();
}

class _CRUDTableScreenState extends State<CRUDTableScreen> {
  List<Person> _people = [];
  FirebaseFirestore firebase = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter CRUD Table'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebase.collection('people').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          _people = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Person(data['name'], data['age']);
          }).toList();

          return ListView.builder(
            itemCount: _people.length,
            itemBuilder: (context, index) {
              String docId = snapshot.data!.docs[index].id;
              return ListTile(
                title: Text(_people[index].name),
                subtitle: Text('Age: ${_people[index].age}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditDialog(index, docId),
                ),
                onLongPress: () => _deletePerson(index, docId),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Person'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addPerson();
                      Navigator.of(context).pop();
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _addPerson() async {
    String name = _nameController.text;
    int age = int.tryParse(_ageController.text) ?? 0;
    if (name.isNotEmpty && age > 0) {
      await firebase.collection('people').add({
        'name': name,
        'age': age,
      });
      setState(() {     //for refreshing the ui
        _people.add(Person(name, age));
      });
      _nameController.clear();
      _ageController.clear();
    }
  }

  void _editPerson(int index, String docId) async {
    String name = _nameController.text;
    int age = int.tryParse(_ageController.text) ?? 0;
    if (name.isNotEmpty && age > 0) {
      await firebase.collection('people').doc(docId).update({
        'name': name,
        'age': age,
      });
      setState(() {
        _people[index] = Person(name, age);
      });
      _nameController.clear();
      _ageController.clear();
    }
  }

  void _deletePerson(int index, String docId) async {
    await firebase.collection('people').doc(docId).delete();
    setState(() {
      _people.removeAt(index);
    });
  }

  void _showEditDialog(int index, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController..text = _people[index].name,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _ageController..text = _people[index].age.toString(),
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editPerson(index, docId);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
