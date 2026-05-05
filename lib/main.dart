import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'daily_bundle_screen.dart';
import 'island_carousel_screen.dart';
import 'milestone_rive_item.dart';
import 'rive_dialog.dart';

void main() {
  RiveNative.init().then((_){
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RiveTestScreen(),
    );
  }
}

class RiveTestScreen extends StatefulWidget {
  const RiveTestScreen({super.key});

  @override
  State<RiveTestScreen> createState() => _RiveTestScreenState();
}

class _RiveTestScreenState extends State<RiveTestScreen> {

  @override
  void initState() {
    super.initState();
  }

  void _startAnimation() {
    // Show the Rive animation in a dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const RiveDialog();
      },
    );
  }

  void _showNormalDialog() {
    // Show a normal text dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Normal Dialog'),
          content: const Text('This is a normal dialog with just text. No Rive animation here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Rive Animation Test'),
      ),
      body: Center(
        child: _buildButtonView(),
      ),
    );
  }

  Widget _buildButtonView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const Text(
        //   'Test Dialog Interference',
        //   style: TextStyle(fontSize: 18),
        // ),
        // const SizedBox(height: 20),
        // ElevatedButton(
        //   onPressed: _showNormalDialog,
        //   child: const Text('Show Normal Dialog'),
        // ),
        // const SizedBox(height: 20),
        // ElevatedButton(
        //   onPressed: _startAnimation,
        //   child: const Text('Show Rive Animation Dialog'),
        // ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DailyBundleScreen(),
            ),
          ),
          child: const Text('Test daily_bundle.riv'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MilestoneRiveItem(),
            ),
          ),
          child: const Text('Test l2_full_path.riv'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const IslandCarouselScreen(),
            ),
          ),
          child: const Text('Test Island Carousel (ela/math)'),
        ),
        const SizedBox(height: 20),
        // const Text(
        //   'Test: Show normal dialog first, close it, then show Rive dialog',
        //   textAlign: TextAlign.center,
        //   style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        // ),
      ],
    );
  }

}