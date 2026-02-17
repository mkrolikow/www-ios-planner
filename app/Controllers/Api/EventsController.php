<?php

namespace App\Controllers\Api;

use App\Controllers\BaseController;
use App\Models\EventModel;
use App\Models\EventTypeModel;

class EventsController extends BaseController
{
    public function index()
    {
        $userId = (int)$this->request->user->id;
        $from = (string)$this->request->getGet('from');
        $to   = (string)$this->request->getGet('to');

        if ($from === '' || $to === '') {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'from and to required (YYYY-MM-DD)']);
        }

        // pobieramy zakres (UTC)
        $m = new EventModel();
        $events = $m->where('user_id', $userId)
            ->where('start_at >=', $from . ' 00:00:00')
            ->where('start_at <=', $to . ' 23:59:59')
            ->orderBy('start_at', 'ASC')
            ->findAll();

        // dociągamy typy dla kolorów
        $typeIds = array_values(array_unique(array_filter(array_map(fn($e) => $e['type_id'], $events))));
        $typesById = [];
        if ($typeIds) {
            $tm = new EventTypeModel();
            $types = $tm->whereIn('id', $typeIds)->findAll();
            foreach ($types as $t) $typesById[(int)$t['id']] = $t;
        }

        $out = array_map(function($e) use ($typesById) {
            $tid = $e['type_id'] ? (int)$e['type_id'] : null;
            return [
                'id' => (int)$e['id'],
                'title' => $e['title'],
                'notes' => $e['notes'],
                'typeId' => $tid,
                'startAt' => gmdate('c', strtotime($e['start_at'] . ' UTC')),
                'endAt' => gmdate('c', strtotime($e['end_at'] . ' UTC')),
                'allDay' => (bool)$e['all_day'],
                'type' => $tid && isset($typesById[$tid]) ? [
                    'id' => (int)$typesById[$tid]['id'],
                    'name' => $typesById[$tid]['name'],
                    'colorHex' => $typesById[$tid]['color_hex'],
                ] : null,
            ];
        }, $events);

        return $this->response->setJSON($out);
    }

    public function create()
    {
        $userId = (int)$this->request->user->id;
        $data = $this->request->getJSON(true) ?? [];

        $title = trim((string)($data['title'] ?? ''));
        $startAt = (string)($data['startAt'] ?? '');
        $endAt   = (string)($data['endAt'] ?? '');
        $typeId  = isset($data['typeId']) ? (int)$data['typeId'] : null;
        $allDay  = !empty($data['allDay']);

        if ($title === '' || $startAt === '' || $endAt === '') {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'title, startAt, endAt required']);
        }

        // ISO -> UTC datetime
        $start = gmdate('Y-m-d H:i:s', strtotime($startAt));
        $end   = gmdate('Y-m-d H:i:s', strtotime($endAt));
        if (strtotime($endAt) <= strtotime($startAt)) {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'endAt must be after startAt']);
        }

        $m = new EventModel();
        $id = $m->insert([
            'user_id' => $userId,
            'type_id' => $typeId ?: null,
            'title' => $title,
            'notes' => $data['notes'] ?? null,
            'start_at' => $start,
            'end_at' => $end,
            'all_day' => $allDay ? 1 : 0,
        ], true);

        return $this->response->setStatusCode(201)->setJSON(['id' => (int)$id]);
    }

    public function update($id)
    {
        $userId = (int)$this->request->user->id;
        $m = new EventModel();
        $event = $m->find((int)$id);

        if (!$event) return $this->response->setStatusCode(404)->setJSON(['error' => 'not found']);
        if ((int)$event['user_id'] !== $userId) return $this->response->setStatusCode(403)->setJSON(['error' => 'forbidden']);

        $data = $this->request->getJSON(true) ?? [];
        $patch = [];

        if (isset($data['title'])) $patch['title'] = trim((string)$data['title']);
        if (array_key_exists('notes', $data)) $patch['notes'] = $data['notes'];

        if (isset($data['typeId'])) $patch['type_id'] = $data['typeId'] ? (int)$data['typeId'] : null;
        if (isset($data['allDay'])) $patch['all_day'] = !empty($data['allDay']) ? 1 : 0;

        if (isset($data['startAt'])) $patch['start_at'] = gmdate('Y-m-d H:i:s', strtotime((string)$data['startAt']));
        if (isset($data['endAt']))   $patch['end_at']   = gmdate('Y-m-d H:i:s', strtotime((string)$data['endAt']));

        // walidacja czasu jeśli oba są obecne po patchu
        $start = $patch['start_at'] ?? $event['start_at'];
        $end   = $patch['end_at']   ?? $event['end_at'];
        if (strtotime($end . ' UTC') <= strtotime($start . ' UTC')) {
            return $this->response->setStatusCode(422)->setJSON(['error' => 'endAt must be after startAt']);
        }

        $m->update((int)$id, $patch);
        return $this->response->setJSON(['ok' => true]);
    }

    public function delete($id)
    {
        $userId = (int)$this->request->user->id;
        $m = new EventModel();
        $event = $m->find((int)$id);

        if (!$event) return $this->response->setStatusCode(404)->setJSON(['error' => 'not found']);
        if ((int)$event['user_id'] !== $userId) return $this->response->setStatusCode(403)->setJSON(['error' => 'forbidden']);

        $m->delete((int)$id);
        return $this->response->setJSON(['ok' => true]);
    }
}
