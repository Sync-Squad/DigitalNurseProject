// @ts-nocheck
import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import Stripe from 'stripe';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpgradeSubscriptionDto } from './dto/upgrade-subscription.dto';
import { SUBSCRIPTION_PLANS } from './constants/plans.constant';
import { getPKTDate } from '../common/utils/date-utils';

@Injectable()
export class SubscriptionsService {
  private stripe: Stripe;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
  ) {
    const stripeKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (stripeKey && stripeKey !== 'your-stripe-secret-key') {
      this.stripe = new Stripe(stripeKey, {
        apiVersion: '2025-09-30.clover',
      });
    } else {
      // Initialize with dummy key for development/testing
      this.stripe = new Stripe('sk_test_dummy_key_for_development', {
        apiVersion: '2025-09-30.clover',
      });
    }
  }

  async getPlans() {
    return Object.entries(SUBSCRIPTION_PLANS).map(([key, value]) => ({
      planType: key,
      ...value,
    }));
  }

  async getActiveSubscriptions() {
    const subscriptions = await this.prisma.subscription.findMany({
      where: { status: 'active' },
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            full_name: true,
            userId: true,
          },
        },
      },
    });

    const planIds = Array.from(
      new Set(
        subscriptions
          .map((sub) => sub.planId?.toString())
          .filter(Boolean) as string[],
      ),
    );

    const plans =
      planIds.length > 0
        ? await this.prisma.subscriptionPlan.findMany({
            where: { planId: { in: planIds.map((id) => BigInt(id)) } },
          })
        : [];

    const planMap = new Map<string, string>();
    for (const plan of plans) {
      planMap.set(plan.planId.toString(), plan.planCode.toUpperCase());
    }

    return subscriptions.map((sub) => {
      const planCode = sub.planId
        ? planMap.get(sub.planId.toString()) || 'BASIC'
        : 'FREE';
      const plan =
        planCode === 'PREMIUM'
          ? 'Premium'
          : planCode === 'FREE'
            ? 'Free'
            : 'Essential';

      const renewalDate =
        sub.endDate ??
        getPKTDate(sub.startDate.getTime() + 30 * 24 * 60 * 60 * 1000);

      const daysUntilRenewal = Math.ceil(
        (renewalDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24),
      );

      const paymentStatus =
        daysUntilRenewal < 0 ? 'Past Due' : daysUntilRenewal <= 7 ? 'Due' : 'Paid';

      return {
        id: sub.subscriptionId.toString(),
        patientId: sub.userId.toString(),
        patient: sub.user?.full_name || 'Unknown',
        plan,
        renewalDate: renewalDate.toISOString(),
        paymentStatus,
        lastInvoice: `INV-${sub.subscriptionId.toString().padStart(6, '0')}`,
        addOns: [] as string[],
      };
    });
  }

  async getCurrentSubscription(userId: string) {
    const userIdBigInt = BigInt(userId);
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        userId: userIdBigInt,
        status: 'active',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    if (!subscription) {
      throw new NotFoundException('No active subscription found');
    }

    // Get plan details from SubscriptionPlan if planId exists, otherwise assume FREE
    let planDetails: typeof SUBSCRIPTION_PLANS[keyof typeof SUBSCRIPTION_PLANS] = SUBSCRIPTION_PLANS.FREE;
    if (subscription.planId) {
      const plan = await this.prisma.subscriptionPlan.findUnique({
        where: { planId: subscription.planId },
      });
      if (plan) {
        const planCode = plan.planCode.toUpperCase();
        const foundPlan = SUBSCRIPTION_PLANS[planCode as keyof typeof SUBSCRIPTION_PLANS];
        if (foundPlan) {
          planDetails = foundPlan;
        }
      }
    }

    return {
      ...subscription,
      subscriptionId: subscription.subscriptionId.toString(),
      userId: subscription.userId.toString(),
      planDetails,
    };
  }

  async createSubscription(
    userId: string,
    createSubscriptionDto: CreateSubscriptionDto,
  ) {
    const { planType } = createSubscriptionDto;

    if (planType === 'FREE') {
      throw new BadRequestException(
        'Cannot create a FREE subscription through this endpoint',
      );
    }

    // Get user
    const userIdBigInt = BigInt(userId);
    const user = await this.prisma.user.findUnique({
      where: { userId: userIdBigInt },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check for existing active subscription
    const existingSubscription = await this.prisma.subscription.findFirst({
      where: {
        userId: userIdBigInt,
        status: 'active',
      },
    });

    // Check if user has a paid plan (non-null planId means paid plan)
    if (existingSubscription && existingSubscription.planId !== null) {
      throw new BadRequestException(
        'User already has an active paid subscription',
      );
    }

    // Get or create SubscriptionPlan record
    const plan = await this.prisma.subscriptionPlan.findUnique({
      where: { planCode: planType.toLowerCase() },
    });

    let planId: bigint | null = null;
    if (!plan) {
      // Create plan if it doesn't exist
      const planDetails = SUBSCRIPTION_PLANS[planType];
      const newPlan = await this.prisma.subscriptionPlan.create({
        data: {
          planCode: planType.toLowerCase(),
          planName: planDetails.name,
          currency: planDetails.currency,
          monthlyPrice: planDetails.price,
          limits: planDetails.features || {},
        },
      });
      planId = newPlan.planId;
    } else {
      planId = plan.planId;
    }

    // Create or retrieve Stripe customer
    // Note: Stripe integration fields don't exist in schema - storing in metadata/separate table would be needed
    let stripeCustomerId: string | undefined;
    if (user.email) {
      try {
        const customer = await this.stripe.customers.create({
          email: user.email,
          name: user.full_name || undefined,
          metadata: {
            userId: userId,
          },
        });
        stripeCustomerId = customer.id;
      } catch (error) {
        console.warn('Stripe customer creation failed:', error);
      }
    }

    // Create Stripe checkout session
    const planDetails = SUBSCRIPTION_PLANS[planType];

    let session: Stripe.Checkout.Session | null = null;
    if (stripeCustomerId && planDetails.stripePriceId) {
      try {
        session = await this.stripe.checkout.sessions.create({
          customer: stripeCustomerId,
          payment_method_types: ['card'],
          line_items: [
            {
              price: planDetails.stripePriceId,
              quantity: 1,
            },
          ],
          mode: 'subscription',
          success_url: `${this.configService.get<string>('APP_BASE_URL') || this.configService.get<string>('FRONTEND_URL')}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
          cancel_url: `${this.configService.get<string>('APP_BASE_URL') || this.configService.get<string>('FRONTEND_URL')}/subscription/cancel`,
          metadata: {
            userId,
            planType,
          },
        });
      } catch (error) {
        console.warn('Stripe checkout session creation failed:', error);
      }
    }

    // Update or create subscription
    if (existingSubscription) {
      await this.prisma.subscription.update({
        where: { subscriptionId: existingSubscription.subscriptionId },
        data: {
          status: 'active',
          planId,
        },
      });
    } else {
      await this.prisma.subscription.create({
        data: {
          userId: userIdBigInt,
          planId,
          status: 'active',
        },
      });
    }

    if (session) {
      return {
        sessionId: session.id,
        sessionUrl: session.url,
      };
    } else {
      // Return success even if Stripe fails (for development/testing)
      return {
        message: 'Subscription created successfully',
        note: 'Stripe integration not available',
      };
    }
  }

  async upgradeSubscription(
    userId: string,
    upgradeSubscriptionDto: UpgradeSubscriptionDto,
  ) {
    const { newPlanType } = upgradeSubscriptionDto;
    const userIdBigInt = BigInt(userId);

    const currentSubscription = await this.prisma.subscription.findFirst({
      where: {
        userId: userIdBigInt,
        status: 'active',
      },
    });

    if (!currentSubscription) {
      throw new NotFoundException('No active subscription found');
    }

    // Get current plan code
    let currentPlanCode = 'FREE';
    if (currentSubscription.planId) {
      const currentPlan = await this.prisma.subscriptionPlan.findUnique({
        where: { planId: currentSubscription.planId },
      });
      if (currentPlan) {
        currentPlanCode = currentPlan.planCode.toUpperCase();
      }
    }

    if (currentPlanCode === newPlanType) {
      throw new BadRequestException('User is already on this plan');
    }

    // Check if upgrade is valid (prevent downgrade through this endpoint)
    const planHierarchy = { FREE: 0, BASIC: 1, PREMIUM: 2 };
    if (planHierarchy[newPlanType] <= planHierarchy[currentPlanCode as keyof typeof planHierarchy]) {
      throw new BadRequestException(
        'Use downgrade or cancel endpoint for this operation',
      );
    }

    // Get or create new plan
    let newPlanId: bigint | null = null;
    const newPlan = await this.prisma.subscriptionPlan.findUnique({
      where: { planCode: newPlanType.toLowerCase() },
    });

    if (newPlan) {
      newPlanId = newPlan.planId;
    } else {
      // Create plan if it doesn't exist
      const planDetails = SUBSCRIPTION_PLANS[newPlanType];
      const createdPlan = await this.prisma.subscriptionPlan.create({
        data: {
          planCode: newPlanType.toLowerCase(),
          planName: planDetails.name,
          currency: planDetails.currency,
          monthlyPrice: planDetails.price,
          limits: planDetails.features || {},
        },
      });
      newPlanId = createdPlan.planId;
    }

    // Update subscription in database
    const updatedSubscription = await this.prisma.subscription.update({
      where: { subscriptionId: currentSubscription.subscriptionId },
      data: {
        planId: newPlanId,
        updatedAt: getPKTDate(),
      },
    });

    return {
      message: 'Subscription upgraded successfully',
      subscription: {
        ...updatedSubscription,
        subscriptionId: updatedSubscription.subscriptionId.toString(),
        userId: updatedSubscription.userId.toString(),
      },
    };
  }

  async continueWithExistingPlan(userId: string) {
    const subscription = await this.getCurrentSubscription(userId);

    return {
      message: 'Continuing with existing plan',
      subscription,
    };
  }

  async cancelSubscription(userId: string) {
    const userIdBigInt = BigInt(userId);
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        userId: userIdBigInt,
        status: 'active',
      },
    });

    if (!subscription) {
      throw new NotFoundException('No active subscription found');
    }

    // Check if it's a FREE plan
    if (subscription.planId === null) {
      throw new BadRequestException('Cannot cancel FREE subscription');
    }

    // Update subscription to set endDate (cancellation)
    const updatedSubscription = await this.prisma.subscription.update({
      where: { subscriptionId: subscription.subscriptionId },
      data: {
        status: 'cancelled',
        endDate: getPKTDate(),
        updatedAt: getPKTDate(),
      },
    });

    return {
      message: 'Subscription cancelled successfully',
      subscription: {
        ...updatedSubscription,
        subscriptionId: updatedSubscription.subscriptionId.toString(),
        userId: updatedSubscription.userId.toString(),
      },
    };
  }

  async handleStripeWebhook(event: Stripe.Event) {
    switch (event.type) {
      case 'checkout.session.completed':
        await this.handleCheckoutSessionCompleted(
          event.data.object as Stripe.Checkout.Session,
        );
        break;

      case 'customer.subscription.updated':
        await this.handleSubscriptionUpdated(
          event.data.object as Stripe.Subscription,
        );
        break;

      case 'customer.subscription.deleted':
        await this.handleSubscriptionDeleted(
          event.data.object as Stripe.Subscription,
        );
        break;

      case 'invoice.payment_succeeded':
        await this.handleInvoicePaymentSucceeded(
          event.data.object as Stripe.Invoice,
        );
        break;

      case 'invoice.payment_failed':
        await this.handleInvoicePaymentFailed(
          event.data.object as Stripe.Invoice,
        );
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
  }

  private async handleCheckoutSessionCompleted(
    session: Stripe.Checkout.Session,
  ) {
    const userId = session.metadata?.userId;
    const planType = session.metadata?.planType;

    if (!userId || !planType) {
      console.error('Missing metadata in checkout session');
      return;
    }

    const userIdBigInt = BigInt(userId);

    // Get or create plan
    const plan = await this.prisma.subscriptionPlan.findUnique({
      where: { planCode: planType.toLowerCase() },
    });

    let planId: bigint | null = null;
    if (plan) {
      planId = plan.planId;
    } else {
      const planDetails = SUBSCRIPTION_PLANS[planType as keyof typeof SUBSCRIPTION_PLANS];
      if (planDetails) {
        const newPlan = await this.prisma.subscriptionPlan.create({
          data: {
            planCode: planType.toLowerCase(),
            planName: planDetails.name,
            currency: planDetails.currency,
            monthlyPrice: planDetails.price,
            limits: planDetails.features || {},
          },
        });
        planId = newPlan.planId;
      }
    }

    // Update subscription to active
    await this.prisma.subscription.updateMany({
      where: {
        userId: userIdBigInt,
        status: 'active',
      },
      data: {
        planId,
        status: 'active',
      },
    });

    // Note: Payment model doesn't exist in schema - would need to be added for payment tracking
    console.log('Payment completed:', {
      userId,
      amount: (session.amount_total || 0) / 100,
      currency: session.currency,
    });
  }

  private async handleSubscriptionUpdated(subscription: Stripe.Subscription) {
    // Note: stripeSubscriptionId field doesn't exist in schema
    // This would need to be stored in a separate mapping table or added to schema
    console.log('Stripe subscription updated:', {
      subscriptionId: subscription.id,
      status: subscription.status,
    });
    // Would need additional logic to map Stripe subscription to database subscription
  }

  private async handleSubscriptionDeleted(subscription: Stripe.Subscription) {
    // Note: stripeSubscriptionId field doesn't exist in schema
    // This would need to be stored in a separate mapping table or added to schema
    console.log('Stripe subscription deleted:', {
      subscriptionId: subscription.id,
    });
    // Would need additional logic to map Stripe subscription to database subscription
    // and handle downgrade to FREE plan
  }

  private async handleInvoicePaymentSucceeded(invoice: Stripe.Invoice) {
    const invoiceData = invoice as any;
    if (!invoiceData.subscription) return;

    // Note: Payment model and stripeSubscriptionId don't exist in schema
    console.log('Invoice payment succeeded:', {
      subscriptionId: invoiceData.subscription,
      amount: (invoice.amount_paid || 0) / 100,
      currency: invoice.currency,
    });
    // Would need Payment model and Stripe mapping to properly track payments
  }

  private async handleInvoicePaymentFailed(invoice: Stripe.Invoice) {
    const invoiceData = invoice as any;
    if (!invoiceData.subscription) return;

    // Note: Payment model and stripeSubscriptionId don't exist in schema
    console.log('Invoice payment failed:', {
      subscriptionId: invoiceData.subscription,
      amount: (invoice.amount_due || 0) / 100,
      currency: invoice.currency,
    });
    // Would need Payment model and Stripe mapping to properly track failed payments
  }
}
