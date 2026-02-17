<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run()
    {
        $this->db->table('users')->insert([
            'email' => 'admin@planer.local',
            'password_hash' => password_hash('Admin123!', PASSWORD_DEFAULT),
            'name' => 'Administrator',
            'role' => 'admin',
            'is_active' => 1,
            'created_at' => date('Y-m-d H:i:s'),
        ]);
    }
}
