
import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  const configs = await prisma.appConfig.findMany();
  console.log(JSON.stringify(configs, null, 2));
  await prisma.$disconnect();
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
