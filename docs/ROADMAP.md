# 🗺️ ROADMAP & SPRINT PLANNING — SMEDA HEBAT

**SMEDA HEBAT: Digital School Operating System**

| Metadata | |
|---|---|
| **Tim** | 1 Developer (Fullstack) |
| **Tech Stack** | Flutter, NestJS, PostgreSQL, Redis |
| **Target** | Production-ready dalam 3 bulan (12 sprint) |
| **Start Date** | TBD |

---

## Daftar Isi

1. [Milestone Overview](#1-milestone-overview)
2. [Sprint Breakdown](#2-sprint-breakdown)
   - [Fase 1: Foundation (Sprint 1–4)](#fase-1-foundation-sprint-1-4)
   - [Fase 2: Core Features (Sprint 5–8)](#fase-2-core-features-sprint-5-8)
   - [Fase 3: MVP Launch (Sprint 9–12)](#fase-3-mvp-launch-sprint-9-12)
3. [Dependency Graph](#3-dependency-graph)
4. [Risk Register](#4-risk-register)
5. [Definition of Done](#5-definition-of-done)

---

## 1. Milestone Overview

### Fase 1: Foundation (Sprint 1–4) — Bulan 1

> **Tema:** Bangun fondasi yang kokoh. Infrastruktur, CI/CD, arsitektur backend & frontend, schema database, dan sistem autentikasi.

| Sprint | Nama | Fokus Utama |
|--------|------|-------------|
| 1 | Project Bootstrap | Monorepo, Docker, CI, database schema |
| 2 | Auth System | Register/Login, JWT, role, OTP |
| 3 | User & Role Management | Admin panel, manajemen user, sekolah |
| 4 | Dashboard Foundation | Layout, navigation, theming, base components |

**Gate:** Auth flow end-to-end berfungsi di staging. Siap menerima pengembangan fitur inti.

---

### Fase 2: Core Features (Sprint 5–8) — Bulan 2

> **Tema:** Bangun fitur inti akademik — jadwal, piket, mata pelajaran, dan sistem presensi QR.

| Sprint | Nama | Fokus Utama |
|--------|------|-------------|
| 5 | Academic: Master Data | Kelas, mapel, guru, tahun ajaran |
| 6 | Academic: Schedule | Jadwal pelajaran, CRUD + view |
| 7 | Attendance: QR System | Generate QR, scan, log presensi |
| 8 | Academic: Pickets | Jadwal piket, CRUD + view |

**Gate:** Semua fitur inti MVP bisa diakses via aplikasi. Siap masuk pengujian dan finalisasi.

---

### Fase 3: MVP Launch (Sprint 9–12) — Bulan 3

> **Tema:** Polish, hardening, dokumentasi, dan persiapan rilis.

| Sprint | Nama | Fokus Utama |
|--------|------|-------------|
| 9 | Reports & Recap | Laporan presensi, rekap akademik |
| 10 | Notification System | In-app notif, reminder jadwal/piket |
| 11 | Testing & Bug Fixing | QA, E2E, regression, performance |
| 12 | Deployment & Launch | Staging → Production, monitoring, docs |

**Gate:** MVP siap digunakan oleh sekolah rintisan.

---

## 2. Sprint Breakdown

---

### Fase 1: Foundation (Sprint 1–4)

---

#### Sprint 1: Project Bootstrap

| Item | Detail |
|------|--------|
| **Tujuan** | Setup foundation teknis: repo, infrastruktur lokal, pipeline CI, dan skema database awal. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Inisialisasi Turborepo monorepo dengan folder `apps/` dan `packages/` | Kecil | DevOps |
| 2 | Setup NestJS project (`apps/api`) dengan modular structure | Sedang | Backend |
| 3 | Setup Flutter project (`apps/mobile`) dengan folder structure | Sedang | Frontend |
| 4 | Setup Docker Compose (PostgreSQL 15, Redis 7, MinIO) | Kecil | DevOps |
| 5 | Setup Prisma ORM + migration awal (user, role, sekolah) | Sedang | Backend |
| 6 | Setup GitHub Actions CI — lint, build, test | Sedang | DevOps |
| 7 | Setup ESLint, Prettier, Husky, commitlint | Kecil | DevOps |
| 8 | Setup environment variables (.env example, validation) | Kecil | DevOps |
| 9 | Setup shared package (`@smedahebat/shared`) untuk tipe & konstanta | Kecil | Shared |
| 10 | Setup logger (Pino/NestJS Pino) | Kecil | Backend |
| 11 | Setup API response interceptor + exception filter | Kecil | Backend |
| 12 | Docs: README (cara running, environment), CONTRIBUTING.md | Kecil | Docs |

**Deliverable:**
- Monorepo dapat di-clone dan dijalankan dengan `docker compose up` + `npm run dev`
- Prisma migration berjalan tanpa error
- CI pipeline hijau (build + lint)

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Setup Turborepo memakan waktu | Sprint molor | Pakai referensi template yang sudah teruji |
| Konflik versi dependency | Build gagal | Lock dependency dengan npm, test di clean environment |

**Estimasi total: ~22 poin (kecil=1, sedang=3, besar=5) — 7 task kecil + 5 task sedang = 22 poin**

---

#### Sprint 2: Auth System

| Item | Detail |
|------|--------|
| **Tujuan** | Sistem autentikasi end-to-end: register, login, refresh token, role management backend, dan halaman login/splash di Flutter. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: Module Auth — Register (email, password, role) | Sedang | Backend |
| 2 | Backend: Login API + JWT access token (15 menit) | Sedang | Backend |
| 3 | Backend: JWT refresh token (7 hari) + rotasi | Sedang | Backend |
| 4 | Backend: Role guard & decorator (Admin, Guru, Siswa) | Kecil | Backend |
| 5 | Backend: Rate limiter pada endpoint auth | Kecil | Backend |
| 6 | Backend: First-time flow API (verifikasi NIS → kirim OTP) | Sedang | Backend |
| 7 | Backend: OTP generate + verify (Redis-based, 5 menit expiry) | Sedang | Backend |
| 8 | Backend: Set password pertama kali | Kecil | Backend |
| 9 | Flutter: Splash screen + auto-login check | Kecil | Frontend |
| 10 | Flutter: Login page (email + password) | Kecil | Frontend |
| 11 | Flutter: First-time flow (Input NIS → Verifikasi → OTP → Set Password) | Besar | Frontend |
| 12 | Flutter: Secure token storage (flutter_secure_storage) | Kecil | Frontend |
| 13 | Flutter: Auth service + interceptor (auto-refresh token) | Sedang | Frontend |
| 14 | Flutter: State management auth (Riverpod) | Kecil | Frontend |
| 15 | Testing: Unit test auth service (backend) | Kecil | Backend |

**Deliverable:**
- Backend: semua endpoint auth terdaftar di Swagger/Postman
- Flutter: user bisa login, register, dan melalui first-time flow
- Token disimpan aman, auto-refresh bekerja

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| OTP delivery (SMS/Email) belum siap | First-time flow terhambat | Gunakan OTP mock/logging di development; integrasi SMTP/WhatsApp API di Fase 3 |
| First-time flow UX rumit | User bingung | Buat flow diagram di Flutter sebelum coding; validasi input tiap step |

**Estimasi total: 1×8 + 6×3 + 7×1 = 8+18+7 = 33 poin**

---

#### Sprint 3: User & Role Management

| Item | Detail |
|------|--------|
| **Tujuan** | Admin dapat mengelola user (guru, siswa) dan mengatur role. Data sekolah dasar siap digunakan. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: CRUD User (Admin only) | Sedang | Backend |
| 2 | Backend: CRUD Role & Permission | Sedang | Backend |
| 3 | Backend: Assign role ke user | Kecil | Backend |
| 4 | Backend: Import user via Excel/CSV | Besar | Backend |
| 5 | Backend: Modul Sekolah (profil sekolah, tahun ajaran) | Sedang | Backend |
| 6 | Flutter: Admin — User Management page (list, search, filter) | Sedang | Frontend |
| 7 | Flutter: Admin — Create/Edit User form | Sedang | Frontend |
| 8 | Flutter: Admin — Role management page | Kecil | Frontend |
| 9 | Flutter: Admin — Import user page (upload CSV) | Sedang | Frontend |
| 10 | Backend: Seeder untuk data dummy (user, sekolah) | Kecil | Backend |
| 11 | Testing: E2E auth flow + role access | Kecil | QA |

**Deliverable:**
- Admin dapat CRUD user, mengatur role, dan import user dari CSV
- Data sekolah dasar terisi
- Role-based access control berfungsi (Admin bisa akses, Guru/Siswa ditolak)

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Import CSV dengan berbagai format | Parsing error | Tentukan format baku; validasi ketat sebelum insert; kasih error message jelas |
| Permission granularity belum fix | Harus refactor | Gunakan RBAC sederhana (Admin, Guru, Siswa) dulu; jangan buat custom permission di MVP |

**Estimasi total: 1×5 + 5×3 + 4×1 = 5+15+4 = 24 poin**

---

#### Sprint 4: Dashboard Foundation

| Item | Detail |
|------|--------|
| **Tujuan** | Layout dasar aplikasi Flutter selesai: sidebar, navigation, theming, dashboard widget framework. Backend menyediakan API overview. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Flutter: App shell layout (Drawer/BottomNav + AppBar) | Sedang | Frontend |
| 2 | Flutter: Theming system (light/dark mode, color tokens) | Sedang | Frontend |
| 3 | Flutter: Base components (button, card, input, dialog, snackbar) | Sedang | Frontend |
| 4 | Flutter: Navigation system (GoRouter, auth guard) | Sedang | Frontend |
| 5 | Flutter: Responsive layout (breakpoints untuk tablet/handphone) | Sedang | Frontend |
| 6 | Flutter: Dashboard page (widget kosong dengan placeholder) | Kecil | Frontend |
| 7 | Flutter: Empty state, loading state, error state components | Kecil | Frontend |
| 8 | Backend: API Dashboard overview (statistik umum) | Kecil | Backend |
| 9 | Backend: Generic pagination, sorting, filter utility | Sedang | Backend |
| 10 | Flutter: Pagination + infinite scroll mixin | Kecil | Frontend |
| 11 | Refactor: Shared error handling pattern (backend + frontend) | Kecil | Shared |

**Deliverable:**
- Layout responsif dengan navigasi berfungsi
- Setiap halaman punya konsistensi loading, empty, error state
- Backend punya pagination utility siap pakai

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Desain UI belum fix | Layout berubah-ubah | Tentukan wireframe di awal sprint; komit pada satu layout dulu |
| Over-engineering component | Waktu habis | Buat komponen yang dibutuhkan sekarang; refactor nanti |

**Estimasi total: 6×3 + 5×1 = 18+5 = 23 poin**

---

### Fase 2: Core Features (Sprint 5–8)

---

#### Sprint 5: Academic — Master Data

| Item | Detail |
|------|--------|
| **Tujuan** | Modul akademik: CRUD master data untuk kelas, mata pelajaran, guru, dan tahun ajaran. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: CRUD Kelas (tingkat, jurusan, wali kelas) | Sedang | Backend |
| 2 | Backend: CRUD Mata Pelajaran (nama, kode, kelompok) | Sedang | Backend |
| 3 | Backend: Assign guru ke mapel | Kecil | Backend |
| 4 | Backend: CRUD Tahun Ajaran + Semester | Kecil | Backend |
| 5 | Backend: Relasi Kelas → Siswa (many-to-many) | Kecil | Backend |
| 6 | Flutter: Kelas page (list, create, edit) | Sedang | Frontend |
| 7 | Flutter: Mapel page (list, create, edit) | Sedang | Frontend |
| 8 | Flutter: Tahun Ajaran page | Kecil | Frontend |
| 9 | Flutter: Assign guru ke mapel — UI | Kecil | Frontend |
| 10 | Backend: Seeder data akademik dummy | Kecil | Backend |
| 11 | Testing: Validation test untuk setiap entity | Kecil | QA |

**Deliverable:**
- Semua master data akademik bisa dikelola via aplikasi
- Relasi antar entity terbentuk (Kelas → Siswa, Guru → Mapel)
- Data dummy siap untuk development sprint berikutnya

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Struktur jurusan tiap sekolah berbeda | Data tidak fleksibel | Buat field `jurusan` sebagai string bebas; tidak pakai enum kaku |
| Relasi kompleks | Query lambat | Gunakan Prisma `include`/`select` dengan hati-hati; hindari N+1 |

**Estimasi total: 4×3 + 5×1 + 1×5 = 12+5+5 = 22 poin** _(sebenarnya? 4 medium + 5 small + 0 besar -> 4×3+5×1=17... OK kita skip besar di sini, semua sedang/kecil)_

**Estimasi total (revisi): 4×3 + 7×1 = 12+7 = 19 poin**

---

#### Sprint 6: Academic — Jadwal Pelajaran

| Item | Detail |
|------|--------|
| **Tujuan** | Sistem jadwal pelajaran: admin bisa membuat jadwal, user bisa melihat jadwal harian/mingguan. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: CRUD Jadwal (hari, jam, kelas, mapel, guru) | Besar | Backend |
| 2 | Backend: Conflict detection (guru/kelas double-booked) | Sedang | Backend |
| 3 | Backend: API jadwal by kelas + by guru + by hari | Sedang | Backend |
| 4 | Backend: Generate jadwal otomatis (algoritma sederhana) | Besar | Backend |
| 5 | Flutter: Schedule grid view (mingguan, per hari) | Besar | Frontend |
| 6 | Flutter: CRUD schedule form (pilih hari, jam, drag-drop) | Besar | Frontend |
| 7 | Flutter: My Schedule page (untuk guru: jadwal ngajar; siswa: jadwal kelas) | Sedang | Frontend |
| 8 | Flutter: Conflict warning UI | Kecil | Frontend |
| 9 | Testing: Conflict detection logic | Kecil | QA |

**Deliverable:**
- Admin bisa membuat jadwal secara manual dengan deteksi konflik
- Guru dan siswa bisa melihat jadwal masing-masing
- Kalender mingguan tampil rapi di Flutter

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Algoritma generate jadwal otomatis sangat kompleks | Tidak selesai dalam 1 sprint | Pindahkan ke post-MVP; sprint ini fokus ke CRUD manual |
| Tampilan grid schedule di Flutter rumit (berbeda jam tiap hari) | UI tidak rapi | Pakai package `table_calendar` atau `syncfusion`; fallback ke ListView jika grid terlalu berat |

**Estimasi total: 3×5 + 3×3 + 2×1 = 15+9+2 = 26 poin**

---

#### Sprint 7: Attendance — QR System

| Item | Detail |
|------|--------|
| **Tujuan** | Sistem presensi berbasis QR code: guru generate QR untuk sesi kelas, siswa scan untuk absen. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: Generate QR token (signed, time-limited) | Sedang | Backend |
| 2 | Backend: Verify QR + record attendance | Sedang | Backend |
| 3 | Backend: CRUD sesi presensi (link ke jadwal) | Sedang | Backend |
| 4 | Backend: API riwayat presensi (by siswa, by kelas, by date) | Sedang | Backend |
| 5 | Backend: Status presensi (hadir, izin, sakit, alpa, terlambat) | Kecil | Backend |
| 6 | Flutter: QR Generator page (guru — tampilkan QR di layar) | Sedang | Frontend |
| 7 | Flutter: QR Scanner page (siswa — scan kamera) | Sedang | Frontend |
| 8 | Flutter: Attendance history page (filter by date, status) | Sedang | Frontend |
| 9 | Flutter: QR refresh otomatis (tiap 30 detik) + animasi | Kecil | Frontend |
| 10 | Flutter: Geo-tagging opsional (lokasi saat scan) | Kecil | Frontend |
| 11 | Backend: Anti-spam (1 scan per sesi per siswa) | Kecil | Backend |
| 12 | Testing: Scan flow E2E (simulasi QR) | Kecil | QA |

**Deliverable:**
- Guru bisa generate QR yang valid 30 detik
- Siswa bisa scan QR dan tercatat presensinya
- Riwayat presensi bisa dilihat dan difilter

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| QR scanner bermasalah di HP lama/gambar kurang jelas | Scan gagal | Sediakan fallback: manual attendance (guru mencentang) |
| Clock drift antara device & server | QR invalid padahal masih masa berlaku | Beri toleransi ±30 detik di backend |

**Estimasi total: 6×3 + 4×1 + 1×5 = 18+4+5 = 27 poin** _(revisi: tidak ada besar -> 6 medium + 4 small = 18+4=22)_

**Estimasi total (revisi): 6×3 + 6×1 = 18+6 = 24 poin**

---

#### Sprint 8: Academic — Jadwal Piket

| Item | Detail |
|------|--------|
| **Tujuan** | Sistem jadwal piket kelas: admin/guru mengatur jadwal piket siswa, siswa bisa melihat giliran piket. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: CRUD Piket (siswa, hari, minggu) | Sedang | Backend |
| 2 | Backend: Rotasi piket otomatis (tiap minggu) | Sedang | Backend |
| 3 | Backend: API piket by kelas + by siswa | Kecil | Backend |
| 4 | Backend: API reminder piket (siapa yg piket hari ini) | Kecil | Backend |
| 5 | Flutter: Picket schedule view (mingguan, per kelas) | Sedang | Frontend |
| 6 | Flutter: My Picket page (jadwal piket saya) | Kecil | Frontend |
| 7 | Flutter: Admin — manage piket (drag-drop siswa) | Sedang | Frontend |
| 8 | Flutter: Picket history / log | Kecil | Frontend |
| 9 | Refactor: Unified calendar component (dipakai jadwal + piket) | Sedang | Frontend |
| 10 | Testing: Rotasi logic unit test | Kecil | QA |

**Deliverable:**
- Admin bisa mengatur jadwal piket dengan drag-drop
- Rotasi piket otomatis setiap minggu
- Siswa bisa melihat kapan jadwal piketnya

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Rotasi otomatis butuh cron job | Infra tambahan | Gunakan Redis scheduler (Bull Queue) di NestJS |
| UI drag-drop memakan waktu | Sprint molor | Pakai package `reorderable_list`; jika tidak cukup waktu, ganti dengan dropdown select |

**Estimasi total: 4×3 + 5×1 + 0×5 = 12+5 = 17 poin**

---

### Fase 3: MVP Launch (Sprint 9–12)

---

#### Sprint 9: Reports & Recap

| Item | Detail |
|------|--------|
| **Tujuan** | Fitur laporan dan rekap: presensi, jadwal, aktivitas akademik. Export PDF/Excel. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: Report — rekap presensi per siswa (bulanan) | Sedang | Backend |
| 2 | Backend: Report — rekap presensi per kelas | Sedang | Backend |
| 3 | Backend: Report — jadwal mingguan (PDF) | Sedang | Backend |
| 4 | Backend: Export ke Excel (presensi, data siswa) | Sedang | Backend |
| 5 | Backend: Aggregation pipeline (Presensi → rekap) | Sedang | Backend |
| 6 | Flutter: Report page — pilih kelas, periode, generate | Sedang | Frontend |
| 7 | Flutter: PDF preview + download | Kecil | Frontend |
| 8 | Flutter: Excel export button | Kecil | Frontend |
| 9 | Flutter: Dashboard statistic widget (kehadiran %) | Kecil | Frontend |
| 10 | Backend: Caching report results (Redis, TTL 1 jam) | Kecil | Backend |

**Deliverable:**
- Report presensi bisa digenerate per siswa & per kelas
- Export PDF dan Excel berfungsi
- Dashboard menampilkan statistik kehadiran

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Report dengan data banyak slow | Timeout | Implementasi pagination + Redis cache; generate async jika perlu |
| PDF generation library bermasalah | Export gagal | Punya fallback: export CSV sederhana |

**Estimasi total: 6×3 + 4×1 = 18+4 = 22 poin**

---

#### Sprint 10: Notification System

| Item | Detail |
|------|--------|
| **Tujuan** | Sistem notifikasi in-app dan reminder. Pemberitahuan jadwal, piket, presensi. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: Notification module (create, list, mark read) | Sedang | Backend |
| 2 | Backend: Schedule reminder cron (jadwal besok, piket hari ini) | Sedang | Backend |
| 3 | Backend: Attendance notification (orang tua dapat notif anak absen) | Kecil | Backend |
| 4 | Backend: WebSocket gateway (real-time notif) | Sedang | Backend |
| 5 | Flutter: Notification service (polling + WebSocket) | Sedang | Frontend |
| 6 | Flutter: Notification bell icon + badge count | Kecil | Frontend |
| 7 | Flutter: Notification list page | Kecil | Frontend |
| 8 | Flutter: Local notification (background) | Kecil | Frontend |
| 9 | Flutter: Deep linking — tap notif → buka halaman terkait | Kecil | Frontend |
| 10 | Testing: Notification delivery test | Kecil | QA |

**Deliverable:**
- Notifikasi muncul real-time via WebSocket
- Reminder jadwal dan piket terkirim otomatis
- Badge notifikasi di app bar

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| WebSocket stabil di dev tapi tidak di staging | Notifikasi tidak realtime | Fallback ke polling tiap 30 detik |
| Firebase Cloud Messaging setup kompleks | Tidak selesai | Skip FCM di MVP; cukup in-app notification + local notification |

**Estimasi total: 4×3 + 5×1 + 0×5 = 12+5 = 17 poin**

---

#### Sprint 11: Testing & Bug Fixing

| Item | Detail |
|------|--------|
| **Tujuan** | Quality assurance menyeluruh. Regression test, bug fixing, performance optimization. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Backend: Unit test coverage (min 70%) | Besar | Backend |
| 2 | Backend: E2E test untuk semua API endpoint | Besar | Backend |
| 3 | Backend: Security audit (JWT, rate limiting, SQL injection) | Sedang | Backend |
| 4 | Backend: Performance profiling — query optimization | Sedang | Backend |
| 5 | Backend: Error logging & monitoring setup (Sentry) | Kecil | Backend |
| 6 | Flutter: Unit test — service, provider, model | Sedang | Frontend |
| 7 | Flutter: Widget test — halaman kritis (login, dashboard) | Sedang | Frontend |
| 8 | Flutter: Integration test — flow end-to-end | Besar | Frontend |
| 9 | Flutter: Performance — list.builder, image caching, rebuild | Sedang | Frontend |
| 10 | Regression: Test semua fitur sprint 1-10 | Sedang | QA |
| 11 | Bug fixing berdasarkan hasil test | Sedang | All |
| 12 | UI/UX polish — konsistensi spacing, typography, color | Sedang | Frontend |

**Deliverable:**
- Coverage report: backend ≥70%, frontend ≥50%
- Semua critical bug fixed
- Aplikasi siap untuk production deployment

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| Bug terlalu banyak | Tidak semua terfix | Prioritaskan critical & high severity; low severity pindah ke backlog |
| Waktu testing kurang | Kualitas menurun | Sprint ini dedicated testing; jangan mulai fitur baru |

**Estimasi total: 3×5 + 7×3 + 1×1 = 15+21+1 = 37 poin**

---

#### Sprint 12: Deployment & Launch

| Item | Detail |
|------|--------|
| **Tujuan** | Deployment ke production, setup monitoring, dokumentasi final. |

**Task List:**

| # | Task | Estimasi | Modul |
|---|------|----------|-------|
| 1 | Setup production server (VPS/Cloud) | Sedang | DevOps |
| 2 | Setup Docker Compose production (PostgreSQL, Redis, MinIO, API) | Sedang | DevOps |
| 3 | Setup reverse proxy (Nginx/Caddy) + SSL (Let's Encrypt) | Kecil | DevOps |
| 4 | Setup CI/CD pipeline (GitHub Actions → deploy) | Sedang | DevOps |
| 5 | Setup database backup (otomatis, harian) | Kecil | DevOps |
| 6 | Setup monitoring (Sentry, Grafana/Prometheus basic) | Sedang | DevOps |
| 7 | Setup domain + DNS (api.smedahebat.sch.id, app.smedahebat.sch.id) | Kecil | DevOps |
| 8 | Setup MinIO production + bucket policy | Kecil | DevOps |
| 9 | Seed data production (sekolah, admin default) | Kecil | Backend |
| 10 | Flutter: Build APK + App Bundle (release) | Kecil | Frontend |
| 11 | Flutter: Setup code signing + Play Console (opsional) | Sedang | Frontend |
| 12 | Dokumentasi: Deployment guide | Kecil | Docs |
| 13 | Dokumentasi: API documentation final (Swagger/Stoplight) | Kecil | Docs |
| 14 | Dokumentasi: User manual (Admin, Guru, Siswa) | Kecil | Docs |
| 15 | Smoke test production | Kecil | QA |
| 16 | Go/No-Go meeting + Launch | Kecil | PM |

**Deliverable:**
- Aplikasi live di production
- Monitoring aktif
- Dokumentasi lengkap

**Risk & Blockers:**
| Risiko | Dampak | Mitigasi |
|--------|--------|----------|
| SSL certificate issue | HTTPS tidak jalan | Gunakan Caddy (auto SSL); test staging lebih dulu |
| Server tidak cukup resource | App lemot | Pilih server dengan min 2GB RAM; monitor di minggu pertama |
| Ada critical bug setelah deploy | User experience buruk | Rollback plan: deploy lama tetap online; fix hotfix dalam 24 jam |

**Estimasi total: 7×3 + 9×1 = 21+9 = 30 poin**

---

## 3. Dependency Graph

### Modul Dependency

```
Sprint 1 (Bootstrap)
    │
    ▼
Sprint 2 (Auth) ──────────────────────────────────────────────┐
    │                                                          │
    ├──► Sprint 3 (User & Role Mgmt)                          │
    │       │                                                  │
    │       └──► Sprint 5 (Academic: Master Data) ────────────┤
    │               │                                          │
    │               ├──► Sprint 6 (Academic: Jadwal) ─────────┤
    │               │       │                                  │
    │               │       └──► Sprint 7 (Attendance: QR) ───┤
    │               │                                           │
    │               └──► Sprint 8 (Academic: Piket) ──────────┤
    │                                                            │
    └──► Sprint 4 (Dashboard Foundation) ──────────────────────┤
            │                                                    │
            └──► Sprint 9 (Reports & Recap) ───────────────────┤
                    │                                            │
                    ├──► Sprint 10 (Notification)               │
                    │                                            │
                    └──► Sprint 11 (Testing) ──────────────────► Sprint 12 (Launch)
```

### Critical Path

```
Sprint 1 → Sprint 2 → Sprint 3 → Sprint 5 → Sprint 6 → Sprint 7 → Sprint 9 → Sprint 10 → Sprint 11 → Sprint 12
```

Jalur kritis ini **tidak boleh molor**. Keterlambatan di salah satu sprint akan langsung berdampak pada tanggal rilis.

### Parallel Tracks

Beberapa modul bisa dikerjakan paralel (jika ada jeda menunggu review, atau backend selesai lebih dulu):

| Track 1 (Backend-heavy) | Track 2 (Frontend-heavy) |
|--------------------------|--------------------------|
| Sprint 5: Backend master data | Sprint 4: Dashboard layout |
| Sprint 6: Backend jadwal | Sprint 6: Tampilan jadwal |
| Sprint 7: Backend QR attendance | Sprint 7: QR scanner UI |
| Sprint 8: Backend piket | Sprint 8: Picket UI |

Karena kamu sendiri, paralelisasi berarti: selesaikan backend suatu modul, lalu kerjakan frontend modul tersebut sambil lanjut backend modul berikutnya.

---

## 4. Risk Register

| ID | Risiko | Probabilitas | Dampak | Level | Mitigasi |
|----|--------|-------------|--------|-------|----------|
| R1 | **Sakit/musibah** — Developer incapacitated 1-2 minggu | Medium | Critical | **HIGH** | Dokumentasi berjalan; handover document; punya emergency buffer 1 sprint |
| R2 | **Scope creep** — Stakeholder minta fitur tambahan di luar MVP | High | High | **HIGH** | Battle-proven scope: semua fitur di luar MVP ditolak sampai launch; catat di backlog |
| R3 | **Teknologi Flutter versi baru bermasalah** — Breaking change | Medium | Medium | **MEDIUM** | Lock Flutter version di `fvm`; jangan upgrade di tengah sprint |
| R4 | **Dependency vulnerability** — Package critical vulnerability | Low | High | **MEDIUM** | Github Dependabot aktif; sempatkan fixed di sprint 11 |
| R5 | **Database migration error** — Data loss di production | Low | Critical | **HIGH** | Backup otomatis; migration diuji di staging dulu; rollback migration plan |
| R6 | **Performa QR scan lambat** — User experience buruk | Medium | Medium | **MEDIUM** | Optimasi kamera (resolution rendah); testing di 5 device berbeda |
| R7 | **Server tidak cukup resource** — App crash saat banyak user | Low | High | **MEDIUM** | Monitoring (CPU, RAM, connection pool); auto-scaling jika budget ada |
| R8 | **Bug critical setelah production launch** — Flow utama error | Medium | Critical | **HIGH** | Hotfix procedure: detect → fix → deploy dalam 24 jam; .env toggle untuk fitur |
| R9 | **Koneksi internet sekolah lambat** — App lemot | High | Medium | **HIGH** | Optimasi payload API; kompresi gambar; implementasi offline-first (Flutter local cache) |
| R10 | **Kurang pengalaman dengan NestJS/Flutter** — Estimasi meleset | High | High | **HIGH** | Buffer tiap sprint (+20% estimasi); learning time dihitung; spike solution untuk bagian paling asing |

### Risk Matrix

```
Dampak
  ▲
C  │ R1  R5  R8
R  │
I  │ R2      R9  R10
T  │
I  │ R3  R6
K  │
A  │         R4
L  │
   └────────────────────► Probabilitas
        Low  Med  High
```

---

## 5. Definition of Done

Setiap sprint dinyatakan **selesai (Done)** jika semua kriteria berikut terpenuhi:

### Kode
- [ ] Semua task dalam sprint selesai (100% code complete)
- [ ] Tidak ada warning ESLint/Prettier
- [ ] Build berhasil (backend `npm run build`, frontend `flutter build`)
- [ ] Tidak ada TypeScript error (backend)
- [ ] Tidak ada Dart analysis issue (frontend `dart analyze`)
- [ ] Unit test untuk logic baru: minimal 1 test per method baru

### API
- [ ] Semua endpoint baru terdaftar dan bisa diakses via Swagger/Postman
- [ ] Response mengikuti format standar (code, message, data, meta)
- [ ] Validasi input di semua endpoint (class-validator / zod)
- [ ] Error handling: semua error ter-tangkap, tidak ada crash 500

### Frontend
- [ ] Halaman baru bisa diakses melalui navigasi
- [ ] Loading state muncul saat fetch data
- [ ] Empty state muncul saat data kosong
- [ ] Error state muncul saat request gagal
- [ ] Responsive di handphone (360px ke atas)

### Testing
- [ ] Backend: unit test pass (`npm run test`)
- [ ] Frontend: minimal widget test untuk halaman baru
- [ ] Manual smoke test: flow utama berfungsi (tidak harus E2E otomatis)

### Dokumentasi
- [ ] README diupdate jika ada perubahan cara running
- [ ] API documented (Swagger decorator sudah ditambahkan)
- [ ] Environment variable baru dicatat di .env.example

### Code Review
- [ ] (Walaupun sendiri) PR dibuat dan di-merge setelah review diri sendiri
- [ ] Commit messages mengikuti conventional commits (feat:, fix:, chore:, etc.)

### Deploy
- [ ] Staging deployment berhasil (docker compose up without error)
- [ ] Database migration berjalan tanpa error
- [ ] Feature flag untuk fitur baru (jika belum siap publik)

---

## Lampiran: Estimasi Guide

| Estimasi | Poin | Arti |
|----------|------|------|
| **Kecil** | 1 | 2-4 jam, task jelas, tanpa riset |
| **Sedang** | 3 | 1-2 hari, butuh riset ringan, kompleksitas sedang |
| **Besar** | 5 | 3-5 hari, butuh riset, integrasi kompleks |

**Total estimasi sepanjang 12 sprint:**

| Sprint | Total Poin |
|--------|-----------|
| 1 | 22 |
| 2 | 33 |
| 3 | 24 |
| 4 | 23 |
| 5 | 19 |
| 6 | 26 |
| 7 | 24 |
| 8 | 17 |
| 9 | 22 |
| 10 | 17 |
| 11 | 37 |
| 12 | 30 |
| **Total** | **294 poin** |

> **Catatan:** Dengan 12 sprint × 5 hari kerja, rata-rata perlu ~4,9 poin per hari. Jika 1 developer bekerja efektif 6 jam/hari, estimasi ini cukup realistis dengan buffer ~15% untuk hal tak terduga.

---

*Dokumen ini living document — update setiap akhir sprint berdasarkan retrospective.*
