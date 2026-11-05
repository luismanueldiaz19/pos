<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run()
    {
        // 🔐 PERMISOS
        $permisos = [

            // CLIENTES
            'ver_clientes',
            'crear_clientes',
            'editar_clientes',
            'eliminar_clientes',

            // PRODUCTOS
            'ver_productos',
            'crear_productos',
            'editar_productos',
            'eliminar_productos',

            // FACTURAS
            'ver_facturas',
            'crear_facturas',
            'editar_facturas',
            'eliminar_facturas',

            // EVENTOS / BUFFET
            'ver_eventos',
            'crear_eventos',

            // INVENTARIO
            'ver_inventario',
            'crear_inventario',
            'gestionar_recetas',

            // GASTOS
            'ver_gastos',
            'crear_gastos',

            // NOMINA
            'ver_nomina',

            // USUARIOS
            'gestionar_usuarios'
        ];

        foreach ($permisos as $permiso) {
            Permission::firstOrCreate(['name' => $permiso]);
        }

        // 👑 ADMIN
        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->givePermissionTo(Permission::all());

        // 💰 CAJERO
        $cajero = Role::firstOrCreate(['name' => 'cajero']);
        $cajero->givePermissionTo([
            'ver_clientes',
            'crear_clientes',
            'ver_facturas',
            'crear_facturas',
            'ver_productos'
        ]);

        // 🧮 CONTADOR
        $contador = Role::firstOrCreate(['name' => 'contador']);
        $contador->givePermissionTo([
            'ver_clientes',
            'ver_facturas',
            'ver_gastos',
            'ver_nomina',
            'ver_inventario'
        ]);

        // 📝 AUXILIAR CONTABLE
        $auxiliar = Role::firstOrCreate(['name' => 'auxiliar contable']);
        $auxiliar->givePermissionTo([
            'ver_nomina'
        ]);
    }
}
