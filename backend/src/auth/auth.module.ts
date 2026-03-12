import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { EmailModule } from '../email/email.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './strategies/jwt.strategy';
import { LocalStrategy } from './strategies/local.strategy';
import { GoogleStrategy } from './strategies/google.strategy';

// Create providers array conditionally
const createAuthProviders = () => {
  const baseProviders = [AuthService, JwtStrategy, LocalStrategy];
  
  // GoogleStrategy will be conditionally added via factory
  // to prevent initialization errors when credentials are missing
  const googleStrategyProvider = {
    provide: GoogleStrategy,
    useFactory: (configService: ConfigService, authService: AuthService) => {
      const clientID = configService.get<string>('GOOGLE_CLIENT_ID');
      // Only create GoogleStrategy if credentials are configured
      if (clientID && clientID.trim() !== '') {
        return new GoogleStrategy(configService, authService);
      }
      // Return a no-op object to satisfy dependency injection
      // This prevents errors but Google OAuth won't work without credentials
      return Object.create(null);
    },
    inject: [ConfigService, AuthService],
  };
  
  return [...baseProviders, googleStrategyProvider];
};

@Module({
  imports: [
    PassportModule,
    JwtModule.register({}), // Configuration is done in strategies
    ConfigModule,
    EmailModule,
  ],
  controllers: [AuthController],
  providers: createAuthProviders(),
  exports: [AuthService],
})
export class AuthModule {}
