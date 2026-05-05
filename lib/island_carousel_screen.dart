import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class IslandCarouselScreen extends StatefulWidget {
  const IslandCarouselScreen({super.key});

  @override
  State<IslandCarouselScreen> createState() => _IslandCarouselScreenState();
}

class _IslandCarouselScreenState extends State<IslandCarouselScreen> {
  static const int _islandCount = 6;
  static const String _elaAsset = 'assets/images/ela_island_1.riv';
  static const String _mathAsset = 'assets/images/math_island_1.riv';
  static const String _artboardName = 'islandArtBoard';
  static const String _stateMachineName = 'islandSM';

  // Static finals — created once, same instance on every build.
  // RiveWidgetBuilder.didUpdateWidget sees no change → no Rive reinitialization.
  static final _artboardSelector = ArtboardSelector.byName(_artboardName);
  static final _stateMachineSelector =
      StateMachineSelector.byName(_stateMachineName);

  late PageController _pageController;
  bool _pageControllerInitialized = false;

  // ValueNotifier drives nav buttons and title without rebuilding the PageView.
  final _currentPageNotifier = ValueNotifier<int>(0);
  int get _currentPage => _currentPageNotifier.value;

  int _lastRivePage = 0;

  late final List<FileLoader> _fileLoaders;
  // One DataBind per island, created once in initState — stable across builds.
  late final List<DataBind> _dataBinds;

  final Map<int, RiveWidgetController> _controllers = {};
  final Map<int, ViewModelInstance> _viewModels = {};
  final Set<int> _initializingControllers = {};
  final Set<int> _pausedIslands = {};

  String _assetForIndex(int i) => i % 2 == 0 ? _elaAsset : _mathAsset;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5, initialPage: 0);
    _fileLoaders = List.generate(
      _islandCount,
      (i) => FileLoader.fromAsset(_assetForIndex(i), riveFactory: Factory.rive),
    );
    _dataBinds = List.generate(_islandCount, (_) => DataBind.auto());
  }

  void _navigateTo(int page) {
    if (page < 0 || page >= _islandCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Fires at the 0.5 threshold during drag.
  // No setState — the PageView tree never rebuilds while scrolling.
  void _onPageScrolled() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    final rounded = page.round();
    if (rounded != _lastRivePage) {
      _lastRivePage = rounded;
      _currentPageNotifier.value = rounded; // updates nav buttons / title only
      _applyStateForPage(rounded);
    }
  }

  void _applyStateForPage(int page) {
    for (int i = 0; i < _islandCount; i++) {
      final vm = _viewModels[i];
      final controller = _controllers[i];
      if (vm == null || controller == null) continue;
      if (_initializingControllers.contains(i)) continue;

      final isActive = i == page;
      vm.enumerator('status')?.value = isActive ? 'selected' : 'unselected';
      vm.trigger('start')?.trigger();

      if (isActive) {
        try { controller.active = true; } catch (_) {}
        _pausedIslands.remove(i);
      } else {
        _pausedIslands.add(i);
      }
    }
  }

  void _onIslandLoaded(int index, RiveLoaded state) {
    _controllers[index] = state.controller;
    final vm = state.viewModelInstance;
    if (vm != null) _viewModels[index] = vm;
    _initializingControllers.add(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializingControllers.remove(index);

      final viewModel = _viewModels[index];
      if (viewModel == null) return;

      final isActive = index == _currentPage;
      viewModel.enumerator('status')?.value = isActive ? 'selected' : 'unselected';
      viewModel.trigger('start')?.trigger();
      if (isActive) {
        try { state.controller.active = true; } catch (_) {}
      }
      if (mounted) setState(() {
        print('setstate: Island $index loaded. Active: $isActive. Paused islands: $_pausedIslands');
      });
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScrolled);
    _pageController.dispose();
    _currentPageNotifier.dispose();
    for (final loader in _fileLoaders) {
      loader.dispose();
    }
    super.dispose();
  }

  static const double _islandSize = 800.0;

  double _viewportFraction(double screenWidth) {
    double spacing;
    if (screenWidth >= 1280.0) {
      spacing = (screenWidth / 1280.0) * 638.0;
    } else if (screenWidth >= 1024.0) {
      spacing = (screenWidth / 1024.0) * 512.0;
    } else if (screenWidth >= 600.0) {
      spacing = (screenWidth / 600.0) * 356.0;
    } else {
      spacing = 356.0;
    }
    return (spacing / screenWidth).clamp(0.5, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final W = MediaQuery.of(context).size.width;

    if (!_pageControllerInitialized && !_pageController.hasClients) {
      final vf = _viewportFraction(W);
      _pageController.dispose();
      _pageController = PageController(viewportFraction: vf, initialPage: 0);
      _pageController.addListener(_onPageScrolled);
      _pageControllerInitialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2744),
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: _currentPageNotifier,
          builder: (_, page, __) =>
              Text('Island Carousel (${page + 1}/$_islandCount)'),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // clipBehavior: Clip.none lets 800px islands overflow their slot
          // so all 3 are visible simultaneously.
          PageView.builder(
            controller: _pageController,
            clipBehavior: Clip.none,
            physics: const _NoMomentumScrollPhysics(),
            itemCount: _islandCount,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double distance = 0.0;
                  if (_pageController.position.haveDimensions) {
                    distance = (_pageController.page! - index).abs();
                  }
                  final scale = (1.0 - distance * 0.25).clamp(0.75, 1.0);
                  // Smooth opacity — avoids binary jump that triggers Metal layer churn
                  final opacity =
                      (1.0 - distance.clamp(0.0, 1.0) * 0.2).clamp(0.8, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                // child is built once per parent build (not per animation frame).
                // Stable DataBind / selectors → RiveWidgetBuilder never reinitializes.
                child: _buildIsland(index),
              );
            },
          ),
          // Only this Row rebuilds when the page changes.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ValueListenableBuilder<int>(
                valueListenable: _currentPageNotifier,
                builder: (_, page, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavButton(
                      icon: Icons.chevron_left,
                      enabled: page > 0,
                      onTap: () => _navigateTo(page - 1),
                    ),
                    const SizedBox(width: 48),
                    _NavButton(
                      icon: Icons.chevron_right,
                      enabled: page < _islandCount - 1,
                      onTap: () => _navigateTo(page + 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsland(int index) {
    return OverflowBox(
      alignment: Alignment.center,
      minWidth: 0,
      maxWidth: _islandSize,
      minHeight: 0,
      maxHeight: _islandSize,
      child: SizedBox.square(
        dimension: _islandSize,
        // Each island gets its own Metal compositing layer.
        child: RepaintBoundary(
          child: RiveWidgetBuilder(
            fileLoader: _fileLoaders[index],
            dataBind: _dataBinds[index],             // stable — created once in initState
            artboardSelector: _artboardSelector,     // stable — static final
            stateMachineSelector: _stateMachineSelector, // stable — static final
            onLoaded: (state) => _onIslandLoaded(index, state),
            builder: (context, state) {
              if (state is RiveLoaded) {
                return RiveWidget(
                  controller: state.controller,
                  fit: Fit.contain,
                );
              }
              if (state is RiveFailed) {
                return Center(
                  child: Text(
                    'Failed: ${state.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

class _NoMomentumScrollPhysics extends ScrollPhysics {
  const _NoMomentumScrollPhysics({super.parent});

  @override
  _NoMomentumScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _NoMomentumScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    return null;
  }
}
