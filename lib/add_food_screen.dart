import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AddFoodScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) addFood;

  AddFoodScreen({required this.addFood});

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final titleController = TextEditingController();
  final hotelController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final qtyController = TextEditingController();
  final costController = TextEditingController();
  final mapLinkController = TextEditingController();

  File? image;
  bool isLoading = false;

  DateTime? selectedExpiry;
  bool isAnimalFood = false;

  // ✅ NEW: FOOD TYPE (ONLY ONE SELECTABLE)
  String selectedFoodType = "Veg";

  //////////////////////////////////////////////////////////
  // 📸 PICK IMAGE
  //////////////////////////////////////////////////////////
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  //////////////////////////////////////////////////////////
  // ☁️ UPLOAD IMAGE
  //////////////////////////////////////////////////////////
  Future<String> uploadImage(File file) async {
    final key = "food/${DateTime.now().millisecondsSinceEpoch}.jpg";

    try {
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        key: key,
        options: StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      ).result;

      print("UPLOAD SUCCESS: $key");
      return key;
    } catch (e) {
      print("UPLOAD ERROR: $e");
      return "";
    }
  }

  //////////////////////////////////////////////////////////
  // 📅 PICK DATE + TIME
  //////////////////////////////////////////////////////////
  Future<void> pickExpiryDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedExpiry = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  //////////////////////////////////////////////////////////
  // ✅ VALIDATION
  //////////////////////////////////////////////////////////
  bool validate() {
    if (titleController.text.isEmpty ||
        hotelController.text.isEmpty ||
        phoneController.text.length != 10 ||
        addressController.text.isEmpty ||
        qtyController.text.isEmpty ||
        costController.text.isEmpty ||
        selectedExpiry == null) {
      _showSnack("Fill all required fields correctly");
      return false;
    }
    return true;
  }

  //////////////////////////////////////////////////////////
  // ➕ SUBMIT FOOD
  //////////////////////////////////////////////////////////
  Future<void> submit() async {
    if (!validate()) return;

    setState(() => isLoading = true);

    try {
      String imgKey = "";

      if (image != null) {
        imgKey = await uploadImage(image!);
      }

      widget.addFood({
        "title": titleController.text.trim(),
        "hotel": hotelController.text.trim(),
        "type": selectedFoodType, // ✅ UPDATED
        "quantity": qtyController.text.trim(),
        "cost": costController.text.trim(),
        "expiryTime": selectedExpiry!.toIso8601String(),
        "image": imgKey,
        "animalFood": isAnimalFood,
        "hotelMapLink": mapLinkController.text.trim(),
      });

      _showSnack("Food added successfully 🎉");

      Navigator.pop(context);
    } catch (e) {
      _showSnack("Error adding food");
    }

    setState(() => isLoading = false);
  }

  //////////////////////////////////////////////////////////
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  //////////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Food"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: inputStyle("Food Name"),
            ),

            SizedBox(height: 12),

            TextField(
              controller: hotelController,
              decoration: inputStyle("Hotel Name"),
            ),

            SizedBox(height: 12),

            TextField(
              controller: phoneController,
              decoration: inputStyle("Hotel Phone"),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 12),

            TextField(
              controller: addressController,
              decoration: inputStyle("Address"),
            ),

            SizedBox(height: 12),

            TextField(
              controller: qtyController,
              decoration: inputStyle("Quantity"),
            ),

            SizedBox(height: 12),

            TextField(
              controller: costController,
              decoration: inputStyle("Cost"),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 15),

            ElevatedButton(
              onPressed: pickExpiryDateTime,
              child: Text(
                selectedExpiry == null
                    ? "Select Expiry Date & Time"
                    : selectedExpiry.toString(),
              ),
            ),

            SizedBox(height: 12),

            TextField(
              controller: mapLinkController,
              decoration: inputStyle("Google Maps Link"),
            ),

            SizedBox(height: 15),

            //////////////////////////////////////////////////////////
            // ✅ RADIO BUTTONS (ONLY ONE SELECTABLE)
            //////////////////////////////////////////////////////////
            Column(
              children: [
                RadioListTile<String>(
                  title: Text("Veg"),
                  value: "Veg",
                  groupValue: selectedFoodType,
                  onChanged: (value) {
                    setState(() {
                      selectedFoodType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text("Non-Veg"),
                  value: "Non-Veg",
                  groupValue: selectedFoodType,
                  onChanged: (value) {
                    setState(() {
                      selectedFoodType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text("Egg"),
                  value: "Egg",
                  groupValue: selectedFoodType,
                  onChanged: (value) {
                    setState(() {
                      selectedFoodType = value!;
                    });
                  },
                ),
              ],
            ),

            CheckboxListTile(
              title: Text("Suitable for Animals"),
              value: isAnimalFood,
              onChanged: (val) {
                setState(() => isAnimalFood = val ?? false);
              },
            ),

            SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.image),
              label: Text("Upload Image"),
            ),

            SizedBox(height: 10),

            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image!,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),

            SizedBox(height: 25),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: EdgeInsets.symmetric(
                          vertical: 14, horizontal: 50),
                    ),
                    child: Text("Add Food"),
                  ),
          ],
        ),
      ),
    );
  }
}