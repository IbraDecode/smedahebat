export interface JwtPayload {
  sub: string;
  nis: string;
  role: string;
}

export interface JwtPayloadWithRt extends JwtPayload {
  refreshToken: string;
}
