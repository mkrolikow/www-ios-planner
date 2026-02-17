<?php

namespace App\Models;

use CodeIgniter\Model;

class EventTypeModel extends Model
{
    protected $table = 'event_types';
    protected $primaryKey = 'id';
    protected $allowedFields = ['user_id','name','color_hex'];
    protected $useTimestamps = true;
}
