<?php

declare(strict_types=1);

namespace App\Modules\Compra\Services;

use App\Modules\Compra\DTOs\CreateCompraDTO;
use App\Modules\Compra\Exceptions\CompraException;
use App\Modules\Compra\Enums\CompraTipoEnum;
use App\Modules\Compra\Enums\CompraEstadoEnum;
use App\Models\Compra;
use App\Models\CompraDetalle;
use App\Models\CuentaPorPagar;
use App\Models\PagoCompra;
use App\Models\Producto;
use App\Models\Proveedor;
use App\Modules\Contabilidad\Services\ContabilidadService;
use App\Services\BankService;
use Illuminate\Support\Facades\DB;
use App\Models\MetodoPago;
use App\Modules\Contabilidad\DTOs\RegistrarAsientoDTO;

class CompraService
{
    public function __construct(
        private readonly ContabilidadService $contabilidadService,
        private readonly ?BankService $bankService = null
    ) {}

    public function create(CreateCompraDTO $dto): array {
        return DB::transaction(function () use ($dto) {
            // 1. Verificar idempotencia: Si ya existe esta factura para este proveedor, no duplicar.
            $compraExistente = Compra::with(['detalles', 'asiento.detalles.cuenta', 'cuentaPorPagar', 'proveedor'])
                ->where('proveedor_id', $dto->proveedor_id)
                ->where('numero_factura_proveedor', $dto->numero_factura_proveedor)
                ->first();

            if ($compraExistente) {
                return $compraExistente->toArray();
            }

            // 2. Obtener proveedor para validar informalidad y cuentas asociadas
            $proveedor = Proveedor::find($dto->proveedor_id);
            $esInformal = (bool) ($proveedor?->es_informal ?? false);

            $subtotal  = 0.0;
            $impuestos = 0.0;
            $total     = 0.0;

            $detallesProcesados = [];

            foreach ($dto->detalles as $d) {
                // Incorporar el factor de conversión en el stock si corresponde
                $factor = isset($d['factor_conversion']) ? (float) $d['factor_conversion'] : 1.0;
                $cantidadFacturada = (float) $d['cantidad'];
                $costoUnitario = (float) $d['costo_unitario'];
                $impuestoMonto = (float) ($d['impuesto_monto'] ?? 0.0);

                $d_subtotal = $cantidadFacturada * $costoUnitario;
                $d_total    = $d_subtotal + $impuestoMonto;

                $d['subtotal'] = $d_subtotal;
                $d['total']    = $d_total;

                // Si no trae cuenta contable explícita y no es producto de inventario,
                // asignar la cuenta contable de gasto del proveedor si existe
                if (empty($d['cuenta_contable_id']) && empty($d['producto_id']) && $proveedor?->cuenta_contable_gasto_id) {
                    $d['cuenta_contable_id'] = $proveedor->cuenta_contable_gasto_id;
                }

                $subtotal  += $d_subtotal;
                $impuestos += $impuestoMonto;
                $total     += $d_total;

                $detallesProcesados[] = $d;
            }

            // 3. Resolver NCF (generar comprobante E41 si el proveedor es informal y no vino NCF)
            $ncfFinal = $dto->ncf;
            if ($esInformal && empty($ncfFinal)) {
                $sec = DB::table('ncf_secuencias')
                    ->where('tipo', '41')
                    ->where('activo', true)
                    ->lockForUpdate()
                    ->first();
                if ($sec) {
                    $nuevo = $sec->actual + 1;
                    DB::table('ncf_secuencias')->where('id', $sec->id)->update(['actual' => $nuevo]);
                    $ncfFinal = 'E41' . str_pad((string)$nuevo, 10, '0', STR_PAD_LEFT);
                }
            }

            // 4. Crear Compra
            $estado = $dto->tipo_compra === CompraTipoEnum::CONTADO ? CompraEstadoEnum::PAGADA->value : CompraEstadoEnum::PENDIENTE->value;

            $compra = Compra::create([
                'proveedor_id'              => $dto->proveedor_id,
                'numero_factura_proveedor'  => $dto->numero_factura_proveedor,
                'ncf'                       => $ncfFinal,
                'fecha_compra'              => $dto->fecha_compra,
                'fecha_vencimiento'         => $dto->fecha_vencimiento,
                'tipo_compra'               => $dto->tipo_compra->value,
                'subtotal'                  => $subtotal,
                'impuestos'                 => $impuestos,
                'total'                     => $total,
                'estado'                    => $estado,
                'usuario_id'                => auth()->id() ?? 1,
                'notas'                     => $dto->notas,
            ]);

            // 5. Guardar Detalles de la Compra
            foreach ($detallesProcesados as $d) {
                CompraDetalle::create([
                    'compra_id'          => $compra->id,
                    'producto_id'        => $d['producto_id'] ?? null,
                    'descripcion'        => $d['descripcion'] ?? null,
                    'cuenta_contable_id' => $d['cuenta_contable_id'] ?? null,
                    'presentacion'       => $d['presentacion'] ?? null,
                    'factor_conversion'  => $d['factor_conversion'] ?? 1,
                    'cantidad'           => $d['cantidad'],
                    'costo_unitario'     => $d['costo_unitario'],
                    'subtotal'           => $d['subtotal'],
                    'impuesto_monto'     => $d['impuesto_monto'],
                    'total'              => $d['total'],
                ]);

                if (!empty($d['producto_id'])) {
                    $factor = isset($d['factor_conversion']) ? (float) $d['factor_conversion'] : 1.0;
                    $cantidadFisica = (float) $d['cantidad'] * $factor;
                    app(\App\Modules\Inventario\Services\InventarioService::class)->procesarEntradaCompra(
                        productoId: (int) $d['producto_id'],
                        cantidad: $cantidadFisica,
                        referencia: $compra->ncf ?? $dto->numero_factura_proveedor ?? "COMPRA-{$compra->id}"
                    );
                }
            }

            // 6. Determinar monto a pagar al proveedor (en informal con retención 100% ITBIS, la deuda a liquidar es subtotal)
            $montoOriginalCxp = ($esInformal && $impuestos > 0) ? $subtotal : $total;

            // 7. Generar Asiento Contable de Compra (compra_inventario)
            $customConfigsCompra = [
                'es_informal' => $esInformal,
                'detalles' => $detallesProcesados,
            ];

            if ($proveedor?->cuenta_contable_cxp_id) {
                $customConfigsCompra['compra_proveedor_haber'] = $proveedor->cuenta_contable_cxp_id;
            }

            $esGasto = collect($detallesProcesados)->every(fn($d) => empty($d['producto_id']));
            $descGastoGlosa = ($esGasto && !empty($detallesProcesados[0]['descripcion']))
                ? " ({$detallesProcesados[0]['descripcion']})"
                : '';
            $prefijoGlosa = $esGasto ? 'Registro de gasto' : 'Registro de compra';
            $glosaCompra = "{$prefijoGlosa} factura " . ($dto->numero_factura_proveedor ?? 'S/N') . ($proveedor ? " - {$proveedor->nombre}" : '') . $descGastoGlosa;

            $asientoCompra = $this->contabilidadService->registrarAsientoAuto(
                new RegistrarAsientoDTO(
                    tipo_transaccion: 'compra_inventario',
                    subtotal: (float) $subtotal,
                    itbis: (float) $impuestos,
                    total: (float) $total,
                    referencia: $ncfFinal ?? $dto->numero_factura_proveedor ?? ($esGasto ? "GASTO-{$compra->id}" : "COMPRA-{$compra->id}"),
                    glosa: $glosaCompra,
                    usuario_id: auth()->id() ?? 1,
                    custom_configs: $customConfigsCompra,
                    costo: 0.0,
                    fecha: $dto->fecha_compra
                )
            );

            if ($asientoCompra) {
                $compra->asiento_id = $asientoCompra->id;
                $compra->save();
            }

            // 8. LÓGICA DE CONTADO VS CRÉDITO
            if ($dto->tipo_compra === CompraTipoEnum::CONTADO) {
                // Compra al contado: Registrar la CxP en estado PAGADA y con balance 0
                $cxp = CuentaPorPagar::create([
                    'proveedor_id'      => $dto->proveedor_id,
                    'compra_id'         => $compra->id,
                    'monto_original'    => $montoOriginalCxp,
                    'balance_pendiente' => 0,
                    'fecha_vencimiento' => $dto->fecha_vencimiento ?? $dto->fecha_compra,
                    'estado'            => 'PAGADA',
                ]);

                if ($dto->metodo_pago_id) {
                    $metodo = MetodoPago::find($dto->metodo_pago_id);
                    $cuentaDefaultCaja = $this->contabilidadService->obtenerCuentaPorClave('pago_compra_efectivo_haber');
                    $cuentaOrigenId = $metodo?->catalogo_cuenta_id ?? $cuentaDefaultCaja;

                    if (!$cuentaOrigenId) {
                        throw new CompraException('No se encontró una cuenta contable de origen para el método de pago ni en la configuración contable (pago_compra_efectivo_haber).');
                    }

                    // Asiento contable del pago inmediato (pago_compra)
                    $customConfigsPago = [
                        'pago_compra_efectivo_haber' => $cuentaOrigenId,
                    ];
                    if ($proveedor?->cuenta_contable_cxp_id) {
                        $customConfigsPago['compra_proveedor_haber'] = $proveedor->cuenta_contable_cxp_id;
                    }

                    $prefijoPagoGlosa = $esGasto ? 'Pago inmediato de gasto' : 'Pago inmediato de compra';
                    $asientoPago = $this->contabilidadService->registrarAsientoAuto(
                        new RegistrarAsientoDTO(
                            tipo_transaccion: 'pago_compra',
                            subtotal: 0.0,
                            itbis: 0.0,
                            total: (float) $montoOriginalCxp,
                            referencia: $dto->referencia_pago ?? ($esGasto ? "PAGO-GASTO-{$compra->id}" : "PAGO-COMPRA-{$compra->id}"),
                            glosa: "{$prefijoPagoGlosa} factura " . ($dto->numero_factura_proveedor ?? 'S/N') . ($proveedor ? " - {$proveedor->nombre}" : ''),
                            usuario_id: auth()->id() ?? 1,
                            custom_configs: $customConfigsPago,
                            costo: 0.0,
                            fecha: $dto->fecha_compra
                        )
                    );

                    // Crear el recibo de pago asociado a la compra, cxp y asiento
                    $pago = PagoCompra::create([
                        'cxp_id'           => $cxp->id,
                        'compra_id'        => $compra->id,
                        'monto_pagado'     => $montoOriginalCxp,
                        'fecha_pago'       => $dto->fecha_compra,
                        'metodo_pago_id'   => $dto->metodo_pago_id,
                        'referencia'       => $dto->referencia_pago ?? "Pago Fac. {$dto->numero_factura_proveedor}",
                        'cuenta_origen_id' => $cuentaOrigenId,
                        'asiento_id'       => $asientoPago?->id,
                        'usuario_id'       => auth()->id() ?? 1,
                    ]);

                    // Impacto bancario / caja si tiene cuenta bancaria vinculada
                    if ($metodo && $metodo->bank_account_id && $this->bankService) {
                        $this->bankService->registrarTransaccion(
                            $metodo->bank_account_id,
                            'withdrawal',
                            (float) $montoOriginalCxp,
                            $dto->referencia_pago ?? "Pago Fac. {$dto->numero_factura_proveedor}",
                            "Pago inmediato Factura Prov. {$dto->numero_factura_proveedor}",
                            $asientoPago?->id
                        );
                    }
                }
            } else {
                // Compra al crédito: Se registra la CxP pendiente
                $cxp = CuentaPorPagar::create([
                    'proveedor_id'      => $dto->proveedor_id,
                    'compra_id'         => $compra->id,
                    'monto_original'    => $montoOriginalCxp,
                    'balance_pendiente' => $montoOriginalCxp,
                    'fecha_vencimiento' => $dto->fecha_vencimiento ?? $dto->fecha_compra,
                    'estado'            => 'PENDIENTE',
                ]);
            }

            $compra->load(['detalles', 'asiento.detalles.cuenta', 'cuentaPorPagar', 'proveedor']);
            return $compra->toArray();
        });
    }
}
