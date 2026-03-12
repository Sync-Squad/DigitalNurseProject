import { Test, TestingModule } from '@nestjs/testing';
import { DashboardService } from './dashboard.service';
import { PrismaService } from '../prisma/prisma.service';

describe('DashboardService', () => {
  let service: DashboardService;

  const prismaMock = {
    user: {
      count: jest.fn().mockResolvedValue(2),
      findMany: jest.fn().mockResolvedValue([]),
    },
    vitalMeasurement: {
      count: jest.fn().mockResolvedValue(5),
    },
    medication: {
      count: jest.fn().mockResolvedValue(3),
    },
    subscription: {
      count: jest.fn().mockResolvedValue(4),
      findMany: jest
        .fn()
        .mockResolvedValue([{ planId: BigInt(1) }, { planId: null }]),
    },
    subscriptionPlan: {
      findMany: jest
        .fn()
        .mockResolvedValue([{ planId: BigInt(1), planCode: 'premium' }]),
    },
  } as unknown as PrismaService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardService,
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
      ],
    }).compile();

    service = module.get<DashboardService>(DashboardService);
  });

  it('calculates summary metrics', async () => {
    const metrics = await service.getMetrics();

    expect(metrics.totalPatients).toBe(2);
    expect(metrics.totalVitals).toBe(5);
    expect(metrics.totalMedications).toBe(3);
    expect(metrics.activeSubscriptions).toBe(4);
    expect(prismaMock.subscription.findMany).toHaveBeenCalled();
  });

  it('builds stats with growth and breakdown', async () => {
    (prismaMock.user.findMany as jest.Mock).mockResolvedValue([
      { createdAt: new Date(), address: 'City, Country', userId: BigInt(1) },
    ]);
    const stats = await service.getStats();

    expect(stats.patientGrowth.last7Days.length).toBeGreaterThan(0);
    expect(stats.subscriptionBreakdown.length).toBeGreaterThan(0);
    expect(stats.cityPatients.length).toBeGreaterThan(0);
  });
});

