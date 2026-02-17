<?php

namespace App\Libraries;

use App\Config\Jwt as JwtConfig;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class JwtService
{
    public function __construct(private JwtConfig $cfg) {}

    public function createAccessToken(int $userId, string $role): string
    {
        $now = time();
        $payload = [
            'iss' => $this->cfg->issuer,
            'iat' => $now,
            'exp' => $now + $this->cfg->accessTtlSeconds,
            'sub' => (string)$userId,
            'role' => $role,
            'typ' => 'access',
        ];
        return JWT::encode($payload, $this->cfg->secret, 'HS256');
    }

    public function createRefreshToken(int $userId): string
    {
        $now = time();
        $payload = [
            'iss' => $this->cfg->issuer,
            'iat' => $now,
            'exp' => $now + $this->cfg->refreshTtlSeconds,
            'sub' => (string)$userId,
            'typ' => 'refresh',
        ];
        return JWT::encode($payload, $this->cfg->secret, 'HS256');
    }

    public function decode(string $token): object
    {
        return JWT::decode($token, new Key($this->cfg->secret, 'HS256'));
    }
}
