import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  UseGuards,
  Headers,
  RawBodyRequest,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SubscriptionsService } from './subscriptions.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpgradeSubscriptionDto } from './dto/upgrade-subscription.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { User } from '@prisma/client';
import { Public } from '../common/decorators/public.decorator';
import Stripe from 'stripe';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';

@ApiTags('Subscriptions')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(
    private subscriptionsService: SubscriptionsService,
    private configService: ConfigService,
  ) {}

  @Public()
  @Get('plans')
  @ApiOperation({ summary: 'Get all available subscription plans' })
  @ApiResponse({ status: 200, description: 'Plans retrieved successfully' })
  async getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('current')
  @ApiOperation({ summary: 'Get current user subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription retrieved successfully',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'No active subscription found' })
  async getCurrentSubscription(@CurrentUser() user: User) {
    return this.subscriptionsService.getCurrentSubscription(user.userId.toString());
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('active')
  @ApiOperation({ summary: 'Get all active subscriptions' })
  @ApiResponse({ status: 200, description: 'Active subscriptions retrieved' })
  async getActiveSubscriptions() {
    return this.subscriptionsService.getActiveSubscriptions();
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('create')
  @ApiOperation({ summary: 'Create a new subscription' })
  @ApiResponse({
    status: 201,
    description: 'Subscription created successfully',
  })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async createSubscription(
    @CurrentUser() user: User,
    @Body() createSubscriptionDto: CreateSubscriptionDto,
  ) {
    return this.subscriptionsService.createSubscription(
      user.userId.toString(),
      createSubscriptionDto,
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('upgrade')
  @ApiOperation({ summary: 'Upgrade subscription plan' })
  @ApiResponse({
    status: 200,
    description: 'Subscription upgraded successfully',
  })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async upgradeSubscription(
    @CurrentUser() user: User,
    @Body() upgradeSubscriptionDto: UpgradeSubscriptionDto,
  ) {
    return this.subscriptionsService.upgradeSubscription(
      user.userId.toString(),
      upgradeSubscriptionDto,
    );
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('continue')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Continue with existing plan' })
  @ApiResponse({ status: 200, description: 'Continuing with existing plan' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async continueWithExistingPlan(@CurrentUser() user: User) {
    return this.subscriptionsService.continueWithExistingPlan(user.userId.toString());
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Delete('cancel')
  @ApiOperation({ summary: 'Cancel subscription' })
  @ApiResponse({
    status: 200,
    description: 'Subscription cancelled successfully',
  })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async cancelSubscription(@CurrentUser() user: User) {
    return this.subscriptionsService.cancelSubscription(user.userId.toString());
  }

  @Public()
  @Post('webhooks/stripe')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Stripe webhook handler' })
  async handleStripeWebhook(
    @Headers('stripe-signature') signature: string,
    @Req() request: any,
  ) {
    const webhookSecret = this.configService.get<string>(
      'STRIPE_WEBHOOK_SECRET',
    );
    const stripeKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    const stripe = new Stripe(
      stripeKey && stripeKey !== 'your-stripe-secret-key'
        ? stripeKey
        : 'sk_test_dummy_key_for_development',
      {
        apiVersion: '2025-09-30.clover',
      },
    );

    try {
      const event = stripe.webhooks.constructEvent(
        request.rawBody || '',
        signature,
        webhookSecret || '',
      );

      await this.subscriptionsService.handleStripeWebhook(event);

      return { received: true };
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      return { error: 'Webhook signature verification failed' };
    }
  }
}
