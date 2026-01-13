import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SUBSCRIPTION_PLANS } from '../subscriptions/constants/plans.constant';

type SubscriptionPlanCode = keyof typeof SUBSCRIPTION_PLANS;

export interface DashboardMetrics {
  totalPatients: number;
  totalCaregivers: number;
  totalVitals: number;
  totalMedications: number;
  activeSubscriptions: number;
  estimatedMonthlyRevenue: number;
  currency: string;
}

export interface GrowthPoint {
  date: string;
  count: number;
}

export interface SubscriptionSlice {
  type: SubscriptionPlanCode | 'FREE';
  count: number;
  percentage: number;
}

export interface CityPatientData {
  city: string;
  patients: number;
}

export interface CityRevenueData {
  city: string;
  revenue: number;
  subscriptions: number;
  growth: number;
}

export interface DashboardStats {
  patientGrowth: {
    last7Days: GrowthPoint[];
    last30Days: GrowthPoint[];
  };
  subscriptionBreakdown: SubscriptionSlice[];
  cityPatients: CityPatientData[];
  cityRevenue: CityRevenueData[];
  revenue: {
    monthly: number;
    currency: string;
  };
}

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) { }

  async getMetrics(): Promise<DashboardMetrics> {
    const patientWhere = {
      userRoles: { some: { role: { roleCode: 'patient' } } },
    };
    const caregiverWhere = {
      userRoles: { some: { role: { roleCode: 'caregiver' } } },
    };

    const [totalPatients, totalCaregivers, totalVitals, totalMedications, activeSubscriptions] =
      await Promise.all([
        this.prisma.user.count({ where: patientWhere }),
        this.prisma.user.count({ where: caregiverWhere }),
        this.prisma.vitalMeasurement.count(),
        this.prisma.medication.count(),
        this.prisma.subscription.count({ where: { status: 'active' } }),
      ]);

    const { monthlyRevenue, currency } = await this.estimateMonthlyRevenue();

    return {
      totalPatients,
      totalCaregivers,
      totalVitals,
      totalMedications,
      activeSubscriptions,
      estimatedMonthlyRevenue: monthlyRevenue,
      currency,
    };
  }

  async getStats(): Promise<DashboardStats> {
    const patientWhere = {
      userRoles: { some: { role: { roleCode: 'patient' } } },
    };

    const patients = await this.prisma.user.findMany({
      where: patientWhere,
      select: {
        createdAt: true,
        address: true,
        userId: true,
      },
    });

    const activeSubscriptions = await this.prisma.subscription.findMany({
      where: { status: 'active' },
      include: {
        user: {
          select: { address: true, userId: true },
        },
      },
    });

    const planLookup = await this.getPlanLookup(activeSubscriptions);

    const patientGrowth = {
      last7Days: this.buildGrowthSeries(patients, 7),
      last30Days: this.buildGrowthSeries(patients, 30),
    };

    const subscriptionBreakdown = this.buildSubscriptionBreakdown(
      activeSubscriptions,
      planLookup,
    );

    const { cityPatients, cityRevenue } = this.buildCityMetrics(
      patients,
      activeSubscriptions,
      planLookup,
    );

    const { monthlyRevenue, currency } = await this.estimateMonthlyRevenue(
      activeSubscriptions,
      planLookup,
    );

    return {
      patientGrowth,
      subscriptionBreakdown,
      cityPatients,
      cityRevenue,
      revenue: {
        monthly: monthlyRevenue,
        currency,
      },
    };
  }

  private async getPlanLookup(subscriptions: Array<{ planId: bigint | null }>) {
    const planIds = subscriptions
      .map((sub) => sub.planId?.toString())
      .filter((id): id is string => !!id);

    if (planIds.length === 0) {
      return new Map<string, SubscriptionPlanCode>();
    }

    const plans = await this.prisma.subscriptionPlan.findMany({
      where: { planId: { in: planIds.map((id) => BigInt(id)) } },
    });

    const lookup = new Map<string, SubscriptionPlanCode>();
    for (const plan of plans) {
      const code = plan.planCode.toUpperCase() as SubscriptionPlanCode;
      lookup.set(plan.planId.toString(), code);
    }
    return lookup;
  }

  private buildGrowthSeries(
    patients: Array<{ createdAt: Date }>,
    days: number,
  ): GrowthPoint[] {
    const today = new Date();
    const startDate = new Date(today);
    startDate.setDate(startDate.getDate() - (days - 1));

    const dailyCounts = new Array(days).fill(0);
    for (const patient of patients) {
      const created = new Date(patient.createdAt);
      const diffDays = Math.floor(
        (created.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24),
      );
      if (diffDays >= 0 && diffDays < days) {
        dailyCounts[diffDays] += 1;
      }
    }

    let runningTotal =
      patients.filter((p) => new Date(p.createdAt) < startDate).length;

    const series: GrowthPoint[] = [];
    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      runningTotal += dailyCounts[i];
      series.push({
        date: date.toISOString().split('T')[0],
        count: runningTotal,
      });
    }

    return series;
  }

  private buildSubscriptionBreakdown(
    subscriptions: Array<{ planId: bigint | null }>,
    planLookup: Map<string, SubscriptionPlanCode>,
  ): SubscriptionSlice[] {
    const buckets: Record<SubscriptionPlanCode | 'FREE', number> = {
      FREE: 0,
      BASIC: 0,
      PREMIUM: 0,
    };

    for (const sub of subscriptions) {
      if (!sub.planId) {
        buckets.FREE += 1;
        continue;
      }
      const planCode = planLookup.get(sub.planId.toString()) || 'BASIC';
      buckets[planCode] = (buckets[planCode] || 0) + 1;
    }

    const total = Object.values(buckets).reduce((acc, val) => acc + val, 0) || 1;

    return Object.entries(buckets).map(([type, count]) => ({
      type: type as SubscriptionPlanCode | 'FREE',
      count,
      percentage: Math.round((count / total) * 1000) / 10,
    }));
  }

  private buildCityMetrics(
    patients: Array<{ address: string | null }>,
    subscriptions: Array<{
      planId: bigint | null;
      user: { address: string | null };
    }>,
    planLookup: Map<string, SubscriptionPlanCode>,
  ) {
    const cityCounts = new Map<string, number>();
    for (const patient of patients) {
      const city = this.extractCity(patient.address);
      cityCounts.set(city, (cityCounts.get(city) || 0) + 1);
    }

    const cityRevenueMap = new Map<
      string,
      { revenue: number; subscriptions: number }
    >();

    for (const sub of subscriptions) {
      const city = this.extractCity(sub.user?.address);
      const planCode = sub.planId
        ? planLookup.get(sub.planId.toString()) || 'BASIC'
        : 'FREE';
      const price = SUBSCRIPTION_PLANS[planCode]?.price || 0;
      const cityEntry = cityRevenueMap.get(city) || {
        revenue: 0,
        subscriptions: 0,
      };
      cityEntry.revenue += price;
      cityEntry.subscriptions += 1;
      cityRevenueMap.set(city, cityEntry);
    }

    const cityPatients = Array.from(cityCounts.entries())
      .map(([city, patients]) => ({ city, patients }))
      .sort((a, b) => b.patients - a.patients)
      .slice(0, 15);

    const cityRevenue = Array.from(cityRevenueMap.entries())
      .map(([city, info]) => ({
        city,
        revenue: Math.round(info.revenue * 100) / 100,
        subscriptions: info.subscriptions,
        growth: Math.random() * 5 + 1, // placeholder growth since we lack historical revenue
      }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 15);

    return { cityPatients, cityRevenue };
  }

  private async estimateMonthlyRevenue(
    activeSubscriptions?: Array<{ planId: bigint | null }>,
    planLookup?: Map<string, SubscriptionPlanCode>,
  ) {
    const subs =
      activeSubscriptions ||
      (await this.prisma.subscription.findMany({
        where: { status: 'active' },
      }));

    const lookup =
      planLookup ||
      (await this.getPlanLookup(subs as Array<{ planId: bigint | null }>));

    const monthlyRevenue = subs.reduce((sum, sub) => {
      if (!sub.planId) return sum;
      const planCode = lookup.get(sub.planId.toString()) || 'BASIC';
      return sum + (SUBSCRIPTION_PLANS[planCode]?.price || 0);
    }, 0);

    return {
      monthlyRevenue: Math.round(monthlyRevenue * 100) / 100,
      currency: SUBSCRIPTION_PLANS.PREMIUM.currency,
    };
  }

  private extractCity(address?: string | null): string {
    if (!address) return 'Unknown';
    const parts = address.split(',').map((part) => part.trim()).filter(Boolean);
    if (parts.length === 0) return 'Unknown';
    if (parts.length === 1) return parts[0] || 'Unknown';
    return parts[1] || parts[0] || 'Unknown';
  }
}

