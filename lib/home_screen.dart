import 'package:flutter/material.dart';
import 'search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBarWidget(
                controller: _searchController,
                hintText: 'Search songs and playlists...',
                onChanged: (query) {
                  // TODO: Implement search logic
                },
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Recent Playlists',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // TODO: Implement Recent Playlists UI
              const Center(child: Text('Coming soon...')),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Recent Songs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              // TODO: Implement Recent Songs UI
              const Center(child: Text('Coming soon...')),
            ],
          ),
        ),
      ),
    );
  }
}
