---
description: Simpan checkpoint proyek agar dapat dilanjutkan pada sesi berikutnya
argument-hint: "[catatan tambahan]"
---

Buat checkpoint pekerjaan saat ini.

Pertama, periksa kondisi repository dan pekerjaan yang telah dilakukan.

Jika terdapat perubahan struktur, kontrak, workflow, command penting, atau
batas domain, muat skill `peta-auto` dan perbarui AGENTS.md yang relevan.

Setelah itu, buat atau perbarui file `.pi/HANDOFF.md` di root proyek.

Isi `.pi/HANDOFF.md` dengan struktur berikut:

# Project Handoff

## Current Objective

Tujuan utama pekerjaan yang sedang dilakukan.

## Project State

Status proyek: NEW, IN_PROGRESS, ESTABLISHED, atau UNKNOWN.

## Completed

Pekerjaan yang benar-benar sudah selesai dan terverifikasi.

## Changed Files

Daftar file yang dibuat atau diubah beserta tujuan singkatnya.

## Verification

Command test, build, lint, atau pemeriksaan yang telah dijalankan.

Catat hasilnya secara jujur sebagai PASS, FAIL, BLOCKED, atau SKIPPED.

## Current Blockers

Masalah yang belum terselesaikan beserta evidence yang tersedia.

## Next Steps

Langkah berikutnya dalam urutan prioritas.

## Resume Instructions

Instruksi singkat dan konkret untuk agent pada sesi berikutnya.

## User Notes

$ARGUMENTS

Aturan:

- Jangan menulis API key, token, credential, isi `.env`, atau secret.
- Jangan mengarang hasil test atau status pekerjaan.
- Jangan memasukkan seluruh Git diff.
- Buat checkpoint singkat tetapi cukup untuk melanjutkan pekerjaan.
- Jangan commit atau push kecuali diminta.
