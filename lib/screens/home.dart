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
  final tController = TextEditingController();
  final dController = TextEditingController();
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    fetchTodo();
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
    } else {
      errorSnackBar(context, "Failed to load data, try again later");
    }
  }

  void createNewTodo() {
    showDialog(
        context: context,
        builder: (context) {
          return DialogBox(
            title: "Add Todo",
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
      fetchTodo();

      tController.clear();
      dController.clear();
      Navigator.of(context).pop();
    } else {
      errorSnackBar(context, "Failed!");
      Navigator.of(context).pop();
    }
  }

  void editExistingTodo(dynamic todo) {
    final tController = TextEditingController(text: todo['title']);
    final dController = TextEditingController(text: todo['desc']);

    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          title: "Edit Todo",
          tcontroller: tController,
          dcontroller: dController,
          onCancel: () => Navigator.of(context).pop(),
          onSave: () {
            editTodo(
              todo['id'],
              tController.text,
              dController.text,
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> editTodo(int id, String title, String desc) async {
    final body = {'title': title, 'desc': desc, 'completed': false};
    final url = 'http://10.0.2.2:8000/api/todos/update/$id';
    final uri = Uri.parse(url);

    final response = await http.put(
      uri,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      fetchTodo();
      successSnackBar(context, "Successfully updated");
    } else {
      errorSnackBar(context, "Failed to edit");
    }
  }

  Future<void> deleteTodo(int id) async {
    final response = await http
        .delete(Uri.parse('http://10.0.2.2:8000/api/todos/delete/$id'));
    if (response.statusCode == 200) {
      fetchTodo();
      successSnackBar(context, "Successfully updated");
    } else {
      errorSnackBar(context, "Failed to delete");
    }
  }

  Future<void> checkUpdate(dynamic todo, int id) async {
    final url = 'http://10.0.2.2:8000/api/todos/update/$id';
    final uri = Uri.parse(url);
    final response = await http.put(
      uri,
      body: jsonEncode(todo),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update todo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        title: const Text("Todo App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: RefreshIndicator(
          onRefresh: fetchTodo,
          child: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: Checkbox(
                    value: todo['completed'] == 1,
                    onChanged: (bool? newVal) async {
                      if (newVal != null) {
                        setState(() {
                          isChecked = newVal;
                        });

                        // Update the todo in the database
                        todo['completed'] = isChecked ? 1 : 0;
                        try {
                          await checkUpdate(todo, todo['id']);
                        } catch (e) {
                          debugPrint('Error updating todo: $e');
                          errorSnackBar(context, "Failed to update todo.");
                        }
                      }
                    },
                  ),
                  title: Text(todo['title']),
                  subtitle: Text(todo['desc']),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editExistingTodo(todo);
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
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ];
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
