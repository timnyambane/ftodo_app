import 'package:flutter/material.dart';

class DialogBox extends StatelessWidget {
  final TextEditingController tcontroller;
  final TextEditingController dcontroller;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const DialogBox({
    super.key,
    required this.tcontroller,
    required this.dcontroller,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Todo"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tcontroller,
            decoration: const InputDecoration(
                border: UnderlineInputBorder(), hintText: "Title"),
          ),
          TextField(
            controller: dcontroller,
            decoration: const InputDecoration(
                border: UnderlineInputBorder(), hintText: "Description"),
            keyboardType: TextInputType.multiline,
            maxLines: 4,
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: onSave,
          child: const Text("Save"),
        )
      ],
    );
  }
}
