import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ResetPasswordDto {
    @ApiProperty({
        example: 'abcdef123456...',
        description: 'The reset password token from the email link',
    })
    @IsString()
    @IsNotEmpty()
    token!: string;

    @ApiProperty({ example: 'StrongNewPassword123!' })
    @IsString()
    @MinLength(8)
    newPassword!: string;
}
