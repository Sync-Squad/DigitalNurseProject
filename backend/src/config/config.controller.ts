import { Controller, Get, Put, Body, Param, NotFoundException, BadRequestException } from '@nestjs/common';
import { AppConfigService } from './config.service';
import { Public } from '../common/decorators/public.decorator';
import { UpdateGeminiApiKeyDto } from './dto/update-gemini-api-key.dto';

@Controller('config')
export class AppConfigController {
  constructor(private readonly configService: AppConfigService) {}

  /**
   * GET /config/:key
   * Returns a specific configuration value from the database
   */
  @Public()
  @Get(':key')
  async getConfig(@Param('key') key: string) {
    const normalizedKey = key.replace(/-/g, '_');
    const config = await this.configService.getConfigByKey(normalizedKey);

    if (!config) {
      throw new NotFoundException(`Configuration ${key} (normalized: ${normalizedKey}) not found`);
    }

    return {
      apiKey: config.configValue, // Backward compatibility for mobile
      config_key: config.configKey,
      config_value: config.configValue,
      description: config.description,
    };
  }

  /**
   * PUT /config/:key
   * Updates any configuration key in the database
   */
  @Put(':key')
  async updateConfig(
    @Param('key') key: string,
    @Body('value') value?: string,
    @Body('config_value') configValue?: string,
    @Body('description') description?: string,
  ) {
    const finalValue = value ?? configValue;

    if (finalValue === undefined) {
      throw new BadRequestException('Value is required (as "value" or "config_value")');
    }

    const normalizedKey = key.replace(/-/g, '_');
    await this.configService.upsertConfig(normalizedKey, finalValue, description);

    return {
      message: `Configuration ${key} updated successfully`,
      config_key: key,
    };
  }

  /**
   * GET /config
   * Returns all active configuration values
   */
  @Public()
  @Get()
  async getAllConfig() {
    return this.configService.getAllConfig();
  }
}
