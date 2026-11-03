<?php
require 'backend/vendor/autoload.php';
$app = require_once 'backend/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;

// Create dummy user to test delete
$dummy = User::create([
    'name' => 'To Delete',
    'username' => 'todelete' . rand(100, 999),
    'email' => 'todelete' . rand(100, 999) . '@test.com',
    'password' => bcrypt('password'),
]);

$admin = User::first();
$token = $admin->createToken('test_del')->plainTextToken;

$ch = curl_init('http://127.0.0.1:8000/api/usuarios/' . $dummy->id);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $token, 'Accept: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "CODE: $code\nRES: $res\n";

