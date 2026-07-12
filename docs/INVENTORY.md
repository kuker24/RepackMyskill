# Phase 1 — Inventory dan Source Lock

Audit dilakukan terhadap `PI_HOME=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}` yang saat audit ter-resolve menjadi `/home/fahmiagent/.pi/agent`. Audit tidak membaca atau menyalin konfigurasi akun, credential, session, log, cache, backup, `node_modules`, runtime database, atau data privat.

## Ringkasan

- Semua komponen wajib yang disebutkan ditemukan.
- Tiga package npm terkunci pada versi terpasang yang diminta.
- Tiga checkout Git berada pada commit yang dapat diverifikasi dengan `git rev-parse HEAD`.
- Plan guard memblokir nama tool `Agent` dan semua nama tool yang memuat `subagent` saat fase `planning`.
- Todo Tools lulus `npm audit --omit=dev`, typecheck, dan 12 test dengan lockfile lokal aman.
- Enam belas skill Astral aktif merupakan salinan selektif dari checkout AstralForge dengan patch lokal pada field frontmatter `name:` saja; seluruh file pendamping cocok byte-for-byte dengan upstream.
- Tidak ada file wajib berstatus `MISSING`.

## Inventory komponen

| Komponen | Lokasi sumber relatif terhadap `PI_HOME` | Metode pemasangan | Versi atau commit | Status | Salin atau upstream | Risiko dan catatan |
|---|---|---|---|---|---|---|
| Pi package: 9Router extension | `npm/package.json`, `npm/package-lock.json` | `pi install npm:pi-9router-ext@0.2.2` | `0.2.2` | FOUND | Upstream npm | `9router-config.json`, `auth.json`, dan `settings.json` tidak boleh disalin; konfigurasi akun/credential harus dibuat pengguna secara terpisah. |
| Pi package: subagents | `npm/package.json`, `npm/package-lock.json` | `pi install npm:@tintinweb/pi-subagents@0.13.0` | `0.13.0` | FOUND | Upstream npm | Memasang Agent/subagent tool yang kemudian dibatasi Plan guard. |
| Pi package: Plan Mode | `npm/package.json`, `npm/package-lock.json` | `pi install npm:pi-plan-extension@0.1.0` | `0.1.0` | FOUND | Upstream npm | Harus dipasang sebelum guard lokal dimuat. |
| Todo Tools | `git/github.com/code-yeongyu/pi-todotools` | Checkout Git commit terkunci, lalu gunakan lockfile aman lokal dan `npm ci` | commit `93ba67efa5a7358356a829569365bb017a8ad498`; package `0.1.1` | FOUND | Upstream Git + lockfile lokal terverifikasi | Working tree hanya mengubah `package-lock.json`. Jangan memakai lockfile upstream mentah. Detail verifikasi di bawah. |
| Fable agents | `agents/fable-luna.md`, `agents/fable-sol.md`, `agents/fable-terra.md` | Salin file custom | n/a | FOUND | Salin | Nama agent harus tetap cocok dengan routing. |
| Fable core dan auto | `skills/fable-core/`, `skills/fable-auto/` | Salin direktori custom | n/a | FOUND | Salin | `fable-auto` terintegrasi dengan Peta, Senior Engineer Auto, workflow controller, dan Plan Mode. |
| Fable prompts | `prompts/f5.md`, `prompts/fl.md`, `prompts/fs.md`, `prompts/ft.md` | Salin file custom | n/a | FOUND | Salin | `f5.md` memuat Senior Engineer Auto dan marker workflow. |
| Fable routing global | `AGENTS.md` | Salin file custom setelah review konflik | n/a | FOUND | Salin | File global; installer masa depan harus backup/merge secara aman, bukan menimpa tanpa persetujuan. |
| Peta Auto | `skills/peta-auto/`, `prompts/peta-auto.md` | Salin skill dan prompt custom | n/a | FOUND | Salin | Dipanggil untuk pemetaan proyek nontrivial. |
| Progress workflow | `prompts/simpan-progres.md`, `prompts/lanjut-proyek.md` | Salin prompt custom | n/a | FOUND | Salin | Format HANDOFF terdokumentasi; bukan runtime state yang harus dibundel. |
| HANDOFF contract | `prompts/simpan-progres.md`, `skills/senior-engineer-auto/SKILL.md` | Reproduksi aturan, jangan salin `.pi/HANDOFF.md` proyek pengguna | n/a | FOUND | Salin aturan saja | Struktur: `Project Handoff`, `Current Objective`, `Project State`, `Completed`, `Changed Files`, `Verification`, `Current Blockers`, `Next Steps`, `Resume Instructions`, `User Notes`. |
| Senior Engineer Auto | `skills/senior-engineer-auto/`, `prompts/senior-auto.md` | Salin skill dan prompt custom | n/a | FOUND | Salin | Terintegrasi pada `skills/fable-auto/SKILL.md`, `prompts/f5.md`, dan `AGENTS.md`. |
| EVIDENCE contract | `skills/senior-engineer-auto/SKILL.md` | Reproduksi aturan, jangan salin `.pi/EVIDENCE.md` proyek pengguna | n/a | FOUND | Salin aturan saja | Struktur: `Engineering Evidence`, `Objective`, `Scope`, `Skills Used`, `Files Changed`, `Commands Run`, `Results`, `Verification Status`, `Remaining Risks`. |
| AstralForge vendor | `vendor/astralforge` | Clone/fetch upstream pada commit terkunci; ambil hanya 16 skill terpilih | `3f59d793a2691a95e63355f91adaeb72a7120fac` | FOUND | Upstream Git selektif | Remote: `https://github.com/kuker24/AstralForge-Senior-Engineer-Skills.git`. Checkout vendor memiliki perubahan lokal pada tiga file report; report tidak diperlukan dan tidak boleh dibundel. |
| 16 Astral selective skills | `skills/astral-*` untuk daftar di bawah | Salin skill terpilih dari `vendor/astralforge/skills/<nama>/`, ubah frontmatter `name` menjadi `astral-<nama>` | vendor commit di atas | FOUND (16/16) | Upstream selektif + patch nama deterministik | Jangan memasukkan seluruh vendor. Semua file selain `SKILL.md` cocok upstream; setiap `SKILL.md` hanya berbeda pada satu baris `name:`. |
| Impeccable skill | `skills/impeccable/` | `npx impeccable@3.2.1 skills install -y --providers=pi --scope=global --no-hooks` | CLI `3.2.1`; skill metadata `3.9.1` | FOUND | Upstream CLI | Perbedaan versi CLI dan skill valid; jangan dipaksa sama. Skill aktif berisi 102 file. |
| Impeccable prompt | `prompts/impeccable.md` | Salin file custom | n/a | FOUND | Salin | Senior Engineer Auto mengutamakan Impeccable untuk task UI/UX. |
| Plan config | `pi-plan-extension.json` | Salin file custom setelah package Plan Mode terpasang | schema/config lokal | FOUND | Salin | JSON valid; `bash_allowlist` aktif. |
| Fable Plan guard | `extensions/fable-plan-guard/index.ts` | Salin extension custom | n/a | FOUND | Salin | Pada `planning`, hook `tool_call` memblokir `toolName === "agent"` atau nama yang memuat `subagent`; hook `before_agent_start` juga menyuntikkan larangan mutasi. |
| Grill Me entry point | `skills/grill-me/` | Ambil selektif dari vendor Matt Pocock | vendor commit di bawah | FOUND | Upstream Git selektif | `SKILL.md` hanya mengarahkan ke sesi `/grilling`; tetap dibutuhkan sebagai entry point. |
| Grilling workflow | `skills/grilling/` | Ambil selektif dari vendor Matt Pocock | vendor commit di bawah | FOUND | Upstream Git selektif | Berisi workflow interview utama; kedua skill wajib. |
| Grill prompt | `prompts/grill-me.md` | Salin file custom | n/a | FOUND | Salin | Memanggil skill `grilling`. |
| Matt Pocock vendor | `vendor/mattpocock-skills` | Clone/fetch upstream pada commit terkunci; ambil dua skill saja | `391a2701dd948f94f56a39f7533f8eea9a859c87` | FOUND | Upstream Git selektif | Remote: `https://github.com/mattpocock/skills.git`; dua `SKILL.md` aktif cocok byte-for-byte dengan vendor. |
| Workflow markers | `AGENTS.md`, `skills/fable-auto/SKILL.md`, `prompts/f5.md` | Pertahankan blok marker saat copy/merge | marker pair | FOUND (3/3) | Salin | Ketiganya memiliki tepat marker `FABLE-WORKFLOW-INTEGRATION:START` dan `FABLE-WORKFLOW-INTEGRATION:END`. |

## Enam belas skill Astral terpilih

Semua berstatus **FOUND** pada `skills/<nama>/`:

1. `astral-full-debug`
2. `astral-full-review`
3. `astral-full-test`
4. `astral-full-security`
5. `astral-full-architecture-review`
6. `astral-full-dependency-audit`
7. `astral-full-performance-audit`
8. `astral-full-api-testing`
9. `astral-lint-and-validate`
10. `astral-deployment-procedures`
11. `astral-api-patterns`
12. `astral-database-design`
13. `astral-frontend-design`
14. `astral-react-best-practices`
15. `astral-typescript`
16. `astral-python-patterns`

Transformasi lokal wajib untuk setiap skill:

```text
vendor path: skills/<nama>/
active path: skills/astral-<nama>/
frontmatter: name: <nama> menjadi name: astral-<nama>
```

Tidak ditemukan patch isi lain pada snapshot aktif.

## Todo Tools: source lock dan keamanan

Evidence checkout aktif:

- `git rev-parse HEAD`: `93ba67efa5a7358356a829569365bb017a8ad498`
- `git status --short`: hanya `M package-lock.json`
- lockfile upstream SHA-256: `7996d22ffba202660791e3ffeb1ae5b1c1a69e34bcb924d8be0b204a112f9a5d`
- lockfile lokal aman SHA-256: `dcf0f4defb744d4b0d619d54b982463810d8926a89e40741d9a75cf2572750d4`
- patch arsip ditemukan pada `backups/todotools-security-patch/todotools-security.patch`
- patch SHA-256: `c6f29463dddf3388321f5f51463deb80e434511b889ab0cbffcf2e58bf735b6f`
- patch tidak disalin karena `backups/` dilarang masuk repository.

Verifikasi non-mutating dari checkout dengan lockfile lokal:

| Command | Hasil |
|---|---|
| `npm audit --omit=dev` | PASS — `found 0 vulnerabilities` |
| `npm run typecheck` | PASS — `tsgo --noEmit` exit 0 |
| `npm test` | PASS — 3 test files, 12 tests |

Pilihan paling reproducible: **checkout commit upstream lalu bawa/gunakan lockfile lokal aman yang hash-nya dikunci**, kemudian jalankan `npm ci`. Alasan: state aktif yang lolos audit berbeda dari upstream hanya pada lockfile; pendekatan ini lebih kecil dan deterministik daripada menerapkan patch backup yang lebih luas. Patch tetap dicatat sebagai provenance/fallback, bukan payload repository Phase 1. Installer masa depan harus memperoleh lockfile aman dari artefak repository yang ditambahkan pada fase berikutnya dan memverifikasi SHA-256 sebelum `npm ci`.

## Urutan instalasi yang diperlukan

1. Verifikasi runtime: Pi Coding Agent, Node.js `>=20`, npm, npx, Git, dan utilitas SHA-256; `jq` atau Python dipakai untuk validasi manifest.
2. Tentukan `PI_HOME=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}` dan buat backup aman di luar payload repository sebelum merge konfigurasi global.
3. Pasang package npm terkunci: `pi-9router-ext@0.2.2`, `@tintinweb/pi-subagents@0.13.0`, lalu `pi-plan-extension@0.1.0`.
4. Checkout Todo Tools pada commit terkunci, pasang lockfile aman dengan hash terkunci, jalankan `npm ci`, lalu jalankan audit, typecheck, dan 12 test.
5. Checkout AstralForge pada commit terkunci; ekstrak hanya 16 skill; rename direktori dengan prefix `astral-` dan patch hanya field `name:`.
6. Jalankan instalasi Impeccable persis dengan CLI `3.2.1` dan opsi `--no-hooks`; validasi metadata skill yang dihasilkan tetap `3.9.1` untuk source lock ini.
7. Checkout vendor Matt Pocock pada commit terkunci; ekstrak hanya `grill-me` dan `grilling`.
8. Salin file/direktori custom Fable, Peta, Senior Auto, prompts, `pi-plan-extension.json`, dan Plan guard. Merge `AGENTS.md` secara marker-aware; jangan menimpa aturan pengguna diam-diam.
9. Muat ulang Pi, lalu verifikasi package, agent, prompt, skill, Plan guard, marker workflow, dan command Todo Tools.
10. Konfigurasi 9Router dilakukan pengguna lewat environment/config privat terpisah. Jangan mengambil konfigurasi akun dari mesin sumber.

## Konflik dan ketergantungan

- **Plan dependency:** `fable-plan-guard` membutuhkan event custom `pi-plan-extension`; package Plan Mode harus tersedia lebih dulu.
- **Plan enforcement:** aturan prompt saja tidak cukup. Guard extension merupakan kontrol runtime yang memblokir Agent/subagent saat fase planning.
- **Agent dependency:** routing Fable membutuhkan package subagents dan tiga file agent bernama tepat.
- **Senior dependency:** `fable-auto`, `f5`, dan `AGENTS.md` mengarahkan task nontrivial ke `senior-engineer-auto`.
- **Impeccable dependency:** Senior Engineer Auto menunjuk lokasi global `skills/impeccable` dan script di dalamnya.
- **Astral namespace patch:** prefix `astral-` mencegah tabrakan nama dan harus diterapkan pada direktori serta frontmatter.
- **Global AGENTS conflict:** instalasi baru mungkin sudah memiliki aturan global. Merge blok routing dan marker; backup lalu minta konfirmasi sebelum replacement penuh.
- **Todo lock conflict:** menjalankan install biasa dapat menulis ulang lockfile aman. Gunakan `npm ci`, bukan `npm install`, setelah lockfile aman ditempatkan.
- **CLI/skill version:** Impeccable CLI `3.2.1` menghasilkan/mengelola skill metadata `3.9.1` pada instalasi aktif; bukan mismatch yang harus “diperbaiki”.

## Path yang dilarang masuk repository

- Secret/account config: `.env`, `.env.*`, `*.key`, `*.pem`, `secrets/`, `auth.json`, `9router-config.json`, `settings.json`, cookie, Authorization header, credential, password, token, API key.
- Runtime/private state: `.pi/HANDOFF.md` dan `.pi/EVIDENCE.md` milik proyek pengguna, sessions, session history, logs, runtime database, cache, temp, data privat.
- Dependency/generated: seluruh `npm/`, `node_modules/`, package cache, `dist/`, build output, `coverage/`.
- Source checkout besar: seluruh `git/`, seluruh `vendor/`, `.git` vendor. Hanya source terpilih yang diambil ulang dari commit terkunci.
- Recovery/archive: seluruh `backups/`, termasuk patch Todo Tools; hanya hash dan lokasi provenance dicatat.

## Status MISSING dan risiko tersisa

- Komponen wajib MISSING: **tidak ada**.
- `PI_HOME` absolut pada manifest merupakan metadata mesin audit, bukan secret, tetapi tetap path lokal dan perlu dinormalisasi saat installer dibuat.
- Instalasi ulang Impeccable CLI `3.2.1` perlu diuji kelak untuk memastikan masih menghasilkan skill `3.9.1`; registry dapat berubah walau CLI dipin.
- Lockfile aman Todo Tools belum menjadi payload repository karena Phase 1 hanya mengizinkan empat file keluaran. Fase installer perlu menambahkan artefak lockfile terverifikasi atau mekanisme patch yang hash-checked.
- Checkout AstralForge memiliki tiga report termodifikasi yang tidak relevan; jangan gunakan working tree vendor sebagai payload utuh.
- Verifikasi awal yang salah dijalankan dari root repository gagal dengan `ENOLOCK`/`ENOENT`; command kemudian dijalankan ulang dari checkout Todo Tools dan lulus. Tidak ada source yang berubah.
