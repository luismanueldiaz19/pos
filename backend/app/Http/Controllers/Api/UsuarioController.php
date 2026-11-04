<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Spatie\Permission\Models\Role;

class UsuarioController extends Controller
{
    /**
     * Valida que el usuario en sesión sea exclusivamente 'ludeveloper'.
     * Ningún otro usuario (incluso si tiene rol admin) puede gestionar usuarios y roles.
     */
    private function ensureSuperDev(Request $request): void
    {
        $user = $request->user();
        if (!$user || strtolower(trim((string) $user->username)) !== 'ludeveloper') {
            abort(response()->json([
                'status'  => false,
                'message' => "Acceso restringido. Únicamente el usuario 'ludeveloper' tiene autorización para gestionar usuarios y roles.",
            ], 403));
        }
    }

    /**
     * Lista todos los usuarios con sus roles asociados, con soporte de búsqueda y filtros.
     */
    public function index(Request $request): JsonResponse
    {
        $this->ensureSuperDev($request);

        $query = User::with('roles')
            ->orderBy('id', 'desc');

        if ($request->filled('search')) {
            $search = trim((string) $request->search);
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('username', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('role') && strtolower((string) $request->role) !== 'todos') {
            $roleName = trim((string) $request->role);
            $query->whereHas('roles', function ($q) use ($roleName) {
                $q->where('name', $roleName);
            });
        }

        $usuarios = $query->get()->map(function (User $user) {
            return [
                'id'         => $user->id,
                'name'       => $user->name,
                'username'   => $user->username,
                'email'      => $user->email,
                'roles'      => $user->roles->pluck('name')->values(),
                'created_at' => $user->created_at?->toIso8601String(),
                'updated_at' => $user->updated_at?->toIso8601String(),
            ];
        });

        return response()->json([
            'status' => true,
            'data'   => $usuarios,
            'total'  => $usuarios->count(),
        ]);
    }

    /**
     * Obtiene el catálogo de roles disponibles con conteo de usuarios.
     */
    public function roles(Request $request): JsonResponse
    {
        $this->ensureSuperDev($request);

        // Obtenemos todos los roles de Spatie mapeados limpiamente
        $roles = Role::all()->map(function (Role $role) {
            return [
                'id'           => $role->id,
                'name'         => $role->name,
                'guard_name'   => $role->guard_name,
                'users_count'  => 0,
            ];
        });

        return response()->json([
            'status' => true,
            'data'   => $roles,
        ]);
    }

    /**
     * Registra un nuevo usuario y le asigna roles.
     */
    public function store(Request $request): JsonResponse
    {
        $this->ensureSuperDev($request);

        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'username' => 'required|string|max:100|unique:users,username',
            'email'    => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
            'roles'    => 'nullable|array',
            'roles.*'  => 'string|exists:roles,name',
        ], [
            'username.unique' => 'Este nombre de usuario ya está registrado.',
            'email.unique'    => 'Este correo electrónico ya está registrado.',
            'password.min'    => 'La contraseña debe contener al menos 6 caracteres.',
            'roles.*.exists'  => 'Uno de los roles seleccionados no es válido.',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'username' => $validated['username'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $roles = !empty($validated['roles']) ? $validated['roles'] : ['vendedor'];
        $user->syncRoles($roles);

        $user->load('roles');

        return response()->json([
            'status'  => true,
            'message' => 'Usuario creado exitosamente.',
            'data'    => [
                'id'         => $user->id,
                'name'       => $user->name,
                'username'   => $user->username,
                'email'      => $user->email,
                'roles'      => $user->roles->pluck('name')->values(),
                'created_at' => $user->created_at?->toIso8601String(),
            ],
        ], 201);
    }

    /**
     * Muestra la información detallada de un usuario.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $this->ensureSuperDev($request);

        $user = User::with('roles')->find($id);

        if (!$user) {
            return response()->json([
                'status'  => false,
                'message' => 'Usuario no encontrado.',
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data'   => [
                'id'          => $user->id,
                'name'        => $user->name,
                'username'    => $user->username,
                'email'       => $user->email,
                'roles'       => $user->roles->pluck('name')->values(),
                'permissions' => $user->getAllPermissions()->pluck('name')->values(),
                'created_at'  => $user->created_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Actualiza un usuario existente y reasigna sus roles.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $this->ensureSuperDev($request);

        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'username' => ['required', 'string', 'max:100', Rule::unique('users', 'username')->ignore($user->id)],
            'email'    => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'roles'    => 'nullable|array',
            'roles.*'  => 'string|exists:roles,name',
        ], [
            'username.unique' => 'Este nombre de usuario ya está en uso por otro usuario.',
            'email.unique'    => 'Este correo electrónico ya está en uso por otro usuario.',
            'password.min'    => 'La nueva contraseña debe contener al menos 6 caracteres.',
            'roles.*.exists'  => 'Uno de los roles seleccionados no es válido.',
        ]);

        $user->name = $validated['name'];
        $user->username = $validated['username'];
        $user->email = $validated['email'];

        if (!empty($validated['password'])) {
            $user->password = Hash::make($validated['password']);
        }

        $user->save();

        if (isset($validated['roles'])) {
            // Protección: Evitar que el último administrador se quite el rol admin
            if ($user->hasRole('admin') && !in_array('admin', $validated['roles'])) {
                $totalAdmins = User::role('admin')->count();
                if ($totalAdmins <= 1) {
                    return response()->json([
                        'status'  => false,
                        'message' => 'No puedes remover el rol de Administrador porque es el único administrador del sistema.',
                    ], 422);
                }
            }
            $user->syncRoles($validated['roles']);
        }

        $user->load('roles');

        return response()->json([
            'status'  => true,
            'message' => 'Usuario actualizado correctamente.',
            'data'    => [
                'id'         => $user->id,
                'name'       => $user->name,
                'username'   => $user->username,
                'email'      => $user->email,
                'roles'      => $user->roles->pluck('name')->values(),
                'updated_at' => $user->updated_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Los usuarios no se pueden eliminar por motivos de auditoría y trazabilidad histórica en el sistema.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $this->ensureSuperDev($request);

        return response()->json([
            'status'  => false,
            'message' => 'Los usuarios no se pueden eliminar del sistema por integridad y trazabilidad histórica.',
        ], 422);
    }
}
