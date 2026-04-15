import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class DailyBundleScreen extends StatefulWidget {
  const DailyBundleScreen({super.key});

  @override
  State<DailyBundleScreen> createState() => _DailyBundleScreenState();
}

class _DailyBundleScreenState extends State<DailyBundleScreen> {
  static const _riveUrl =
      'https://staging-cdn.splashmath.com/assets/magical-dashboard/rive/desktop/daily_bundle.riv';
  static const _riveAsset = 'assets/images/dailybundle.riv';
  static const _useLocalAsset = true;

  late final FileLoader _fileLoader = _useLocalAsset
      ? FileLoader.fromAsset(
          _riveAsset,
          riveFactory: Factory.rive,
        )
      : FileLoader.fromUrl(
          '$_riveUrl?cacheBust=${DateTime.now().millisecondsSinceEpoch}',
          riveFactory: Factory.rive,
        );
  StateMachine? _stateMachine;
  ViewModelInstance? _riveVm;
  Map<String, bool> _bindings = {};

  // Controls
  String _rocketState = 'notStarted';
  double _missionProgress = 50;
  int _currentMissionNumber = 3;
  bool _orbFTUE = false;
  bool _completedOrb = false;
  String _subject = 'math';
  double _starNumber = 2;
  double _orbFlagNumber = 0;

  final _cgPackNameController = TextEditingController(text: 'math');
  final _podiumNameController = TextEditingController(text: 'Hero');

  bool _startFired = false;
  bool _celebrationFired = false;

  @override
  void initState() {
    super.initState();
  }

  void _onRiveLoaded(RiveLoaded state) {
    _stateMachine = state.controller.stateMachine;
    _riveVm = state.viewModelInstance;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final vm = _riveVm;
      if (vm == null) {
        debugPrint('[DailyBundle] viewModelInstance is NULL after 100ms');
        setState(() => _bindings = {'viewModelInstance': false});
        return;
      }
      _inspectAndApply(vm);
    });
  }

  void _inspectAndApply(ViewModelInstance vm) {
    final orbVm = vm.viewModel('propertyOfOrbVM');
    final podiumVm = vm.viewModel('podiumName');

    final results = <String, bool>{
      'rocketState (Enum)': vm.enumerator('rocketState') != null,
      'orbFTUE (Boolean)': vm.boolean('orbFTUE') != null,
      'missionProgress (Number)': vm.number('missionProgress') != null,
      'currentMissionNumber (Number)': vm.number('currentMissionNumber') != null,
      'cgPackName (String)': vm.string('cgPackName') != null,
      'subject (Enum)': vm.enumerator('subject') != null,
      'completedOrb (Boolean)': vm.boolean('completedOrb') != null,
      'startCelebration (Trigger)': vm.trigger('startCelebration') != null,
      'start (Trigger)': vm.trigger('start') != null,
      'propertyOfOrbVM (ViewModel)': orbVm != null,
      '  starNumber (Number)': orbVm?.number('starNumber') != null,
      '  orbFlagNumber (Number)': orbVm?.number('orbFlagNumber') != null,
      'podiumName (ViewModel)': podiumVm != null,
      '  podiumNameText (String)': podiumVm?.string('podiumNameText') != null,
    };

    final buf = StringBuffer('\n[DailyBundle] Binding inspection:\n');
    for (final e in results.entries) {
      buf.writeln('  ${e.value ? '✓' : '✗'} ${e.key}');
    }
    debugPrint(buf.toString());

    // Apply initial values
    vm.enumerator('rocketState')?.value = _rocketState;
    vm.boolean('orbFTUE')?.value = _orbFTUE;
    vm.number('missionProgress')?.value = _missionProgress;
    vm.number('currentMissionNumber')?.value = _currentMissionNumber.toDouble();
    vm.string('cgPackName')?.value = 'math';
    vm.enumerator('subject')?.value = _subject;
    vm.boolean('completedOrb')?.value = _completedOrb;
    orbVm?.number('starNumber')?.value = _starNumber;
    orbVm?.number('orbFlagNumber')?.value = _orbFlagNumber;
    podiumVm?.string('podiumNameText')?.value = 'Hero';
    vm.trigger('start')?.trigger();

    setState(() => _bindings = results);
  }

  void _triggerStart() {
    _riveVm?.trigger('start')?.trigger();
    setState(() => _startFired = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _startFired = false);
    });
  }

  void _triggerCelebration() {
    _riveVm?.trigger('startCelebration')?.trigger();
    setState(() => _celebrationFired = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _celebrationFired = false);
    });
  }

  @override
  void dispose() {
    _stateMachine?.dispose();
    _fileLoader.dispose();
    _cgPackNameController.dispose();
    _podiumNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: const Text('daily_bundle.riv'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: Row(
          children: [
            Expanded(flex: 3, child: _buildRivePanel()),
            _buildControlPanel(),
          ],
        ),
      );

  Widget _buildRivePanel() => RiveWidgetBuilder(
      fileLoader: _fileLoader,
      dataBind: DataBind.auto(),
      artboardSelector: ArtboardSelector.byDefault(),
      stateMachineSelector: StateMachineSelector.byDefault(),
      onLoaded: _onRiveLoaded,
      builder: (context, state) {
        if (state is RiveLoaded) {
          return RiveWidget(controller: state.controller, fit: Fit.contain);
        }
        if (state is RiveFailed) {
          return Center(
            child: Text('Rive render failed: ${state.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );

  Widget _buildControlPanel() {
    return Container(
      width: 300,
      color: Colors.grey[850],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Bindings'),
            if (_bindings.isEmpty)
              const Text('Loading…',
                  style: TextStyle(color: Colors.white54, fontSize: 12))
            else
              ..._bindings.entries.map(_bindingRow),
            const _Divider(),
            _section('rocketState (Enum)'),
            DropdownButton<String>(
              value: _rocketState,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'notStarted', child: Text('notStarted')),
                DropdownMenuItem(value: 'midWay', child: Text('midWay')),
                DropdownMenuItem(value: 'flying', child: Text('flying')),
                DropdownMenuItem(value: 'insideDB', child: Text('insideDB')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _rocketState = v);
                _riveVm?.enumerator('rocketState')?.value = v;
                _triggerStart();
              },
            ),
            _section('missionProgress: ${_missionProgress.toStringAsFixed(0)}'),
            Slider(
              value: _missionProgress,
              min: 0,
              max: 100,
              onChanged: (v) {
                setState(() => _missionProgress = v);
                _riveVm?.number('missionProgress')?.value = v;
              },
            ),
            _section('currentMissionNumber: $_currentMissionNumber'),
            Slider(
              value: _currentMissionNumber.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) {
                setState(() => _currentMissionNumber = v.toInt());
                _riveVm?.number('currentMissionNumber')?.value = v;
              },
            ),
            _section('subject (Enum)'),
            DropdownButton<String>(
              value: _subject,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'math', child: Text('math')),
                DropdownMenuItem(value: 'english', child: Text('english')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _subject = v);
                _riveVm?.enumerator('subject')?.value = v;
              },
            ),
            _section('cgPackName (String)'),
            _stringField(
              controller: _cgPackNameController,
              onSubmitted: (v) => _riveVm?.string('cgPackName')?.value = v,
            ),
            _section('podiumNameText (String)'),
            _stringField(
              controller: _podiumNameController,
              onSubmitted: (v) => _riveVm
                  ?.viewModel('podiumName')
                  ?.string('podiumNameText')
                  ?.value = v,
            ),
            _section('starNumber: ${_starNumber.toStringAsFixed(0)}'),
            Slider(
              value: _starNumber,
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: (v) {
                setState(() => _starNumber = v);
                _riveVm
                    ?.viewModel('propertyOfOrbVM')
                    ?.number('starNumber')
                    ?.value = v;
              },
            ),
            _section('orbFlagNumber: ${_orbFlagNumber.toStringAsFixed(0)}'),
            Slider(
              value: _orbFlagNumber,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) {
                setState(() => _orbFlagNumber = v);
                _riveVm
                    ?.viewModel('propertyOfOrbVM')
                    ?.number('orbFlagNumber')
                    ?.value = v;
              },
            ),
            SwitchListTile(
              title: const Text('orbFTUE',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              value: _orbFTUE,
              activeThumbColor: Colors.deepPurple,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                setState(() => _orbFTUE = v);
                _riveVm?.boolean('orbFTUE')?.value = v;
              },
            ),
            SwitchListTile(
              title: const Text('completedOrb',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              value: _completedOrb,
              activeThumbColor: Colors.deepPurple,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                setState(() => _completedOrb = v);
                _riveVm?.boolean('completedOrb')?.value = v;
              },
            ),
            const SizedBox(height: 8),
            _triggerButton(
              label: '▶  start',
              firedLabel: '✓ fired!',
              color: Colors.deepPurple,
              firedColor: Colors.green[700]!,
              fired: _startFired,
              onTap: _triggerStart,
            ),
            const SizedBox(height: 8),
            _triggerButton(
              label: '🎉  startCelebration',
              firedLabel: '✓ fired!',
              color: Colors.orange,
              firedColor: Colors.green[700]!,
              fired: _celebrationFired,
              onTap: _triggerCelebration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );

  Widget _bindingRow(MapEntry<String, bool> e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(e.value ? Icons.check_circle : Icons.cancel,
                color: e.value ? Colors.greenAccent : Colors.redAccent,
                size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(e.key,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          e.value ? Colors.white70 : Colors.redAccent[100])),
            ),
          ],
        ),
      );

  Widget _stringField({
    required TextEditingController controller,
    required ValueChanged<String> onSubmitted,
  }) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: Color(0xFF424242),
          border: OutlineInputBorder(borderSide: BorderSide.none),
          hintText: 'Enter value…',
          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        onSubmitted: onSubmitted,
      );

  Widget _triggerButton({
    required String label,
    required String firedLabel,
    required Color color,
    required Color firedColor,
    required bool fired,
    required VoidCallback onTap,
  }) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: fired ? firedColor : color,
            elevation: fired ? 0 : 2,
          ),
          onPressed: onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              fired ? firedLabel : label,
              key: ValueKey(fired),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: Colors.white24, height: 24);
}
