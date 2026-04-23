import 'dart:convert';
import 'package:flutter/material.dart';
import 'add_food_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'report_screen.dart';
import 'chatbot_screen.dart'; // ✅ NEW IMPORT

import 'amplifyconfiguration.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(MyApp());
}

Future<void> _configureAmplify() async {
  try {
    if (Amplify.isConfigured) return;

    await Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyAPI(),
      AmplifyStorageS3(),
    ]);

    await Amplify.configure(amplifyconfig);
  } catch (e) {
    print("Error configuring Amplify: $e");
  }
}

//////////////////////////////////////////////////////////
// APP ROOT
//////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Waste App',
      theme: ThemeData(primarySwatch: Colors.green),

      home: FutureBuilder<AuthSession>(
        future: Amplify.Auth.fetchAuthSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final session = snapshot.data;

            if (session != null && session.isSignedIn) {
              return HomeScreen();
            } else {
              return EntryScreen();
            }
          }

          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),

      routes: {
        "/home": (context) => HomeScreen(),
      },
    );
  }
}

//////////////////////////////////////////////////////////
// ENTRY SCREEN
//////////////////////////////////////////////////////////

class EntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade800],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)),
            margin: EdgeInsets.all(25),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco, size: 80, color: Colors.green.shade700),
                  SizedBox(height: 15),
                  Text("Food Saver",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    child: Text("Login"),
                  ),

                  SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => SignupScreen()));
                    },
                    child: Text("Signup"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// HOME SCREEN
//////////////////////////////////////////////////////////

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> foodItems = [];

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    try {
      await Amplify.Auth.getCurrentUser();
      fetchFood();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
    }
  }

  //////////////////////////////////////////////////////////
  // IMAGE FETCH
  //////////////////////////////////////////////////////////
  Future<String> getImageUrl(String key) async {
    try {
      if (key.isEmpty) return "";

      final result = await Amplify.Storage.getUrl(
        key: key,
        options: StorageGetUrlOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      return result.url.toString();
    } catch (e) {
      print("IMAGE ERROR: $e");
      return "";
    }
  }

  //////////////////////////////////////////////////////////
  // OPEN MAP
  //////////////////////////////////////////////////////////
  Future<void> openMap(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  //////////////////////////////////////////////////////////
  // FETCH FOOD
  //////////////////////////////////////////////////////////
  Future<void> fetchFood() async {
    try {
      final response = await Amplify.API.query(
        request: GraphQLRequest<String>(
          document: '''
          query {
            listFoodItems {
              items {
                id title type claimed image quantity cost animalFood hotelMapLink
              }
            }
          }
          ''',
        ),
      ).response;

      if (response.data == null) return;

      final data = jsonDecode(response.data!);
      final List items = data["listFoodItems"]["items"] ?? [];

      List<Map<String, dynamic>> loaded = [];

      for (var item in items) {
        if (item == null) continue;

        loaded.add({
          "id": item["id"],
          "title": item["title"] ?? "",
          "type": item["type"] ?? "",
          "claimed": item["claimed"] ?? false,
          "image": item["image"] ?? "",
          "quantity": item["quantity"].toString(),
          "cost": double.tryParse(item["cost"].toString()) ?? 0,
          "animalFood": item["animalFood"] ?? false,
          "map": item["hotelMapLink"] ?? "",
        });
      }

      setState(() {
        foodItems = loaded;
      });
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  //////////////////////////////////////////////////////////
  // ADD FOOD
  //////////////////////////////////////////////////////////
  Future<void> addFood(Map<String, dynamic> newFood) async {
    try {
      await Amplify.API.mutate(
        request: GraphQLRequest(
          document: '''
          mutation {
            createFoodItem(input: {
              title: "${newFood["title"]}",
              type: "${newFood["type"]}",
              image: "${newFood["image"]}",
              quantity: "${newFood["quantity"]}",
              cost: "${newFood["cost"]}",
              animalFood: ${newFood["animalFood"]},
              hotelMapLink: "${newFood["hotelMapLink"]}",
              claimed: false
            }) { id }
          }
          ''',
        ),
      ).response;

      fetchFood();
    } catch (e) {
      print("Add error: $e");
    }
  }

  //////////////////////////////////////////////////////////
  // CLAIM FOOD
  //////////////////////////////////////////////////////////
  Future<void> claimFood(Map<String, dynamic> item) async {
    await Amplify.API.mutate(
      request: GraphQLRequest(
        document:
            '''mutation { updateFoodItem(input:{id:"${item["id"]}", claimed:true}){id}}''',
      ),
    ).response;

    fetchFood();

    if (item["map"] != null && item["map"] != "") {
      await openMap(item["map"]);
    }
  }

  //////////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Waste Management"),
        actions: [
          // ✅ REPORT BUTTON
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: "Generate Report",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen()),
              );
            },
          ),

          // 🤖 NEW CHATBOT BUTTON
          IconButton(
            icon: Icon(Icons.smart_toy),
            tooltip: "Guide Bot",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatbotScreen()),
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Amplify.Auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),

      body: foodItems.isEmpty
          ? Center(child: Text("No food available"))
          : ListView.builder(
              itemCount: foodItems.length,
              itemBuilder: (_, i) {
                var item = foodItems[i];

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: item["image"] != ""
                        ? FutureBuilder(
                            future: getImageUrl(item["image"]),
                            builder: (_, snap) {
                              if (!snap.hasData || snap.data == "") {
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Icon(Icons.fastfood),
                                );
                              }

                              return SizedBox(
                                width: 60,
                                height: 60,
                                child: Image.network(
                                  snap.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.broken_image),
                                ),
                              );
                            },
                          )
                        : SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(Icons.fastfood),
                          ),

                    title: Text(item["title"]),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Qty: ${item["quantity"]} | ₹${item["cost"]}"),
                        Text("Type: ${item["type"]}"),
                        if (item["animalFood"] == true)
                          Text("🐾 Suitable for Animals"),
                      ],
                    ),

                    trailing: ElevatedButton(
                      onPressed: item["claimed"] == true
                          ? null
                          : () => claimFood(item),
                      child:
                          Text(item["claimed"] == true ? "Claimed" : "Claim"),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFoodScreen(addFood: addFood),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}