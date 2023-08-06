import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../auth.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  final User? user;

  const TaskListScreen({Key? key, required this.user}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final Auth _auth = Auth();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDueDateController = TextEditingController();
  final TextEditingController _taskDescriptionController =
  TextEditingController();
  late CollectionReference _userTasks;

  DateTime? _selectedDateTime;
  late String _maxTemp;
  late String _minTemp;
  late String _currentTemp;
  late String _condition;

  @override
  void initState() {
    super.initState();
    _userTasks = FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.user!.uid)
        .collection('userTasks');
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDueDateController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _addTask() {
    _userTasks
        .add({
      'name': _taskNameController.text,
      'dueDate': _selectedDateTime != null
          ? DateFormat('MMMM dd, yyyy - hh:mm a').format(_selectedDateTime!)
          : '',
      'description': _taskDescriptionController.text,
    })
        .then((value) {
      _taskNameController.clear();
      _taskDueDateController.clear();
      _taskDescriptionController.clear();
      _selectedDateTime = null;
    })
        .catchError((error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: Text(
              'Failed to add task: $error',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    });
  }

  void _deleteTask(String taskId) {
    _userTasks.doc(taskId).delete().catchError((error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: Text(
              'Failed to delete task: $error',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    });
  }

  void _updateTask(
      String taskId, String name, String dueDate, String description) {
    _userTasks.doc(taskId).update({
      'name': name,
      'dueDate': dueDate,
      'description': description,
    }).catchError((error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.white)),
            content: Text(
              'Failed to update task: $error',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildTaskItem(DocumentSnapshot task) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final TextEditingController _editNameController =
            TextEditingController(text: task['name']);
            final TextEditingController _editDueDateController =
            TextEditingController(text: task['dueDate']);
            final TextEditingController _editDescriptionController =
            TextEditingController(text: task['description']);

            return AlertDialog(
              title: const Text('Edit Task',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _editNameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextFormField(
                    controller: _editDueDateController,
                    decoration: const InputDecoration(labelText: 'Due Date'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextFormField(
                    controller: _editDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: Colors.black,
              actions: [
                TextButton(
                  onPressed: () {
                    _updateTask(
                      task.id,
                      _editNameController.text,
                      _editDueDateController.text,
                      _editDescriptionController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Update',
                      style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      child: ListTile(
        title: Text(task['name'], style: const TextStyle(color: Colors.white)),
        subtitle:
        Text(task['dueDate'], style: const TextStyle(color: Colors.white)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _deleteTask(task.id);
          },
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = selectedDateTime;
          _taskDueDateController.text =
              DateFormat('MMMM dd, yyyy - hh:mm a').format(selectedDateTime);
        });
      }
    }
  }

  Future<void> _fetchWeatherData() async {
    final url =
        'http://api.weatherapi.com/v1/forecast.json?key=895ae6f6c97e4f229fe184124231507&q=Atlanta&days=2&aqi=no&alerts=no';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final forecast = data['forecast']['forecastday'][0];
      final maxTemp = forecast['day']['maxtemp_f'];
      final minTemp = forecast['day']['mintemp_f'];
      final currentTemp = data['current']['temp_f'];
      final condition = forecast['day']['condition']['text'];

      setState(() {
        _maxTemp = maxTemp.toString();
        _minTemp = minTemp.toString();
        _currentTemp = currentTemp.toString();
        _condition = condition;
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Weather API Error'),
            content: Text('Failed to fetch weather data'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Task List', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userTasks.snapshots(),
              builder:
                  (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data == null || snapshot.data!.size == 0) {
                  return const Center(
                    child: Text('No tasks found',
                        style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.size,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildTaskItem(snapshot.data!.docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Add Task',
                    style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _taskNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red), // Set the focused underline color to red
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _taskDueDateController,
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              labelStyle: TextStyle(color: Colors.white),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red), // Set the focused underline color to red
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            onTap: () {
                              _showDatePicker();
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _showDatePicker();
                          },
                          icon:
                          const Icon(Icons.calendar_today, color: Colors.white),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _taskDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red), // Set the focused underline color to red
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: Colors.black,
                actions: [
                  TextButton(
                    onPressed: () {
                      _addTask();
                      Navigator.of(context).pop();
                    },
                    child:
                    const Text('Add', style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.red, // Set the background color to red
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text(
                    "Here's today's forecast.",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Current Temperature: $_currentTemp°F',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'High Temperature: $_maxTemp°F',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Low Temperature: $_minTemp°F',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Outside conditions: $_condition',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.black,
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.wb_sunny),
          label: const Text(
            'Show Weather',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }
}
