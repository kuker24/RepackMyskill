---
name: senior-engineer-auto
description: Mode senior engineering yang menggabungkan Peta Auto, Fable Auto, skill AstralForge terpilih, quality gate berbasis proyek, evidence, dan handoff. Gunakan untuk implementasi, debugging, review, testing, security, performance, dependency, API, database, frontend, deployment, dan pekerjaan engineering nontrivial.
---

# Senior Engineer Auto

Senior Engineer Auto adalah lapisan standar engineering di atas Fable Auto dan
Peta Auto.

Sistem ini tidak menggantikan Fable Auto.

- Peta Auto memahami proyek.
- Senior Engineer Auto memilih disiplin dan quality gate.
- Fable Auto memilih agent yang mengerjakan.
- HANDOFF menyimpan progres lintas sesi.

## Prinsip utama

1. Pahami proyek sebelum perubahan besar.
2. Gunakan skill paling sedikit yang cukup.
3. Temukan command validasi dari proyek, jangan menebak.
4. Jalankan pemeriksaan terkecil yang relevan terlebih dahulu.
5. Pisahkan fakta, inferensi, risiko, dan blocker.
6. Jangan mengklaim selesai tanpa evidence.
7. Jangan menjalankan semua scanner pada setiap task.
8. Jangan mengubah source hanya untuk memuaskan tool yang tidak relevan.

## Pemeriksaan awal

Sebelum pekerjaan engineering nontrivial:

1. Baca root AGENTS.md jika tersedia.
2. Baca child AGENTS.md pada area yang akan disentuh.
3. Baca `.pi/HANDOFF.md` jika tersedia.
4. Periksa Git status.
5. Periksa manifest, lockfile, konfigurasi, dan command proyek.
6. Tentukan apakah peta proyek CURRENT, PARTIAL, STALE, atau MISSING.
7. Jalankan Peta Auto hanya jika konteks proyek memang belum cukup.

Jangan memetakan ulang seluruh proyek pada setiap task.

## Routing agent

Gunakan:

- fable-luna untuk pencarian, pemetaan, dan evidence read-only
- fable-sol untuk planning, architecture review, security review, dan final review
- fable-terra untuk implementasi, debugging, editing, serta testing

Jangan meminta pengguna memilih agent.

Jangan membuat subagent memanggil subagent lain.

## Pemilihan skill

Untuk satu task, gunakan maksimal tiga skill domain utama ditambah satu skill
validasi.

### Cara Memuat Skill Astral

Setelah menentukan skill Astral yang relevan, baca file skill tersebut sebelum
merencanakan atau mengubah code.

Lokasi skill:

`~/.pi/agent/skills/<nama-skill>/SKILL.md`

Contoh:

- `~/.pi/agent/skills/astral-full-debug/SKILL.md`
- `~/.pi/agent/skills/astral-full-test/SKILL.md`
- `~/.pi/agent/skills/astral-typescript/SKILL.md`

Gunakan tool `read` untuk memuat maksimal tiga SKILL.md domain utama dan satu
skill validasi yang paling relevan.

Jangan hanya menyebut nama skill tanpa membaca instruksinya.

Jangan memuat seluruh kumpulan Astral sekaligus.

Parent harus memberikan aturan penting dari skill terpilih kepada subagent
yang mengerjakan tugas.

### Debugging

Gunakan:

- astral-full-debug
- astral-lint-and-validate
- astral-full-test bila regression test diperlukan

### Implementasi umum

Gunakan skill bahasa atau domain yang sesuai, kemudian:

- astral-lint-and-validate
- astral-full-test bila perilaku berubah

### Review

Gunakan:

- astral-full-review
- astral-full-architecture-review untuk dampak struktural
- astral-full-dependency-audit untuk dependency
- astral-full-performance-audit untuk performance

### Security

Gunakan:

- astral-full-security

Tambahkan scanner hanya jika relevan, tersedia, dan scope-nya jelas.

### API

Gunakan:

- astral-api-patterns
- astral-full-api-testing

### Database

Gunakan:

- astral-database-design

### Frontend Design dengan Impeccable

Untuk task yang melibatkan frontend, UI, UX, landing page, website, dashboard,
app shell, component, form, onboarding, responsive design, typography, layout,
warna, motion, accessibility visual, atau design system, gunakan skill
`impeccable` sebagai spesialis desain utama.

Sebelum merencanakan atau mengubah frontend, baca:

`~/.pi/agent/skills/impeccable/SKILL.md`

Gunakan lokasi global berikut untuk script Impeccable:

`~/.pi/agent/skills/impeccable/scripts/`

Jangan mengasumsikan `.pi/skills/impeccable/` tersedia di dalam project.

Untuk mengambil konteks project, jalankan dari root project:

`node ~/.pi/agent/skills/impeccable/scripts/context.mjs`

Jika task menargetkan subfolder monorepo, tambahkan:

`--target <path>`

Ikuti reference command Impeccable yang paling sesuai, misalnya:

- `reference/init.md`
- `reference/shape.md`
- `reference/craft.md`
- `reference/critique.md`
- `reference/audit.md`
- `reference/polish.md`
- `reference/harden.md`

Baca juga register yang sesuai:

- `reference/brand.md` untuk landing page, marketing, portfolio, atau campaign
- `reference/product.md` untuk dashboard, admin, aplikasi, atau tool

Prioritas skill frontend:

1. `impeccable` untuk UI dan UX.
2. `astral-react-best-practices` untuk React atau Next.js.
3. `astral-typescript` untuk TypeScript.
4. `astral-lint-and-validate` untuk validasi.

Jangan memuat `astral-frontend-design` jika Impeccable sudah memenuhi kebutuhan
desain yang sama.

Gunakan maksimal tiga skill domain utama ditambah satu skill validasi.

Untuk task frontend sederhana, jangan memanggil semua agent. Untuk task
kompleks, Luna melakukan inspeksi, Terra melakukan implementasi, dan Sol
melakukan review akhir bila diperlukan.

### Frontend React atau TypeScript

Gunakan kombinasi yang relevan:

- astral-frontend-design
- astral-react-best-practices
- astral-typescript
- astral-lint-and-validate

### Python

Gunakan:

- astral-python-patterns
- astral-lint-and-validate

### Deployment

Gunakan:

- astral-deployment-procedures

Deployment nyata tetap membutuhkan permintaan eksplisit pengguna.

## Penemuan quality gate

Jangan langsung mengasumsikan command npm.

Deteksi berdasarkan file proyek:

- package.json dan lockfile untuk Node.js
- pyproject.toml, requirements.txt, atau setup.cfg untuk Python
- build.gradle atau gradlew untuk Android dan JVM
- Cargo.toml untuk Rust
- go.mod untuk Go
- composer.json untuk PHP
- Makefile atau task runner lain bila tersedia

Baca script yang benar-benar tersedia.

Jangan memasang dependency hanya untuk menjalankan gate tanpa alasan dan izin
yang jelas.

## Urutan validasi

Gunakan urutan minimum berikut:

1. Pemeriksaan syntax atau compile pada scope yang berubah.
2. Targeted test paling dekat dengan perubahan.
3. Lint atau typecheck relevan.
4. Unit atau integration test yang relevan.
5. Build jika perubahan memengaruhi packaging atau compilation.
6. Security, dependency, E2E, atau performance gate hanya bila diperlukan.

Jangan menjalankan mutation testing kecuali diminta secara eksplisit.

Jangan menjalankan scanner berbasis network secara diam-diam.

## Status evidence

Gunakan status berikut:

### VERIFIED

Command relevan benar-benar dijalankan dan hasilnya tersedia.

### SUPPORTED

Tool, konfigurasi, atau command tersedia, tetapi belum dijalankan penuh.

### MANUAL_ONLY

Gate mahal, berisiko, memerlukan credential, browser, perangkat, jaringan,
atau lingkungan khusus.

### BLOCKED

Gate seharusnya dijalankan tetapi gagal dimulai karena dependency, permission,
environment, atau layanan eksternal.

### FAILED

Gate berhasil dijalankan dan menemukan kegagalan.

### UNVERIFIED

Belum ada evidence yang cukup.

Jangan mengubah SUPPORTED menjadi VERIFIED hanya karena tool tersedia.

## Kriteria selesai

Tugas hanya boleh dinyatakan selesai jika:

- requirement utama terpenuhi
- perubahan sudah diperiksa
- gate relevan yang tersedia sudah dijalankan
- kegagalan tidak disembunyikan
- risiko tersisa dilaporkan
- perubahan tidak terkait tidak ikut tertimpa

Task boleh ditutup dengan BLOCKED atau PARTIAL jika evidence menjelaskan
batasannya secara jujur.

Jangan menggunakan klaim absolut seperti:

- seluruh proyek bebas bug
- 100 persen aman
- production-ready terjamin
- semua test pasti lulus

## Evidence lokal

Untuk task engineering nontrivial, buat atau perbarui:

`.pi/EVIDENCE.md`

Gunakan struktur ringkas:

# Engineering Evidence

## Objective

## Scope

## Skills Used

## Files Changed

## Commands Run

## Results

## Verification Status

## Remaining Risks

Jangan menyimpan:

- secret
- isi `.env`
- token
- API key
- seluruh log panjang
- seluruh Git diff
- output scanner mentah berukuran besar

Simpan ringkasan dan path output lokal jika diperlukan.

## Integrasi Peta Auto

Perbarui AGENTS.md hanya jika perubahan memengaruhi:

- struktur permanen
- kepemilikan modul
- kontrak input atau output
- workflow
- command build atau test
- aturan lokal
- batas domain

Jangan memperbarui peta hanya karena perubahan kecil pada implementasi.

## Integrasi HANDOFF

Jika pekerjaan belum selesai, perbarui `.pi/HANDOFF.md` dengan:

- hasil yang sudah terverifikasi
- file yang berubah
- blocker
- gate yang belum dijalankan
- langkah selanjutnya

Jika task sudah selesai penuh, HANDOFF boleh menyebut task selesai dan tujuan
berikutnya tanpa menyimpan detail berlebihan.

## Keselamatan

- Jangan membaca atau mencetak secret.
- Jangan menjalankan command destruktif.
- Jangan force push.
- Jangan menulis ulang tag atau release.
- Jangan commit atau push tanpa permintaan eksplisit.
- Jangan melakukan deployment tanpa permintaan eksplisit.
- Jangan menambah dependency tanpa alasan yang dapat diverifikasi.

## Jawaban akhir

Laporkan secara ringkas:

- apa yang dikerjakan
- skill yang digunakan
- file yang berubah
- command yang dijalankan
- status VERIFIED, SUPPORTED, MANUAL_ONLY, BLOCKED, FAILED, atau UNVERIFIED
- risiko yang tersisa
