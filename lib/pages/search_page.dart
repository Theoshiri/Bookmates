import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'book_detail_page.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];

  Future<void> _searchBooks(String query) async {
    var url =
        'https://www.googleapis.com/books/v1/volumes?q=${query.replaceAll(' ', '+')}';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        searchResults = data['items'];
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  void _openBookDetailsPage(dynamic book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsPage(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: SizedBox(
          height: 40.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextField(
              style: TextStyle(color: Colors.black),
              controller: _searchController,
              onSubmitted: (value) {
                _searchBooks(value);
              },
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 4.0),
                hintText: 'Search For Books',
                hintStyle: TextStyle(
                  color: Colors.black,
                ),
                border: InputBorder.none,
                prefixIcon:
                    Icon(Icons.search, color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ),
      ),
      body: searchResults.length > 0
          ? ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (BuildContext context, int index) {
                var book = searchResults[index]['volumeInfo'];
                return GestureDetector(
                  onTap: () {
                    _openBookDetailsPage(searchResults[index]);
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        book['imageLinks'] != null
                            ? Container(
                                width: 70.0,
                                margin: EdgeInsets.only(right: 16.0),
                                child: Image.network(
                                    book['imageLinks']['smallThumbnail']),
                              )
                            : Icon(Icons.book, size: 70.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                book['authors'] != null
                                    ? book['authors'][0]
                                    : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                book['description'] != null
                                    ? book['description']
                                    : '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
    );
  }
}
