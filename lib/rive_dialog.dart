import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveDialog extends StatefulWidget {
  const RiveDialog({super.key});

  @override
  State<RiveDialog> createState() => _RiveDialogState();
}

class _RiveDialogState extends State<RiveDialog> {
  FileLoader? _fileLoader;
  RiveWidgetController? _riveController;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    print('Loading Rive file...');
    final file = await File.asset('assets/images/dashboardItemNudge_v11.riv',
          riveFactory: Factory.rive);
    _fileLoader = FileLoader.fromFile(file!, riveFactory: Factory.rive);
    print('FileLoader created: ${_fileLoader != null}');
    setState(() {});
  }

  void _onRiveLoaded(RiveWidgetController controller) {
    print('Rive animation loaded successfully!');
    _riveController = controller;

    // Start animation
    final stateMachine = controller.stateMachine;
    if (stateMachine != null) {
      print('State machine found, triggering start');
      final trigger = stateMachine.trigger('start');
      // trigger?.fire();
    } else {
      print('No state machine found');
    }
  }

  @override
  void dispose() {
    _fileLoader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          // Full screen Rive animation
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: _buildRiveWidget(),
          ),
          
          // Close button in bottom right
          Positioned(
            bottom: 50,
            right: 30,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: Colors.white.withOpacity(0.9),
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiveWidget() {
    if (_fileLoader == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return RiveWidgetBuilder(
      fileLoader: _fileLoader!,
      onLoaded: (state) {
        print('RiveWidgetBuilder onLoaded called');
        _onRiveLoaded(state.controller);
      },
      builder: (context, state) {
        print('RiveWidgetBuilder builder called with state: $state');

        switch (state) {
          case RiveLoading():
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );

          case RiveFailed():
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load animation: ${state.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );

          case RiveLoaded():
            return RiveWidget(
              controller: _riveController!,
              fit: Fit.contain,
            );
        }
      },
    );
  }
}