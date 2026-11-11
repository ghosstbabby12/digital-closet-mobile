import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:closet_ai/core/theme/app_theme.dart';
import 'package:closet_ai/core/widgets/error_snackbar.dart';
import 'package:closet_ai/core/widgets/photo_source_sheet.dart';
import 'package:closet_ai/core/widgets/retry_message.dart';
import 'package:closet_ai/features/closet/domain/garment.dart';
import 'package:closet_ai/features/home/presentation/widgets/screen_header.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/body_photo_controller.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/dressing_room_controller.dart';
import 'package:closet_ai/features/try_on/presentation/controllers/try_on_request_provider.dart';
import 'package:closet_ai/features/try_on/presentation/screens/looks_screen.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/body_photo_intro.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/garment_picker.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/layer_toolbar.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/look_generator_panel.dart';
import 'package:closet_ai/features/try_on/presentation/widgets/try_on_stage.dart';

class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({super.key});

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  bool _uploading = false;

  DressingRoomController get _room => ref.read(dressingRoomProvider.notifier);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  Future<void> _uploadFrom(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxHeight: 2000);
    if (picked == null) return;
    setState(() => _uploading = true);
    await _run(() => ref.read(bodyPhotoProvider.notifier).upload(picked));
    if (mounted) setState(() => _uploading = false);
  }

  void _showPhotoOptions({required bool hasPhoto}) => showPhotoSourceSheet(
    context,
    onPick: _uploadFrom,
    removeLabel: 'Eliminar mi foto',
    onRemove: hasPhoto
        ? () => _run(() async {
            await ref.read(bodyPhotoProvider.notifier).delete();
            _room.clear();
          })
        : null,
  );

  Future<void> _generateLook() => _run(() async {
    final look = await _room.generateLook();
    if (mounted) await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LookScreen(look: look)));
  });

  Future<void> _wearOutfit(List<Garment> garments) async {
    final error = await _room.wearOutfit(garments);
    if (error != null && mounted) showErrorSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tryOnRequestProvider, (previous, next) {
      if (next == null) return;
      // Cleared after the frame so the home shell also sees the request.
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(tryOnRequestProvider.notifier).state = null);
      _wearOutfit(next);
    });
    final photo = ref.watch(bodyPhotoProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Probador',
            actions: [
              HeaderIconButton(
                icon: Icons.photo_library_outlined,
                tooltip: 'Mis looks',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LooksScreen())),
              ),
              if (photo.valueOrNull != null)
                HeaderIconButton(
                  icon: Icons.person_outline,
                  tooltip: 'Mi foto',
                  onPressed: () => _showPhotoOptions(hasPhoto: true),
                ),
            ],
          ),
          Expanded(
            child: photo.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => RetryMessage(
                message: 'No se pudo cargar tu foto:\n$error',
                onRetry: () => ref.read(bodyPhotoProvider.notifier).load(),
              ),
              data: (url) {
                if (url == null) {
                  return BodyPhotoIntro(uploading: _uploading, onUpload: () => _showPhotoOptions(hasPhoto: false));
                }
                _room.measureBody(url);
                return _dressingRoom(url);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dressingRoom(String photoUrl) {
    final canGenerate = ref.watch(dressingRoomProvider.select((room) => room.aiLayers.isNotEmpty));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, floatingNavClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TryOnStage(
              photoUrl: photoUrl,
              busy: _uploading,
              onPhotoError: () => ref.read(bodyPhotoProvider.notifier).load(),
            ),
          ),
          const SizedBox(height: 52, child: LayerToolbar()),
          SizedBox(height: 76, child: GarmentPicker(onPick: (garment) => _run(() => _room.addGarment(garment)))),
          if (canGenerate) ...[const SizedBox(height: 10), LookGeneratorPanel(onGenerate: _generateLook)],
        ],
      ),
    );
  }
}
