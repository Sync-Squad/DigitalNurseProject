import { IsString, IsNotEmpty } from 'class-validator';

export class UpdateGeminiApiKeyDto {
  @IsString()
  @IsNotEmpty()
  apiKey!: string;
}

