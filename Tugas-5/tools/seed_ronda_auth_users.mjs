import { createClient } from '@supabase/supabase-js';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

// Reads a gitignored project-root .env.local without printing its contents.
try {
  const envPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../.env.local');
  const contents = await readFile(envPath, 'utf8');
  for (const line of contents.split(/\r?\n/)) {
    const match = line.match(/^\s*(SUPABASE_URL|SUPABASE_SERVICE_ROLE_KEY|SUPABASE_SECRET_KEY)\s*=\s*(.*?)\s*$/);
    if (match && !process.env[match[1]]) {
      process.env[match[1]] = match[2].replace(/^(["'])(.*)\1$/, '$2');
    }
  }
} catch (error) {
  if (error?.code !== 'ENOENT') throw error;
}

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  throw new Error('Set SUPABASE_URL and SUPABASE_SECRET_KEY (or SUPABASE_SERVICE_ROLE_KEY) in .env.local.');
}

const supabase = createClient(url, key, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const rtId = 'RT-04-RW-02-SUKOLILO';
const password = 'password123';
const accounts = [
  ['user-rt-01', 'Nicholas Benaya (Ketua RT)', '081234567801', 'Jl. Teknik Komputer No. 01, RT 04', 'admin_rt', 'fcm_token_admin_rt_01'],
  ['user-petugas-01', 'Jordi (Petugas Ronda)', '081234567802', 'Jl. Gebang Putih Blok A No. 10', 'petugas_ronda', 'fcm_token_petugas_jordi'],
  ['user-petugas-02', 'Devi Putri Sekar Arum', '081234567803', 'Jl. Gebang Putih Blok B No. 04', 'petugas_ronda', 'fcm_token_petugas_devi'],
  ['user-petugas-03', 'Budi Santoso (Petugas Ronda)', '081234567806', 'Jl. Gebang Timur Blok C No. 08', 'petugas_ronda', 'fcm_token_petugas_budi'],
  ['user-warga-01', 'Fito Dwi Ardiansah (Warga)', '081234567804', 'Jl. Gebang Timur No. 15', 'warga', 'fcm_token_warga_fito'],
];

const { data, error: listError } = await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
if (listError) throw listError;

for (const [rondaId, name, phone, address, role, fcmToken] of accounts) {
  const email = `ronda.${phone}@example.com`;
  const appMetadata = {
    ronda_user_id: rondaId,
    rt_id: rtId,
    role,
    whatsapp: phone,
    full_name: name,
    address,
    fcm_token: fcmToken,
  };
  const existing = data.users.find((user) => user.email === email);
  const result = existing
    ? await supabase.auth.admin.updateUserById(existing.id, {
        password,
        email_confirm: true,
        app_metadata: appMetadata,
      })
    : await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        app_metadata: appMetadata,
        user_metadata: { full_name: name },
      });
  if (result.error) throw result.error;
  console.log(`Created/updated ${role} account for ${phone}`);
}
