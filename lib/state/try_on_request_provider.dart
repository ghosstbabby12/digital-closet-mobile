import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/garment.dart';

/// Prendas que otra pantalla pide probar en el Probador. La pestaña de inicio
/// abre el Probador y este las coloca y vuelve a dejar el valor en null.
final tryOnRequestProvider = StateProvider<List<Garment>?>((ref) => null);
