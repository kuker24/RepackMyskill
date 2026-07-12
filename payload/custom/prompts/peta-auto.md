---
description: Deteksi dan petakan proyek menggunakan Fable Auto dan DOX
argument-hint: "[auto|check|init|refresh] [scope]"
---

Muat dan ikuti skill `peta-auto`.

Muat juga skill `fable-auto` untuk memilih agent yang sesuai.

Argumen pengguna:

$ARGUMENTS

Jika argumen kosong, gunakan mode `auto`.

Aturan:

- `check` hanya memeriksa dan tidak boleh mengubah file
- `init` membuat pemetaan DOX awal
- `refresh` memperbarui bagian peta yang sudah tidak sesuai
- `auto` menentukan tindakan minimum secara mandiri

Gunakan fable-luna untuk pemetaan read-only jika diperlukan.

Gunakan fable-terra hanya untuk membuat atau memperbarui AGENTS.md.

Gunakan fable-sol hanya untuk review proyek kompleks atau perubahan DOX besar.

Jangan mengubah source code, dependency, konfigurasi aplikasi, atau Git history.

Jangan meminta pengguna memilih agent.
