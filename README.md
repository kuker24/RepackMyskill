# RepackMyskill

Installer reproducible untuk konfigurasi publik [Pi Coding Agent](https://github.com/badlogic/pi-mono). RepackMyskill memasang workflow Fable, Plan Mode guard, prompt, skill, dan extension yang sudah dipin. Tidak membundel API key, token, session, atau konfigurasi akun.

## Fitur

- Package Pi dengan versi/commit pinned dan pemeriksaan idempotent.
- Payload custom dengan SHA-256 sebelum perubahan target.
- Backup manifest, state atomik, rollback filesystem, dan uninstall konservatif.
- Merge `AGENTS.md` berbasis marker; isi pengguna di luar block dipertahankan.
- 16 skill AstralForge terseleksi, 20 skill HyperFrames native, Grill Me + Grilling, Todo Tools lockfile aman, dan Impeccable pinned.
- `doctor.sh` read-only dengan output manusia atau JSON.
- Test sandbox memakai `HOME` dan `PI_CODING_AGENT_DIR` sementara.

## Komponen

| Area | Komponen |
|---|---|
| Pi packages | `pi-9router-ext@0.2.2`, `@tintinweb/pi-subagents@0.13.0`, `pi-plan-extension@0.1.0`, Todo Tools commit `93ba67e…` |
| Workflow | Fable Core/Auto, Peta Auto, Senior Engineer Auto, Luna/Sol/Terra |
| Plan Mode | `pi-plan-extension`, Fable Plan Guard, dan Fable Agent Compatibility runtime |
| Skills | 16 AstralForge, 20 HyperFrames, `grill-me`, `grilling`, Impeccable |
| Prompts | `/f5`, `/fl`, `/fs`, `/ft`, `/peta-auto`, `/senior-auto`, `/impeccable`, `/grill-me` |

Pin lengkap: [`docs/INVENTORY.md`](docs/INVENTORY.md), [`manifest/source-lock.json`](manifest/source-lock.json), dan [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Prasyarat

- Pi Coding Agent dengan command `pi`
- Bash, Git, Python 3, `sha256sum`
- Node.js 22+
- FFmpeg 7+, FFprobe, dan Chrome/Chromium untuk HyperFrames render
- npm dan npx
- Akses jaringan ke npm dan source Git yang dipin untuk instalasi penuh

Target selalu dinamis:

```bash
PI_HOME=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
```

## Quick start

```bash
git clone https://github.com/kuker24/RepackMyskill.git
cd RepackMyskill
bash install.sh --yes
```

Lalu jalankan:

```text
pi
/reload
/9router-config
```

`/9router-config` meminta konfigurasi pribadi pengguna. API key dan konfigurasi akun tidak pernah dibundel oleh repository ini.

## Instalasi manual dan dry-run

```bash
bash install.sh --dry-run --yes
bash install.sh
```

Dry-run memeriksa source dan payload tanpa mengubah `PI_HOME`, membuat backup, clone, atau memasang package.

## Operasi lifecycle

```bash
bash doctor.sh
bash doctor.sh --json
bash update.sh --yes
bash rollback.sh --backup "$PI_HOME/backups/repackmyskill-YYYYMMDD-HHMMSS-PID" --yes
bash uninstall.sh --yes --keep-packages
```

- `update.sh` menjalankan ulang pin saat ini, bukan update ke versi terbaru acak.
- `rollback.sh` hanya mengembalikan file yang belum dimodifikasi sejak operasi dicatat. File yang berubah dipertahankan dengan `WARN`.
- `uninstall.sh` menghapus hanya file terkelola dan block marker RepackMyskill. Package hanya dihapus memakai command resmi `pi remove` bila state membuktikan package tersebut dipasang oleh RepackMyskill. Gunakan `--keep-packages` untuk mempertahankan package.

Detail: [`docs/INSTALL.md`](docs/INSTALL.md).

## Perintah utama setelah `/reload`

```text
/f5
/fl
/fs
/ft
/peta-auto
/senior-auto
/impeccable
/grill-me
/plan
/skill:hyperframes
/skill:motion-graphics
/skill:website-to-video
```

## Keamanan

- Validasi `manifest/payload.sha256` sebelum mutasi filesystem.
- Menolak symlink payload dan target terkelola yang tidak aman.
- Backup timestamped memiliki `manifest.json` berisi file lama, file baru, checksum, dan package yang baru dipasang pada operasi.
- State atomik berada pada `$PI_HOME/.repackmyskill/state.json` dan tidak memuat credential.
- Todo Tools memakai lockfile aman terverifikasi, `npm ci --ignore-scripts --omit=dev`, dan audit npm high/critical.
- HyperFrames memakai 20 skill native dari commit pinned `ccf5f20b…`; installer dan wrapper memeriksa SHA-512 npm untuk CLI `0.7.54` sebelum eksekusi. Jalankan `hyperframes lint` dan `hyperframes check` sebelum render.
- Fable Agent Compatibility menghapus isolation worktree yang dipaksakan upstream hanya untuk Luna, Sol, dan Terra; tipe Agent lain tidak berubah.
- Tidak menjalankan `npm audit fix --force`, `git reset --hard`, force push, atau login.
- Tidak menyentuh `auth.json`, `settings.json` user selain metadata package yang Pi sendiri kelola, `9router-config.json`, session, cache, atau seluruh `PI_HOME`.

## Troubleshooting

**`Node.js minimal versi 22`** — perbarui Node.js, lalu ulangi dry-run.

**FFmpeg/FFprobe atau integrity HyperFrames gagal** — pasang FFmpeg 7+ beserta FFprobe, lalu periksa koneksi npm dan pin manifest. Jangan melewati check dengan mengganti versi CLI.

**Checksum payload gagal** — hentikan. Checkout ulang repository dari source tepercaya; jangan ubah manifest untuk menutupi perubahan.

**`pi list` atau package tidak tersedia** — pasang Pi Coding Agent lebih dulu dan pastikan `pi` ada pada `PATH`.

**Audit Todo Tools gagal** — installer berhenti dan mengembalikan filesystem. Jangan memakai audit fix paksa; periksa output npm dan backup path.

**Marker `AGENTS.md` rusak/ganda** — installer berhenti agar aturan pengguna tidak rusak. Perbaiki pasangan marker berikut secara manual, lalu ulangi:

```text
<!-- REPACKMYSKILL:START -->
<!-- REPACKMYSKILL:END -->
```

## Lisensi

Script dan konfigurasi custom RepackMyskill dilisensikan [MIT](LICENSE). Komponen pihak ketiga mempertahankan lisensi masing-masing; lihat [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
