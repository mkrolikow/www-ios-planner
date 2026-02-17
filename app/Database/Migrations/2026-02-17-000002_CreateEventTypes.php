<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateEventTypes extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => ['type' => 'INT', 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'unsigned' => true, 'null' => true], // null = globalny typ (admin)
            'name' => ['type' => 'VARCHAR', 'constraint' => 80],
            'color_hex' => ['type' => 'VARCHAR', 'constraint' => 8, 'default' => '#007AFF'],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey('user_id');
        $this->forge->createTable('event_types', true);

        // FK opcjonalnie – na hostingach czasem problematyczne, ale MySQL zwykle ok:
        // $this->db->query('ALTER TABLE event_types ADD CONSTRAINT fk_event_types_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL');
    }

    public function down()
    {
        $this->forge->dropTable('event_types', true);
    }
}
