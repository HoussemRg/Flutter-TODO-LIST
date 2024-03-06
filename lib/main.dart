import 'package:flutter/material.dart';
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
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyHomePage(),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List todos = [];
  String inputField = "";

  Future<void> createTodos(String todoTitle) async {
    try {
      await FirebaseFirestore.instance.collection("MyToDoList").add({
        "todoTitle": todoTitle,
        "userId": FirebaseAuth.instance.currentUser!.uid,
      });
    } catch (e) {
      print("Error creating todo: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  Future<void> loadTodos() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("MyToDoList")
          .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();
      setState(() {
        todos = querySnapshot.docs.map((doc) => doc["todoTitle"]).toList();
      });
    } catch (e) {
      print("Error loading todos: $e");
    }
  }

  // Fonction pour gérer la déconnexion de l'utilisateur
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TODO LIST",style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        actions: [
          // Ajout du bouton de déconnexion
          IconButton(
            icon: Icon(Icons.logout,color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
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
                        await createTodos(inputField);
                        await loadTodos();
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
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            key: Key(todos[index]),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              await FirebaseFirestore.instance
                  .collection("MyToDoList")
                  .where("todoTitle", isEqualTo: todos[index])
                  .get()
                  .then(
                    (QuerySnapshot snapshot) {
                  snapshot.docs.forEach((doc) {
                    doc.reference.delete();
                  });
                },
              );
              await loadTodos();
            },
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                title: Text(todos[index]),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("MyToDoList")
                        .where("todoTitle", isEqualTo: todos[index])
                        .get()
                        .then(
                          (QuerySnapshot snapshot) {
                        snapshot.docs.forEach((doc) {
                          doc.reference.delete();
                        });
                      },
                    );
                    await loadTodos();
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registerUser() async {
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
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _registerUser,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginUser() async {
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
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _loginUser,
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
