<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // Crear usuario administrador
        $admin = User::firstOrCreate(
            ['username' => 'ludeveloper'],
            [
                'name'     => 'Administrador',
                'email'    => 'lwader@gmail.com',
                'password' => Hash::make('199512'), // Cambiar en producción
            ]
        );


        // Asignar rol admin (que incluye todos los permisos)
        $admin->assignRole('admin');

        // Crear usuario cajero
        $cajero = User::firstOrCreate(
            ['username' => 'cajero'],
            [
                'name'     => 'Cajera 1',
                'email'    => 'cajero@gmail.com',
                'password' => Hash::make('cajero123'),
            ]
        );
        $cajero->assignRole('cajero');

        // // Crear segundo usuario cajero
        // $cajero2 = User::firstOrCreate(
        //     ['username' => 'cajero2'],
        //     [
        //         'name'     => 'Cajero Dos',
        //         'email'    => 'cajero2@gmail.com',
        //         'password' => Hash::make('cajero123'),
        //     ]
        // );
        // $cajero2->assignRole('cajero');
    }
}
