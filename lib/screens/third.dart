import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ThirdScreen extends StatefulWidget {
  const ThirdScreen({super.key});

  @override
  State<ThirdScreen> createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  List<dynamic> users = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchUsers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchUsers();
      }
    });
  }

  Future<void> fetchUsers({bool refresh = false}) async {
  if (isLoading) return;

  setState(() {
    isLoading = true;
    if (refresh) {
      currentPage = 1;
      hasMore = true;
    }
  });

  final url = 'https://reqres.in/api/users?page=$currentPage&per_page=6';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'x-api-key': 'reqres-free-v1',
      },
    );

  try {
    final response = await http.get(Uri.parse(url));
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> fetchedUsers = data['data'];

      setState(() {
        if (refresh) {
          users = fetchedUsers;
        } else {
          users.addAll(fetchedUsers);
        }

        if (fetchedUsers.isEmpty || fetchedUsers.length < 6) {
          hasMore = false;
        } else {
          currentPage++;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ${response.statusCode}: ${response.reasonPhrase}")),
      );
    }
  } catch (e) {
    print('Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exception: $e")),
    );
  }

  setState(() {
    isLoading = false;
  });
}


  void onUserTap(dynamic user) {
    final String fullName = '${user['first_name']} ${user['last_name']}';
    Navigator.pop(context, fullName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Third Screen"),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchUsers(refresh: true),
        child: users.isEmpty && !isLoading
            ? const Center(child: Text("No users found."))
            : ListView.builder(
                controller: _scrollController,
                itemCount: users.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < users.length) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user['avatar']),
                      ),
                      title: Text(
                        '${user['first_name']} ${user['last_name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['email'].toLowerCase()),
                      onTap: () => onUserTap(user),
                    );
                  } else {
                    // Loading indicator
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
      ),
    );
  }
}
