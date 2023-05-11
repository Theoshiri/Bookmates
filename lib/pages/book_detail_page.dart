import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({Key? key, required this.book}) : super(key: key);

  final dynamic book;

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  bool isLiked = false;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> toggleLike() async {
    final bookTitle = widget.book['volumeInfo']['title'];
    final bookRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('Favorite Books')
        .doc(bookTitle);

    final bookAuthor = widget.book['volumeInfo']['authors'][0];
    final thumbnail = widget.book['volumeInfo']['imageLinks']['thumbnail'];

    if (isLiked) {
      await bookRef.delete();
    } else {
      await bookRef.set({
        'title': bookTitle,
        'author': bookAuthor,
        'thumbnail': thumbnail,
      });
    }

    setState(() {
      isLiked = !isLiked;
    });
  }

  Future<bool> isBookLiked() async {
    final bookTitle = widget.book['volumeInfo']['title'];
    final bookRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.uid)
        .collection('Favorite Books')
        .doc(bookTitle);

    final snapshot = await bookRef.get();
    return snapshot.exists;
  }

  Future<List<dynamic>> getRecommendedBooks() async {
    final bookAuthor = widget.book['volumeInfo']['authors'][0];
    final authorQuery = 'inauthor:"$bookAuthor"';
    final url =
        'https://www.googleapis.com/books/v1/volumes?q=$authorQuery&maxResults=11';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final items = jsonResponse['items'] ?? [];
      final recommendedBooks = items
          .where((item) => item['id'] != widget.book['id'])
          .take(10)
          .toList();
      return recommendedBooks;
    } else {
      throw Exception('Failed to load recommended books');
    }
  }

  @override
  void initState() {
    super.initState();
    isBookLiked().then((value) {
      setState(() {
        isLiked = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Book Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Center(
              child: Image.network(
                widget.book['volumeInfo']['imageLinks']['thumbnail'],
                height: 200,
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.book['volumeInfo']['title'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.book['volumeInfo']['authors'][0],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.book['volumeInfo']['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Recommended Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 15),
            FutureBuilder<List<dynamic>>(
              future: getRecommendedBooks(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No Recommendations Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        final book = snapshot.data![index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookDetailsPage(book: book),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                book['volumeInfo']['imageLinks'] != null &&
                                        book['volumeInfo']['imageLinks']
                                                ['thumbnail'] !=
                                            null
                                    ? Image.network(
                                        book['volumeInfo']['imageLinks']
                                            ['thumbnail'],
                                        height: 130,
                                        width: 90,
                                      )
                                    : Image.asset(
                                        'assets/images/missing-book-thumbnail.png',
                                        height: 130,
                                        width: 90,
                                      ),
                                SizedBox(height: 5),
                                SizedBox(
                                  width: 90,
                                  child: book['volumeInfo']['title'] != null
                                      ? Text(
                                          book['volumeInfo']['title'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      : Text(
                                          'Unknown title',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                                SizedBox(height: 3),
                                SizedBox(
                                  width: 90,
                                  child:
                                      book['volumeInfo']['authors'] != null &&
                                              book['volumeInfo']['authors']
                                                  .isNotEmpty
                                          ? Text(
                                              book['volumeInfo']['authors'][0],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            )
                                          : SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 5),
            // Add reviews widget here
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Feature Coming Soon",
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: toggleLike,
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : null,
        ),
      ),
    );
  }
}
