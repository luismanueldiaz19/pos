<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\CatalogoCuenta;

class CatalogoCuentasSeeder extends Seeder
{
    public function run()
    {
        // --- 1. ACTIVOS ---
        $activos = CatalogoCuenta::create([
            'codigo' => '1',
            'nombre' => 'ACTIVOS',
            'tipo'   => 'Activo',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $corrientes = CatalogoCuenta::create([
            'codigo' => '1.1',
            'nombre' => 'ACTIVOS CORRIENTES',
            'tipo'   => 'Activo',
            'nivel'  => 2,
            'padre_id' => $activos->id,
            'permite_movimiento' => false
        ]);

        // Efectivo
        $efectivo = CatalogoCuenta::create([
            'codigo' => '1.1.01',
            'nombre' => 'EFECTIVO EN CAJA Y BANCOS',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.01',
            'nombre' => 'CAJA',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.02',
            'nombre' => 'CAJA CHICA',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.01.03',
            'nombre' => 'BANCOS',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $efectivo->id,
            'permite_movimiento' => true
        ]);

        // Cuentas por Cobrar
        $cxc = CatalogoCuenta::create([
            'codigo' => '1.1.03',
            'nombre' => 'CUENTAS POR COBRAR CLIENTES',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.04',
            'nombre' => 'CUENTAS POR COBRAR EMPLEADOS',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => true
        ]);

        // Inventarios
        $inventarios = CatalogoCuenta::create([
            'codigo' => '1.1.05',
            'nombre' => 'INVENTARIOS',
            'tipo'   => 'Activo',
            'nivel'  => 3,
            'padre_id' => $corrientes->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.05.01',
            'nombre' => 'INVENTARIO DE ALIMENTOS',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $inventarios->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '1.1.05.02',
            'nombre' => 'INVENTARIO DE BEBIDAS',
            'tipo'   => 'Activo',
            'nivel'  => 4,
            'padre_id' => $inventarios->id,
            'permite_movimiento' => true
        ]);

        // --- 2. PASIVOS ---
        $pasivos = CatalogoCuenta::create([
            'codigo' => '2',
            'nombre' => 'PASIVOS',
            'tipo'   => 'Pasivo',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $pasCorrientes = CatalogoCuenta::create([
            'codigo' => '2.1',
            'nombre' => 'PASIVOS CORRIENTES',
            'tipo'   => 'Pasivo',
            'nivel'  => 2,
            'padre_id' => $pasivos->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.01',
            'nombre' => 'CUENTAS POR PAGAR PROVEEDORES',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.02',
            'nombre' => 'ITBIS POR PAGAR',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.03',
            'nombre' => 'ITBIS RETENIDO POR PAGAR',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '2.1.04',
            'nombre' => 'PRESTAMOS BANCARIOS POR PAGAR',
            'tipo'   => 'Pasivo',
            'nivel'  => 3,
            'padre_id' => $pasCorrientes->id,
            'permite_movimiento' => true
        ]);

        // --- 3. CAPITAL ---
        $capital = CatalogoCuenta::create([
            'codigo' => '3',
            'nombre' => 'CAPITAL Y RESERVAS',
            'tipo'   => 'Capital',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        // --- 4. INGRESOS ---
        $ingresos = CatalogoCuenta::create([
            'codigo' => '4',
            'nombre' => 'INGRESOS',
            'tipo'   => 'Ingresos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        $ventas = CatalogoCuenta::create([
            'codigo' => '4.1',
            'nombre' => 'VENTAS',
            'tipo'   => 'Ingresos',
            'nivel'  => 2,
            'padre_id' => $ingresos->id,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '4.1.01',
            'nombre' => 'VENTAS DE ALIMENTOS',
            'tipo'   => 'Ingresos',
            'nivel'  => 3,
            'padre_id' => $ventas->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '4.1.02',
            'nombre' => 'VENTAS DE BEBIDAS',
            'tipo'   => 'Ingresos',
            'nivel'  => 3,
            'padre_id' => $ventas->id,
            'permite_movimiento' => true
        ]);

        // --- 5. COSTOS ---
        $costos = CatalogoCuenta::create([
            'codigo' => '5',
            'nombre' => 'COSTOS DE VENTAS',
            'tipo'   => 'Costos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.1',
            'nombre' => 'COSTO DE ALIMENTOS',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.2',
            'nombre' => 'COSTO DE BEBIDAS',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.3',
            'nombre' => 'COSTO DE EMPAQUES Y DESECHABLES',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.4',
            'nombre' => 'MERMAS Y DESPERDICIOS',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '5.5',
            'nombre' => 'OTROS COSTOS DIRECTOS',
            'tipo'   => 'Costos',
            'nivel'  => 2,
            'padre_id' => $costos->id,
            'permite_movimiento' => true
        ]);

        // --- 6. GASTOS ---
        $gastos = CatalogoCuenta::create([
            'codigo' => '6',
            'nombre' => 'GASTOS',
            'tipo'   => 'Gastos',
            'nivel'  => 1,
            'permite_movimiento' => false
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.1',
            'nombre' => 'NOMINA Y SALARIOS',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.2',
            'nombre' => 'ENERGIA ELECTRICA',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.3',
            'nombre' => 'PAGO DE AGUA',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.4',
            'nombre' => 'BOTE DE BASURA',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.5',
            'nombre' => 'ALQUILER DE LOCAL',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.6',
            'nombre' => 'MANTENIMIENTO DE EQUIPOS',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.7',
            'nombre' => 'PUBLICIDAD Y MARKETING',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.8',
            'nombre' => 'GASTOS DE LIMPIEZA Y SUMINISTROS',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.9',
            'nombre' => 'TELEFONO E INTERNET',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.10',
            'nombre' => 'OTROS GASTOS',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.11',
            'nombre' => 'GASTOS FINANCIEROS (INTERESES)',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.12',
            'nombre' => 'COMBUSTIBLE Y TRANSPORTE',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);

        CatalogoCuenta::create([
            'codigo' => '6.13',
            'nombre' => 'REPUESTOS Y REPARACIONES MENORES',
            'tipo'   => 'Gastos',
            'nivel'  => 2,
            'padre_id' => $gastos->id,
            'permite_movimiento' => true
        ]);
    }
}
