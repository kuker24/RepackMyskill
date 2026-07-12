# Third-Party Notices

RepackMyskill mengatur instalasi komponen berikut. Source pihak ketiga tetap milik pembuat masing-masing dan tidak diklaim sebagai karya RepackMyskill.

| Proyek | Repository/package | Pin | Metode instalasi | Lisensi terverifikasi |
|---|---|---|---|---|
| pi-9router-ext | https://github.com/irfansofyana/pi-9router-ext.git | npm `0.2.2` | `pi install npm:pi-9router-ext@0.2.2` | MIT, dari metadata package terpasang |
| @tintinweb/pi-subagents | https://github.com/tintinweb/pi-subagents.git | npm `0.13.0` | `pi install npm:@tintinweb/pi-subagents@0.13.0` | MIT, dari metadata package terpasang |
| pi-plan-extension | `npm:pi-plan-extension` | npm `0.1.0` | `pi install npm:pi-plan-extension@0.1.0` | MIT, dari metadata package terpasang; URL repository tidak tersedia pada metadata audit |
| pi-todotools | https://github.com/code-yeongyu/pi-todotools.git | commit `93ba67efa5a7358356a829569365bb017a8ad498` | `pi install` Git pin, lalu lockfile aman dan `npm ci --ignore-scripts` | MIT, dari `LICENSE` checkout terkunci |
| AstralForge Senior Engineer Skills | https://github.com/kuker24/AstralForge-Senior-Engineer-Skills.git | commit `3f59d793a2691a95e63355f91adaeb72a7120fac` | Clone temporary; salin tepat 16 skill | License verification required; tidak ditemukan file license root pada checkout audit |
| Matt Pocock Skills | https://github.com/mattpocock/skills.git | commit `391a2701dd948f94f56a39f7533f8eea9a859c87` | Clone temporary; salin hanya `grill-me` dan `grilling` | MIT, dari `LICENSE.md` checkout terkunci |
| Impeccable | `npm:impeccable` | CLI `3.2.1`; skill audit `3.9.1` | `npx --yes impeccable@3.2.1 skills install -y --providers=pi --scope=global --no-hooks` | Apache 2.0, dari metadata `skills/impeccable/SKILL.md` audit |

Lockfile dan patch Todo Tools dalam `payload/todotools/` merupakan artefak reproduksi/audit untuk source pihak ketiga, bukan perubahan kepemilikan atau lisensi.
