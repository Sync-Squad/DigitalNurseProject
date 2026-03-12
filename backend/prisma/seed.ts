import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function upsertRole(roleCode: string, roleName: string) {
  await prisma.role.upsert({
    where: { roleCode },
    update: { roleName, isActive: true },
    create: {
      roleCode,
      roleName,
      isActive: true,
    },
  });
}

async function upsertUserWithRole(options: {
  email: string;
  fullName: string;
  phone?: string;
  password: string;
  roleCode: 'patient' | 'caregiver';
  address?: string;
  gender?: string;
}) {
  const { email, fullName, phone, password, roleCode, address, gender } =
    options;

  const role = await prisma.role.findUnique({
    where: { roleCode },
  });

  if (!role) {
    throw new Error(`Role ${roleCode} not found. Have you seeded roles first?`);
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const user = await prisma.user.upsert({
    where: { email },
    update: {
      full_name: fullName,
      phone: phone ?? null,
      passwordHash,
      status: 'active',
      address: address ?? null,
      gender: gender ?? null,
      emailVerified: true, // Auto-verify test users
    },
    create: {
      email,
      phone: phone ?? null,
      passwordHash,
      full_name: fullName,
      authProvider: 'password',
      address: address ?? null,
      gender: gender ?? null,
      emailVerified: true, // Auto-verify test users
    },
  });

  const existingRole = await prisma.userRole.findFirst({
    where: { userId: user.userId, roleId: role.roleId },
  });

  if (!existingRole) {
    await prisma.userRole.create({
      data: {
        userId: user.userId,
        roleId: role.roleId,
      },
    });
  }

  const existingSubscription = await prisma.subscription.findFirst({
    where: { userId: user.userId },
  });

  if (!existingSubscription) {
    await prisma.subscription.create({
      data: {
        userId: user.userId,
        planId: null,
        status: 'active',
      },
    });
  }

  return user;
}

async function upsertAppConfig(
  configKey: string,
  configValue: string,
  description?: string,
) {
  await prisma.appConfig.upsert({
    where: { configKey },
    update: { configValue, description, isActive: true },
    create: {
      configKey,
      configValue,
      description,
      isActive: true,
    },
  });
}

async function main() {
  console.log('Starting database seed...');

  // Handle legacy elder role migration to patient
  const existingPatientRole = await prisma.role.findUnique({
    where: { roleCode: 'patient' },
  });

  if (existingPatientRole) {
    // Patient role already exists, just delete any legacy elder role
    await prisma.role.deleteMany({
      where: { roleCode: 'elder' },
    });
  } else {
    // No patient role exists, try to rename elder to patient
    await prisma.role.updateMany({
      where: { roleCode: 'elder' },
      data: { roleCode: 'patient', roleName: 'Patient' },
    });
  }

  await upsertRole('patient', 'Patient');
  await upsertRole('caregiver', 'Caregiver');

  // Seed application configuration
  console.log('Seeding app configuration...');
  await upsertAppConfig(
    'gemini_api_key',
    'AIzaSyBB-nGNXzlo399N1viNLq011V4YJJDWzBg',
    'Google Gemini API key for AI features',
  );

  const demoPatient = await upsertUserWithRole({
    email: 'patient@example.com',
    fullName: 'Demo Patient',
    phone: '+15550000001',
    password: 'password123',
    roleCode: 'patient',
    gender: 'female',
    address: '123 Demo Street, Springfield',
  });

  const demoCaregiver = await upsertUserWithRole({
    email: 'caregiver@example.com',
    fullName: 'Demo Caregiver',
    phone: '+15550000002',
    password: 'password123',
    roleCode: 'caregiver',
    gender: 'female',
    address: '456 Helper Avenue, Springfield',
  });

  const existingAssignment = await prisma.elderAssignment.findFirst({
    where: {
      elderUserId: demoPatient.userId,
      caregiverUserId: demoCaregiver.userId,
    },
  });

  if (!existingAssignment) {
    await prisma.elderAssignment.create({
      data: {
        elderUserId: demoPatient.userId,
        caregiverUserId: demoCaregiver.userId,
        relationshipCode: 'daughter',
        relationshipDomain: 'relationships',
        isPrimary: true,
        notifyPrefs: {
          medication: true,
          vitals: true,
          documents: true,
        },
      },
    });
  }

  console.log('Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error('Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
