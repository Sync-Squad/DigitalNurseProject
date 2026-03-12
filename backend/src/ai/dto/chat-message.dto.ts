import { IsString, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ChatMessageDto {
  @ApiProperty({
    description: 'User message to the AI assistant',
    example: "How's my blood pressure been?",
  })
  @IsString()
  message!: string;

  @ApiPropertyOptional({
    description: 'Conversation ID for continuing a conversation',
  })
  @IsOptional()
  @IsNumber()
  conversationId?: bigint;

  @ApiPropertyOptional({
    description: 'Elder user ID for context (if caregiver is asking about a patient)',
  })
  @IsOptional()
  @IsNumber()
  elderUserId?: bigint;
}

export class CreateConversationDto {
  @ApiPropertyOptional({
    description: 'Elder user ID for context',
  })
  @IsOptional()
  @IsNumber()
  elderUserId?: bigint;
}

