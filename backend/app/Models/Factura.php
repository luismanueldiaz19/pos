<?php

namespace App\Models;

use App\Modules\Ecf\Models\EcfDocumento;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Factura extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'user_id',
        'caja_sesion_id',
        'ncf',
        'tipo_factura',
        'fecha_emision',
        'fecha_vencimiento',
        'subtotal',
        'descuento_total',
        'itbis',
        'total',
        'estado',
        'nota',
        'asiento_id',
        'dias_credito',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function detalles()
    {
        return $this->hasMany(FacturaDetalle::class);
    }

    public function asiento()
    {
        return $this->belongsTo(AsientoContable::class, 'asiento_id');
    }

    public function ecfDocumento()
    {
        return $this->hasOne(EcfDocumento::class, 'factura_id');
    }

    public function pagos()
    {
        return $this->hasMany(Pago::class);
    }
}
