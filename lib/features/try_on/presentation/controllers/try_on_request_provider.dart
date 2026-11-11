import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:closet_ai/features/closet/domain/garment.dart';

/// Garments another screen asks to try on in the Probador. The home shell
/// opens the Probador, which puts them on and sets the value back to null.
final tryOnRequestProvider = StateProvider<List<Garment>?>((ref) => null);
