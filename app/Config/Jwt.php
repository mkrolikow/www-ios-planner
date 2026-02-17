<?php

namespace App\Config;

use CodeIgniter\Config\BaseConfig;

class Jwt extends BaseConfig
{
    public string $secret = 'CHANGE_ME_SUPER_SECRET_64CHARS_MIN';
    public string $issuer = 'planer-ci4';
    public int $accessTtlSeconds = 60 * 60;        // 1h
    public int $refreshTtlSeconds = 60 * 60 * 24 * 14; // 14 dni
}
