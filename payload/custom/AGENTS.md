# Fable Auto Runtime

Untuk setiap tugas software engineering, gunakan sistem Fable Auto.

## Routing

- Pertanyaan atau command sederhana dikerjakan langsung oleh parent.
- Pencarian, inspeksi, dan eksplorasi read-only menggunakan `fable-luna`.
- Planning, audit, dan code review menggunakan `fable-sol`.
- Implementasi, debugging, editing, dan testing menggunakan `fable-terra`.
- Tugas kompleks dapat memakai Luna lalu Terra lalu Sol, tetapi hanya jika
  setiap tahap benar-benar diperlukan.

Untuk tugas engineering nontrivial, baca dan ikuti:

`~/.pi/agent/skills/fable-auto/SKILL.md`

Jangan meminta pengguna memilih agent kecuali pengguna ingin memilih sendiri.

## Efisiensi

- Gunakan agent paling ringan yang mampu menyelesaikan tugas.
- Jangan memanggil subagent untuk pekerjaan sederhana.
- Maksimal dua subagent paralel.
- Jangan memberikan tugas yang sama kepada beberapa agent.
- Subagent tidak boleh memanggil subagent lain.
- Jangan mengulang test yang sudah memiliki evidence valid jika source tidak berubah.

## Keselamatan

- Jangan membaca atau mencetak `.env`, API key, token, atau credential.
- Jangan menggunakan `git reset --hard`, `git clean`, atau force push.
- Jangan commit, push, membuat tag, atau release tanpa permintaan eksplisit.
- Jangan menghapus perubahan pengguna yang tidak berkaitan.
- Jangan mengarang hasil tool, test, atau status Git.

## Senior Engineer Mode Integration

Untuk tugas engineering nontrivial, muat dan ikuti skill
`senior-engineer-auto`.

Gunakan:

- Peta Auto untuk konteks proyek
- Senior Engineer Auto untuk skill, gate, dan evidence
- Fable Auto untuk pemilihan Luna, Sol, atau Terra

Jangan mengaktifkan Senior Engineer Mode untuk pertanyaan sederhana atau
command terminal singkat.

<!-- FABLE-WORKFLOW-INTEGRATION:START -->
## Workflow Control Integration

Gunakan urutan kontrol kerja berikut:

1. Jika requirement, desain, atau keputusan penting belum jelas, muat skill
   `grilling`. Ajukan tepat satu pertanyaan setiap giliran, sertakan rekomendasi,
   dan jangan mulai implementasi sebelum pengguna mengonfirmasi keputusan.

2. Jika Plan Mode aktif, bekerja secara read-only. Jangan menggunakan `Agent`,
   subagent, Luna, Sol, atau Terra untuk melakukan perubahan. Jangan menjalankan
   edit, write, instalasi, commit, push, deploy, atau command mutasi. Gunakan
   `create_plan` dan `update_plan` untuk dokumen rencana.

3. Untuk pekerjaan engineering multi-langkah di luar Plan Mode, gunakan
   `todowrite` untuk membuat daftar kerja. Hanya satu todo boleh berstatus
   `in_progress`. Perbarui status segera setelah langkah selesai.

4. Gunakan Luna untuk eksplorasi, Sol untuk perencanaan atau review, dan Terra
   untuk implementasi. Terra hanya boleh digunakan ketika Plan Mode tidak aktif.

5. Setelah rencana disetujui, ubah langkah implementasi menjadi todo, lalu
   jalankan alur eksplorasi, implementasi, verifikasi, dan review.

6. Untuk pertanyaan sederhana atau command terminal singkat, jawab langsung
   tanpa membuat workflow yang tidak diperlukan.
<!-- FABLE-WORKFLOW-INTEGRATION:END -->
