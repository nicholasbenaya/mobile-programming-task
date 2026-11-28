import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

/// Admin form card for editing site name, type, address, geofence radius, SOS SLA, and join approval.
class SiteSettingsFormCard extends StatelessWidget {
  const SiteSettingsFormCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.addressController,
    required this.geofenceController,
    required this.sosSlaController,
    required this.siteType,
    required this.requireJoinApproval,
    required this.isSaving,
    required this.onSiteTypeChanged,
    required this.onRequireApprovalChanged,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController geofenceController;
  final TextEditingController sosSlaController;
  final SiteType siteType;
  final bool requireJoinApproval;
  final bool isSaving;
  final ValueChanged<SiteType> onSiteTypeChanged;
  final ValueChanged<bool> onRequireApprovalChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceLg),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pengaturan Wilayah', style: textTheme.titleLarge),
              const SizedBox(height: CivicTokens.spaceMd),
              TextFormField(
                controller: nameController,
                enabled: !isSaving,
                decoration: const InputDecoration(labelText: 'Nama Wilayah'),
                validator: (value) => (value ?? '').trim().length < 3
                    ? 'Nama wilayah minimal 3 karakter.'
                    : null,
              ),
              const SizedBox(height: CivicTokens.spaceMd),
              DropdownButtonFormField<SiteType>(
                initialValue: siteType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Jenis Wilayah'),
                items: SiteType.values
                    .map(
                      (type) => DropdownMenuItem<SiteType>(
                        value: type,
                        child: Text(type.labelId),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          onSiteTypeChanged(value);
                        }
                      },
              ),
              const SizedBox(height: CivicTokens.spaceMd),
              TextFormField(
                controller: addressController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Ringkasan Alamat',
                ),
              ),
              const SizedBox(height: CivicTokens.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: geofenceController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Radius (m)',
                        helperText: '10 sampai 200',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 10 || parsed > 200) {
                          return '10 sampai 200 m';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: CivicTokens.spaceMd),
                  Expanded(
                    child: TextFormField(
                      controller: sosSlaController,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Eskalasi SOS (mnt)',
                        helperText: '1 sampai 30',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 1 || parsed > 30) {
                          return '1 sampai 30 mnt';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CivicTokens.spaceSm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wajib Persetujuan Admin'),
                subtitle: const Text(
                  'Anggota baru menunggu persetujuan sebelum mengakses wilayah.',
                ),
                value: requireJoinApproval,
                onChanged: isSaving ? null : onRequireApprovalChanged,
              ),
              const SizedBox(height: CivicTokens.spaceMd),
              FilledButton(
                onPressed: isSaving ? null : onSave,
                child: const Text('Simpan Pengaturan Wilayah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
