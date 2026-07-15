<!-- REPACKMYSKILL:START -->
# RepackMyskill Runtime

## Fable Auto

Untuk setiap tugas software engineering, gunakan `skills/fable-auto/SKILL.md`.

- Gunakan `fable-luna` untuk pencarian, inspeksi, pemetaan, dan evidence read-only.
- Gunakan `fable-sol` untuk planning, audit, architecture review, security review, dan final review.
- Gunakan `fable-terra` untuk implementasi, debugging, editing, dan testing.
- Gunakan agent paling ringan yang cukup; maksimal dua subagent paralel.
- Jangan memberi tugas sama kepada beberapa agent atau membiarkan subagent memanggil subagent.
- Jangan meminta pengguna memilih agent kecuali pengguna ingin memilih sendiri.

## Fable Agent Compatibility

Extension `extensions/fable-agent-compat/index.ts` menghapus `isolation` yang dipaksakan upstream hanya untuk `fable-luna`, `fable-sol`, dan `fable-terra`. Agent lain tidak diubah. Muat ulang Pi setelah instalasi agar extension aktif.

## Peta Auto

Untuk tugas nontrivial pada repository yang belum dikenal, gunakan `skills/peta-auto/SKILL.md` untuk memahami struktur, entry point, command, kontrak, dan aturan lokal. Jangan memetakan ulang bila peta masih valid. Perbarui AGENTS.md proyek hanya jika struktur, kontrak, workflow, command penting, atau batas domain berubah.

## Senior Engineer Auto

Untuk pekerjaan engineering nontrivial, muat `skills/senior-engineer-auto/SKILL.md`.

- Peta Auto menyediakan konteks proyek.
- Senior Engineer Auto memilih skill, quality gate, dan evidence.
- Fable Auto memilih Luna, Sol, atau Terra.
- Gunakan skill Astral paling sedikit yang relevan dan jalankan validasi yang tersedia.
- Jangan mengklaim selesai tanpa evidence.
- Gunakan Impeccable sebagai spesialis utama untuk frontend, UI, dan UX; gunakan lokasi global `skills/impeccable` serta script di dalamnya.

## Workflow Control

<!-- FABLE-WORKFLOW-INTEGRATION:START -->
1. Jika requirement atau keputusan penting belum jelas, muat skill `grilling`. Ajukan tepat satu pertanyaan per giliran, sertakan rekomendasi, dan jangan mulai implementasi sebelum pengguna mengonfirmasi keputusan.
2. Jika Plan Mode aktif, bekerja read-only. Jangan menggunakan `Agent`, subagent, Luna, Sol, atau Terra untuk perubahan. Jangan menjalankan edit, write, instalasi, commit, push, deploy, atau command mutasi. Gunakan `create_plan` dan `update_plan` untuk dokumen rencana.
3. Di luar Plan Mode, gunakan `todowrite` untuk pekerjaan multi-langkah. Tepat satu todo berstatus `in_progress`; perbarui status segera setelah tiap langkah selesai.
4. Terra hanya boleh digunakan saat Plan Mode tidak aktif.
5. Verifikasi perubahan dengan test, lint, typecheck, build, atau gate relevan yang benar-benar tersedia.
<!-- FABLE-WORKFLOW-INTEGRATION:END -->

## Plan Mode Runtime Guard

Extension `extensions/fable-plan-guard/index.ts` wajib aktif bersama `pi-plan-extension`. Saat fase `planning`, guard harus memblokir tool bernama `Agent` dan tool apa pun yang namanya memuat `subagent`, serta menyuntikkan larangan mutasi sebelum agent dimulai.

## Todo Tools

Gunakan `todowrite` dan `todoread` sebagai mekanisme koordinasi semua tugas multi-langkah. Setiap todo harus menyebut WHERE, HOW, WHY, dan hasil yang diharapkan; tiap todo harus atomic; hanya satu boleh `in_progress`; tandai `completed` segera setelah evidence tersedia.

## Grill Me

Skill `grill-me` adalah entry point dan skill `grilling` berisi workflow utama. Gunakan keduanya: cari fakta dari repository, tanyakan keputusan satu per satu, sertakan rekomendasi, dan jangan menjalankan rencana sampai pengguna menyatakan pemahaman sudah sama.

## HyperFrames

Untuk setiap permintaan membuat, mengedit, menganimasikan, preview, lint, check, atau render video/motion graphic berbasis HTML, muat skill `hyperframes` lebih dulu. Gunakan HyperFrames sebagai default, bukan React atau Remotion, kecuali pengguna meminta tool lain secara eksplisit.

- Muat `hyperframes-core` sebelum menulis composition HTML.
- Gunakan `hyperframes-animation` untuk GSAP, Lottie, Three.js, SVG, Canvas, CSS, WAAPI, atau WebGL.
- Composition wajib memakai atribut composition/clip/track yang benar, timeline paused dan seekable, serta deterministic rendering.
- Gunakan wrapper global `hyperframes` untuk `init`, `preview`, `lint`, `check`, `doctor`, dan `render`; wrapper memverifikasi SHA-512 pin `hyperframes@0.7.54` sebelum eksekusi.
- Jalankan `lint` dan `check` sebelum render. Jangan menjalankan render produksi tanpa permintaan pengguna.
- Workflow tersedia: `general-video`, `motion-graphics`, `website-to-video`, `slideshow`, `product-launch-video`, dan workflow upstream lain yang terpasang.

## Safety

- Jangan membaca atau mencetak `.env`, API key, token, credential, password, cookie, atau data privat.
- Jangan menggunakan `git reset --hard`, `git clean`, force push, atau command destruktif.
- Jangan commit, push, tag, release, deploy, atau login tanpa permintaan eksplisit.
- Jangan menghapus perubahan pengguna yang tidak terkait atau mengarang hasil test/status Git.
<!-- REPACKMYSKILL:END -->
