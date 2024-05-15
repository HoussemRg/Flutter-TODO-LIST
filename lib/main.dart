import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyASI6-8uAlpsDYP2bAdkinhbBg_kwsqTqs",
      appId: "1:845058142638:android:4ec8685448b0fe6a5e583f",
      messagingSenderId: "845058142638",
      projectId: "todo-list-aa5f7",
    ),
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      ),
    ),
  );
}

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            "TODO LIST",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          width: 500,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.center,
                  width: 500,
                  child: Container(
                    child: Image.asset(
                      "images/enit.png",
                      width: 200,
                      height: 200,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: Colors.blue[100]!, width: 10, style: BorderStyle.solid),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.topCenter,
                  height: 150,
                  width: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 30),
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()),
                            );
                          },
                          child: const Text('Register'),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 70),
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: const Text('Login'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          // Ajout du bouton de déconnexion
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
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

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(
              label: 'Username', // Champ du nom d'utilisateur
              controller: _usernameController,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                  );

                  // Enregistrement de l'utilisateur dans Firestore
                  await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
                    "username": _usernameController.text.trim(), // Enregistrer le nom d'utilisateur
                    "email": _emailController.text.trim(),
                  });

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TodoListPage()),
                  );
                } on FirebaseAuthException catch (e) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.message ?? 'An error occurred while registering. Please try again.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  print(e.toString());
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(
              label: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TodoListPage()),
                  );
                } on FirebaseAuthException catch (e) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.message ?? 'An error occurred while logging in. Please try again.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  print(e.toString());
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInputField({
  required String label,
  required TextEditingController controller,
  bool isPassword = false,
}) {
  return TextField(
    controller: controller,
    obscureText: isPassword,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    ),
  );
}