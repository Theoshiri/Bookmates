import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'book_detail_page.dart';
import 'edit_profile_page.dart';

import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? userName;
  int followersCount = 0;
  int followingCount = 0;
  int favoriteBooksCount = 0;

  String? userUID;

  final storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _getUserInfo();
      _getFavoriteBooksCount();
    }
  }

  void _getUserInfo() async {
    final email = user!.email;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('Email', isEqualTo: email)
        .get();

    final documentSnapshot = querySnapshot.docs.first;

    setState(() {
      userName = documentSnapshot['Name'];
      followersCount = documentSnapshot['Followers'];
      followingCount = documentSnapshot['Following'];
      String? profileImg = documentSnapshot['profileImg'];
      if (profileImg != null && profileImg.isNotEmpty) {
        user!.updatePhotoURL(profileImg);
      }
    });
  }

  void _getFavoriteBooksCount() async {
    final userId = user!.uid;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Favorite Books')
        .get();

    setState(() {
      favoriteBooksCount = querySnapshot.docs.length;
    });
  }

  void _openBookDetailsPage(dynamic book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsPage(book: book),
      ),
    );
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final file = File(pickedFile.path);

    final email = user!.email;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('Email', isEqualTo: email)
        .get();

    final documentSnapshot = querySnapshot.docs.first;
    setState(() {
      userUID = documentSnapshot['UID'];
    });

    final snapshot = await storage
        .ref()
        .child('profile_images/${user!.uid}.jpg')
        .putFile(file);
    final downloadURL = await snapshot.ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: userUID)
        .get()
        .then((QuerySnapshot snapshot) {
      snapshot.docs[0].reference.update({'profileImg': downloadURL});
    }).catchError((error) => print("Failed to update user: $error"));

    user!.updatePhotoURL(downloadURL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            if (user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      left: 40,
                      right: 40,
                      top: 40,
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _uploadImage(),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(user!.photoURL ??
                                'https://via.placeholder.com/200'),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '${userName ?? ''}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Favorites',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$favoriteBooksCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Followers',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$followersCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Following',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '$followingCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // SizedBox(height: 10),
                        // SizedBox(
                        //   width: double.infinity,
                        //   child: ElevatedButton(
                        //     style: ElevatedButton.styleFrom(
                        //       primary: Theme.of(context).primaryColor,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //     ),
                        //     onPressed: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => EditProfilePage()),
                        //       );
                        //     },
                        //     child: Text('Edit Profile'),
                        //   ),
                        // ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                  Container(
                    child: SizedBox(
                      height: 400, // Define a height for the ListView
                      child: Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(user!.uid)
                              .collection('Favorite Books')
                              .snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Something went wrong');
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return Text('No favorite books added yet.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                  ));
                            }

                            return ListView(
                              children: snapshot.data!.docs.map((document) {
                                final bookTitle = document['title'];
                                final bookAuthor = document['author'];
                                return ListTile(
                                  leading: Image.network(
                                    document['thumbnail'],
                                    width: 50,
                                  ),
                                  title: Text(bookTitle),
                                  subtitle: Text(bookAuthor),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Please log in to view your profile.',
                style: TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}
