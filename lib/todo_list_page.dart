import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'todo_provider.dart';
import 'home_page.dart';

class TodoListPage extends StatelessWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("TODO LIST", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String inputField = '';
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: const Text("Add new task"),
                content: TextField(
                  onChanged: (String value) {
                    inputField = value;
                  },
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () async {
                      if (inputField.isNotEmpty) {
                        await todoProvider.addTodo(inputField, userId);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text("Add"),
                  )
                ],
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final todos = todoProvider.todos;
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (BuildContext context, int index) {
              return Dismissible(
                key: Key(todos[index]),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await todoProvider.removeTodo(todos[index], userId);
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    title: Text(todos[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            String updatedName = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String newName = todos[index];
                                return AlertDialog(
                                  title: const Text("Edit Task"),
                                  content: TextField(
                                    onChanged: (value) {
                                      newName = value;
                                    },
                                    controller: TextEditingController(text: todos[index]),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(todos[index]);
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(newName);
                                      },
                                      child: const Text("Save"),
                                    )
                                  ],
                                );
                              },
                            );

                            if (updatedName != null && updatedName != todos[index]) {
                              await FirebaseFirestore.instance
                                  .collection("MyToDoList")
                                  .where("todoTitle", isEqualTo: todos[index])
                                  .where("userId", isEqualTo: userId)
                                  .get()
                                  .then(
                                    (QuerySnapshot snapshot) {
                                  snapshot.docs.forEach((doc) {
                                    doc.reference.update({"todoTitle": updatedName});
                                  });
                                },
                              );
                              await todoProvider.loadTodos(userId);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await todoProvider.removeTodo(todos[index], userId);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}