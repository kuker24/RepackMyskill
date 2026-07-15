# Instalasi dan Lifecycle RepackMyskill

## Prasyarat

Installer tidak memasang Pi Coding Agent. Siapkan:

- Pi Coding Agent (`pi` pada `PATH`)
- Bash, Git, Python 3, dan `sha256sum`
- Node.js 22 atau lebih baru
- FFmpeg 7 atau lebih baru, FFprobe, dan Chrome/Chromium untuk HyperFrames render
- npm dan npx
- jaringan ke npm dan source Git yang dipin

Target selalu dinamis:

```bash
PI_HOME=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
```

## Validasi tanpa perubahan

```bash
bash install.sh --dry-run --yes
```

Dry-run memverifikasi checksum payload, JSON, prerequisite Node.js/FFmpeg/FFprobe, pin, dan rencana operasi. Tidak membaca `pi list` karena beberapa versi Pi memperbarui metadata saat command itu dijalankan. Tidak membuat backup, directory, clone, package install, atau file di `PI_HOME`. Dry-run memvalidasi format pin integrity HyperFrames; instalasi nyata mencocokkan `npm view hyperframes@0.7.54 dist.integrity` sebelum mutasi target.

## Instalasi

```bash
bash install.sh
bash install.sh --yes
```

Opsi tambahan:

```text
--skip-impeccable
--skip-astral
--skip-grill
```

Installer memverifikasi payload sebelum mutasi. Pada instalasi nyata, setiap perubahan filesystem masuk transaksi. Backup berada di:

```text
$PI_HOME/backups/repackmyskill-YYYYMMDD-HHMMSS-PID/
```

`manifest.json` backup mencatat file yang sudah ada, file baru, checksum target hasil instalasi, dan package yang baru dipasang dalam operasi. Bila instalasi gagal, filesystem dikembalikan dan package yang baru dipasang dihapus dengan `pi remove` bila memungkinkan. Path backup selalu dicetak saat sukses atau gagal.

State atomik ditulis hanya setelah instalasi berhasil:

```text
$PI_HOME/.repackmyskill/state.json
```

State hanya berisi versi/pin, managed path + checksum, marker, skip component, backup terakhir, dan verification result. State tidak menyimpan credential atau session.

## Yang dipasang

- `npm:pi-9router-ext@0.2.2`
- `npm:@tintinweb/pi-subagents@0.13.0`
- `npm:pi-plan-extension@0.1.0`
- `git:github.com/code-yeongyu/pi-todotools@93ba67efa5a7358356a829569365bb017a8ad498`
- Todo Tools lockfile aman dengan `npm ci --ignore-scripts --omit=dev` dan `npm audit --omit=dev --audit-level=high`
- tepat 16 skill AstralForge dari commit `3f59d793a2691a95e63355f91adaeb72a7120fac`
- `grill-me` dan `grilling` dari commit `391a2701dd948f94f56a39f7533f8eea9a859c87`
- Impeccable CLI `3.2.1`, provider Pi, global scope, tanpa hooks
- custom agent, prompt, Plan guard, Fable/Peta/Senior skill
- 20 skill HyperFrames native dari commit `ccf5f20b3beea2b245c398a89cb686077b546de2` dan wrapper CLI `hyperframes@0.7.54` dengan check `npm dist.integrity` SHA-512 sebelum eksekusi
- extension Fable Agent Compatibility yang menghapus forced worktree isolation hanya untuk `fable-luna`, `fable-sol`, dan `fable-terra`
- marker block RepackMyskill pada `AGENTS.md`; teks di luar marker dipertahankan

## Doctor

```bash
bash doctor.sh
bash doctor.sh --json
```

`doctor.sh` read-only. Check mencakup prerequisite, Node 22, state, checksum payload, custom file, marker, package pin, Todo audit, Fable/Peta/Senior/Plan guard/Fable Agent Compatibility, prompt, 16 Astral skill, 20 HyperFrames skill, FFmpeg 7+, FFprobe, browser render, Grill Me/Grilling, Impeccable kecuali di-skip, dan secret-pattern pada repository. Exit code nonzero bila ada `FAIL`.

## Update

```bash
bash update.sh --yes
bash update.sh --dry-run --yes
```

Update membaca state, memverifikasi payload, lalu memanggil installer dengan pin manifest saat ini. Tidak mengejar latest. File pengguna di luar area terkelola tidak disentuh. `doctor.sh` berjalan sesudah update nyata.

## Rollback

```bash
bash rollback.sh --backup "$PI_HOME/backups/repackmyskill-YYYYMMDD-HHMMSS-PID" --yes
bash rollback.sh --dry-run
```

Tanpa `--backup`, rollback memakai backup terakhir pada state. Manifest backup wajib valid. File baru hanya dihapus bila checksum masih cocok dengan hasil instalasi; file yang diubah pengguna dipertahankan dan menghasilkan `WARN`.

## Uninstall

```bash
bash uninstall.sh --dry-run --yes
bash uninstall.sh --yes
bash uninstall.sh --yes --keep-packages
```

Uninstall membaca state, membuat backup, lalu menghapus hanya managed path yang checksum-nya masih cocok. File yang berubah disalin ke backup dan dipertahankan. Hanya block marker RepackMyskill yang dihapus dari `AGENTS.md`. Credential 9Router, project, dan keseluruhan `PI_HOME` tidak pernah dihapus.

`pi --help` diperiksa sebelum package mutation. Bila state membuktikan package dipasang oleh RepackMyskill, uninstaller memakai syntax resmi `pi remove <source>`; bila tidak, package dibiarkan atau dilaporkan untuk penanganan manual.

## Setelah instalasi

```text
pi
/reload
/9router-config
```

Masukkan credential 9Router sendiri melalui `/9router-config`. RepackMyskill tidak membawa `auth.json`, `settings.json` privat, `9router-config.json`, API key, token, cookie, session, log, cache, atau backup lama.

## Troubleshooting

### Payload checksum atau JSON gagal

Hentikan. Checkout ulang source tepercaya. Jangan mengubah manifest agar check lewat.

### Todo Tools audit gagal

Transaksi berhenti dan filesystem dikembalikan. Jangan gunakan `npm audit fix --force`; periksa output npm dan backup path.

### Marker AGENTS rusak/ganda

Installer berhenti untuk melindungi isi pengguna. Pastikan terdapat maksimal satu pasangan valid:

```text
<!-- REPACKMYSKILL:START -->
<!-- REPACKMYSKILL:END -->
```

### FFmpeg/FFprobe atau integrity HyperFrames gagal

Pasang FFmpeg 7+ beserta FFprobe. Untuk integrity mismatch, periksa koneksi npm dan manifest pin; jangan mengganti versi CLI atau melewati check.

### Network sementara gagal

Installer retry clone/package install satu kali. Jika masih gagal, gunakan backup path yang dilaporkan dan ulangi setelah jaringan pulih.
