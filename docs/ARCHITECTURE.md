# ARSITEKTUR SISTEM — SMEDA HEBAT: Digital School Operating System

Dokumen ini menjelaskan arsitektur sistem secara menyeluruh untuk platform SMEDA HEBAT, sebuah sistem operasi sekolah digital yang dibangun dengan pendekatan monorepo menggunakan Turborepo.

---

## Daftar Isi

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Monorepo Structure (Turborepo)](#2-monorepo-structure-turborepo)
3. [Backend Architecture (NestJS)](#3-backend-architecture-nestjs)
4. [Database Architecture](#4-database-architecture)
5. [API Design](#5-api-design)
6. [Flutter Architecture](#6-flutter-architecture)
7. [Security Architecture](#7-security-architecture)
8. [Offline Strategy](#8-offline-strategy)
9. [Deployment Architecture](#9-deployment-architecture)

---

## 1. System Architecture Overview

### Diagram Arsitektur (High-Level)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MOBILE CLIENTS                               │
│                   (Flutter - Android / iOS)                         │
└────────────────────────┬────────────────────────────────────────────┘
                         │ HTTPS / WSS
                         ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      NGINX REVERSE PROXY                            │
│                   (SSL Termination / Load Balancing)                 │
└──────────┬──────────────────────────────┬───────────────────────────┘
           │                              │
           ▼                              ▼
┌────────────────────┐     ┌──────────────────────────────┐
│   STATIC / CDN     │     │     API GATEWAY (NestJS)      │
│ (Flutter Web, doc) │     │  ┌────────────────────────┐  │
└────────────────────┘     │  │  /api/v1/*              │  │
                           │  │  /ws/* (WebSocket)      │  │
                           │  │  /auth/*                │  │
                           │  └────────────────────────┘  │
                           └──────────┬───────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BACKEND SERVICE (NestJS Monolith)                 │
│                                                                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐  │
│  │ Auth    │ │ Academic│ │ Finance │ │ HR      │ │ Notification │  │
│  │ Module  │ │ Module  │ │ Module  │ │ Module  │ │ Module       │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └──────┬───────┘  │
│       │           │           │           │              │          │
│       └───────────┴───────────┴───────────┴──────────────┘          │
│                           │                                         │
│                    ┌──────┴───────┐                                 │
│                    │ Event Bus    │                                 │
│                    │ (EventEmitter│                                 │
│                    │  + Bull)     │                                 │
│                    └──────┬───────┘                                 │
└───────────────────────────┼─────────────────────────────────────────┘
                            │
          ┌─────────────────┼──────────────────────┐
          ▼                 ▼                      ▼
┌──────────────┐  ┌──────────────┐  ┌────────────────────┐
│  PostgreSQL   │  │    Redis     │  │    Meilisearch     │
│  (Primary DB) │  │  (Cache+Queue)│  │   (Full-text Search)│
└──────────────┘  └──────────────┘  └────────────────────┘
                            │
                            ▼
                  ┌────────────────────┐
                  │   MinIO / AWS S3    │
                  │   (File Storage)    │
                  └────────────────────┘
```

### Alur Request

1. **Mobile App** mengirim request HTTPS ke domain utama (contoh: `api.smedahebat.sch.id`).
2. **Nginx** menerima request, melakukan SSL termination, dan meneruskan ke **NestJS API Gateway**.
3. **NestJS Guard** memvalidasi JWT token (jika endpoint dilindungi).
4. **NestJS Controller** menerima request dan meneruskannya ke **Service Layer**.
5. **Service Layer** menjalankan logika bisnis, berinteraksi dengan **Repository Layer** (Prisma) untuk query ke PostgreSQL.
6. Data yang sering diakses (contoh: daftar kelas, profil siswa) di-cache di **Redis**.
7. Untuk operasi yang berat (contoh: generate rapor, kirim notifikasi massal), service mengirim **job** ke **Bull Queue** (Redis backend) — diproses secara async oleh **Worker**.
8. Pencarian teks (contoh: cari siswa, buku perpustakaan) dialihkan ke **Meilisearch**.
9. File (contoh: foto profil, dokumen) diunggah langsung atau melalui backend ke **S3-compatible storage**.
10. **Response** dikembalikan dalam format JSON standar melalui jalur yang sama.

### Event-Driven Architecture

SMEDA HEBAT menggunakan pola **Event-Driven** untuk menangani operasi yang membutuhkan decoupling antar modul.

**Event Bus Lokal (EventEmitter2):**
- Digunakan untuk event intra-process yang cepat — contoh: saat siswa baru didaftarkan, module Academic mengemit event `student.registered` yang didengar oleh module Finance (untuk membuat tagihan awal) dan module HR (untuk assign wali kelas).

**Event Bus Eksternal (Bull Queue + Redis):**
- Digunakan untuk job yang perlu diproses secara async atau di-retry jika gagal.
- Contoh event: `notification.send`, `report.generate`, `backup.database`, `sync.offline`.

```
┌──────────┐   emit: academic.grade.published   ┌────────────┐
│ Academic │ ───────────────────────────────────► │   Event    │
│ Module   │                                     │    Bus     │
└──────────┘                                     └───┬───┬────┘
                                                      │   │
                          ┌───────────────────────────┘   └─────────┐
                          ▼                                       ▼
                  ┌──────────────┐                       ┌──────────────┐
                  │ Notification │                       │  Reporting   │
                  │ Module       │                       │  Module      │
                  └──────────────┘                       └──────────────┘
                  Kirim push notifikasi                  Generate rapor
                  ke orang tua siswa                     PDF & kirim email
```

**Keuntungan Event-Driven:**
- Decoupling: setiap module tidak perlu tahu implementasi module lain.
- Scalability: event bisa diproses secara parallel oleh multiple workers.
- Reliability: Bull Queue menyediakan retry mechanism, job persistence, dan rate limiting.
- Auditable: semua event tercatat, memudahkan debugging dan audit trail.

---

## 2. Monorepo Structure (Turborepo)

### Struktur Direktori

```
smedahebat/
├── apps/
│   ├── mobile/                          # Flutter application
│   │   ├── lib/
│   │   │   ├── core/                    # Core utilities, themes, constants
│   │   │   ├── data/                    # Data layer (repositories, datasources)
│   │   │   ├── domain/                  # Domain layer (entities, usecases)
│   │   │   └── presentation/            # UI layer (pages, widgets, providers)
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── api/                             # NestJS backend application
│       ├── src/
│       │   ├── modules/                 # Feature modules
│       │   ├── common/                  # Shared utilities, guards, filters
│       │   ├── config/                  # Configuration module
│       │   └── main.ts                  # Entry point
│       ├── test/
│       ├── prisma/                      # Prisma schema & migrations
│       └── package.json
│
├── packages/
│   ├── shared/                          # Shared TypeScript types & interfaces
│   │   ├── src/
│   │   │   ├── types/
│   │   │   ├── interfaces/
│   │   │   ├── enums/
│   │   │   └── dto/
│   │   └── package.json
│   │
│   ├── config/                          # Shared configurations
│   │   ├── eslint-preset/               # ESLint config
│   │   ├── typescript-config/           # TypeScript base config
│   │   └── jest-preset/                 # Jest test config
│   │
│   └── database/                        # Database package
│       ├── prisma/
│       │   ├── schema.prisma            # Main schema
│       │   ├── migrations/              # Migration files
│       │   └── seeds/                   # Seed scripts
│       └── src/
│           ├── client.ts                # Prisma client singleton
│           └── utils/
│
├── docker/
│   ├── Dockerfile.api                   # NestJS production image
│   ├── Dockerfile.mobile                # Flutter build image
│   ├── nginx/
│   │   └── nginx.conf                   # Nginx configuration
│   └── docker-compose.yml               # All services orchestration
│
├── .github/
│   └── workflows/
│       ├── ci.yml                       # CI pipeline
│       └── cd.yml                       # CD pipeline
│
├── docs/                                # Documentation
├── turbo.json                           # Turborepo pipeline config
└── package.json                         # Root package.json
```

### Turborepo Pipeline (turbo.json)

```json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "build/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "dev": {
      "cache": false,
      "dependsOn": ["^build"]
    },
    "db:migrate": {
      "cache": false,
      "dependsOn": ["build"]
    },
    "db:seed": {
      "cache": false,
      "dependsOn": ["db:migrate"]
    }
  }
}
```

**Keuntungan Monorepo dengan Turborepo:**
- **Caching:** Turborepo secara otomatis me-cache output build. Jika source code tidak berubah, build di-skip dan menggunakan cache — menghemat waktu CI/CD drastis.
- **Parallel Execution:** Pipeline tasks dijalankan secara parallel sesuai dependency graph.
- **Shared Packages:** Tipe, konfigurasi, dan schema database di-share antara backend dan package lainnya tanpa perlu publish ke registry eksternal.
- **Atomic Changes:** Satu commit bisa mencakup perubahan yang melintasi backend dan shared types tanpa risiko version mismatch.

---

## 3. Backend Architecture (NestJS)

### Modular Monolith

SMEDA HEBAT menggunakan pendekatan **Modular Monolith** di NestJS. Semua module berada dalam satu proses deployment, tetapi dipisahkan secara logis dan terisolasi — memudahkan refactoring ke microservices di masa depan jika diperlukan.

### Daftar Module dan Dependensi

```
┌─────────────────────────────────────────────────────────────────────┐
│                           API APPLICATION                           │
│                                                                      │
│  ┌────────────┐    ┌─────────────────┐    ┌──────────────────────┐  │
│  │ AuthModule │    │ AcademicModule   │    │ FinanceModule        │  │
│  │            │    │                  │    │                      │  │
│  │ - JWT      │    │ - Kelas          │    │ - Pembayaran SPP     │  │
│  │ - OTP      │    │ - Jadwal         │    │ - Tagihan            │  │
│  │ - RBAC     │    │ - Nilai & Raport │    │ - Laporan Keuangan   │  │
│  │ - Session  │    │ - Presensi       │    │ - Buku Kas           │  │
│  └─────┬──────┘    │ - Kurikulum      │    └──────────┬───────────┘  │
│        │           └────────┬─────────┘               │              │
│        ▼                    ▼                         ▼              │
│  ┌────────────┐    ┌─────────────────┐    ┌──────────────────────┐  │
│  │ HRModule   │    │ LibraryModule   │    │ CommunicationModule  │  │
│  │            │    │                 │    │                      │  │
│  │ - Guru     │    │ - Buku          │    │ - Announcement       │  │
│  │ - Siswa    │    │ - Peminjaman    │    │ - Chat (WebSocket)   │  │
│  │ - Pegawai  │    │ - Katalog       │    │ - Diskusi Kelas      │  │
│  │ - Unit     │    └────────┬────────┘    └──────────┬───────────┘  │
│  └─────┬──────┘             │                        │              │
│        │                    │                        │              │
│        ▼                    ▼                        ▼              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  NotificationModule     │   ReportingModule                  │   │
│  │  - Push (FCM)           │   - Generate PDF (Rapor, Sertifikat)│   │
│  │  - Email (Nodemailer)   │   - Export Excel/CSV               │   │
│  │  - In-app notification  │   - Dashboard Analytics            │   │
│  └─────────────────────────┴────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Shared Modules:                                              │   │
│  │  - DatabaseModule (Prisma)    - RedisModule                   │   │
│  │  - QueueModule (Bull)         - StorageModule (S3)           │   │
│  │  - SearchModule (Meilisearch) - WebSocketModule               │   │
│  │  - EventEmitterModule          - ConfigModule                 │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Layer Architecture (Per Module)

Setiap module mengikuti struktur 3-layer yang ketat:

```
Module/
├── controllers/
│   └── siswa.controller.ts          # Handling HTTP request/response
├── services/
│   └── siswa.service.ts             # Business logic
├── repositories/
│   └── siswa.repository.ts          # Database interaction (Prisma)
├── guards/
│   └── roles.guard.ts               # Authorization rules
├── interceptors/
│   └── siswa.interceptor.ts         # Request/response transformation
├── filters/
│   └── http-exception.filter.ts     # Error handling
├── dto/
│   ├── create-siswa.dto.ts          # Request validation
│   └── update-siswa.dto.ts
├── types/
│   └── siswa.types.ts               # Module-specific types
├── events/
│   ├── siswa-created.event.ts       # Event definition
│   └── siswa-created.handler.ts     # Event handler
└── module.ts
│   └── siswa.module.ts              # Module definition

Contoh dependency injection chain:

Controller (HTTP) → Service (Business Logic) → Repository (Prisma) → PostgreSQL
```

### Guard / Interceptor / Filter Setup

**Global Guards:**
- `JwtAuthGuard` — Validasi access token di setiap request (kecuali endpoint publik seperti login).
- `RolesGuard` — Cek role user berdasarkan RBAC.
- `ThrottlerGuard` — Rate limiting per IP/user.

**Global Interceptors (urutan eksekusi dari luar ke dalam):**
1. `LoggingInterceptor` — Mencatat request/response (method, URL, duration, status code).
2. `TransformInterceptor` — Membungkus response ke format standar `{ success, data, meta, timestamp }`.
3. `CacheInterceptor` — Mengambil data dari Redis cache (hanya untuk GET requests yang di-cache).
4. `TimeoutInterceptor` — Memutus koneksi jika request melebihi batas waktu (30 detik).

**Global Filters:**
- `AllExceptionsFilter` — Menangkap semua exception dan mengembalikan format error standar.
- `ValidationFilter` — Menangani error dari class-validator (DTO validation).

### Event-Driven Setup

NestJS EventEmitter2 digunakan untuk komunikasi intra-module dan cross-module:

```typescript
// events/siswa-created.event.ts
export class SiswaCreatedEvent {
  constructor(
    public readonly siswaId: string,
    public readonly sekolahId: string,
    public readonly kelasId: string,
  ) {}
}

// students.service.ts
@Injectable()
export class SiswaService {
  constructor(private eventEmitter: EventEmitter2) {}

  async create(dto: CreateSiswaDto) {
    const siswa = await this.repository.create(dto);

    this.eventEmitter.emit(
      'siswa.created',
      new SiswaCreatedEvent(siswa.id, siswa.sekolahId, siswa.kelasId),
    );

    return siswa;
  }
}

// finance.module.ts
@Injectable()
export class FinanceEventHandler {
  @OnEvent('siswa.created')
  async handleSiswaBaru(event: SiswaCreatedEvent) {
    // Buat tagihan SPP awal untuk siswa baru
    await this.tagihanService.buatTagihanAwal(event.siswaId);
  }
}
```

Untuk job berat, Bull Queue digunakan:

```typescript
@Processor('notification')
export class NotificationWorker {
  @Process('send-bulk-push')
  async handleSendBulkPush(job: Job) {
    const { userIds, title, body } = job.data;
    await this.fcmService.sendToMultiple(userIds, { title, body });
  }
}
```

---

## 4. Database Architecture

### PostgreSQL sebagai Primary Database

PostgreSQL dipilih karena:
- **Reliability:** ACID compliance penuh — kritis untuk data keuangan dan akademik.
- **Feature-rich:** Dukungan JSONB untuk data semi-structured, Array, Full-Text Search (walaupun Meilisearch untuk production).
- **Concurrency:** MVCC (Multi-Version Concurrency Control) menangani ribuan koneksi simultan dari seluruh siswa/guru di sekolah.
- **Extension:** PostGIS untuk fitur geografis (misal: mapping sekolah), pg_cron untuk scheduled tasks.

### Prisma ORM

Prisma digunakan sebagai ORM dengan alasan:
- **Type Safety:** Semua query di-type-check oleh TypeScript — mengurangi runtime error.
- **Auto-generated Client:** Prisma Client di-generate dari schema, memberikan autocomplete penuh.
- **Migration:** Prisma Migrate menangani version control database.
- **Performance:** Prisma menggunakan binary engine yang optimized.

### Entity Relationship Overview

Berikut adalah entitas utama (deskripsi tekstual, diagram ERD penuh ada di file terpisah):

```
SEKOLAH (School)
├── id: UUID (PK)
├── nama, npsn, alamat, telepon, email
├── status: NEGERI / SWASTA
├── jenjang: SD / SMP / SMA / SMK
├── logo_url, akreditasi
└── relasi: hasMany USER, hasMany KELAS, hasMany TAHUN_AJARAN

USER (Pengguna — polymorphic via role)
├── id: UUID (PK)
├── sekolahId: UUID (FK → SEKOLAH)
├── role: ADMIN_SEKOLAH / GURU / SISWA / ORANG_TUA / PEGAWAI
├── email, password_hash, no_telepon
├── foto_profile_url
├── is_active: boolean
├── last_login: timestamp
└── one-to-one dengan: GURU / SISWA / ORANG_TUA / PEGAWAI (tergantung role)

KELAS (Class)
├── id: UUID (PK)
├── sekolahId: UUID (FK → SEKOLAH)
├── nama: "7A", "XII IPA 1"
├── tingkat: 1-12 (atau sesuai jenjang)
├── tahunAjaranId: UUID (FK → TAHUN_AJARAN)
├── waliKelasId: UUID (FK → GURU)
├── kapasitas: integer
└── relasi: hasMany SISWA, hasMany JADWAL_PELAJARAN

SISWA (Student)
├── id: UUID (PK)
├── userId: UUID (FK → USER, unique)
├── kelasId: UUID (FK → KELAS)
├── nis, nisn (unique)
├── nama_lengkap, tempat_lahir, tanggal_lahir
├── jenis_kelamin, agama, alamat
└── relasi: hasMany NILAI, hasMany PRESENSI, hasMany TAGIHAN

GURU (Teacher)
├── id: UUID (PK)
├── userId: UUID (FK → USER, unique)
├── nip (unique)
├── nama_lengkap, nuptk
├── mata_pelajaran_utama
├── status_kepegawaian: PNS / PPPK / HONORER
└── relasi: hasMany MATA_PELAJARAN, hasMany KELAS (as wali kelas)

MATA_PELAJARAN (Subject)
├── id: UUID (PK)
├── sekolahId: UUID (FK → SEKOLAH)
├── nama: "Matematika", "Bahasa Indonesia"
├── kode: "MTK-7A"
├── kelompok: A (Wajib) / B (Muatan Lokal) / C (Peminatan)
├── kkm: decimal (Kriteria Ketuntasan Minimal)
└── relasi: many-to-many GURU via GURU_MAPEL

JADWAL_PELAJARAN (Schedule)
├── id: UUID (PK)
├── kelasId: UUID (FK → KELAS)
├── mataPelajaranId: UUID (FK → MATA_PELAJARAN)
├── guruId: UUID (FK → GURU)
├── hari: ENUM (Senin - Sabtu)
├── jam_mulai: time, jam_selesai: time
├── ruangan: varchar
└── unique constraint: (kelasId, hari, jam_mulai, ruangan)

NILAI (Grade)
├── id: UUID (PK)
├── siswaId: UUID (FK → SISWA)
├── mataPelajaranId: UUID (FK → MATA_PELAJARAN)
├── tahunAjaranId: UUID (FK → TAHUN_AJARAN)
├── semester: 1 / 2
├── jenis: TUGAS / UTS / UAS / PRAKTIK / SIKAP
├── nilai: decimal
├── bobot: integer (untuk perhitungan nilai akhir)
└── relasi: hasMany ke detail penilaian

PRESENSI (Attendance)
├── id: UUID (PK)
├── siswaId: UUID (FK → SISWA)
├── jadwalId: UUID (FK → JADWAL_PELAJARAN)
├── tanggal: date
├── status: HADIR / SAKIT / IZIN / ALFA / TERLAMBAT
├── jam_masuk: timestamp
├── keterangan: text
└── unique constraint: (siswaId, jadwalId, tanggal)

TAGIHAN (Invoice / Fee)
├── id: UUID (PK)
├── siswaId: UUID (FK → SISWA)
├── jenis: SPP / DAFTAR_ULANG / KEGIATAN / SERAGAM / BUKU
├── jumlah: decimal
├── jatuh_tempo: date
├── status: BELUM_DIBAYAR / LUNAS / ANGSURAN / DIBATALKAN
├── denda: decimal
└── relasi: hasMany PEMBAYARAN

PEMBAYARAN (Payment)
├── id: UUID (PK)
├── tagihanId: UUID (FK → TAGIHAN)
├── metode: TUNAI / TRANSFER / VA / QRIS
├── jumlah: decimal
├── tanggal_bayar: timestamp
├── reference: varchar (dari payment gateway)
├── bukti_url: varchar
└── dicatat_oleh: UUID (FK → USER, untuk admin/guru)
```

### Migration Strategy

- **Development:** `prisma migrate dev` — auto-generate migration dari perubahan schema, langsung terapkan ke database lokal.
- **Staging/Production:** `prisma migrate deploy` — hanya menjalankan migration yang belum dijalankan (safe untuk production).
- **Naming Convention:** `YYYYMMDDHHMMSS_description_of_change` — Prisma secara otomatis menamai file migration dengan timestamp.
- **Review Process:** Setiap perubahan schema harus melalui code review. Migration file di-commit ke repository.
- **Rollback:** Jika migration bermasalah di production, gunakan `prisma migrate resolve` untuk menandai migration sebagai sudah dijalankan (atau rollback manual dengan restore database dari backup).
- **Seed Data:** Data master (seperti daftar provinsi/kota, tipe tagihan default) di-seed menggunakan `prisma db seed`.

### Indexing Strategy

```prisma
model Siswa {
  id            String   @id @default(uuid())
  nis           String   @unique
  nisn          String   @unique
  namaLengkap   String
  kelasId       String
  sekolahId     String

  @@index([kelasId])
  @@index([sekolahId])
  @@index([namaLengkap])
  @@index([kelasId, sekolahId])
}

model Nilai {
  id               String @id @default(uuid())
  siswaId          String
  mataPelajaranId  String
  tahunAjaranId    String
  semester         Int

  @@index([siswaId, mataPelajaranId, tahunAjaranId, semester])
  @@index([mataPelajaranId, tahunAjaranId, semester])
}

model Presensi {
  id             String   @id @default(uuid())
  siswaId        String
  jadwalId       String
  tanggal        DateTime @db.Date
  status         PresensiStatus

  @@unique([siswaId, jadwalId, tanggal])
  @@index([tanggal])
  @@index([status])
  @@index([siswaId, tanggal])
}

model Tagihan {
  id        String   @id @default(uuid())
  siswaId   String
  jenis     JenisTagihan
  status    StatusTagihan
  jatuhTempo DateTime @db.Date

  @@index([siswaId, status])
  @@index([status, jatuhTempo])
  @@index([jenis, status])
}
```

**Prinsip Indexing:**
1. Index pada kolom yang sering muncul di `WHERE`, `JOIN`, dan `ORDER BY`.
2. Composite index untuk query multi-kolom (contoh: pencarian nilai berdasarkan siswa + mapel + semester).
3. Unique constraint untuk kolom yang harus unik (nis, nisn, nip, email) — sekaligus membuat index.
4. Partial index untuk data yang jarang diquery (contoh: hanya tagihan dengan status `BELUM_DIBAYAR`).
5. Hindari over-indexing — terlalu banyak index memperlambat write.

---

## 5. API Design

### RESTful API Design Principles

- **Resource-oriented:** Endpoint merepresentasikan resource (`/siswa`, `/kelas`, `/nilai`).
- **HTTP Methods:** GET (baca), POST (buat), PATCH (ubah partial), DELETE (hapus).
- **Plural Nouns:** `/api/v1/siswa`, bukan `/api/v1/siswa-list`.
- **Sub-resource:** `/api/v1/kelas/:kelasId/siswa` untuk relasi.
- **Consistent Naming:** Snake case untuk query params (`page_size`), kebab-case untuk URL (`/tahun-ajaran`).

### Base URL Structure

```
Production:  https://api.smedahebat.sch.id/api/v1/
Staging:     https://staging-api.smedahebat.sch.id/api/v1/
Local:       http://localhost:3000/api/v1/
```

### Authentication: JWT (Access + Refresh Token)

```
POST /api/v1/auth/login
  Body: { email, password }
  Response: {
    access_token: "eyJhbGciOiJIUzI1NiIs...",
    refresh_token: "dGhpcyBpcyBhIHJlZnJl...",
    expires_in: 900,        // 15 menit
    user: { id, name, role, sekolahId }
  }

POST /api/v1/auth/refresh
  Body: { refresh_token }
  Response: { access_token, refresh_token, expires_in }

POST /api/v1/auth/logout
  Header: Authorization: Bearer <access_token>
  // Revoke refresh token di database
```

**Token Storage di Mobile:**
- Access token: disimpan di memory (in-memory state management) — tidak di persistent storage.
- Refresh token: disimpan di secure storage (flutter_secure_storage) — encrypted di Android Keystore / iOS Keychain.

**Token Lifecycle:**
- Access token expires dalam 15 menit.
- Refresh token expires dalam 7 hari.
- Setiap kali access token expires, Flutter interceptor otomatis memanggil `/auth/refresh` untuk mendapatkan token baru.
- Jika refresh token juga expired, user di-redirect ke halaman login.

### Response Format Standar

**Sukses (200/201):**
```json
{
  "success": true,
  "data": {
    "id": "uuid-siswa-123",
    "nama": "Ahmad Fauzi",
    "nis": "12345",
    "kelas": { "id": "uuid-kelas", "nama": "7A" }
  },
  "meta": {
    "timestamp": "2026-07-24T10:30:00Z",
    "requestId": "req-abc123"
  }
}
```

**List dengan Pagination (200):**
```json
{
  "success": true,
  "data": [
    { "id": "uuid-1", "nama": "Siswa 1" },
    { "id": "uuid-2", "nama": "Siswa 2" }
  ],
  "meta": {
    "page": 1,
    "pageSize": 10,
    "totalItems": 150,
    "totalPages": 15,
    "hasNextPage": true,
    "hasPreviousPage": false,
    "timestamp": "2026-07-24T10:30:00Z",
    "requestId": "req-abc123"
  }
}
```

### Error Handling Format

**Error (4xx/5xx):**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data yang dikirim tidak valid",
    "details": [
      { "field": "email", "message": "Email harus berupa alamat email yang valid" },
      { "field": "password", "message": "Password minimal 8 karakter" }
    ]
  },
  "meta": {
    "timestamp": "2026-07-24T10:30:00Z",
    "requestId": "req-abc123"
  }
}
```

**Standard Error Codes:**
| HTTP Status | Code | Deskripsi |
|-------------|------|-----------|
| 400 | `VALIDATION_ERROR` | Validasi input gagal |
| 401 | `UNAUTHORIZED` | Token tidak valid / expired |
| 403 | `FORBIDDEN` | Tidak punya akses ke resource |
| 404 | `NOT_FOUND` | Resource tidak ditemukan |
| 409 | `CONFLICT` | Data duplikat / conflict |
| 422 | `UNPROCESSABLE_ENTITY` | Data valid tapi tidak bisa diproses |
| 429 | `RATE_LIMIT_EXCEEDED` | Terlalu banyak request |
| 500 | `INTERNAL_ERROR` | Server error (jangan expose detail) |

### Pagination, Filtering, Sorting

**Query Parameters:**

```
GET /api/v1/siswa?page=1&page_size=20&search=ahmad&filter[kelas]=7A&sort=-created_at&include=kelas

Parameter:
  page        = 1 (default)
  page_size   = 10 (default), max 100
  search      = Pencarian teks (full-text, via Meilisearch)
  filter      = Filter spesifik: filter[kelas]=7A&filter[jenis_kelamin]=L
  sort        = Sorting: sort=nama (ascending), sort=-nama (descending)
  include     = Relasi: include=kelas,kelas.waliKelas
  fields      = Kolom spesifik: fields=id,nama,nis
```

**Response Header untuk Rate Limiting:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1627054200
```

---

## 6. Flutter Architecture

### Clean Architecture Layers

SMEDA HEBAT menggunakan **Clean Architecture** yang diadaptasi untuk Flutter, memisahkan kode menjadi 3 lapisan utama:

```
lib/
├── core/                          # Lapisan Core — utilities dan shared resources
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── utils/
│   └── widgets/                   # Shared widgets (buttons, textfields, dll)
│
├── data/                          # Lapisan Data — implementasi teknis
│   ├── datasources/
│   │   ├── remote/                # API calls (Dio)
│   │   └── local/                 # Local DB (drift/floor), SharedPreferences
│   ├── models/                    # Data models (JSON serialization)
│   ├── repositories/              # Implementasi domain repository
│   └── providers/                 # Riverpod providers untuk data layer
│
├── domain/                        # Lapisan Domain — aturan bisnis murni
│   ├── entities/                  # Business objects (tanpa dependensi framework)
│   ├── repositories/              # Abstract repository interfaces
│   └── usecases/                  # Use cases (business logic)
│
├── presentation/                  # Lapisan Presentasi — UI
│   ├── features/
│   │   ├── auth/
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   └── providers/         # Riverpod state notifier
│   │   ├── dashboard/
│   │   ├── akademik/
│   │   ├── keuangan/
│   │   └── ... (fitur lainnya)
│   └── router/
│       └── app_router.dart        # GoRouter configuration
│
├── app.dart                       # MaterialApp + ProviderScope
└── main.dart                      # Entry point
```

### Alur Data (Dependency Rule)

```
UI (Widgets)
    │  membaca state via Riverpod ref.watch()
    ▼
Provider (Riverpod StateNotifier / AsyncNotifier)
    │  memanggil UseCase / langsung ke Repository
    ▼
UseCase (Domain) — OPSIONAL, untuk logika kompleks
    │  memanggil Repository (abstract)
    ▼
RepositoryImpl (Data) — implementasi konkret
    │  memilih: RemoteDataSource / LocalDataSource
    ▼
RemoteDataSource → Dio (HTTP) → NestJS API
LocalDataSource  → drift/floor (SQLite) → Local Database
```

**Aturan Ketat Clean Architecture:**
- `domain` tidak boleh mengimpor apapun dari `data` atau `presentation`.
- `data` mengimpor `domain` (mengimplementasikan abstract repository).
- `presentation` mengimpor `domain` (entities, usecases) dan `data` (providers).
- Semua dependensi mengarah ke dalam (menuju domain).

### State Management: Riverpod

**Pilihan: Riverpod** — dengan alasan:

| Aspek | Riverpod | BLoC | Alasan Riverpod |
|-------|----------|------|-----------------|
| Boilerplate | Rendah | Tinggi | Riverpod: hanya perlu `StateNotifier` + `Provider`. BLoC: perlu Event, State, Bloc class terpisah. Untuk startup dengan tim kecil, Riverpod lebih produktif. |
| Compile-safe | Ya | Ya | Keduanya type-safe, tetapi Riverpod tidak bergantung pada BuildContext — bisa diakses di mana saja. |
| Testability | Sangat Baik | Baik | Riverpod memungkinkan override provider di test tanpa mock complex. |
| Learning Curve | Sedang | Sedang-Tinggi | BLoC memiliki konsep Stream/Event yang lebih abstrak. Riverpod lebih intuitif untuk developer yang familiar dengan React hooks. |
| Performance | Excellent | Excellent | Keduanya performant. Riverpod menggunakan `ref.watch` granular — hanya rebuild widget yang dependensinya berubah. |

**Penggunaan Riverpod di SMEDA HEBAT:**

```dart
// 1. Define StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial());

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    final result = await _authRepository.login(email, password);
    state = result.fold(
      (failure) => AuthState.error(failure),
      (user) => AuthState.authenticated(user),
    );
  }
}

// 2. Define Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// 3. Use in Widget
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return authState.when(
      initial: () => LoginForm(),
      loading: () => const LoadingOverlay(),
      authenticated: (user) => const DashboardPage(),
      error: (error) => ErrorScreen(error),
    );
  }
}
```

### Offline-First dengan drift (SQLite)

**Pilihan: drift** (dulu bernama moor) — alasan:
- Type-safe SQL queries (generated code).
- Mendukung migrations, transactions, DAO pattern.
- Performa lebih baik daripada Hive untuk data relasional.
- Mendukung complex queries (JOIN, subquery) — penting untuk data akademik.

**Arsitektur Offline:**

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                          │
│  ┌──────────────────────┐     ┌──────────────────────┐  │
│  │  RemoteDataSource    │     │  LocalDataSource     │  │
│  │  (Dio → NestJS API)  │     │  (drift → SQLite)    │  │
│  └──────────┬───────────┘     └──────────┬───────────┘  │
│             │                            │              │
│             ▼                            ▼              │
│  ┌──────────────────────────────────────────────────┐   │
│  │           Sync Manager (Queue-based)             │   │
│  │  - Online mode: tulis ke remote + local          │   │
│  │  - Offline mode: tulis ke local + queue          │   │
│  │  - Kembali online: flush queue ke remote         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

**Flow Operasi Write (misal: input nilai):**
1. User menekan "Simpan Nilai" — app berada dalam mode offline.
2. Data nilai disimpan ke SQLite (local) terlebih dahulu.
3. Operasi dimasukkan ke **Sync Queue** (tabel SQLite khusus): `{ operation: "CREATE_NILAI", data: {...}, timestamp, retry_count }`.
4. Saat koneksi kembali, **Sync Manager** mengambil antrian dari queue (urutan kronologis).
5. Setiap operasi dikirim ke API. Jika sukses, hapus dari queue. Jika gagal (conflict), resolusi konflik dijalankan.
6. UI mendapat feedback real-time melalui Stream dari database lokal.

### Network Layer (Dio)

Konfigurasi Dio mencakup:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.smedahebat.sch.id/api/v1/',
  connectTimeout: 10000,
  receiveTimeout: 15000,
  headers: { 'Content-Type': 'application/json' },
));

// Interceptor: Auth token
dio.interceptors.add(AuthInterceptor(
  tokenStorage: secureStorage,
  onTokenExpired: () async {
    // Refresh token otomatis
    final newToken = await authRepository.refreshToken();
    return newToken;
  },
));

// Interceptor: Logging & retry
dio.interceptors.add(RetryInterceptor(
  retries: 3,
  retryDelays: [1, 2, 3].map((s) => Duration(seconds: s)).toList(),
));
```

### Route Design (GoRouter)

```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isAuthenticated;
    final isOnAuthPage = state.matchedLocation.startsWith('/auth');

    if (!isLoggedIn && !isOnAuthPage) return '/auth/login';
    if (isLoggedIn && isOnAuthPage) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordPage()),
    ShellRoute(
      builder: (_, __, child) => AppShell(child: child), // Bottom navigation
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(path: '/akademik', builder: (_, __) => const AkademikPage()),
        GoRoute(path: '/keuangan', builder: (_, __) => const KeuanganPage()),
        GoRoute(path: '/pesan', builder: (_, __) => const PesanPage()),
        GoRoute(path: '/profil', builder: (_, __) => const ProfilPage()),
      ],
    ),
    // Sub-routes
    GoRoute(path: '/akademik/kelas/:id', builder: (_, state) => DetailKelasPage(id: state.pathParameters['id']!)),
    GoRoute(path: '/akademik/nilai/:siswaId', builder: (_, state) => NilaiSiswaPage(siswaId: state.pathParameters['siswaId']!)),
    GoRoute(path: '/keuangan/tagihan/:id', builder: (_, state) => DetailTagihanPage(id: state.pathParameters['id']!)),
  ],
);
```

---

## 7. Security Architecture

### JWT Strategy

SMEDA HEBAT menggunakan dual-token JWT dengan pendekatan **signed but not encrypted** (standar JWT):

| Aspek | Access Token | Refresh Token |
|-------|-------------|---------------|
| Masa berlaku | 15 menit | 7 hari |
| Disimpan di | Memory (Flutter) | Secure storage (encrypted) |
| Dikirim via | `Authorization: Bearer` header | HTTP body (endpoint /auth/refresh) |
| Berisi | `userId, role, sekolahId, iat, exp` | `userId, tokenId, iat, exp` |
| Signature | HMAC-SHA256 (HS256) | HMAC-SHA256 (HS256) |

**Keamanan tambahan:**
- Refresh token disimpan di database dengan hash (bukan plaintext).
- Jika refresh token digunakan lebih dari sekali (dengan token lama yang masih valid), semua session user di-revoke (deteksi token reuse / rotation).
- Access token **tidak** dikirim ulang saat refresh — access token baru dengan `iat` baru.

### Role-Based Access Control (RBAC)

**Hierarki Role:**

```
SUPER_ADMIN            # Tim SMEDA HEBAT (pengelola platform)
  └── ADMIN_SEKOLAH    # Kepala Sekolah / Operator Sekolah
        ├── GURU       # Guru (akses sesuai mapel dan kelas yang diajar)
        ├── SISWA      # Siswa (akses data diri sendiri)
        ├── ORANG_TUA  # Orang tua/wali (akses data anak)
        └── PEGAWAI    # Staf tata usaha, keuangan, perpustakaan
```

**Implementasi di NestJS:**

```typescript
// roles.decorator.ts
@SetMetadata('roles', [Role.ADMIN_SEKOLAH, Role.GURU])
@SetMetadata('permissions', ['siswa:read', 'nilai:write'])

// roles.guard.ts
@Injectable()
export class RolesGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.get<Role[]>('roles', handler);
    const requiredPermissions = this.reflector.get<string[]>('permissions', handler);
    const { user } = context.switchToHttp().getRequest();

    if (requiredRoles && !requiredRoles.includes(user.role)) return false;
    if (requiredPermissions && !requiredPermissions.every(p => user.permissions.includes(p))) return false;
    return true;
  }
}
```

**Implementasi Policy-Based (lebih granular):**
Untuk kasus di mana role tidak cukup (contoh: guru hanya bisa mengedit nilai siswa yang dia ajar), digunakan **Policy Guard**:

```typescript
@Injectable()
export class SiswaPolicyGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const { user, params } = context.switchToHttp().getRequest();
    const siswa = await this.siswaService.findById(params.id);
    // Guru hanya bisa akses siswa di kelas yang dia ajar
    return this.academicService.isGuruKelas(user.id, siswa.kelasId);
  }
}
```

### Input Validation

- **DTO Validation:** Menggunakan `class-validator` + `class-transformer` di NestJS dengan `ValidationPipe` global.
- **Whitelist:** `whitelist: true` — property yang tidak ada di DTO otomatis di-strip.
- **Sanitization:** HTML entities di-strip untuk input teks (mencegah XSS).
- **File Upload:** Validasi tipe file (MIME check), ukuran maksimal, dan scan antivirus (ClamAV untuk production).

### Rate Limiting

Menggunakan `@nestjs/throttler`:

```typescript
// Global: 100 request per 60 detik per IP
@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 100,
    }),
  ],
})

// Endpoint spesifik: login — 5 attempt per menit
@Throttle(5, 60)
@Post('login')
async login(@Body() dto: LoginDto) { ... }
```

Rate limiting diterapkan dengan Redis store untuk persistensi di environment multi-instance.

### CORS

```typescript
// main.ts
app.enableCors({
  origin: [
    'https://smedahebat.sch.id',
    'https://admin.smedahebat.sch.id',
    // Staging domains
    'https://staging.smedahebat.sch.id',
  ],
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400, // Preflight cache 24 jam
});
```

### Environment Variables & Secrets Management

**Prinsip:** Tidak ada secret di codebase. Semua melalui environment variable.

```
# File: .env (tidak di-commit)
DATABASE_URL=postgresql://user:pass@localhost:5432/smedahebat
REDIS_URL=redis://localhost:6379
JWT_ACCESS_SECRET=<random-64-char>
JWT_REFRESH_SECRET=<random-64-char>
MEILISEARCH_URL=http://localhost:7700
MEILISEARCH_API_KEY=<key>
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=smedahebat-files
FCM_SERVER_KEY=<key>
SMTP_HOST=smtp.sendgrid.net
SMTP_API_KEY=<key>
```

**Best Practices:**
- File `.env` masuk ke `.gitignore`.
- Template `.env.example` di-commit (dengan placeholder values).
- Di production, secrets diset via **Docker secrets** atau **GitHub Actions secrets**.
- Secret key JWT minimal 64 karakter random (generate dengan `openssl rand -hex 64`).

---

## 8. Offline Strategy

### Arsitektur Offline SMEDA HEBAT

Koneksi internet di lingkungan sekolah Indonesia tidak selalu stabil. Oleh karena itu, SMEDA HEBAT dirancang dengan **Offline-First** sebagai prinsip utama.

```
                  ONLINE                          OFFLINE
           ┌──────────────────┐           ┌──────────────────┐
           │  NestJS API      │           │  Flutter App     │
           │  (Source of      │  ← sync → │  (SQLite + Queue)│
           │   Truth)         │           │                  │
           └──────────────────┘           └──────────────────┘
```

### Queue-Based Sync

**Tabel Sync Queue di SQLite:**

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  operation TEXT NOT NULL,    -- CREATE / UPDATE / DELETE
  entity TEXT NOT NULL,       -- "siswa", "nilai", "presensi"
  entity_id TEXT,
  data JSON NOT NULL,         -- Data lengkap yang akan dikirim
  status TEXT DEFAULT 'pending',  -- pending / syncing / completed / failed
  created_at INTEGER NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  conflict_resolution TEXT DEFAULT 'client_wins'
);
```

**Alur Sinkronisasi:**

```
1. Saat Online:
   - READ: Baca dari remote API, cache di SQLite.
   - WRITE: Kirim ke API langsung. Jika sukses, simpan di SQLite. Jika gagal, masuk queue.

2. Saat Offline:
   - READ: Baca dari SQLite (data yang sudah di-cache sebelumnya).
   - WRITE: Simpan di SQLite + tambahkan entry ke sync_queue.

3. Transisi Offline → Online:
   - ConnectivityManager mendeteksi koneksi kembali.
   - Sync Manager mengambil entry dari sync_queue (urut by created_at ASC).
   - Kirim satu per satu ke API.
   - Jika sukses → hapus dari queue + update local data.
   - Jika gagal (409 Conflict) → jalankan conflict resolution.
   - Jika gagal (server error) → retry dengan exponential backoff (max 5 retry).
```

### Local Database untuk Cache

**drift (SQLite) — Caching Strategy:**

```dart
@DriftDatabase(tables: [Siswa, Nilai, Presensi, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
}

// Strategy: Cache-First
Future<SiswaData> getSiswa(String id) async {
  // 1. Coba baca dari cache
  final cached = await _local.getSiswa(id);
  if (cached != null) return cached;

  // 2. Jika tidak ada, ambil dari remote
  final remote = await _remote.getSiswa(id);
  await _local.upsertSiswa(remote); // Cache ke local
  return remote;
}

// Untuk data yang sering berubah (nilai, presensi):
// Selalu coba remote dulu (atau gunakan "stale-while-revalidate")
Future<SiswaData> getSiswaWithStaleWhileRevalidate(String id) async {
  final cached = await _local.getSiswa(id);

  // Tampilkan cache dulu, lalu refresh di background
  _remote.getSiswa(id).then((fresh) {
    _local.upsertSiswa(fresh);
    // Notify UI via Stream jika data berubah
    _siswaStreamController.add(fresh);
  });

  return cached;
}
```

**Data yang di-cache secara lokal:**
| Tipe Data | Cache Duration | Update Frequency |
|-----------|---------------|------------------|
| Profil user, daftar kelas | 24 jam | Jarang berubah |
| Jadwal pelajaran | 1 minggu | Per semester |
| Nilai siswa | Hingga sync baru | Saat guru input |
| Daftar siswa per kelas | 1 jam | Harian |
| Tagihan & pembayaran | 30 menit | Saat ada transaksi baru |

### Conflict Resolution Strategy

Konflik terjadi ketika data yang sama diubah di dua tempat berbeda saat offline. SMEDA HEBAT menggunakan strategi berikut:

**1. Last-Writer-Wins (LWW) — Default:**
Setiap operasi menyertakan timestamp `updated_at`. Data dengan timestamp terbaru yang menang. Ini adalah default untuk sebagian besar data (profil, catatan, dll).

**2. Merge Strategy — untuk data tertentu:**
Contoh: presensi yang diinput oleh guru dan admin secara bersamaan. Pendekatan merge:
- Guru mengirim presensi untuk siswa A, B, C (shift pagi).
- Admin mengirim presensi untuk seluruh kelas (termasuk A, B, C) dengan status berbeda.
- Backend melakukan merge: untuk siswa yang sudah ada data dari guru, tidak overwrite — hanya menambah yang belum ada.

**3. Client-Wins — untuk data yang user-generated:**
Catatan guru, komentar, dan data yang tidak kritis — data dari client menang.

**4. Manual Resolution — untuk data keuangan:**
Jika terjadi konflik pada data tagihan/pembayaran, operasi akan ditahan dan menunggu admin untuk mereview (melalui dashboard notifikasi konflik).

**Implementasi di Backend:**

```typescript
async function resolveConflict(
  entity: string,
  clientData: any,
  serverData: any,
): Promise<any> {
  switch (entity) {
    case 'presensi':
      return mergePresensi(clientData, serverData);
    case 'tagihan':
      return manualResolution(clientData, serverData); // Push notif ke admin
    default:
      return lastWriterWins(clientData, serverData);
  }
}
```

---

## 9. Deployment Architecture

### Docker Compose — Semua Service

```yaml
# docker/docker-compose.yml
version: '3.9'

services:
  # ===================== API =====================
  api:
    build:
      context: ..
      dockerfile: docker/Dockerfile.api
    container_name: smeda-api
    ports:
      - "3000:3000"
    env_file: ../.env
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
      meilisearch:
        condition: service_started
      minio:
        condition: service_started
    volumes:
      - uploads:/app/uploads
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== WORKER (Bull) =====================
  worker:
    build:
      context: ..
      dockerfile: docker/Dockerfile.api
    container_name: smeda-worker
    command: node dist/workers/main.js
    env_file: ../.env
    depends_on:
      - api
      - redis
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== DATABASE =====================
  postgres:
    image: postgres:16-alpine
    container_name: smeda-postgres
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: smedahebat
      POSTGRES_USER: smeda
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U smeda -d smedahebat"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== CACHE & QUEUE =====================
  redis:
    image: redis:7-alpine
    container_name: smeda-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== SEARCH =====================
  meilisearch:
    image: getmeili/meilisearch:v1.7
    container_name: smeda-meilisearch
    ports:
      - "7700:7700"
    environment:
      MEILI_MASTER_KEY: ${MEILISEARCH_API_KEY}
    volumes:
      - meilisearch-data:/meili_data
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== FILE STORAGE =====================
  minio:
    image: minio/minio:latest
    container_name: smeda-minio
    ports:
      - "9000:9000"  # API
      - "9001:9001"  # Console
    environment:
      MINIO_ROOT_USER: ${S3_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${S3_SECRET_KEY}
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"
    restart: unless-stopped
    networks:
      - smeda-network

  # ===================== REVERSE PROXY =====================
  nginx:
    image: nginx:alpine
    container_name: smeda-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro  # Let's Encrypt certs
    depends_on:
      - api
    restart: unless-stopped
    networks:
      - smeda-network

volumes:
  postgres-data:
  redis-data:
  meilisearch-data:
  minio-data:
  uploads:

networks:
  smeda-network:
    driver: bridge
```

### Nginx Reverse Proxy Configuration

```nginx
# docker/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream api_servers {
        server api:3000;
    }

    # HTTP → HTTPS redirect
    server {
        listen 80;
        server_name api.smedahebat.sch.id;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name api.smedahebat.sch.id;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Rate limiting
        limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
        limit_req zone=api_limit burst=200 nodelay;

        # Request size limit (untuk upload file)
        client_max_body_size 50M;

        location /api/ {
            proxy_pass http://api_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /ws/ {
            proxy_pass http://api_servers;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 86400; # WebSocket keepalive
        }

        location /storage/ {
            proxy_pass http://minio:9000;
            proxy_set_header Host $host;
        }

        # Security headers
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    }
}
```

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3 with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npx turbo lint --parallel
      - run: npx turbo typecheck --parallel
      - run: npx turbo test --parallel

  build:
    name: Build & Docker
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci && npx turbo build
      - name: Build Docker Image
        run: |
          docker build -t smeda-api:latest -f docker/Dockerfile.api .
          docker tag smeda-api:latest ghcr.io/smedahebat/api:${{ github.sha }}
      - name: Push to Registry
        run: |
          echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/smedahebat/api:${{ github.sha }}

  deploy-staging:
    name: Deploy to Staging
    needs: build
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          script: |
            cd /opt/smedahebat
            docker compose pull
            docker compose up -d --force-recreate api worker
            docker compose exec api npx prisma migrate deploy
            docker system prune -f

  deploy-production:
    name: Deploy to Production
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /opt/smedahebat
            docker compose pull
            docker compose up -d --force-recreate api worker
            docker compose exec api npx prisma migrate deploy
            docker system prune -f
```

### Dockerfile Backend (NestJS — Multi-stage Build)

```dockerfile
# docker/Dockerfile.api
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Install turborepo & dependencies
COPY package.json turbo.json ./
COPY apps/api/package.json ./apps/api/
COPY packages/ ./packages/
RUN npm ci

COPY . .
RUN npx turbo build --filter=api...

# Stage 2: Production
FROM node:20-alpine
WORKDIR /app

RUN apk add --no-cache tini curl

COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/apps/api/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/api/prisma ./prisma

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/api/v1/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/main"]
```

---

## Ringkasan

| Layer | Teknologi | Tujuan |
|-------|-----------|--------|
| **Mobile** | Flutter + Riverpod + drift | Aplikasi pengguna utama (offline-first) |
| **Backend** | NestJS + Prisma + Bull | API server, business logic, job processing |
| **Database** | PostgreSQL | Primary data store (ACID) |
| **Cache** | Redis | Caching + job queue backend |
| **Search** | Meilisearch | Full-text search cepat |
| **Storage** | MinIO / S3 | File storage (foto, dokumen) |
| **Realtime** | WebSocket (Socket.io) | Chat, notifikasi real-time |
| **Push** | Firebase Cloud Messaging | Push notification mobile |
| **Reverse Proxy** | Nginx | SSL, rate limiting, load balancing |
| **Container** | Docker + Compose | Orchestrasi semua service |
| **Monorepo** | Turborepo | Manajemen kode terpusat |
| **CI/CD** | GitHub Actions | Build, test, deploy otomatis |

---

*Dokumen ini adalah living document dan akan terus diperbarui seiring perkembangan sistem. Untuk pertanyaan atau saran, hubungi tim engineering SMEDA HEBAT.*
