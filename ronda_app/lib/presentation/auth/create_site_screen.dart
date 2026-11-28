import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/router/app_router.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/presentation/shared/forensic_strip.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Create new multi-tenant site screen with interactive OpenStreetMap center picker.
class CreateSiteScreen extends ConsumerStatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  ConsumerState<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends ConsumerState<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapController = MapController();

  SiteType _siteType = SiteType.perumahan;
  LatLng _center = const LatLng(-7.25747, 112.75209);
  double _geofenceMeters = 30;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(mySitesProvider.notifier)
          .createSite(
            name: _nameController.text.trim(),
            siteType: _siteType,
            addressSummary: _addressController.text.trim(),
            centerLat: _center.latitude,
            centerLng: _center.longitude,
            defaultGeofenceMeters: _geofenceMeters.round(),
          );
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.adminHome);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = AppFailure.fromException(error).message;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final enableTiles = ref.watch(mapNetworkTilesEnabledProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Wilayah Baru')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              CivicTokens.spaceLg,
              CivicTokens.spaceLg,
              CivicTokens.spaceLg,
              CivicTokens.spaceSection + bottomInset,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.statusEmergencyTint,
                          borderRadius: BorderRadius.circular(
                            CivicTokens.radiusControl,
                          ),
                          border: Border.all(
                            color: tokens.statusEmergencyText.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(CivicTokens.spaceMd),
                          child: Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.statusEmergencyText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: CivicTokens.spaceLg),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(CivicTokens.spaceLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informasi Wilayah',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            TextFormField(
                              controller: _nameController,
                              enabled: !_isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nama Wilayah',
                                hintText: 'Contoh: Perumahan Melati Asri',
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().length < 3) {
                                  return 'Nama wilayah minimal 3 karakter.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            DropdownButtonFormField<SiteType>(
                              initialValue: _siteType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Wilayah',
                              ),
                              items: SiteType.values
                                  .map(
                                    (type) => DropdownMenuItem<SiteType>(
                                      value: type,
                                      child: Text(type.labelId),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: _isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _siteType = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            TextFormField(
                              controller: _addressController,
                              enabled: !_isSubmitting,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Ringkasan Alamat (Opsional)',
                                hintText: 'Kecamatan, kota, atau patokan utama',
                              ),
                            ),
                            const SizedBox(height: CivicTokens.spaceLg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Radius Geofence Bawaan',
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: CivicTokens.spaceSm),
                                Text(
                                  '${_geofenceMeters.round()} m',
                                  style: tokens.forensicMono,
                                ),
                              ],
                            ),
                            Slider(
                              value: _geofenceMeters,
                              min: 10,
                              max: 200,
                              divisions: 38,
                              label: '${_geofenceMeters.round()} m',
                              onChanged: _isSubmitting
                                  ? null
                                  : (value) =>
                                        setState(() => _geofenceMeters = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: CivicTokens.spaceLg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(CivicTokens.spaceLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Titik Pusat Peta Wilayah',
                              style: textTheme.titleLarge,
                            ),
                            const SizedBox(height: CivicTokens.spaceXs),
                            Text(
                              'Ketuk peta untuk menentukan titik pusat wilayah dan batas radius patroli.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                CivicTokens.radiusControl,
                              ),
                              child: SizedBox(
                                height: 220,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: tokens.surfaceSubtle,
                                    border: Border.all(
                                      color: tokens.borderHairline,
                                    ),
                                  ),
                                  child: FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _center,
                                      initialZoom: 16,
                                      onTap: (_, point) {
                                        setState(() => _center = point);
                                      },
                                    ),
                                    children: [
                                      if (enableTiles)
                                        TileLayer(
                                          urlTemplate:
                                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName:
                                              'id.rondadigital.ronda_app',
                                        ),
                                      CircleLayer(
                                        circles: [
                                          CircleMarker(
                                            point: _center,
                                            radius: _geofenceMeters,
                                            useRadiusInMeter: true,
                                            color: tokens.accentFill.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderColor:
                                                tokens.accentOperational,
                                            borderStrokeWidth: 2,
                                          ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _center,
                                            width: 40,
                                            height: 40,
                                            child: Icon(
                                              Icons.location_on_rounded,
                                              size: 36,
                                              color: tokens.brandPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: CivicTokens.spaceMd),
                            ForensicStrip(
                              entries: [
                                ForensicEntry(
                                  label: 'Koordinat Pusat',
                                  value: ForensicStrip.formatCoordinates(
                                    _center.latitude,
                                    _center.longitude,
                                  ),
                                  icon: Icons.my_location_outlined,
                                ),
                                ForensicEntry(
                                  label: 'Radius Geofence',
                                  value: '${_geofenceMeters.round()} m',
                                  icon: Icons.radar_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: CivicTokens.spaceXl),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: tokens.onBrandPrimary,
                              ),
                            )
                          : const Text('Simpan & Buat Wilayah'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
