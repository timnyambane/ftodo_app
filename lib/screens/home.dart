// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:todo_app/screens/dialog.dart';
import 'package:todo_app/services/globals.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List todos = [];
  @override
  void initState() {
    super.initState();
    fetchTodo();
  }

  final tController = TextEditingController();
  final dController = TextEditingController();

  void createNewTodo() {
    showDialog(
        context: context,
        builder: (context) {
          return DialogBox(
            tcontroller: tController,
            dcontroller: dController,
            onCancel: () => Navigator.of(context).pop(),
            onSave: saveNewTask,
          );
        });
  }

  Future<void> saveNewTask() async {
    final body = {
      'title': tController.text,
      'desc': dController.text,
      'completed': false
    };
    const url = 'http://10.0.2.2:8000/api/todos/store';
    final uri = Uri.parse(url);

    final response = await http.post(uri,
        body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      successSnackBar(context, "Added succesfully");
      tController.clear();
      dController.clear();
      Navigator.of(context).pop();
    } else {
      errorSnackBar(context, "Failed!");
      Navigator.of(context).pop();
    }
  }

  Future<void> updateTodo(int id, Map<String, dynamic> data) async {
    final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/api/todos/put/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data));
    if (response.statusCode == 200) {
      fetchTodo();
    } else {
      errorSnackBar(context, "Failed to update");
    }
  }

  Future<void> deleteTodo(int id) async {
    final response = await http
        .delete(Uri.parse('http://10.0.2.2:8000/api/todos/delete/$id'));
    if (response.statusCode == 200) {
      fetchTodo();
    } else {
      errorSnackBar(context, "Failed to delete");
    }
  }

  Future<void> fetchTodo() async {
    const url = 'http://10.0.2.2:8000/api/todos/index';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final result = json.toList();

      setState(() {
        todos = result;
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo App"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchTodo,
        child: ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return ListTile(
              leading: Checkbox(
                value: todo['completed'] == 1,
                onChanged: (value) {
                  final data = {'completed': value == true ? 1 : 0};
                  updateTodo(todo['id'], data);
                },
              ),
              title: Text(todo['title']),
              subtitle: Text(todo['desc']),
              trailing: PopupMenuButton(
                onSelected: (value) {
                  if (value == 'edit') {
                  } else if (value == 'delete') {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm delete"),
                            content: const Text(
                                "Are you sure you want to delete this todo?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  deleteTodo(todo['id']);
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        });
                  }
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ];
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
