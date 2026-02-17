<?php

namespace App\Models;

use CodeIgniter\Model;

class EventModel extends Model
{
    protected $table = 'events';
    protected $primaryKey = 'id';
    protected $allowedFields = [
        'user_id','type_id','title','notes','start_at','end_at','all_day'
    ];
    protected $useTimestamps = true;
}
