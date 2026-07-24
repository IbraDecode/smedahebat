import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash('admin123', 12);

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
    },
  });

  console.log(`Admin user created: ${admin.nis} (${admin.name})`);

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
