<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Proveedor;

class ProveedorSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run(): void {
        Proveedor::firstOrCreate(
            ['nombre' => 'Gastos Menores / Ocasionales'],
            [
                'rnc' => '000000000',
                'telefono' => '000-000-0000',
                'direccion' => 'Operaciones Locales',
                'es_informal' => true,
                'activo' => true,
            ]
        );




        
        Proveedor::create([
            'nombre' => 'Distribuidora Formal SRL (Ejemplo)',
            'rnc' => '130123456',
            'telefono' => '809-555-1234',
            'email' => 'ventas@distformal.com',
            'direccion' => 'Av. Winston Churchill, Santo Domingo',
            'es_informal' => false,
            'activo' => true,
        ]);

        Proveedor::create([
            'nombre' => 'Juan Pérez - Colmado Informal (Ejemplo)',
            'rnc' => '00101234567',
            'telefono' => '829-555-9876',
            'email' => null,
            'direccion' => 'Calle Central, Ensanche Ensanche, Sto Dgo',
            'es_informal' => true,
            'activo' => true,
        ]);
    }
}
