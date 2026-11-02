<?php

declare(strict_types=1);

namespace App\Modules\Cotizacion\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cotizacion\DTOs\CreateCotizacionDTO;
use App\Modules\Cotizacion\Http\Requests\StoreCotizacionRequest;
use App\Modules\Cotizacion\Http\Requests\UpdateCotizacionStatusRequest;
use App\Modules\Cotizacion\Services\CotizacionService;
use App\Modules\Shared\Traits\ApiResponseTrait;
use App\Models\Cotizacion;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class CotizacionController extends Controller
{
    use ApiResponseTrait;

    public function __construct(
        private readonly CotizacionService $cotizacionService
    ) {}

    private function resolveCompanyData(Request $request): array
    {
        return [
            'company_name'    => $request->input('company_name') ?: config('company.nombre'),
            'company_rnc'     => $request->input('company_rnc') ?: config('company.rnc'),
            'company_address' => $request->input('company_address') ?: config('company.direccion'),
            'company_phone'   => $request->input('company_phone') ?: config('company.telefono'),
            'company_email'   => $request->input('company_email') ?: config('company.email'),
        ];
    }

    public function store(StoreCotizacionRequest $request): JsonResponse
    {
        try {
            $dto = CreateCotizacionDTO::fromRequest($request);
            $result = $this->cotizacionService->create($dto);

            return $this->successResponse(
                data: $result,
                message: 'Cotización creada correctamente',
                code: 201
            );
        } catch (\Exception $e) {
            return $this->errorResponse(
                message: 'Error al crear la cotización: ' . $e->getMessage(),
                code: 500
            );
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = Cotizacion::with(['cliente', 'user'])->orderBy('fecha_emision', 'desc');

        if ($request->filled('fecha_desde')) {
            $query->where('fecha_emision', '>=', $request->fecha_desde);
        }

        if ($request->filled('fecha_hasta')) {
            $query->where('fecha_emision', '<=', $request->fecha_hasta . ' 23:59:59');
        }

        if ($request->filled('cliente_id')) {
            $query->where('cliente_id', $request->cliente_id);
        }

        if ($request->filled('estado') && $request->estado !== 'todos') {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('buscar')) {
            $search = $request->buscar;
            $query->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%");
                $q->orWhereHas('cliente', function ($q2) use ($search) {
                    $q2->where('nombre', 'LIKE', "%{$search}%")
                       ->orWhere('rnc_cedula', 'LIKE', "%{$search}%");
                });
            });
        }

        $resumenQuery = clone $query;
        $totales = $resumenQuery->reorder()->selectRaw('
            COUNT(*) as cantidad_cotizaciones, 
            SUM(total) as total_monto
        ')->first();

        $cotizaciones = $query->paginate($request->per_page ?? 15);
        $companyData = $this->resolveCompanyData($request);

        $cotizaciones->getCollection()->transform(function ($cotizacion) use ($companyData) {
            $token = Str::random(40);
            Cache::put("short_link_{$token}", [
                'type' => 'cotizacion',
                'id' => $cotizacion->id,
                'companyData' => $companyData
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/d/{$token}";
            return $cotizacion;
        });

        return response()->json([
            'status' => true,
            'data'   => $cotizaciones,
            'resumen' => $totales
        ]);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        try {
            $cotizacion = Cotizacion::with(['cliente', 'detalles', 'user'])->find($id);

            if (!$cotizacion) {
                return $this->errorResponse('Cotización no encontrada', 404);
            }

            $companyData = $this->resolveCompanyData($request);
            $token = Str::random(40);
            Cache::put("short_link_{$token}", [
                'type' => 'cotizacion',
                'id' => $cotizacion->id,
                'companyData' => $companyData
            ], now()->addHours(24));

            $cotizacion->pdf_url = "/d/{$token}";

            return $this->successResponse(
                data: $cotizacion,
                message: 'Cotización encontrada'
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Error al obtener la cotización: ' . $e->getMessage(), 500);
        }
    }

    public function updateStatus(UpdateCotizacionStatusRequest $request, int $id): JsonResponse
    {
        $cotizacion = Cotizacion::find($id);
        if (!$cotizacion) {
            return $this->errorResponse('No encontrada', 404);
        }

        $cotizacion->estado = $request->validated('estado');
        $cotizacion->save();

        return $this->successResponse(
            message: 'Estado actualizado a ' . $cotizacion->estado
        );
    }
}
