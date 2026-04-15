# Bug Report: Flutter Rive Runtime — `daily_bundle.riv`

## Environment
- Dart SDK: `3.10.3`
- Flutter: `3.38.4`
- `rive` package: `0.14.0`
- Rive file: `assets/images/dailybundle.riv`
- All inputs confirmed bound (green ✓) via `ViewModelInstance` inspection at runtime

---

## Issue 1: Nested ViewModel inputs not responding

Setting values on nested `ViewModelInstance` properties has no visual effect, even though the instances are found and non-null:

```dart
vm.viewModel('propertyOfOrbVM')?.number('starNumber')?.value = 2;
vm.viewModel('propertyOfOrbVM')?.number('orbFlagNumber')?.value = 3;
vm.viewModel('podiumName')?.string('podiumNameText')?.value = 'Hero';
```

Also unresponsive at the top-level VM:
```dart
vm.number('currentMissionNumber')?.value = 3;
vm.string('cgPackName')?.value = 'math';
vm.boolean('completedOrb')?.value = true;
```

All of these work correctly in the Rive editor preview.

---

## Issue 2: `rocketState` enum — only 2 of 4 values work

`notStarted` and `midWay` render correctly. `flying` and `insideDB` have no visual effect despite the enum value being set successfully:

```dart
vm.enumerator('rocketState')?.value = 'flying';   // no change
vm.enumerator('rocketState')?.value = 'insideDB';  // no change
```

---

## Issue 3: Thunder UI components missing during rocket progress

The editor preview shows thunder/lightning UI elements during rocket progress animation. These components are completely invisible when rendered in Flutter.

---

## Issue 4: Orb UI invisible after `startCelebration` trigger

**Steps to reproduce:**
1. Set `missionProgress` → `100`
2. Set `propertyOfOrbVM.orbFlagNumber` and `propertyOfOrbVM.starNumber`
3. Fire `startCelebration` trigger

**Result:** Celebration animation plays, but the orb UI is not visible.  
**Expected:** Orb UI visible with correct star/flag state (works in editor preview).

---

## Note

All bindings resolve as non-null at runtime. The issue appears to be in how the Flutter runtime applies ViewModel values compared to the editor preview.
