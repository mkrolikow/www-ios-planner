<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table = 'users';
    protected $primaryKey = 'id';

    protected $allowedFields = [
        'email','password_hash','name','role','is_active'
    ];

    protected $useTimestamps = true;

    public function findActiveByEmail(string $email)
    {
        return $this->where('email', $email)->where('is_active', 1)->first();
    }
}
