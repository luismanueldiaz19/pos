<?php

$nombre = env('COMPANY_NAME', env('DGII_EMISOR_RAZON_SOCIAL', 'Fundación Centro de Evangelización Padre Fantino'));
$rnc = env('COMPANY_RNC', env('DGII_EMISOR_RNC', '4-30-37238-2'));
$direccion = env('COMPANY_ADDRESS', env('DGII_EMISOR_DIRECCION', 'Av. Presidente Antonio Guzmán Fernande, junumucu Las Vegas, tramo Controba-San Francisco de Macoris'));
$telefono = env('COMPANY_PHONE', env('DGII_EMISOR_TELEFONO', '(809) 697-8028'));
$email = env('COMPANY_EMAIL', env('DGII_EMISOR_CORREO', 'contacto@comunidadfantino.site'));

return [
    // Claves en español
    'nombre'    => $nombre,
    'rnc'       => $rnc,
    'direccion' => $direccion,
    'telefono'  => $telefono,
    'email'     => $email,

    // Claves en inglés (compatibilidad)
    'name'      => $nombre,
    'address'   => $direccion,
    'phone'     => $telefono,
];
