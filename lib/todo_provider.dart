import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoProvider extends ChangeNotifier {
  List<String> _todos = [];

  List<String> get todos => _todos;

  Future<void> loadTodos(String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("MyToDoList")
          .where("userId", isEqualTo: userId)
          .get();
      _todos = querySnapshot.docs.map<String>((doc) => doc["todoTitle"] as String).toList();

      notifyListeners();
    } catch (e) {
      print("Error loading todos: $e");
    }
  }

  Future<void> addTodo(String todoTitle, String userId) async {
    try {
      await FirebaseFirestore.instance.collection("MyToDoList").add({
        "todoTitle": todoTitle,
        "userId": userId,
      });
      await loadTodos(userId);
    } catch (e) {
      print("Error creating todo: $e");
    }
  }

  Future<void> removeTodo(String todoTitle, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection("MyToDoList")
          .where("todoTitle", isEqualTo: todoTitle)
          .where("userId", isEqualTo: userId)
          .get()
          .then(
            (QuerySnapshot snapshot) {
          snapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
        },
      );
      await loadTodos(userId);
    } catch (e) {
      print("Error deleting todo: $e");
    }
  }
}