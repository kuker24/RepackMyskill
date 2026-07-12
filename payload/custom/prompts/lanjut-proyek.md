---
description: Lanjutkan proyek dari AGENTS.md dan checkpoint terakhir
argument-hint: "[tugas atau perubahan tujuan]"
---

Lanjutkan pekerjaan proyek ini menggunakan Fable Auto dan Peta Auto.

Instruksi tambahan pengguna:

$ARGUMENTS

Sebelum mengubah file:

1. Muat skill `fable-auto`.
2. Muat skill `peta-auto`.
3. Baca root AGENTS.md.
4. Baca child AGENTS.md yang relevan dengan area pekerjaan.
5. Baca `.pi/HANDOFF.md` jika tersedia.
6. Periksa Git status dan perubahan yang belum selesai.
7. Verifikasi bahwa isi HANDOFF masih sesuai dengan keadaan source saat ini.

Jangan langsung mempercayai HANDOFF jika source sudah berubah.

Tentukan tindakan berikutnya berdasarkan evidence terbaru.

Gunakan:

- fable-luna untuk inspeksi read-only
- fable-sol untuk planning atau review
- fable-terra untuk implementasi dan testing

Jangan mengulang pekerjaan yang sudah selesai dan terverifikasi.

Lanjutkan dari langkah prioritas tertinggi yang belum selesai.

Setelah pekerjaan bermakna selesai, perbarui AGENTS.md bila kontrak atau
struktur berubah. Perbarui `.pi/HANDOFF.md` jika pekerjaan masih perlu
dilanjutkan pada sesi berikutnya.

Jangan commit atau push kecuali diminta secara eksplisit.
