// @ts-nocheck
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDietLogDto } from './dto/create-diet-log.dto';
import { CreateExerciseLogDto } from './dto/create-exercise-log.dto';
import { CreateDietPlanDto } from './dto/create-diet-plan.dto';
import { UpdateDietPlanDto } from './dto/update-diet-plan.dto';
import { CreateExercisePlanDto } from './dto/create-exercise-plan.dto';
import { UpdateExercisePlanDto } from './dto/update-exercise-plan.dto';
import { ApplyPlanDto } from './dto/apply-plan.dto';
import { ActorContext } from '../common/services/access-control.service';
import { getPKTDate, getPKTDateOnly } from '../common/utils/date-utils';

@Injectable()
export class LifestyleService {
  constructor(private prisma: PrismaService) {}

  // ============================================
  // Diet Log Methods
  // ============================================

  async createDietLog(context: ActorContext, createDto: CreateDietLogDto) {
    const dietLog = await this.prisma.dietLog.create({
      data: {
        userId: context.elderUserId,
        logDate: getPKTDateOnly(createDto.logDate),
        mealType: createDto.mealType,
        foodItems: createDto.description,
        calories: createDto.calories,
        notes: createDto.notes || null,
        createdAt: getPKTDate(),
        updatedAt: getPKTDate(),
      },
    });

    return this.mapDietLogToResponse(dietLog);
  }

  async findAllDietLogs(context: ActorContext, date?: string) {
    const where: any = { userId: context.elderUserId };
    if (date) {
      const targetDate = getPKTDateOnly(date);
      where.logDate = targetDate;
    }

    const dietLogs = await this.prisma.dietLog.findMany({
      where,
      orderBy: {
        logDate: 'desc',
      },
    });

    return dietLogs.map((log) => this.mapDietLogToResponse(log));
  }

  async removeDietLog(context: ActorContext, dietId: bigint) {
    const dietLog = await this.prisma.dietLog.findFirst({
      where: {
        dietId,
        userId: context.elderUserId,
      },
    });

    if (!dietLog) {
      throw new NotFoundException('Diet log not found');
    }

    await this.prisma.dietLog.delete({
      where: { dietId },
    });

    return { message: 'Diet log deleted successfully' };
  }

  // ============================================
  // Exercise Log Methods
  // ============================================

  async createExerciseLog(context: ActorContext, createDto: CreateExerciseLogDto) {
    const exerciseLog = await this.prisma.exerciseLog.create({
      data: {
        userId: context.elderUserId,
        logDate: getPKTDateOnly(createDto.logDate),
        exerciseType: createDto.activityType,
        description: createDto.description,
        durationMinutes: createDto.durationMinutes,
        caloriesBurned: createDto.caloriesBurned,
        intensity: createDto.intensity || null,
        notes: createDto.notes || null,
        createdAt: getPKTDate(),
        updatedAt: getPKTDate(),
      },
    });

    return this.mapExerciseLogToResponse(exerciseLog);
  }

  async findAllExerciseLogs(context: ActorContext, date?: string) {
    const where: any = { userId: context.elderUserId };
    if (date) {
      const targetDate = getPKTDateOnly(date);
      where.logDate = targetDate;
    }

    const exerciseLogs = await this.prisma.exerciseLog.findMany({
      where,
      orderBy: {
        logDate: 'desc',
      },
    });

    return exerciseLogs.map((log) => this.mapExerciseLogToResponse(log));
  }

  async removeExerciseLog(context: ActorContext, exerciseId: bigint) {
    const exerciseLog = await this.prisma.exerciseLog.findFirst({
      where: {
        exerciseId,
        userId: context.elderUserId,
      },
    });

    if (!exerciseLog) {
      throw new NotFoundException('Exercise log not found');
    }

    await this.prisma.exerciseLog.delete({
      where: { exerciseId },
    });

    return { message: 'Exercise log deleted successfully' };
  }

  // ============================================
  // Summary Methods
  // ============================================

  async getDailySummary(context: ActorContext, date: string) {
    const targetDate = getPKTDateOnly(date);

    const dietLogs = await this.prisma.dietLog.findMany({
      where: {
        userId: context.elderUserId,
        logDate: targetDate,
      },
    });

    const exerciseLogs = await this.prisma.exerciseLog.findMany({
      where: {
        userId: context.elderUserId,
        logDate: targetDate,
      },
    });

    const totalCaloriesIn = dietLogs.reduce((sum, log) => sum + (log.calories || 0), 0);
    const totalCaloriesOut = exerciseLogs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);
    const totalExerciseMinutes = exerciseLogs.reduce(
      (sum, log) => sum + (log.durationMinutes || 0),
      0,
    );

    return {
      date: targetDate.toISOString().split('T')[0],
      caloriesIn: totalCaloriesIn,
      caloriesOut: totalCaloriesOut,
      netCalories: totalCaloriesIn - totalCaloriesOut,
      exerciseMinutes: totalExerciseMinutes,
      mealCount: dietLogs.length,
      workoutCount: exerciseLogs.length,
    };
  }

  async getWeeklySummary(context: ActorContext) {
    const now = getPKTDate();
    const weekStart = getPKTDate(now);
    weekStart.setDate(weekStart.getDate() - 7);

    const dietLogs = await this.prisma.dietLog.findMany({
      where: {
        userId: context.elderUserId,
        logDate: {
          gte: weekStart,
        },
      },
    });

    const exerciseLogs = await this.prisma.exerciseLog.findMany({
      where: {
        userId: context.elderUserId,
        logDate: {
          gte: weekStart,
        },
      },
    });

    const totalCaloriesIn = dietLogs.reduce((sum, log) => sum + (log.calories || 0), 0);
    const totalCaloriesOut = exerciseLogs.reduce((sum, log) => sum + (log.caloriesBurned || 0), 0);
    const totalExerciseMinutes = exerciseLogs.reduce(
      (sum, log) => sum + (log.durationMinutes || 0),
      0,
    );

    return {
      weekStart: weekStart.toISOString(),
      weekEnd: now.toISOString(),
      totalCaloriesIn,
      totalCaloriesOut,
      avgCaloriesPerDay: totalCaloriesIn / 7,
      totalExerciseMinutes,
      avgExercisePerDay: totalExerciseMinutes / 7,
    };
  }

  // ============================================
  // Mappers
  // ============================================

  private mapDietLogToResponse(log: any) {
    return {
      id: log.dietId.toString(),
      mealType: log.mealType,
      description: log.foodItems || '',
      calories: log.calories || 0,
      timestamp: log.logDate.toISOString(),
      userId: log.userId.toString(),
      sourcePlanId: log.sourcePlanId?.toString() || null,
    };
  }

  private mapExerciseLogToResponse(log: any) {
    return {
      id: log.exerciseId.toString(),
      activityType: log.exerciseType,
      sourcePlanId: log.sourcePlanId?.toString() || null,
      description: log.description || '',
      durationMinutes: log.durationMinutes || 0,
      caloriesBurned: log.caloriesBurned || 0,
      timestamp: log.logDate.toISOString(),
      userId: log.userId.toString(),
    };
  }

  // ============================================
  // Diet Plan Methods
  // ============================================

  async createDietPlan(context: ActorContext, createDto: CreateDietPlanDto) {
    const plan = await this.prisma.dietPlan.create({
      data: {
        userId: context.elderUserId,
        planName: createDto.planName,
        description: createDto.description || null,
        isActive: true,
        items: {
          create: createDto.items.map((item) => ({
            dayOfWeek: item.dayOfWeek,
            mealType: item.mealType,
            description: item.description,
            calories: item.calories || null,
            notes: item.notes || null,
          })),
        },
      },
      include: {
        items: true,
      },
    });

    return this.mapDietPlanToResponse(plan);
  }

  async findAllDietPlans(context: ActorContext) {
    const plans = await this.prisma.dietPlan.findMany({
      where: {
        userId: context.elderUserId,
      },
      include: {
        items: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return plans.map((plan) => this.mapDietPlanToResponse(plan));
  }

  async findDietPlanById(context: ActorContext, planId: bigint) {
    const plan = await this.prisma.dietPlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
      include: {
        items: true,
      },
    });

    if (!plan) {
      throw new NotFoundException('Diet plan not found');
    }

    return this.mapDietPlanToResponse(plan);
  }

  async updateDietPlan(context: ActorContext, planId: bigint, updateDto: UpdateDietPlanDto) {
    const existingPlan = await this.prisma.dietPlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
    });

    if (!existingPlan) {
      throw new NotFoundException('Diet plan not found');
    }

    // Delete existing items if items are being updated
    if (updateDto.items) {
      await this.prisma.dietPlanItem.deleteMany({
        where: { planId },
      });
    }

    const plan = await this.prisma.dietPlan.update({
      where: { planId },
      data: {
        ...(updateDto.planName && { planName: updateDto.planName }),
        ...(updateDto.description !== undefined && { description: updateDto.description || null }),
        ...(updateDto.items && {
          items: {
            create: updateDto.items.map((item) => ({
              dayOfWeek: item.dayOfWeek,
              mealType: item.mealType,
              description: item.description,
              calories: item.calories || null,
              notes: item.notes || null,
            })),
          },
        }),
      },
      include: {
        items: true,
      },
    });

    return this.mapDietPlanToResponse(plan);
  }

  async deleteDietPlan(context: ActorContext, planId: bigint) {
    const plan = await this.prisma.dietPlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
    });

    if (!plan) {
      throw new NotFoundException('Diet plan not found');
    }

    await this.prisma.dietPlan.delete({
      where: { planId },
    });

    return { message: 'Diet plan deleted successfully' };
  }

  async applyDietPlan(context: ActorContext, planId: bigint, applyDto: ApplyPlanDto) {
    const plan = await this.findDietPlanById(context, planId);
    const startDate = getPKTDateOnly(applyDto.startDate);
    const overwriteExisting = applyDto.overwriteExisting || false;

    const createdLogs = [];
    const skippedLogs = [];

    // Group items by day of week
    const itemsByDay = new Map<number, typeof plan.items>();
    plan.items.forEach((item: any) => {
      if (!itemsByDay.has(item.dayOfWeek)) {
        itemsByDay.set(item.dayOfWeek, []);
      }
      itemsByDay.get(item.dayOfWeek)!.push(item);
    });

    // Process each day of the week
    for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
      const targetDate = new Date(startDate);
      targetDate.setDate(targetDate.getDate() + dayOffset);
      const dayOfWeek = targetDate.getDay();

      const itemsForDay = itemsByDay.get(dayOfWeek) || [];

      // Check if logs already exist for this date
      if (!overwriteExisting) {
        const existingLogs = await this.prisma.dietLog.findMany({
          where: {
            userId: context.elderUserId,
            logDate: targetDate,
          },
        });

        if (existingLogs.length > 0) {
          skippedLogs.push({
            date: targetDate.toISOString().split('T')[0],
            count: itemsForDay.length,
          });
          continue;
        }
      } else {
        // Delete existing logs for this date
        await this.prisma.dietLog.deleteMany({
          where: {
            userId: context.elderUserId,
            logDate: targetDate,
          },
        });
      }

      // Create logs for each item
      for (const item of itemsForDay) {
        const log = await this.prisma.dietLog.create({
          data: {
            userId: context.elderUserId,
            logDate: getPKTDateOnly(targetDate),
            mealType: item.mealType,
            foodItems: item.description,
            calories: item.calories || null,
            notes: item.notes || null,
            sourcePlanId: planId,
          },
        });
        createdLogs.push(this.mapDietLogToResponse(log));
      }
    }

    return {
      message: 'Diet plan applied successfully',
      createdLogs: createdLogs.length,
      skippedLogs: skippedLogs.length,
      details: {
        created: createdLogs,
        skipped: skippedLogs,
      },
    };
  }

  // ============================================
  // Exercise Plan Methods
  // ============================================

  async createExercisePlan(context: ActorContext, createDto: CreateExercisePlanDto) {
    const plan = await this.prisma.exercisePlan.create({
      data: {
        userId: context.elderUserId,
        planName: createDto.planName,
        description: createDto.description || null,
        isActive: true,
        items: {
          create: createDto.items.map((item) => ({
            dayOfWeek: item.dayOfWeek,
            activityType: item.activityType,
            description: item.description,
            durationMinutes: item.durationMinutes || null,
            caloriesBurned: item.caloriesBurned || null,
            intensity: item.intensity || null,
            notes: item.notes || null,
          })),
        },
      },
      include: {
        items: true,
      },
    });

    return this.mapExercisePlanToResponse(plan);
  }

  async findAllExercisePlans(context: ActorContext) {
    const plans = await this.prisma.exercisePlan.findMany({
      where: {
        userId: context.elderUserId,
      },
      include: {
        items: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return plans.map((plan) => this.mapExercisePlanToResponse(plan));
  }

  async findExercisePlanById(context: ActorContext, planId: bigint) {
    const plan = await this.prisma.exercisePlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
      include: {
        items: true,
      },
    });

    if (!plan) {
      throw new NotFoundException('Exercise plan not found');
    }

    return this.mapExercisePlanToResponse(plan);
  }

  async updateExercisePlan(context: ActorContext, planId: bigint, updateDto: UpdateExercisePlanDto) {
    const existingPlan = await this.prisma.exercisePlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
    });

    if (!existingPlan) {
      throw new NotFoundException('Exercise plan not found');
    }

    // Delete existing items if items are being updated
    if (updateDto.items) {
      await this.prisma.exercisePlanItem.deleteMany({
        where: { planId },
      });
    }

    const plan = await this.prisma.exercisePlan.update({
      where: { planId },
      data: {
        ...(updateDto.planName && { planName: updateDto.planName }),
        ...(updateDto.description !== undefined && { description: updateDto.description || null }),
        ...(updateDto.items && {
          items: {
            create: updateDto.items.map((item) => ({
              dayOfWeek: item.dayOfWeek,
              activityType: item.activityType,
              description: item.description,
              durationMinutes: item.durationMinutes || null,
              caloriesBurned: item.caloriesBurned || null,
              intensity: item.intensity || null,
              notes: item.notes || null,
            })),
          },
        }),
      },
      include: {
        items: true,
      },
    });

    return this.mapExercisePlanToResponse(plan);
  }

  async deleteExercisePlan(context: ActorContext, planId: bigint) {
    const plan = await this.prisma.exercisePlan.findFirst({
      where: {
        planId,
        userId: context.elderUserId,
      },
    });

    if (!plan) {
      throw new NotFoundException('Exercise plan not found');
    }

    await this.prisma.exercisePlan.delete({
      where: { planId },
    });

    return { message: 'Exercise plan deleted successfully' };
  }

  async applyExercisePlan(context: ActorContext, planId: bigint, applyDto: ApplyPlanDto) {
    const plan = await this.findExercisePlanById(context, planId);
    const startDate = getPKTDateOnly(applyDto.startDate);
    const overwriteExisting = applyDto.overwriteExisting || false;

    const createdLogs = [];
    const skippedLogs = [];

    // Group items by day of week
    const itemsByDay = new Map<number, typeof plan.items>();
    plan.items.forEach((item: any) => {
      if (!itemsByDay.has(item.dayOfWeek)) {
        itemsByDay.set(item.dayOfWeek, []);
      }
      itemsByDay.get(item.dayOfWeek)!.push(item);
    });

    // Process each day of the week
    for (let dayOffset = 0; dayOffset < 7; dayOffset++) {
      const targetDate = new Date(startDate);
      targetDate.setDate(targetDate.getDate() + dayOffset);
      const dayOfWeek = targetDate.getDay();

      const itemsForDay = itemsByDay.get(dayOfWeek) || [];

      // Check if logs already exist for this date
      if (!overwriteExisting) {
        const existingLogs = await this.prisma.exerciseLog.findMany({
          where: {
            userId: context.elderUserId,
            logDate: targetDate,
          },
        });

        if (existingLogs.length > 0) {
          skippedLogs.push({
            date: targetDate.toISOString().split('T')[0],
            count: itemsForDay.length,
          });
          continue;
        }
      } else {
        // Delete existing logs for this date
        await this.prisma.exerciseLog.deleteMany({
          where: {
            userId: context.elderUserId,
            logDate: targetDate,
          },
        });
      }

      // Create logs for each item
      for (const item of itemsForDay) {
        const log = await this.prisma.exerciseLog.create({
          data: {
            userId: context.elderUserId,
            logDate: getPKTDateOnly(targetDate),
            exerciseType: item.activityType,
            description: item.description,
            durationMinutes: item.durationMinutes || null,
            caloriesBurned: item.caloriesBurned || null,
            intensity: item.intensity || null,
            notes: item.notes || null,
            sourcePlanId: planId,
          },
        });
        createdLogs.push(this.mapExerciseLogToResponse(log));
      }
    }

    return {
      message: 'Exercise plan applied successfully',
      createdLogs: createdLogs.length,
      skippedLogs: skippedLogs.length,
      details: {
        created: createdLogs,
        skipped: skippedLogs,
      },
    };
  }

  // ============================================
  // Plan Compliance Methods
  // ============================================

  async getDietPlanCompliance(
    context: ActorContext,
    planId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const plan = await this.findDietPlanById(context, planId);

    // Get all plan items grouped by day of week
    const itemsByDayOfWeek = new Map<number, any[]>();
    plan.items.forEach((item: any) => {
      if (!itemsByDayOfWeek.has(item.dayOfWeek)) {
        itemsByDayOfWeek.set(item.dayOfWeek, []);
      }
      itemsByDayOfWeek.get(item.dayOfWeek)!.push(item);
    });

    const dailyBreakdown = [];
    let totalPlanned = 0;
    let totalMatched = 0;

    // Process each day in the date range
    const currentDate = new Date(startDate);
    while (currentDate <= endDate) {
      const dayOfWeek = currentDate.getDay();
      const dateStr = currentDate.toISOString().split('T')[0];
      const plannedItems = itemsByDayOfWeek.get(dayOfWeek) || [];

      // Get actual logs for this date
      const actualLogs = await this.prisma.dietLog.findMany({
        where: {
          userId: context.elderUserId,
          logDate: currentDate,
        },
      });

      // Match planned items with actual logs
      const details = [];
      const matchedItems = new Set<number>();

      for (const plannedItem of plannedItems) {
        let matched = false;
        let matchedLog = null;

        // Try to find a matching log by mealType
        for (let i = 0; i < actualLogs.length; i++) {
          if (
            !matchedItems.has(i) &&
            actualLogs[i].mealType === plannedItem.mealType
          ) {
            matched = true;
            matchedLog = actualLogs[i];
            matchedItems.add(i);
            break;
          }
        }

        details.push({
          planned: {
            mealType: plannedItem.mealType,
            description: plannedItem.description,
            calories: plannedItem.calories || 0,
          },
          actual: matchedLog
            ? {
                mealType: matchedLog.mealType,
                description: matchedLog.foodItems || '',
                calories: matchedLog.calories || 0,
              }
            : null,
          matched,
        });

        if (matched) {
          totalMatched++;
        }
      }

      // Add extra logs (not matched to any planned item)
      for (let i = 0; i < actualLogs.length; i++) {
        if (!matchedItems.has(i)) {
          details.push({
            planned: null,
            actual: {
              mealType: actualLogs[i].mealType,
              description: actualLogs[i].foodItems || '',
              calories: actualLogs[i].calories || 0,
            },
            matched: false,
          });
        }
      }

      const compliance =
        plannedItems.length > 0
          ? (details.filter((d) => d.matched && d.planned).length /
              plannedItems.length) *
            100
          : 100;

      dailyBreakdown.push({
        date: dateStr,
        planned: plannedItems.length,
        actual: actualLogs.length,
        matched: details.filter((d) => d.matched && d.planned).length,
        compliance: Math.round(compliance * 100) / 100,
        details,
      });

      totalPlanned += plannedItems.length;
      currentDate.setDate(currentDate.getDate() + 1);
    }

    const overallCompliance =
      totalPlanned > 0 ? (totalMatched / totalPlanned) * 100 : 100;

    return {
      planId: planId.toString(),
      period: {
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
      },
      overallCompliance: Math.round(overallCompliance * 100) / 100,
      dailyBreakdown,
    };
  }

  async getExercisePlanCompliance(
    context: ActorContext,
    planId: bigint,
    startDate: Date,
    endDate: Date,
  ) {
    const plan = await this.findExercisePlanById(context, planId);

    // Get all plan items grouped by day of week
    const itemsByDayOfWeek = new Map<number, any[]>();
    plan.items.forEach((item: any) => {
      if (!itemsByDayOfWeek.has(item.dayOfWeek)) {
        itemsByDayOfWeek.set(item.dayOfWeek, []);
      }
      itemsByDayOfWeek.get(item.dayOfWeek)!.push(item);
    });

    const dailyBreakdown = [];
    let totalPlanned = 0;
    let totalMatched = 0;

    // Process each day in the date range
    const currentDate = new Date(startDate);
    while (currentDate <= endDate) {
      const dayOfWeek = currentDate.getDay();
      const dateStr = currentDate.toISOString().split('T')[0];
      const plannedItems = itemsByDayOfWeek.get(dayOfWeek) || [];

      // Get actual logs for this date
      const actualLogs = await this.prisma.exerciseLog.findMany({
        where: {
          userId: context.elderUserId,
          logDate: currentDate,
        },
      });

      // Match planned items with actual logs
      const details = [];
      const matchedItems = new Set<number>();

      for (const plannedItem of plannedItems) {
        let matched = false;
        let matchedLog = null;

        // Try to find a matching log by activityType
        for (let i = 0; i < actualLogs.length; i++) {
          if (
            !matchedItems.has(i) &&
            actualLogs[i].exerciseType === plannedItem.activityType
          ) {
            matched = true;
            matchedLog = actualLogs[i];
            matchedItems.add(i);
            break;
          }
        }

        details.push({
          planned: {
            activityType: plannedItem.activityType,
            description: plannedItem.description,
            durationMinutes: plannedItem.durationMinutes || 0,
            caloriesBurned: plannedItem.caloriesBurned || 0,
          },
          actual: matchedLog
            ? {
                activityType: matchedLog.exerciseType,
                description: matchedLog.description || '',
                durationMinutes: matchedLog.durationMinutes || 0,
                caloriesBurned: matchedLog.caloriesBurned || 0,
              }
            : null,
          matched,
        });

        if (matched) {
          totalMatched++;
        }
      }

      // Add extra logs (not matched to any planned item)
      for (let i = 0; i < actualLogs.length; i++) {
        if (!matchedItems.has(i)) {
          details.push({
            planned: null,
            actual: {
              activityType: actualLogs[i].exerciseType,
              description: actualLogs[i].description || '',
              durationMinutes: actualLogs[i].durationMinutes || 0,
              caloriesBurned: actualLogs[i].caloriesBurned || 0,
            },
            matched: false,
          });
        }
      }

      const compliance =
        plannedItems.length > 0
          ? (details.filter((d) => d.matched && d.planned).length /
              plannedItems.length) *
            100
          : 100;

      dailyBreakdown.push({
        date: dateStr,
        planned: plannedItems.length,
        actual: actualLogs.length,
        matched: details.filter((d) => d.matched && d.planned).length,
        compliance: Math.round(compliance * 100) / 100,
        details,
      });

      totalPlanned += plannedItems.length;
      currentDate.setDate(currentDate.getDate() + 1);
    }

    const overallCompliance =
      totalPlanned > 0 ? (totalMatched / totalPlanned) * 100 : 100;

    return {
      planId: planId.toString(),
      period: {
        startDate: startDate.toISOString().split('T')[0],
        endDate: endDate.toISOString().split('T')[0],
      },
      overallCompliance: Math.round(overallCompliance * 100) / 100,
      dailyBreakdown,
    };
  }

  // ============================================
  // Plan Mappers
  // ============================================

  private mapDietPlanToResponse(plan: any) {
    return {
      id: plan.planId.toString(),
      planName: plan.planName,
      description: plan.description || '',
      isActive: plan.isActive,
      userId: plan.userId.toString(),
      items: plan.items.map((item: any) => ({
        id: item.itemId.toString(),
        dayOfWeek: item.dayOfWeek,
        mealType: item.mealType,
        description: item.description,
        calories: item.calories || 0,
        notes: item.notes || '',
      })),
      createdAt: plan.createdAt.toISOString(),
      updatedAt: plan.updatedAt.toISOString(),
    };
  }

  private mapExercisePlanToResponse(plan: any) {
    return {
      id: plan.planId.toString(),
      planName: plan.planName,
      description: plan.description || '',
      isActive: plan.isActive,
      userId: plan.userId.toString(),
      items: plan.items.map((item: any) => ({
        id: item.itemId.toString(),
        dayOfWeek: item.dayOfWeek,
        activityType: item.activityType,
        description: item.description,
        durationMinutes: item.durationMinutes || 0,
        caloriesBurned: item.caloriesBurned || 0,
        intensity: item.intensity || '',
        notes: item.notes || '',
      })),
      createdAt: plan.createdAt.toISOString(),
      updatedAt: plan.updatedAt.toISOString(),
    };
  }
}

