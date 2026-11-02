<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Services;

use App\Modules\Cotizacion\DTOs\CreateCotizacionDTO;
use App\Models\Producto;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class CotizacionService
{
    public function create(CreateCotizacionDTO $dto): array
    {
        return DB::transaction(function () use ($dto) {
            $subtotal = 0;
            $itbisTotal = 0;
            $descuentoTotal = 0;

            $detallesCalculados = [];

            foreach ($dto->detalles as $item) {
                if (!isset($item['itbis_porcentaje']) && !empty($item['producto_id'])) {
                    $producto = Producto::with('impuesto')->find($item['producto_id']);
                    $item['itbis_porcentaje'] = ($producto && $producto->impuesto) ? $producto->impuesto->tasa : 0;
                }

                $calc = $this->calcularLinea($item);

                $subtotal += $calc['baseConDescuento'];
                $descuentoTotal += $calc['descuento'];
                $itbisTotal += $calc['itbis'];

                $detallesCalculados[] = [
                    'item' => $item,
                    'calc' => $calc
                ];
            }

            $total = $subtotal + $itbisTotal;

            $fechaVencimiento = $dto->fechaVencimiento ?? date('Y-m-d', strtotime($dto->fechaEmision . ' + 15 days'));

            $cotizacion_id = DB::table('cotizaciones')->insertGetId([
                'user_id' => $dto->userId,
                'cliente_id' => $dto->clienteId,
                'fecha_emision' => $dto->fechaEmision,
                'fecha_vencimiento' => $fechaVencimiento,
                'subtotal' => round($subtotal, 2),
                'descuento_total' => round($descuentoTotal, 2),
                'itbis' => round($itbisTotal, 2),
                'total' => round($total, 2),
                'nota' => $dto->nota,
                'estado' => 'pendiente',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($detallesCalculados as $d) {
                $item = $d['item'];
                $calc = $d['calc'];

                DB::table('cotizacion_detalles')->insert([
                    'cotizacion_id' => $cotizacion_id,
                    'producto_id' => $item['producto_id'] ?? null,
                    'descripcion' => $item['descripcion'],
                    'cantidad' => $item['cantidad'],
                    'precio' => $item['precio'],
                    'itbis' => round($calc['itbis'], 2),
                    'total' => round($calc['total'], 2),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $companyData = [
                'company_name'    => !empty($dto->companyData['company_name']) ? $dto->companyData['company_name'] : config('company.nombre'),
                'company_rnc'     => !empty($dto->companyData['company_rnc']) ? $dto->companyData['company_rnc'] : config('company.rnc'),
                'company_address' => !empty($dto->companyData['company_address']) ? $dto->companyData['company_address'] : config('company.direccion'),
                'company_phone'   => !empty($dto->companyData['company_phone']) ? $dto->companyData['company_phone'] : config('company.telefono'),
                'company_email'   => !empty($dto->companyData['company_email']) ? $dto->companyData['company_email'] : config('company.email'),
            ];

            $token = Str::random(40);
            Cache::put("short_link_{$token}", [
                'type' => 'cotizacion',
                'id' => $cotizacion_id,
                'companyData' => $companyData
            ], now()->addHours(24));

            return [
                'cotizacion_id' => $cotizacion_id,
                'pdf_url' => "/d/{$token}"
            ];
        });
    }

    private function calcularLinea(array $item): array
    {
        $cantidad = (float) $item['cantidad'];
        $precio = (float) $item['precio'];
        $base = $cantidad * $precio;

        $descuento = 0.0;
        if (!empty($item['descuento_porcentaje'])) {
            $descuento = $base * ((float) $item['descuento_porcentaje'] / 100);
        } elseif (!empty($item['descuento'])) {
            $descuento = (float) $item['descuento'];
        }

        $baseConDescuento = max(0, $base - $descuento);

        $itbisPorcentaje = (float) ($item['itbis_porcentaje'] ?? 18);
        $itbis = $baseConDescuento * ($itbisPorcentaje / 100);

        return [
            'base' => $base,
            'descuento' => $descuento,
            'baseConDescuento' => $baseConDescuento,
            'itbis' => $itbis,
            'total' => $baseConDescuento + $itbis
        ];
    }
}
