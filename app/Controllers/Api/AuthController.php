<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\UserModel;

class AuthController extends BaseController
{
    public function login()
    {
        $data = $this->request->getJSON(true) ?? [];
        $email = trim((string)($data['email'] ?? ''));
        $password = (string)($data['password'] ?? '');

        if ($email === '' || $password === '') {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'Email and password required']);
        }

        $users = new UserModel();
        $user = $users->findActiveByEmail($email);

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return $this->response->setStatusCode(401)->setJSON(['error' => 'Invalid credentials']);
        }

        $jwt = service('jwt');
        $access = $jwt->createAccessToken((int)$user['id'], (string)$user['role']);
        $refresh = $jwt->createRefreshToken((int)$user['id']);

        return $this->response->setJSON([
            'accessToken' => $access,
            'refreshToken' => $refresh,
            'user' => [
                'id' => (int)$user['id'],
                'email' => $user['email'],
                'name' => $user['name'],
                'role' => $user['role'],
            ],
        ]);
    }

    public function refresh()
    {
        $data = $this->request->getJSON(true) ?? [];
        $refreshToken = (string)($data['refreshToken'] ?? '');
        if ($refreshToken === '') {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'refreshToken required']);
        }

        $jwt = service('jwt');
        try {
            $payload = $jwt->decode($refreshToken);
            if (($payload->typ ?? '') !== 'refresh') {
                return $this->response->setStatusCode(401)->setJSON(['error' => 'Invalid token type']);
            }

            $users = new UserModel();
            $user = $users->find((int)$payload->sub);
            if (!$user || (int)$user['is_active'] !== 1) {
                return $this->response->setStatusCode(401)->setJSON(['error' => 'User not available']);
            }

            $access = $jwt->createAccessToken((int)$user['id'], (string)$user['role']);
            return $this->response->setJSON(['accessToken' => $access]);
        } catch (\Throwable $e) {
            return $this->response->setStatusCode(401)->setJSON(['error' => 'Invalid refresh token']);
        }
    }
}
