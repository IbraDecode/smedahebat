import { PrismaClient, Role, Gender } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash('admin123', 12);

  const school = await prisma.school.upsert({
    where: { npsn: '12345678' },
    update: {},
    create: {
      name: 'SMKN 2 Mataram',
      address: 'Jl. Pendidikan No. 1, Mataram',
      phone: '0370-123456',
      email: 'info@smkn2mataram.sch.id',
      website: 'https://smkn2mataram.sch.id',
      npsn: '12345678',
      status: 'active',
    },
  });

  const academicYear = await prisma.academicYear.upsert({
    where: {
      schoolId_year_semester: {
        schoolId: school.id,
        year: '2025/2026',
        semester: 1,
      },
    },
    update: {},
    create: {
      schoolId: school.id,
      year: '2025/2026',
      semester: 1,
      isActive: true,
      startDate: new Date('2025-07-01'),
      endDate: new Date('2026-06-30'),
    },
  });

  const admin = await prisma.user.upsert({
    where: { nis: 'admin' },
    update: {},
    create: {
      nis: 'admin',
      name: 'Administrator',
      email: 'admin@smedahebat.sch.id',
      password: hashedPassword,
      role: Role.ADMIN,
      isFirstLogin: false,
      isActive: true,
      schoolId: school.id,
      academicYearId: academicYear.id,
    },
  });

  const guru = await prisma.user.upsert({
    where: { nis: '196501011990011001' },
    update: {},
    create: {
      nis: '196501011990011001',
      nip: '196501011990011001',
      name: 'I Wayan Santosa, S.Pd., M.Pd.',
      email: 'wayan.santosa@smedahebat.sch.id',
      password: hashedPassword,
      role: Role.GURU,
      gender: Gender.L,
      phone: '081234567890',
      address: 'Jl. Merdeka No. 10, Mataram',
      birthDate: new Date('1965-01-01'),
      birthPlace: 'Mataram',
      isFirstLogin: false,
      isActive: true,
      schoolId: school.id,
      academicYearId: academicYear.id,
    },
  });

  const siswa = await prisma.user.upsert({
    where: { nis: '12345' },
    update: {},
    create: {
      nis: '12345',
      name: 'Ahmad Rizki Pratama',
      email: 'ahmad.rizki@smedahebat.sch.id',
      password: hashedPassword,
      role: Role.SISWA,
      gender: Gender.L,
      phone: '087654321098',
      address: 'Jl. Gatot Subroto No. 25, Mataram',
      birthDate: new Date('2008-05-15'),
      birthPlace: 'Mataram',
      isFirstLogin: false,
      isActive: true,
      schoolId: school.id,
      academicYearId: academicYear.id,
    },
  });

  console.log(`School created: ${school.name}`);
  console.log(`Academic year created: ${academicYear.year} - Semester ${academicYear.semester}`);
  console.log(`Admin user created: ${admin.nis} (${admin.name})`);
  console.log(`Teacher created: ${guru.nis} (${guru.name})`);
  console.log(`Student created: ${siswa.nis} (${siswa.name})`);

  const roles = Object.values(Role);
  console.log(`Available roles: ${roles.join(', ')}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
