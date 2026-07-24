import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto, VerifyOtpDto, SetPasswordDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { JwtPayload } from './interfaces/jwt-payload.interface';

interface OtpEntry {
  nis: string;
  otp: string;
  expiresAt: Date;
}

@Injectable()
export class AuthService {
  private otpStore: Map<string, OtpEntry> = new Map();

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { nis: dto.nis } });
    if (existing) throw new ConflictException('NIS already exists');

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    this.otpStore.set(dto.nis, {
      nis: dto.nis,
      otp,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    });

    return {
      message: 'Registration initiated. Please verify OTP.',
      nis: dto.nis,
      otp,
    };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const entry = this.otpStore.get(dto.nis);
    if (!entry) throw new BadRequestException('OTP not requested or expired');

    if (new Date() > entry.expiresAt) {
      this.otpStore.delete(dto.nis);
      throw new BadRequestException('OTP has expired. Please register again.');
    }

    if (entry.otp !== dto.otp) throw new BadRequestException('Invalid OTP');

    this.otpStore.set(`${dto.nis}:verified`, entry);
    this.otpStore.delete(dto.nis);

    return { message: 'OTP verified. Please set your password.', nis: dto.nis };
  }

  async setPassword(dto: SetPasswordDto) {
    const verified = this.otpStore.get(`${dto.nis}:verified`);
    if (!verified) throw new BadRequestException('OTP not verified');

    const existing = await this.prisma.user.findUnique({ where: { nis: dto.nis } });
    if (existing && !existing.isFirstLogin) {
      throw new BadRequestException('Password already set');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.upsert({
      where: { nis: dto.nis },
      update: {
        password: hashedPassword,
        isFirstLogin: false,
        isActive: true,
      },
      create: {
        nis: dto.nis,
        name: verified.nis,
        password: hashedPassword,
        role: 'SISWA',
      },
    });

    this.otpStore.delete(`${dto.nis}:verified`);

    return { message: 'Password set successfully. You can now login.', nis: user.nis };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { nis: dto.nis },
    });

    if (!user) throw new UnauthorizedException('Invalid NIS or password');
    if (!user.isActive) throw new UnauthorizedException('Account is deactivated');
    if (user.isFirstLogin) throw new UnauthorizedException('Please set your password first');

    const isPasswordValid = await bcrypt.compare(dto.password, user.password);
    if (!isPasswordValid) throw new UnauthorizedException('Invalid NIS or password');

    const tokens = await this.generateTokens(user.id, user.role);

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.prisma.session.create({
      data: {
        userId: user.id,
        token: tokens.accessToken,
        expiresAt,
      },
    });

    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: tokens.refreshToken,
        expiresAt,
      },
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLogin: new Date() },
    });

    return {
      user: {
        id: user.id,
        nis: user.nis,
        nip: user.nip,
        name: user.name,
        email: user.email,
        role: user.role,
      },
      ...tokens,
    };
  }

  async refreshToken(dto: RefreshDto) {
    try {
      const payload = this.jwtService.verify<JwtPayload>(dto.refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const storedToken = await this.prisma.refreshToken.findUnique({
        where: { token: dto.refreshToken },
      });

      if (!storedToken || !storedToken.isActive) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      if (new Date() > storedToken.expiresAt) {
        throw new UnauthorizedException('Refresh token expired');
      }

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found or deactivated');
      }

      const tokens = await this.generateTokens(user.id, user.role);

      await this.prisma.refreshToken.update({
        where: { id: storedToken.id },
        data: { isActive: false },
      });

      const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

      await this.prisma.refreshToken.create({
        data: {
          userId: user.id,
          token: tokens.refreshToken,
          expiresAt,
        },
      });

      await this.prisma.session.create({
        data: {
          userId: user.id,
          token: tokens.accessToken,
          expiresAt,
        },
      });

      return tokens;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async logout(userId: string, refreshToken: string) {
    await this.prisma.session.updateMany({
      where: { userId, isActive: true },
      data: { isActive: false },
    });

    await this.prisma.refreshToken.updateMany({
      where: { userId, isActive: true },
      data: { isActive: false },
    });

    if (refreshToken) {
      await this.prisma.refreshToken.update({
        where: { token: refreshToken },
        data: { isActive: false },
      });
    }

    return { message: 'Logged out successfully' };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        nis: true,
        nip: true,
        name: true,
        email: true,
        role: true,
        gender: true,
        phone: true,
        address: true,
        photo: true,
        birthDate: true,
        birthPlace: true,
        isActive: true,
        isFirstLogin: true,
        lastLogin: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) throw new NotFoundException('User not found');

    return user;
  }

  private async generateTokens(userId: string, role: string) {
    const payload: JwtPayload = { sub: userId, nis: '', role };

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { nis: true },
    });

    if (user) payload.nis = user.nis;

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_SECRET'),
        expiresIn: this.configService.get<string>('JWT_EXPIRES_IN') || '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') || '7d',
      }),
    ]);

    return { accessToken, refreshToken };
  }
}
