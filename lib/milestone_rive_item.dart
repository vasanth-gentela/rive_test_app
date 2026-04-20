import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class MilestoneRiveItem extends StatelessWidget {
  const MilestoneRiveItem({super.key});

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.of(context).size.width - 40;
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('l2_full_path.riv'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 284,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _RivePathPanel(noOfLO: 6, width: panelWidth, height: 244),
                  const SizedBox(width: 16),
                  _RivePathPanel(noOfLO: 3, width: panelWidth, height: 244),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _RivePathPanel extends StatefulWidget {
  final int noOfLO;
  final double width;
  final double height;

  const _RivePathPanel({
    required this.noOfLO,
    required this.width,
    required this.height,
  });

  @override
  State<_RivePathPanel> createState() => _RivePathPanelState();
}

class _RivePathPanelState extends State<_RivePathPanel> {
  static const _riveAsset = 'assets/images/l2_full_path.riv';

  late final FileLoader _fileLoader = FileLoader.fromAsset(
    _riveAsset,
    riveFactory: Factory.rive,
  );

  StateMachine? _stateMachine;
  ViewModelInstance? _riveVm;

  void _onRiveLoaded(RiveLoaded state) {
    _stateMachine = state.controller.stateMachine;
    _riveVm = state.viewModelInstance;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final vm = _riveVm;
      if (vm == null) {
        debugPrint('[RivePathPanel(${widget.noOfLO})] viewModelInstance is NULL');
        return;
      }
      _applyDefaults(vm);
    });
  }

  void _applyDefaults(ViewModelInstance vm) {

    vm.number('noOfLO')?.value = widget.noOfLO.toDouble();

    final msVm = vm.viewModel('mileStone');
    msVm?.string('mileStoneNumber')?.value = '1';
    msVm?.string('mileStoneTopic')?.value = 'Addition';

    final chestVm = vm.viewModel('propertyOfChestPath');
    chestVm?.boolean('chestOpen')?.value = false;
    chestVm?.number('lastPathProgress')?.value = 0;

    for (int i = 1; i <= widget.noOfLO; i++) {
      final loVm = vm.viewModel('propertyOfLO$i');
      if (loVm == null) continue;
      loVm.number('pathProgress')?.value = 0;

      final stoolVm = loVm.viewModel('inputsOfLO');
      if (stoolVm == null) continue;
      stoolVm.number('starNumber')?.value = 0;
      stoolVm.enumerator('splasheeOnLO')?.value = 'notCompletedLO';
      stoolVm.trigger('updateLO')?.trigger();
    }

    debugPrint('[RivePathPanel] ${widget.noOfLO} LOs applied');
  }

  @override
  void dispose() {
    _stateMachine?.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  Widget _redLine() => Container(width: 1, color: Colors.red);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RiveWidgetBuilder(
        fileLoader: _fileLoader,
        dataBind: DataBind.auto(),
        artboardSelector: ArtboardSelector.byDefault(),
        stateMachineSelector: StateMachineSelector.byDefault(),
        onLoaded: _onRiveLoaded,
        builder: (context, state) {
          if (state is RiveLoaded) {
            return Stack(
              children: [
                RiveWidget(
                  controller: state.controller,
                  fit: Fit.fitWidth,
                  alignment: Alignment.centerLeft,
                ),
                Positioned(left: 0, top: 0, bottom: 0, child: _redLine()),
                Positioned(right: 0, top: 0, bottom: 0, child: _redLine()),
              ],
            );
          }
          if (state is RiveFailed) {
            return Center(
              child: Text('Failed: ${state.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      ),
    );
  }
}
