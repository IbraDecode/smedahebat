# Product Requirement Document — SMEDA HEBAT

## Digital School Operating System

| Metadata | |
|---|---|
| **Dokumen** | PRD v1.0 |
| **Produk** | SMEDA HEBAT |
| **Status** | Draft |
| **Penulis** | Tim Produk |
| **Tanggal** | Juli 2026 |

---

## Daftar Isi

1. [Executive Summary](#1-executive-summary)
2. [User Personas](#2-user-personas)
3. [User Journeys](#3-user-journeys)
4. [Feature Specifications per Module](#4-feature-specifications-per-module)
5. [Permission Matrix](#5-permission-matrix)
6. [MVP Scope](#6-mvp-scope)
7. [Non-functional Requirements](#7-non-functional-requirements)

---

## 1. Executive Summary

### Visi

Menjadi sistem operasi digital yang menyatukan seluruh ekosistem sekolah — akademik, administrasi, komunikasi, dan evaluasi — dalam satu platform yang intuitif, real-time, dan dapat diakses dari mana saja.

### Misi

1. Menghilangkan fragmentasi data sekolah yang tersebar di buku fisik, spreadsheet, grup WhatsApp, dan aplikasi terpisah.
2. Memberikan visibilitas penuh kepada setiap pemangku kepentingan — siswa, guru, wali kelas, BK, TU, admin, dan kepala sekolah — sesuai peran dan kewenangannya.
3. Mengotomatiskan proses administratif manual yang menyita waktu (absensi, rekap nilai, rapor) sehingga tenaga pendidik bisa fokus pada pengajaran.
4. Menyediakan fondasi teknis yang scalable, aman, dan siap diintegrasikan dengan sistem pihak ketiga (Dapodik, SPMB, bank).

### Problem Statement

Sekolah di Indonesia menghadapi masalah klasik yang tak kunjung selesai:

- **Data tersebar**: Nilai di buku tugas, absensi di kertas, pengumuman di grup WA, jadwal di papan mading. Tidak ada satu source of truth.
- **Komunikasi tidak terstruktur**: Guru memberi tugas lewat chat, siswa lupa, orang tua tidak tahu. Informasi penting tenggelam di grup.
- **Rapor dan rekap manual**: Wali kelas menghabiskan hari-hari menjumlah nilai dan mengetik rapor satu per satu. Rawan salah hitung dan salah tulis.
- **Tidak ada visibilitas real-time**: Kepala sekolah tidak bisa memantau kehadiran guru atau progres akademik siswa tanpa menunggu laporan akhir bulan.
- **Absensi rentan manipulasi**: Absen manual bisa dititipkan. Tidak ada verifikasi bahwa siswa benar-benar hadir di kelas.

**SMEDA HEBAT** hadir untuk menyelesaikan semua ini dalam satu platform terpadu.

### Target User

| Segmen | Jumlah Potensial | Kebutuhan Utama |
|---|---|---|
| Siswa SMP/SMA/SMK | 50–2000 per sekolah | Jadwal, tugas, nilai, pengumuman, absensi QR |
| Guru | 20–100 per sekolah | Presensi, input nilai, jadwal mengajar, pengumuman |
| Wali Kelas | 10–40 per sekolah | Rekap nilai, rapor, monitoring siswa, komunikasi orang tua |
| Guru BK | 1–5 per sekolah | Data bimbingan, catatan konseling, monitoring siswa bermasalah |
| Tata Usaha | 2–10 per sekolah | Manajemen pengguna, data induk, surat-menyurat, pengaturan sistem |
| Admin | 1–3 per sekolah | Konfigurasi sistem, role management, audit log |
| Kepala Sekolah | 1 per sekolah | Dashboard eksekutif, rekap kehadiran, grafik akademik |
| Orang Tua | — — | *Fase 2: pantau perkembangan anak* |

### Success Metrics

| Metrik | Target (6 bulan pasca-launch) | Cara Ukur |
|---|---|---|
| **Adoption Rate** | >80% siswa aktif pakai tiap minggu | Log aktivitas harian |
| **Presensi QR Coverage** | >90% jam pelajaran pakai QR | Hitung absensi via QR vs total |
| **Teacher Onboarding Time** | <15 menit dari daftar sampai absen pertama | Session duration tracking |
| **Dashboard Engagement** | >60% guru buka dashboard >3x/hari | Analytics event |
| **Rapor Generation Time** | Turun dari 3 hari ke <1 jam | A/B benchmark |
| **System Uptime** | >99.5% (downtime <3.5 jam/bulan) | Monitoring infrastruktur |
| **Page Load Time** | <1 detik (P95) | RUM & synthetic monitoring |

---

## 2. User Personas

### Persona 1: Rina Amalia — Siswa Kelas 11

| Atribut | Detail |
|---|---|
| **Usia** | 16 tahun |
| **Kelas** | XI MIPA 2 |
| **Karakter** | Aktif organisasi, sering lupa jadwal, selalu bawa smartphone |
| **Kebiasaan** | Cek HP tiap 5 menit, update IG Story, belajar sistem kebut semalam |
| **Pain Points** | Sering lupa tugas deadline karena catatan di buku terpisah; jadwal berubah mendadak cuma diinfokan lewat grup WA; kalau tidak masuk sekolah susah cari tahu tugas ketinggalan; bingung nilai akhir karena nggak pernah lihat progres |
| **Goal** | Bisa lihat semua jadwal, tugas, dan nilai di satu tempat; dapet notifikasi kalau ada tugas baru atau jadwal berubah |
| **Tech Literacy** | Tinggi — power user smartphone, fast adapter |

---

### Persona 2: Pak Hendro — Guru Matematika

| Atribut | Detail |
|---|---|
| **Usia** | 42 tahun |
| **Mata Pelajaran** | Matematika Wajib & Peminatan |
| **Mengajar** | 6 kelas, ~180 siswa |
| **Karakter** | Disiplin, agak gaptek, lebih suka kertas |
| **Kebiasaan** | Bawa buku nilai fisik kemana-mana, input nilai ke Excel seminggu sekali |
| **Pain Points** | Absen manual makan 5 menit tiap jam pelajaran — kumulatif 30 jam/semester hilang; ngisi rapor 180 siswa pakai tangan pegel dan rawan salah; kalau ada siswa bandel tidak ada catatan terpusat; tugas dikumpul kertas susah diarsip |
| **Goal** | Presensi cukup scan aja; input nilai dari HP langsung selesai; tidak perlu ngetik rapor manual |
| **Tech Literacy** | Rendah — cuma bisa WA dan telepon, takut salah pencet |

---

### Persona 3: Bu Eva — Wali Kelas XI MIPA 2 & Guru Biologi

| Atribut | Detail |
|---|---|
| **Usia** | 35 tahun |
| **Peran** | Wali kelas + Guru Biologi |
| **Karakter** | Multitasker, sering lembur, detail-oriented |
| **Pain Points** | Harus cross-check absen dari 5 guru mapel beda-beda untuk rekap; merekap nilai dari berbagai sumber (Excel, buku, kertas ulangan); komunikasi dengan orang tua masih lewat WA personal — tidak ada track record; menjelang rapor, tidur cuma 3 jam semalem karena input nilai |
| **Goal** | Semua nilai dan absen sudah masuk sistem dari masing-masing guru; rapor bisa generate otomatis; ada portal komunikasi dengan orang tua yang tercatat |
| **Tech Literacy** | Menengah — bisa Excel dan WA, mau belajar kalau ada panduan jelas |

---

### Persona 4: Pak Budi — Kepala Tata Usaha

| Atribut | Detail |
|---|---|
| **Usia** | 50 tahun |
| **Peran** | Kepala TU — mengelola data kepegawaian, data siswa, surat, dan operasional |
| **Karakter** | Sistematis, perfeksionis, beban kerja tinggi |
| **Pain Points** | Data guru dan siswa masih campur aduk di spreadsheet dan binder fisik; tiap tahun ajaran baru harus input ulang data dari formulir kertas; sinkronisasi ke Dapodik manual dan rawan mismatch; laporan untuk kepala sekolah harus dibuat manual tiap bulan |
| **Goal** | Data induk siswa/guru terpusat dan mudah dicari; ada export untuk Dapodik; laporan bisa di-generate otomatis |
| **Tech Literacy** | Rendah—menengah — bisa Excel dan aplikasi surat, perlu pendampingan awal |

---

## 3. User Journeys

### Journey 1: Login — First Time User

**Actor:** Rina (Siswa) — baru didaftarkan sekolah

| Step | Layar | Aksi | Sistem | Catatan |
|---|---|---|---|---|
| 1 | — | Rina terima email/SMS berisi link aktivasi dan kredensial awal (NIS + password sementara) | Sekolah input data siswa, sistem kirim notifikasi | Kredensial awal: NIS + `siswa123` |
| 2 | Login Page | Rina buka aplikasi, input NIS dan password sementara | Validasi kredensial | — |
| 3 | Reset Password Page | Sistem deteksi first login, redirect ke halaman reset password | Token reset terikat session | — |
| 4 | Reset Password Page | Rina buat password baru (min 8 char, kombinasi), input nomor HP | Validasi strength & format | — |
| 5 | OTP Verification | Rina masukkan kode OTP yang dikirim ke HP | Kirim OTP via Firebase Auth | — |
| 6 | Profile Setup | Rina upload foto profil (opsional), konfirmasi nama dan kelas | Pre-filled dari data induk | — |
| 7 | Onboarding Carousel | Rina lihat 3 slide tutorial: dashboard, absensi, tugas | — | Bisa skip |
| 8 | Student Dashboard | Rina masuk ke dashboard siswa | Generate personalized dashboard | Selesai |

---

### Journey 2: Login — Returning User

**Actor:** Pak Hendro (Guru) — sudah punya akun

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Login Page | Pak Hendro buka aplikasi, input email/NIP + password | — |
| 2 | — | — | Validasi kredensial. Jika salah >3x, akun lock 15 menit |
| 3 | OTP (opsional) | Jika login dari perangkat baru, minta OTP | Kirim OTP ke email/HP |
| 4 | Biometric (opsional) | Jika perangkat support, bisa face ID/fingerprint | — |
| 5 | Dashboard | Masuk ke dashboard sesuai role | Generate dashboard guru |

---

### Journey 3: Lihat Jadwal Hari Ini

**Actor:** Rina (Siswa)

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Dashboard | Rina lihat card "Jadwal Hari Ini" di dashboard atas | Ambil data jadwal dari database |
| 2 | — | — | Tampilkan: jam ke-, nama mapel, nama guru, ruang kelas |
| 3 | Detail | Rina tap salah satu jadwal | Buka modal: detail mapel, link materi, catatan tambahan |
| 4 | — | — | Jika ada perubahan jadwal, tampilkan badge "BERUBAH" dengan warna merah |

**Alternatif flow:** Rina bisa buka halaman "Jadwal" untuk lihat jadwal mingguan atau bulanan.

---

### Journey 4: Absensi QR — dari Guru Generate, Siswa Scan

**Actor:** Pak Hendro (Guru) & Rina (Siswa)

#### Sisi Guru

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Dashboard Guru | Pak Hendro tap "Mulai Kelas" | Buka halaman QR generator |
| 2 | QR Generator | Sistem generate QR code unik untuk jam pelajaran ini | QR berisi token JWT: `{class_id, subject_id, session_id, timestamp, expired_at}` |
| 3 | — | Pak Hendro tampilkan QR ke layar proyektor/HP | QR otomatis refresh tiap 30 detik, berlaku 5 menit |
| 4 | Real-time Counter | — | Sistem mulai hitung jumlah siswa yang sudah absen via WebSocket |

#### Sisi Siswa

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Student Dashboard | Rina tap "Absen" | Buka kamera scanner |
| 2 | QR Scanner | Rina scan QR yang ditampilkan guru | Validasi token QR: masih berlaku? sesi cocok? |
| 3 | — | — | Jika valid, catat: `student_id, session_id, timestamp, location (GPS), device_id` |
| 4 | Confirmation | Tampilkan animasi centang hijau + suara "Hadir" | Kirim notifikasi ke guru (siswa X sudah absen) |
| 5 | — | — | Update counter di dashboard guru |

**Edge cases:**
- QR expired → muncul pesan "QR sudah tidak berlaku, minta guru generate ulang"
- GPS di luar radius sekolah → flag "Hadir (Remote)", tampilkan warning
- Siswa scan 2× → tolak, tampilkan "Sudah absen sebelumnya"

---

### Journey 5: Lihat dan Kerjakan Tugas

**Actor:** Rina (Siswa)

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Dashboard | Rina lihat card "Tugas Mendatang" — deadline terdekat | Query tugas dengan due_date >= now, urut ascending |
| 2 | Tugas List | Rina tap card → buka halaman daftar tugas | Tampilkan filter: Semua, Belum Dikumpul, Terlambat, Selesai |
| 3 | Detail Tugas | Rina tap salah satu tugas | Tampilkan: judul, deskripsi, lampiran file, deadline, status |
| 4 | — | — | Jika deadline < 24 jam, tampilkan countdown merah |
| 5 | Submit | Rina upload file atau tulis jawaban teks, tap "Kumpulkan" | Validasi file size maks 10MB, format sesuai ketentuan guru |
| 6 | — | — | Simpan submission dengan timestamp, update status jadi "Selesai" |
| 7 | Confirmation | Tampilkan "Tugas berhasil dikumpulkan" + receipt | Kirim notifikasi ke guru |

---

### Journey 6: Lihat Pengumuman

**Actor:** Rina (Siswa)

| Step | Layar | Aksi | Sistem |
|---|---|---|---|
| 1 | Dashboard | Rina lihat feed "Pengumuman" di dashboard | Ambil pengumuman yang target audience = kelasnya, urut descending |
| 2 | — | — | Tandai pengumuman baru dengan badge biru |
| 3 | Detail | Rina tap pengumuman | Baca detail, lihat lampiran jika ada |
| 4 | — | — | Sistem catat pengumuman sudah dibaca (read receipt) |
| 5 | Notifikasi | — | Kirim push notification via FCM untuk pengumuman urgent (pin) |

---

### Journey 7: Dashboard Personal

**Actor:** Setiap role — konten berbeda

#### Siswa (Rina)
- Card **Jadwal Hari Ini** (jam, mapel, guru, ruang)
- Card **Tugas Mendatang** (3 teratas, deadline countdown)
- Card **Absensi** (persentase kehadiran bulan ini + total alpha/sakit/izin)
- Card **Pengumuman** (3 terbaru)
- Card **Nilai Ringkas** (rata-rata semester)

#### Guru (Pak Hendro)
- Card **Jadwal Mengajar Hari Ini**
- Card **Kelas Aktif** (jumlah siswa per kelas)
- Card **Presensi** (rekap kehadiran hari ini: total hadir/sakit/izin/alpha)
- Card **Tugas Perlu Dinilai** (jumlah submission pending)
- Tombol **Mulai Kelas** (generate QR)

#### Wali Kelas (Bu Eva)
- Semua yang guru punya
- Card **Monitoring Kelas** (grafik kehadiran per siswa)
- Card **Rapor** (progress pengisian rapor: sudah diisi x dari y)

#### Admin TU (Pak Budi)
- Card **Statistik Pengguna** (total siswa/guru/kelas)
- Card **Permintaan Baru** (akun pending aktivasi)
- Grafik **Aktivitas Sistem** (login per hari, storage usage)

---

## 4. Feature Specifications per Module

### 4.1 Module: Core

#### Tujuan
Menjadi fondasi platform yang menangani autentikasi, otorisasi, manajemen pengguna, notifikasi, pencarian, dan konfigurasi sistem.

#### Daftar Fitur

| # | Fitur | Deskripsi | Roles | Acceptance Criteria |
|---|---|---|---|---|
| C1 | Register & Aktivasi | Admin mendaftarkan pengguna baru; sistem kirim link aktivasi via email/WA | Admin, TU | 1. Admin bisa input NIS/NIP, nama, kelas, role. 2. Sistem kirim kredensial awal. 3. Link aktivasi expired dalam 24 jam. |
| C2 | Login (Multi-method) | Login via password, OTP, atau biometric | Semua | 1. Login dengan NIS/NIP/email + password. 2. OTP wajib untuk perangkat baru. 3. Lock setelah 5× gagal. 4. Session token valid 7 hari (refresh token). |
| C3 | Role-based Access Control | Setiap user hanya bisa akses fitur sesuai role | Semua | 1. Hierarki role ketat. 2. Admin bisa membuat custom role. 3. Middleware memblokir akses ilegal. |
| C4 | Manajemen Pengguna | CRUD user, reset password, nonaktifkan akun | Admin, TU | 1. Search user by NIS/NIP/nama. 2. Bulk import via Excel. 3. Audit log untuk setiap perubahan. |
| C5 | Notifikasi (Push & In-app) | Push via FCM, in-app notification center, email | Semua | 1. Notifikasi real-time. 2. Read receipt. 3. Kategori: tugas, absen, pengumuman, sistem. 4. Retry 3× jika FCM gagal. |
| C6 | Global Search | Pencarian terpusat dengan Meilisearch | Semua | 1. Search user, tugas, pengumuman, jadwal. 2. Fuzzy search. 3. Filter by kategori. 4. Hasil dalam <500ms. |
| C7 | Audit Log | Catat semua operasi CRUD penting | Admin | 1. Log: siapa, apa, kapan, data sebelum/sesudah. 2. Retention 90 hari. 3. Export ke CSV. |
| C8 | Settings & Configuration | Konfigurasi sistem, tahun ajaran, semester aktif | Admin | 1. Set tahun ajaran aktif. 2. Konfigurasi jam belajar. 3. Maintenance mode. |

#### Dependensi
- **C1–C4**: Tidak ada dependensi eksternal (pure auth)
- **C5**: Butuh Firebase project & Redis untuk antrean notifikasi
- **C6**: Butuh Meilisearch server
- **C7**: Butuh database write-heavy, arsip bisa pindah ke cold storage

---

### 4.2 Module: Academic

#### Tujuan
Mengelola seluruh data akademik sekolah: jadwal pelajaran, kalender akademik, mata pelajaran, nilai, dan rapor.

#### Daftar Fitur

| # | Fitur | Deskripsi | Roles | Acceptance Criteria |
|---|---|---|---|---|
| A1 | Master Mata Pelajaran | CRUD mata pelajaran, kode mapel, KKM | Admin, TU | 1. Input kode, nama, KKM. 2. Kategorisasi (wajib/minat/lintas minat). 3. Bisa aktif/nonaktifkan. |
| A2 | Kelola Kelas | CRUD kelas, wali kelas, jurusan | Admin, TU | 1. Set wali kelas (guru dengan role wali). 2. Atur rombongan belajar. 3. Pindahkan siswa antar kelas. |
| A3 | Jadwal Pelajaran | Buat jadwal tahunan/semester, atur jam pelajaran | Admin, TU, Wali Kelas | 1. Avoid bentrok ruang & guru secara otomatis. 2. Drag-and-drop. 3. Generate otomatis dari template. 4. Edit jadwal dengan notifikasi perubahan. |
| A4 | Kalender Akademik | Input hari efektif, libur, ujian, kegiatan | Admin, TU | 1. Tampilan kalender. 2. Color-coded. 3. Sinkronisasi dengan jadwal pelajaran. |
| A5 | Input Nilai | Guru input nilai tugas, UTS, UAS per siswa | Guru, Wali Kelas | 1. Input per kelas per mapel. 2. Bobot nilai bisa diatur. 3. Bisa import nilai via Excel. 4. Kunci nilai setelah diverifikasi wali kelas. |
| A6 | Rekap Nilai | Lihat rekap nilai per siswa per semester | Guru, Wali Kelas, Siswa, Kepsek | 1. Tampilan tabel per siswa. 2. Filter by semester. 3. Export ke PDF/Excel. |
| A7 | Rapor | Generate rapor digital + cetak PDF | Wali Kelas, Admin | 1. Generate rapor dari nilai yang sudah final. 2. Template rapor sesuai Diknas. 3. Deskripsi otomatis dari capaian. 4. Preview sebelum final. 5. TTD digital Kepala Sekolah. |
| A8 | Tugas Sekolah | Guru beri tugas, siswa upload, guru nilai | Guru, Siswa | 1. Tugas bisa berisi deskripsi + lampiran. 2. Deadline. 3. Status: open, closed, extended. 4. Plagiarism check flag (fase 2). |

#### Dependensi
- **A1–A4**: Butuh Core (auth, role)
- **A5**: Butuh A1–A2 (mapel, kelas) dan Core
- **A7**: Butuh A5 (nilai) dan A4 (kalender untuk semester)
- **A8**: Butuh S3-compatible storage untuk lampiran

---

### 4.3 Module: Attendance

#### Tujuan
Mengelola presensi siswa dan guru secara digital, real-time, dan anti-manipulasi. Menyediakan rekap yang bisa diekspor kapan saja.

#### Daftar Fitur

| # | Fitur | Deskripsi | Roles | Acceptance Criteria |
|---|---|---|---|---|
| AT1 | QR Code Presence | Guru generate QR, siswa scan, sistem catat presensi | Guru, Siswa | 1. QR unik per sesi (berlaku 5 menit). 2. QR expire otomatis. 3. Hanya bisa scan sekali per sesi. 4. Capture GPS + device ID untuk anti-cheat. |
| AT2 | Manual Presence | Alternatif absen jika QR gagal — guru input manual per siswa | Guru | 1. Tampilan dropdown daftar siswa. 2. Status: Hadir, Sakit, Izin, Alpha. 3. Catatan opsional. 4. Butuh verifikasi wali kelas (untuk Sakit/Izin). |
| AT3 | Rekap Harian | Lihat rekap kehadiran per kelas per hari | Guru, Wali Kelas, BK, Kepsek | 1. Tabel siswa vs status. 2. Summary statistic. 3. Filter tanggal. |
| AT4 | Rekap Bulanan/Semester | Rekap komulatif kehadiran siswa | Wali Kelas, BK, Admin, Kepsek | 1. Grafik kehadiran per siswa. 2. Peringatan jika >20% alpha. 3. Export ke PDF/Excel. |
| AT5 | Tutup Presensi | Guru finalisasi presensi setelah jam usai | Guru | 1. Setelah di-tutup, tidak bisa diedit tanpa approval admin. 2. Kirim notifikasi ke wali kelas. |
| AT6 | Laporan Export PDF | Export rekap absen untuk laporan BK atau wali kelas | Wali Kelas, BK, Admin | 1. Header kop sekolah. 2. Format tabel rapi. 3. Bisa filter per periode. |

#### Dependensi
- **AT1**: Butuh Core (auth), jadwal dari Academic
- **AT2–AT6**: Butuh AT1, Core, dan Academic (data siswa/kelas)

---

### 4.4 Module: Dashboard

#### Tujuan
Menyediakan tampilan personal yang relevan untuk setiap role, berisi widget yang actionable, real-time, dan mendukung pengambilan keputusan.

#### Daftar Fitur

| # | Fitur | Deskripsi | Roles | Acceptance Criteria |
|---|---|---|---|---|
| D1 | Personalized Widget Engine | Sistem menampilkan widget sesuai role pengguna | Semua | 1. Layout grid responsif. 2. Widget bisa di-drag-reorder (fase 2). 3. Setiap widget load independen. |
| D2 | Widget Jadwal Hari Ini | Menampilkan jadwal hari ini dengan waktu dan ruang | Siswa, Guru | 1. Real-time update jika ada perubahan. 2. Tampilkan jam ke- berapa. 3. Highlight sesi berjalan. |
| D3 | Widget Tugas Mendatang | Menampilkan 3-5 tugas terdekat deadline | Siswa, Guru | 1. Countdown. 2. Status badge. 3. Tap buka detail tugas. |
| D4 | Widget Absensi Ringkas | Grafik kehadiran bulan ini (donut chart) | Siswa, Wali Kelas, BK | 1. Persentase + angka. 2. Bandingkan dengan bulan lalu. 3. Warna: hijau (hadir), kuning (sakit), orange (izin), merah (alpha). |
| D5 | Widget Pengumuman | Feed pengumuman terbaru | Semua | 1. 3 item terbaru. 2. Badge baru. 3. Scrolling jika lebih. |
| D6 | Widget Statistik Real-time | Jumlah siswa hadir hari ini dll | Admin, Kepsek | 1. Update via WebSocket. 2. Angka besar (big number style). 3. Trending (naik/turun vs kemarin). |
| D7 | Widget Monitoring Kelas | Grafik kehadiran kelas per siswa | Wali Kelas, BK | 1. Bar chart. 2. Sorting by kehadiran terendah. 3. Warnai yang di bawah threshold. |

#### Dependensi
- **D1–D7**: Butuh data dari Core, Academic, Attendance
- **D6–D7**: Butuh WebSocket untuk real-time

---

## 5. Permission Matrix

| Fitur | Guest | Siswa | Guru | Wali Kelas | BK | TU | Admin | Kepsek |
|---|---|---|---|---|---|---|---|---|
| **AUTH** | | | | | | | | |
| Login | — | R | R | R | R | R | R | R |
| Register | — | — | — | — | — | RW | RW | — |
| Manajemen User | — | — | — | — | — | RW | RW | R |
| **AKADEMIK** | | | | | | | | |
| Lihat Jadwal | — | R | R | RW | R | R | RW | R |
| Kelola Jadwal | — | — | — | RW | — | RW | RW | — |
| Input Nilai | — | — | RW | RW | — | — | — | — |
| Lihat Nilai | — | R | R | RW | R | RW | RW | RW |
| Generate Rapor | — | — | — | RW | — | — | RW | R |
| Tugas: Buat | — | — | RW | RW | — | — | — | — |
| Tugas: Kerjakan | — | RW | — | — | — | — | — | — |
| Tugas: Nilai | — | — | RW | RW | — | — | — | — |
| **ABSENSI** | | | | | | | | |
| QR Generate | — | — | RW | RW | — | — | — | — |
| QR Scan | — | RW | — | — | — | — | — | — |
| Absen Manual | — | — | RW | RW | RW | — | — | — |
| Rekap Absen | — | R | R | RW | RW | RW | RW | RW |
| Export PDF Absen | — | — | R | RW | RW | RW | RW | RW |
| **DASHBOARD** | | | | | | | | |
| Dashboard Personal | — | R | R | R | R | R | R | R |
| Dashboard Admin | — | — | — | — | — | — | RW | — |
| Dashboard Kepsek | — | — | — | — | — | — | — | RW |
| **PENGUMUMAN** | | | | | | | | |
| Baca | — | R | R | R | R | R | R | R |
| Buat | — | — | RW | RW | RW | RW | RW | RW |
| Hapus | — | — | — | RW | — | RW | RW | — |
| **SISTEM** | | | | | | | | |
| Role Management | — | — | — | — | — | — | RW | — |
| Audit Log | — | — | — | — | — | RW | RW | R |
| Settings | — | — | — | — | — | RW | RW | R |
| Search | — | R | R | R | R | R | R | R |

**Keterangan:** R = Read, RW = Read + Write, — = No Access

---

## 6. MVP Scope

### Fitur MVP (Rilis 1.0)

| Modul | Fitur | Prioritas | Alasan |
|---|---|---|---|
| Core | Login & Aktivasi | P0 | Pintu masuk utama. Tanpa ini tidak bisa apa-apa. |
| Core | RBAC (Role-based Access) | P0 | Keamanan dasar. Setiap user harus terbatasi hak aksesnya. |
| Core | Manajemen Pengguna (Admin/TU) | P0 | Butuh input data siswa & guru sebelum aplikasi bisa dipakai. |
| Core | Notifikasi Push + In-app | P1 | Engagement kunci. Siswa perlu diingatkan tugas/guru perlu tahu QR di-scan. |
| Academic | Master Mapel & Kelas | P0 | Data master dasar yang dibutuhkan semua modul lain. |
| Academic | Jadwal Pelajaran (Read + Basic Edit) | P0 | Core value proposition: jadwal terpusat. |
| Academic | Input Nilai | P1 | Wajib untuk rapor, tapi rapor sendiri bisa ditunda |
| Academic | Tugas Sekolah (Buat, Kumpul, Nilai) | P1 | Fitur yang paling mendorong daily active usage. |
| Attendance | QR Presence | P0 | Fitur "wow" yang membedakan dari kompetitor, anti-manipulasi. |
| Attendance | Manual Presence (fallback) | P0 | Jaga-jaga kalau QR gagal. |
| Attendance | Rekap Harian | P1 | Guru perlu lihat siapa yang tidak masuk hari ini. |
| Dashboard | Dashboard Siswa | P1 | Menyatukan jadwal, tugas, absensi di satu layar. |
| Dashboard | Dashboard Guru | P1 | Entry point untuk mulai kelas + lihat jadwal. |
| Dashboard | Dashboard Wali Kelas | P1 | Monitoring kelas + rekap. |
| Dashboard | Dashboard Kepala Sekolah | P1 | Visibilitas eksekutif (rekap kehadiran + nilai). |

### Fitur Ditunda (Rilis 2.0+)

| Modul | Fitur | Alasan Ditunda |
|---|---|---|
| Core | Integrasi Dapodik | Butuh koordinasi dengan Diknas, API belum stabil. |
| Core | SSO / Google Login | Tidak kritis, password login sudah cukup untuk MVP. |
| Academic | Generate Rapor (PDF) | Kompleksitas tinggi (format Diknas berubah-ubah). Cukup rekap nilai digital dulu. |
| Academic | Auto-scheduling Jadwal | Algoritma kompleks. Jadwal manual dulu, auto-schedule di rilis 2.0. |
| Attendance | Face Recognition Presensi | Biaya tinggi, butuh hardware khusus, privasi sensitif. |
| Attendance | Export PDF (format kop surat) | Bisa pakai export Excel dulu. |
| Dashboard | Drag-and-Drop Widget | Nice-to-have, tidak kritis. Widget statis dulu. |
| Dashboard | Widget Kustomisasi | Kompleksitas engineering tinggi. |
| Semua Modul | Dark Mode | Bisa dikerjakan terpisah, tidak blokir fungsionalitas. |
| — | Portal Orang Tua | Butuh role baru, komunikasi 2 arah, scope besar. |
| — | Modul Perpustakaan | Di luar MVP, masuk roadmap Q3. |
| — | Modul Keuangan SPP | Sensitif, butuh integrasi payment gateway & audit ketat. |
| — | Aplikasi Web (versi desktop) | Mobile-first dulu. Web versi lightweight (PWA) di rilis 2.0. |

---

## 7. Non-functional Requirements

### 7.1 Performance

| Parameter | Target | Metode |
|---|---|---|
| API Response Time (P95) | <500ms untuk 90% endpoint | APM monitoring (Grafana + Prometheus) |
| Page Load Dashboard | <1s (First Contentful Paint) | Code splitting, caching Redis, CDN assets |
| Search Query | <300ms (P95) | Meilisearch indexing, typo tolerance |
| QR Generation | <100ms | Generate di server, cache 5 menit |
| Notifikasi Delivery | <5s dari trigger ke device | FCM + fallback polling WebSocket |
| Concurrent Users | Support 5000 per instance | Load testing dengan K6 |
| Database Query (kompleks) | <1s | Indexing strategis, query optimization, connection pooling |

### 7.2 Offline Support Strategy

| Level | Kondisi | Behavior |
|---|---|---|
| Online | Koneksi stabil | Semua operasi real-time via API |
| Degraded | Koneksi lambat (>2s latency) | UI tetap responsif, loading skeleton, request queue |
| Offline (Siswa) | Tidak ada internet | Cache jadwal hari ini + data tugas di local storage (Hydrated Bloc). QR absen tidak bisa — fallback minta absen manual ke guru. |
| Offline (Guru) | Tidak ada internet | Daftar siswa dan data mapel ter-cache. Absen manual bisa dicatat lokal, sinkronisasi saat online. Input nilai tidak bisa — harus online. |
| Reconnection | Kembali online | Background sync dengan konflik resolution (last-write-wins untuk absen). Retry 3× dengan exponential backoff. |

**Implementasi:**
- Flutter: `HydratedBloc` + `sqflite` untuk local DB
- Backend: Queue mechanism untuk batch sync

### 7.3 Security

| Aspek | Implementasi |
|---|---|
| **Autentikasi** | JWT (access token 15 menit + refresh token 7 hari). OTP untuk perangkat baru. |
| **Password Policy** | Min 8 karakter, kombinasi huruf + angka. Hash bcrypt (cost 12). |
| **Data in Transit** | TLS 1.3 minimum. HSTS enabled. |
| **Data at Rest** | Enkripsi AES-256 untuk data sensitif (NIS, alamat, nomor HP, nilai). |
| **Data Sensitif** | Nomor induk, kontak, alamat: encrypted field di database. |
| **SQL Injection** | Semua query via ORM (TypeORM/Prisma) — no raw SQL. |
| **XSS/CSRF** | Input sanitization, Content Security Policy, CSRF token untuk state-changing requests. |
| **Brute Force Protection** | Rate limiting: 5× gagal login dalam 15 menit → lock sementara. |
| **Session Management** | Valid refresh token rotation. Force logout jika password diubah. |
| **Audit Trail** | Semua operasi CRUD tercatat (siapa, apa, kapan, data lama/baru). Audit log immutable (append-only). |
| **RBAC Enforcement** | Middleware di setiap endpoint NestJS (Guard + Decorator). Server-side validation — tidak bergantung pada client. |
| **API Protection** | Rate limiting per endpoint (100 req/min/user umum, 1000 req/min untuk admin). |
| **File Upload** | Scan virus (ClamAV) untuk semua upload. Ekstensi terbatas (pdf, docx, xlsx, jpg, png — maks 10MB). |
| **Backup** | Backup database otomatis tiap 6 jam. Retention 30 hari. Encrypted backup disimpan di S3 region terpisah. |

### 7.4 Scalability

| Aspek | Arsitektur |
|---|---|
| **API Layer** | NestJS horizontal scaling dengan PM2 Cluster Mode. Load balancer (NGINX). |
| **Database** | PostgreSQL dengan read replicas. Connection pooling via PgBouncer. Partitioning untuk tabel besar (attendance, audit log). |
| **Cache** | Redis untuk session store, cache query, rate limiter, queue broker. |
| **Search** | Meilisearch dedicated instance. Re-index periodic via cron. |
| **Storage** | S3-compatible (MinIO atau Cloudflare R2). CDN untuk assets statis. Signed URL untuk file privat. |
| **Realtime** | WebSocket server terpisah (dengan Redis adapter untuk horizontal scaling). Fallback ke polling jika WebSocket gagal. |
| **File Processing** | Antrean Bull Queue (Redis) untuk task berat: rapor generation, PDF export, image compression. |
| **Monitoring** | Prometheus + Grafana untuk metrik. Sentry untuk error tracking. ELK untuk log aggregation. |
| **CI/CD** | GitHub Actions → Docker image → deploy ke staging/production. Blue-green deployment untuk zero downtime. |
| **Auto-scaling** | Kubernetes (fase 2). Untuk MVP cukup VPS dedicated dengan vertical scaling sesuai beban. |

### 7.5 Reliability & Availability

| Metrik | Target |
|---|---|
| Uptime | 99.5% (maks downtime ~3.5 jam/bulan) |
| Planned Maintenance | Diluar jam sekolah (22:00–05:00 WIB), notifikasi 48 jam sebelumnya |
| Backup Recovery | RTO <2 jam, RPO <6 jam |
| Error Rate | <0.1% dari total request |
| Retry Policy | Idempotent key untuk semua write operations |

### 7.6 Compatibility

| Platform | Versi Minimum |
|---|---|
| Android | API 24 (Android 7.0) ke atas |
| iOS | iOS 14 ke atas |
| Web (PWA — fase 2) | Chrome 80+, Firefox 75+, Safari 13.1+ |
| Flutter SDK | 3.24+ |
| Database | PostgreSQL 15+ |
| Node.js | 20 LTS+ |

---

## Appendices

### A. Glossary

| Istilah | Definisi |
|---|---|
| **KBM** | Kegiatan Belajar Mengajar |
| **KKM** | Kriteria Ketuntasan Minimal |
| **NIS/NISN** | Nomor Induk Siswa / Nomor Induk Siswa Nasional |
| **NIP** | Nomor Induk Pegawai (guru/TU) |
| **RBAC** | Role-Based Access Control |
| **Sesi** | Satu pertemuan KBM dalam satu jam pelajaran tertentu |
| **Alpha** | Tidak hadir tanpa keterangan |
| **Rombel** | Rombongan Belajar (satu kelas utuh) |

### B. Referensi

- Standar Pendidikan Nasional (Permendikbud)
- Format Rapor Dikdasmen 2024
- Dapodik API Documentation
- Firebase Cloud Messaging Documentation
- NestJS Security Best Practices

---

*Dokumen ini adalah living document dan akan diperbarui secara berkala seiring perkembangan produk.*
