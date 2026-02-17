<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateEvents extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'unsigned' => true],
            'type_id' => ['type' => 'INT', 'unsigned' => true, 'null' => true],
            'title' => ['type' => 'VARCHAR', 'constraint' => 160],
            'notes' => ['type' => 'TEXT', 'null' => true],
            'start_at' => ['type' => 'DATETIME'], // trzymamy UTC
            'end_at' => ['type' => 'DATETIME'],   // trzymamy UTC
            'all_day' => ['type' => 'TINYINT', 'constraint' => 1, 'default' => 0],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey('user_id');
        $this->forge->addKey('type_id');
        $this->forge->createTable('events', true);

        // FK opcjonalnie
        // $this->db->query('ALTER TABLE events ADD CONSTRAINT fk_events_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
        // $this->db->query('ALTER TABLE events ADD CONSTRAINT fk_events_type FOREIGN KEY (type_id) REFERENCES event_types(id) ON DELETE SET NULL');
    }

    public function down()
    {
        $this->forge->dropTable('events', true);
    }
}
