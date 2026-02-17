<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\EventTypeModel;

class TypesController extends BaseController
{
    public function index()
    {
        $m = new EventTypeModel();
        $types = $m->where('user_id', null)->orderBy('name','ASC')->findAll();

        return view('admin/types', ['types' => $types, 'error' => null]);
    }

    public function create()
    {
        $name = trim((string)$this->request->getPost('name'));
        $color = strtoupper(trim((string)$this->request->getPost('color_hex')));

        if ($name === '' || !preg_match('/^#[0-9A-F]{6}$/', $color)) {
            $m = new EventTypeModel();
            $types = $m->where('user_id', null)->orderBy('name','ASC')->findAll();
            return view('admin/types', ['types' => $types, 'error' => 'Podaj nazwę i poprawny kolor #RRGGBB']);
        }

        $m = new EventTypeModel();
        $m->insert([
            'user_id' => null,
            'name' => $name,
            'color_hex' => $color,
        ]);

        return redirect()->to('/admin/types');
    }
}
