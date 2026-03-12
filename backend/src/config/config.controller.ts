import { Controller, Get, Put, Body, NotFoundException } from '@nestjs/common';
import { AppConfigService } from './config.service';
import { UpdateGeminiApiKeyDto } from './dto/update-gemini-api-key.dto';

@Controller('config')
export class AppConfigController {
  constructor(private readonly configService: AppConfigService) {}

  /**
   * GET /config/gemini-api-key
   * Returns the Gemini API key from the database
   * This endpoint requires authentication (JWT guard is applied globally)
   */
  @Get('gemini-api-key')
  async getGeminiApiKey() {
    const apiKey = await this.configService.getGeminiApiKey();

    if (!apiKey) {
      throw new NotFoundException('Gemini API key not configured');
    }

    return {
      apiKey,
      config_key: 'gemini_api_key',
      config_value: apiKey,
    };
  }

  /**
   * PUT /config/gemini-api-key
   * Updates the Gemini API key in the database
   * This endpoint requires authentication (JWT guard is applied globally)
   */
  @Put('gemini-api-key')
  async updateGeminiApiKey(@Body() dto: UpdateGeminiApiKeyDto) {
    await this.configService.upsertConfig(
      'gemini_api_key',
      dto.apiKey,
      'Google Gemini API key for AI features',
    );

    return {
      message: 'Gemini API key updated successfully',
      config_key: 'gemini_api_key',
    };
  }

  /**
   * GET /config
   * Returns all active configuration values
   * This endpoint requires authentication (JWT guard is applied globally)
   */
  @Get()
  async getAllConfig() {
    const configs = await this.configService.getAllConfig();
    return configs;
  }
}
