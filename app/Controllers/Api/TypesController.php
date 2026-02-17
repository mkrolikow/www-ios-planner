<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\EventTypeModel;

class TypesController extends BaseController
{
    public function index()
    {
        $userId = (int)$this->request->user->id;
        $m = new EventTypeModel();

        // zwracamy typy globalne (user_id null) + userowe
        $types = $m->groupStart()
            ->where('user_id', null)
            ->orWhere('user_id', $userId)
            ->groupEnd()
            ->orderBy('name', 'ASC')
            ->findAll();

        return $this->response->setJSON($types);
    }

    public function create()
    {
        $userId = (int)$this->request->user->id;
        $data = $this->request->getJSON(true) ?? [];

        $name = trim((string)($data['name'] ?? ''));
        $color = strtoupper(trim((string)($data['colorHex'] ?? '#007AFF')));

        if ($name === '') {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'name required']);
        }
        if (!preg_match('/^#[0-9A-F]{6}$/', $color)) {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'colorHex must be #RRGGBB']);
        }

        $m = new EventTypeModel();
        $id = $m->insert([
            'user_id' => $userId,
            'name' => $name,
            'color_hex' => $color,
        ], true);

        return $this->response->setStatusCode(201)->setJSON($m->find($id));
    }

    public function update($id)
    {
        $userId = (int)$this->request->user->id;
        $m = new EventTypeModel();
        $type = $m->find((int)$id);

        if (!$type) return $this->response->setStatusCode(404)->setJSON(['error' => 'not found']);
        if ($type['user_id'] !== null && (int)$type['user_id'] !== $userId) {
            return $this->response->setStatusCode(403)->setJSON(['error' => 'forbidden']);
        }
        // typ globalny może edytować tylko admin:
        if ($type['user_id'] === null && $this->request->user->role !== 'admin') {
            return $this->response->setStatusCode(403)->setJSON(['error' => 'admin only']);
        }

        $data = $this->request->getJSON(true) ?? [];
        $patch = [];

        if (isset($data['name'])) $patch['name'] = trim((string)$data['name']);
        if (isset($data['colorHex'])) {
            $color = strtoupper(trim((string)$data['colorHex']));
            if (!preg_match('/^#[0-9A-F]{6}$/', $color)) {
                return $this->response->setStatusCode(422)->setJSON(['error' => 'colorHex must be #RRGGBB']);
            }
            $patch['color_hex'] = $color;
        }

        $m->update((int)$id, $patch);
        return $this->response->setJSON($m->find((int)$id));
    }

    public function delete($id)
    {
        $userId = (int)$this->request->user->id;
        $m = new EventTypeModel();
        $type = $m->find((int)$id);

        if (!$type) return $this->response->setStatusCode(404)->setJSON(['error' => 'not found']);
        if ($type['user_id'] !== null && (int)$type['user_id'] !== $userId) {
            return $this->response->setStatusCode(403)->setJSON(['error' => 'forbidden']);
        }
        if ($type['user_id'] === null && $this->request->user->role !== 'admin') {
            return $this->response->setStatusCode(403)->setJSON(['error' => 'admin only']);
        }

        $m->delete((int)$id);
        return $this->response->setJSON(['ok' => true]);
    }
}
