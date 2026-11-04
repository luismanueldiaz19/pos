<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Caja;
use App\Models\Turno;

class CajaAndTurnoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        /*
        // Crear 5 cajas
        for ($i = 1; $i <= 5; $i++) {
            Caja::updateOrCreate(
                ['id' => $i],
                ['nombre' => "Caja $i", 'activa' => true]
            );
        }

        // Crear 3 turnos
        Turno::updateOrCreate(
            ['id' => 1],
            ['nombre' => 'Mañana', 'hora_inicio' => '08:00:00', 'hora_fin' => '16:00:00']
        );

        Turno::updateOrCreate(
            ['id' => 2],
            ['nombre' => 'Tarde', 'hora_inicio' => '16:00:00', 'hora_fin' => '00:00:00']
        );

        Turno::updateOrCreate(
            ['id' => 3],
            ['nombre' => 'Noche', 'hora_inicio' => '20:00:00', 'hora_fin' => '04:00:00']
        );
        */

        // Crear una sola caja hasta el momento
        Caja::updateOrCreate(
            ['id' => 1],
            ['nombre' => 'Caja 1', 'activa' => true]
        );

        // Crear un solo turno hasta el momento
        Turno::updateOrCreate(
            ['id' => 1],
            ['nombre' => 'Turno Único', 'hora_inicio' => '06:00:00', 'hora_fin' => '17:00:00']
        );
    }
}
