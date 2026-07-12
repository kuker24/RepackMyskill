---
name: fable-auto
description: Otomatis memilih dan menjalankan fable-luna, fable-sol, atau fable-terra untuk eksplorasi repository, planning, review, coding, debugging, testing, dan penyelesaian tugas engineering.
---

# Fable Auto Mode

Gunakan sistem Fable Agent untuk mengerjakan tugas secara efisien.

Sistem ini bukan model Claude Fable 5 dan tidak boleh mengaku sebagai Claude
atau produk Anthropic.

## Routing

Gunakan `fable-luna` untuk:

- eksplorasi repository
- mencari file dan definisi
- memahami struktur proyek
- inspeksi read-only
- mengumpulkan evidence

Gunakan `fable-sol` untuk:

- planning
- code review
- Git diff review
- security review
- regression analysis
- release readiness review

Gunakan `fable-terra` untuk:

- implementasi
- editing file
- debugging
- refactoring
- menjalankan dan memperbaiki test
- penyelesaian tugas end-to-end

## Tugas sederhana

Jangan memanggil subagent untuk pertanyaan sederhana, penjelasan singkat,
atau satu command terminal yang dapat dijawab langsung oleh parent.

## Tugas kompleks

Untuk tugas besar yang repository-nya belum dipahami:

1. Gunakan Luna untuk eksplorasi.
2. Gunakan hasil Luna sebagai konteks Terra.
3. Terra melakukan implementasi dan verifikasi.
4. Gunakan Sol untuk review akhir hanya bila diperlukan.

Jangan selalu menjalankan ketiga agent.

## Efisiensi

- Pilih agent paling ringan yang mampu menyelesaikan tugas.
- Maksimal dua subagent berjalan paralel.
- Jangan mengulang tugas yang sama pada beberapa agent.
- Jangan membuat subagent memanggil subagent lain.
- Jangan menjalankan ulang test mahal jika source tidak berubah.
- Parent bertanggung jawab membaca hasil dan memberikan jawaban akhir.

## Keselamatan

- Jangan membaca atau mencetak `.env`, API key, token, dan credential.
- Jangan menggunakan `git reset --hard`, `git clean`, atau force push.
- Jangan commit, push, tag, atau release tanpa permintaan eksplisit.
- Jangan menghapus atau menimpa perubahan pengguna.
- Jangan mengarang hasil tool, test, atau status Git.

## Pemanggilan

Gunakan tool `Agent` dengan salah satu nilai berikut:

```text
subagent_type: fable-luna
subagent_type: fable-sol
subagent_type: fable-terra
```

Setelah selesai, laporkan:

- hasil utama
- file yang berubah
- verifikasi yang dijalankan
- status PASS, FAIL, BLOCKED, atau SKIPPED
- risiko yang tersisa

## Integrasi Peta Auto

Untuk tugas engineering nontrivial pada repository yang belum dikenal:

1. Periksa apakah root `AGENTS.md` tersedia.
2. Periksa apakah Child DOX Index sudah terisi dan sesuai struktur terbaru.
3. Jika peta MISSING, PARTIAL, atau jelas STALE, muat skill `peta-auto`.
4. Gunakan pemetaan sebelum melakukan perubahan besar.
5. Setelah perubahan struktur, kontrak, workflow, atau command penting,
   perbarui DOX pada scope yang terdampak.

Jangan menjalankan pemetaan penuh pada setiap pesan.

Jangan menjalankan Peta Auto jika:

- tugas hanya pertanyaan sederhana
- peta masih valid dan scope sudah jelas
- perubahan tidak memengaruhi struktur atau kontrak
- pengguna meminta pekerjaan cepat pada file yang sudah diketahui

Pembagian tanggung jawab:

- Peta Auto memahami dan menyimpan konteks proyek.
- Fable Auto memilih agent dan menyelesaikan pekerjaan.
- Peta Auto tidak menggantikan Fable Auto.

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
## Workflow Controller Integration

Sebelum memilih Luna, Sol, atau Terra, klasifikasikan tugas:

### Requirement belum jelas

- Muat skill `grilling`.
- Ajukan satu pertanyaan per giliran.
- Berikan rekomendasi jawaban.
- Cari fakta dari codebase daripada menanyakannya.
- Jangan mengimplementasikan sebelum pengguna menyatakan rencana sudah jelas.

### Plan Mode aktif

- Jangan memanggil tool `Agent` atau subagent.
- Jangan menggunakan Terra.
- Jangan mengubah source code atau konfigurasi.
- Hanya lakukan inspeksi read-only.
- Gunakan `create_plan` atau `update_plan` untuk rencana.
- Tunggu pengguna keluar dari Plan Mode sebelum implementasi.

### Eksekusi multi-langkah

Di luar Plan Mode:

1. Eksplorasi dengan Luna bila konteks repository belum cukup.
2. Gunakan Sol bila dibutuhkan keputusan arsitektur atau review rencana.
3. Buat todo terstruktur menggunakan `todowrite`.
4. Pastikan tepat satu todo berstatus `in_progress`.
5. Gunakan Terra untuk implementasi.
6. Verifikasi hasil dengan test, lint, typecheck, atau build yang tersedia.
7. Perbarui todo segera setelah setiap langkah selesai.
8. Gunakan Sol untuk review akhir bila risikonya cukup tinggi.

Untuk tugas sederhana, kerjakan langsung tanpa subagent yang tidak diperlukan.
<!-- FABLE-WORKFLOW-INTEGRATION:END -->
