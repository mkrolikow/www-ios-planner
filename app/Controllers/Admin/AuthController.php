<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;
use App\Models\UserModel;

class AuthController extends BaseController
{
    public function loginForm()
    {
        return view('admin/login', ['error' => null]);
    }

    public function loginPost()
    {
        $email = trim((string)$this->request->getPost('email'));
        $password = (string)$this->request->getPost('password');

        $users = new UserModel();
        $user = $users->findActiveByEmail($email);

        if (!$user || $user['role'] !== 'admin' || !password_verify($password, $user['password_hash'])) {
            return view('admin/login', ['error' => 'Nieprawidłowe dane logowania.']);
        }

        session()->set([
            'admin_logged_in' => true,
            'admin_id' => (int)$user['id'],
            'admin_email' => $user['email'],
        ]);

        return redirect()->to('/admin');
    }

    public function logout()
    {
        session()->destroy();
        return redirect()->to('/admin/login');
    }
}
