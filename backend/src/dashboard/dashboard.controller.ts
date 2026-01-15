import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Dashboard')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) { }

  @Get('metrics')
  @ApiOperation({ summary: 'Get dashboard summary metrics' })
  @ApiResponse({ status: 200, description: 'Dashboard metrics retrieved' })
  async getMetrics(@CurrentUser() user: any) {
    return this.dashboardService.getMetrics(user);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get dashboard growth and breakdown stats' })
  @ApiResponse({ status: 200, description: 'Dashboard stats retrieved' })
  async getStats(@CurrentUser() user: any) {
    return this.dashboardService.getStats(user);
  }
}

