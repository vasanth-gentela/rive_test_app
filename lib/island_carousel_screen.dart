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

  late PageController _pageController;
  bool _pageControllerInitialized = false;
  int _currentPage = 0;
  int _lastRivePage = 0;

  late final List<FileLoader> _fileLoaders;
  final Map<int, RiveWidgetController> _controllers = {};
  final Map<int, ViewModelInstance> _viewModels = {};
  final Set<int> _initializingControllers = {};
  final Set<int> _pausedIslands = {};

  String _assetForIndex(int i) => i % 2 == 0 ? _elaAsset : _mathAsset;

  @override
  void initState() {
    super.initState();
    // viewportFraction is computed responsively on first build; use a placeholder here
    _pageController = PageController(viewportFraction: 0.5, initialPage: 0);
    _fileLoaders = List.generate(
      _islandCount,
      (i) => FileLoader.fromAsset(_assetForIndex(i), riveFactory: Factory.rive),
    );
  }

  void _navigateTo(int page) {
    if (page < 0 || page >= _islandCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Fires at 0.5 threshold during drag — matches carousel_islands.dart flicker fix attempt
  void _onPageScrolled() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    final rounded = page.round();
    if (rounded != _lastRivePage) {
      _lastRivePage = rounded;
      setState(()  {
        _currentPage = rounded;
        print('setstate: Page scrolled to $page (rounded: $rounded). Current page: $_currentPage. Paused islands: $_pausedIslands');
      });
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
        // Mirrors _resumeAnimations in carousel_islands.dart
        try {
          controller.active = true;
        } catch (_) {}
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
    for (final loader in _fileLoaders) {
      loader.dispose();
    }
    super.dispose();
  }

  // Matches ResponsiveDimensions.islandContainerSize — always 800×800
  static const double _islandSize = 800.0;

  // Mirrors ResponsiveDimensions.centerToCenterSpacing + _calculateViewportFraction
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
        title: Text('Island Carousel (${_currentPage + 1}/$_islandCount)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Clip.none lets islands overflow into neighbouring slots so all 3 are visible
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
                  // Center island at 1.0, neighbours at 0.75
                  final scale = (1.0 - distance * 0.25).clamp(0.75, 1.0);
                  // Smooth opacity — no binary jump
                  final opacity =
                      (1.0 - distance.clamp(0.0, 1.0) * 0.2).clamp(0.8, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: _buildIsland(index),
              );
            },
          ),
          // Left / right navigation buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavButton(
                    icon: Icons.chevron_left,
                    enabled: _currentPage > 0,
                    onTap: () => _navigateTo(_currentPage - 1),
                  ),
                  const SizedBox(width: 48),
                  _NavButton(
                    icon: Icons.chevron_right,
                    enabled: _currentPage < _islandCount - 1,
                    onTap: () => _navigateTo(_currentPage + 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsland(int index) {
    // OverflowBox lets the 800×800 island escape the slot's tight constraints
    // while staying centered. clipBehavior: Clip.none on PageView shows the overflow.
    return OverflowBox(
      alignment: Alignment.center,
      minWidth: 0,
      maxWidth: _islandSize,
      minHeight: 0,
      maxHeight: _islandSize,
      child: SizedBox.square(
        dimension: _islandSize,
        // RepaintBoundary gives each island its own Metal compositing layer
        child: RepaintBoundary(
          child: RiveWidgetBuilder(
            fileLoader: _fileLoaders[index],
            dataBind: DataBind.auto(),
            artboardSelector: ArtboardSelector.byName(_artboardName),
            stateMachineSelector: StateMachineSelector.byName(_stateMachineName),
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
