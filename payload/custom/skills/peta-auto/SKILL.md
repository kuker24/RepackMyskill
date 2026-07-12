---
name: peta-auto
description: Memetakan proyek baru, proyek yang sedang dikerjakan, atau proyek yang sudah matang menggunakan hierarki DOX AGENTS.md. Gunakan untuk memahami struktur, teknologi, entry point, modul, command, status pekerjaan, aturan lokal, dan area risiko sebelum tugas engineering nontrivial.
---

# Peta Auto

Peta Auto adalah sistem pemetaan proyek berbasis prinsip DOX.

Peta Auto menggunakan hierarki `AGENTS.md` untuk menyimpan konteks proyek
secara ringkas, terstruktur, dan dapat diperbarui.

## Tujuan

Peta Auto harus:

- mengenali keadaan proyek
- menemukan struktur dan batas domain
- menemukan entry point dan konfigurasi penting
- menemukan command build, test, lint, dan run yang benar-benar tersedia
- mencatat aturan proyek yang sudah terverifikasi
- membuat atau memperbarui hierarki AGENTS.md
- menghindari pemetaan ulang yang tidak diperlukan
- menjaga peta tetap sesuai keadaan source terbaru

## Integrasi Fable

Gunakan agent yang sudah tersedia:

- `fable-luna` untuk pemindaian read-only
- `fable-terra` untuk membuat atau memperbarui AGENTS.md
- `fable-sol` untuk memeriksa konsistensi peta pada proyek kompleks

Parent agent mengatur orkestrasi.

Subagent tidak boleh memanggil subagent lain.

## Mode

### auto

Mode default.

Deteksi apakah proyek:

- belum memiliki peta
- memiliki peta yang belum lengkap
- memiliki peta yang masih valid
- memiliki peta yang perlu diperbarui

Lakukan tindakan minimum yang diperlukan.

### check

Hanya memeriksa proyek dan kondisi peta.

Jangan membuat atau mengubah file.

### init

Buat pemetaan awal untuk proyek yang belum memiliki DOX yang layak.

### refresh

Perbarui hanya bagian peta yang terdampak oleh keadaan source saat ini.

Jangan membangun ulang seluruh hierarki jika tidak diperlukan.

## Deteksi keadaan proyek

Gunakan salah satu status berikut berdasarkan evidence:

### NEW

Gunakan jika proyek masih kosong atau baru memiliki struktur awal.

Contoh evidence:

- source sangat sedikit
- belum ada entry point yang jelas
- belum ada command build atau test
- baru memiliki manifest atau scaffold awal

Jangan mengarang arsitektur, command, atau workflow yang belum tersedia.

### IN_PROGRESS

Gunakan jika implementasi sudah ada dan pekerjaan masih aktif.

Contoh evidence:

- terdapat source dan konfigurasi
- working tree memiliki perubahan
- terdapat TODO, roadmap, migration, atau fitur parsial
- test atau build hanya sebagian tersedia

Working tree kotor bukan satu-satunya dasar penentuan status.

### ESTABLISHED

Gunakan jika proyek sudah memiliki struktur stabil.

Contoh evidence:

- entry point jelas
- modul utama dapat diidentifikasi
- build atau test tersedia
- konfigurasi dan dokumentasi cukup matang
- batas domain relatif stabil

### UNKNOWN

Gunakan jika evidence tidak cukup atau saling bertentangan.

Jelaskan informasi yang belum dapat diverifikasi.

## Pemindaian proyek

Sebelum membuat peta, periksa secara bertahap:

1. Root repository.
2. Manifest dan file konfigurasi.
3. Struktur source.
4. Entry point.
5. Test dan quality gate.
6. Dokumentasi yang sudah ada.
7. Git status jika repository menggunakan Git.
8. AGENTS.md yang sudah tersedia.
9. Folder yang menjadi batas domain permanen.

Jangan membaca seluruh isi semua file.

Baca nama file dan struktur terlebih dahulu, kemudian buka hanya file yang
dibutuhkan untuk membuktikan fungsi suatu area.

## Pengecualian pemindaian

Jangan memindai isi secara rekursif pada:

- `.git`
- `node_modules`
- `.gradle`
- `.idea`
- `.vscode`
- `build`
- `dist`
- `.next`
- `.cache`
- `coverage`
- `vendor`
- generated output
- file biner
- arsip
- dependency lock yang sangat besar kecuali diperlukan

Jangan membaca atau mencetak:

- `.env`
- API key
- token
- credential
- private key
- secret
- file konfigurasi rahasia

Nama file rahasia boleh disebut tanpa membaca isinya jika dibutuhkan untuk
menjelaskan struktur.

## Aturan DOX

Root `AGENTS.md` adalah kontrak proyek dan indeks tingkat atas.

Sebelum mengubah file:

1. Baca root AGENTS.md.
2. Tentukan path yang akan disentuh.
3. Baca setiap AGENTS.md dari root menuju path tersebut.
4. Gunakan dokumen terdekat sebagai aturan lokal.
5. Tetap patuhi aturan induk.

Setelah perubahan bermakna:

1. Periksa apakah kontrak atau struktur berubah.
2. Perbarui AGENTS.md terdekat bila diperlukan.
3. Perbarui indeks induk jika child berubah.
4. Hapus informasi basi atau bertentangan.
5. Jangan menambahkan catatan harian atau log pekerjaan.

## Isi root AGENTS.md

Sesuaikan dengan proyek. Gunakan bagian berikut bila relevan:

- Project Purpose
- Project State
- Technology
- Entry Points
- Repository Structure
- Global Contracts
- Common Commands
- Verification
- Known Constraints
- Child DOX Index

Jangan mengisi bagian dengan dugaan.

Gunakan `Unknown` atau kosong jika belum ada evidence.

## Isi child AGENTS.md

Gunakan urutan berikut:

- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

Buat child AGENTS.md hanya jika folder merupakan batas permanen dengan:

- tanggung jawab sendiri
- aturan lokal sendiri
- workflow sendiri
- kontrak input atau output sendiri
- verification sendiri
- kumpulan source yang cukup besar atau kompleks

Jangan membuat AGENTS.md pada setiap folder.

## Menjaga file lama

Jika AGENTS.md sudah ada:

- baca seluruh aturan yang relevan
- pertahankan instruksi pengguna
- pertahankan aturan proyek yang masih benar
- jangan menimpa seluruh file tanpa alasan
- gabungkan DOX secara terstruktur
- hapus informasi basi hanya jika evidence jelas
- jangan melemahkan aturan keamanan yang sudah ada

## Strategi agent

Untuk pemetaan sederhana:

1. Parent dapat melakukan pemeriksaan langsung.
2. Jangan memanggil subagent jika tidak diperlukan.

Untuk proyek menengah:

1. Luna memetakan struktur secara read-only.
2. Terra membuat atau memperbarui peta.

Untuk proyek besar:

1. Maksimal dua Luna boleh memindai area independen secara paralel.
2. Terra menggabungkan hasil dan memperbarui DOX.
3. Sol melakukan review akhir jika terdapat banyak child AGENTS.md atau
   perubahan kontrak besar.

## Batas perubahan

Peta Auto hanya boleh membuat atau mengubah:

- `AGENTS.md`
- child `AGENTS.md`

Peta Auto tidak boleh mengubah source code, dependency, konfigurasi aplikasi,
Git history, atau file pengguna lain kecuali pengguna memintanya secara jelas.

## Hasil akhir

Laporkan:

- status proyek
- evidence penentuan status
- teknologi yang ditemukan
- entry point
- struktur utama
- AGENTS.md yang dibuat atau diubah
- area yang belum dapat diverifikasi
- apakah peta dinilai CURRENT, PARTIAL, STALE, atau MISSING
