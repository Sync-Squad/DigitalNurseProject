import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AcceptInvitationByCodeDto {
  @ApiProperty({ description: 'Invitation code', example: 'abc123xyz' })
  @IsString()
  @IsNotEmpty()
  inviteCode!: string;
}

