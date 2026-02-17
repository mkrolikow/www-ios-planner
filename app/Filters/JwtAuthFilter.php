<?php

namespace App\Filters;

use App\Libraries\JwtService;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class JwtAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $auth = $request->getHeaderLine('Authorization');
        if (!preg_match('/Bearer\s(\S+)/', $auth, $m)) {
            return service('response')->setStatusCode(401)->setJSON(['error' => 'Missing Bearer token']);
        }

        /** @var JwtService $jwt */
        $jwt = service('jwt');
        try {
            $payload = $jwt->decode($m[1]);

            if (($payload->typ ?? '') !== 'access') {
                return service('response')->setStatusCode(401)->setJSON(['error' => 'Invalid token type']);
            }

            // udostępniamy userId/role w request:
            $request->user = (object)[
                'id' => (int)$payload->sub,
                'role' => (string)($payload->role ?? 'user'),
            ];
        } catch (\Throwable $e) {
            return service('response')->setStatusCode(401)->setJSON(['error' => 'Invalid token']);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null) {}
}
