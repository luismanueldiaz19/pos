<?php

return [
    'nombre'    => env('COMPANY_NAME', env('DGII_EMISOR_RAZON_SOCIAL', 'Fundación Centro de Evangelización Padre Fantino')),
    'rnc'       => env('COMPANY_RNC', env('DGII_EMISOR_RNC', '4-30-37238-2')),
    'direccion' => env('COMPANY_ADDRESS', env('DGII_EMISOR_DIRECCION', 'Av. Presidente Antonio Guzmán Fernández, junumucu Las Vegas')),
    'telefono'  => env('COMPANY_PHONE', env('DGII_EMISOR_TELEFONO', '(809) 697-8028')),
    'email'     => env('COMPANY_EMAIL', env('DGII_EMISOR_CORREO', '')),
];

