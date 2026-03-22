import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8'

function getCorsHeaders(origin: string | null) {
  return {
    'Access-Control-Allow-Origin': origin ?? '*',
    'Vary': 'Origin',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400'
  }
}

type AppRole = 'admin' | 'empleado'

type CreateUserPayload = {
  email?: string
  password?: string
  full_name?: string | null
  role?: AppRole
}

function jsonResponse(body: Record<string, unknown>, origin: string | null, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...getCorsHeaders(origin),
      'Content-Type': 'application/json'
    }
  })
}

serve(async (req) => {
  const origin = req.headers.get('origin')
  const corsHeaders = getCorsHeaders(origin)

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Metodo no permitido' }, origin, 405)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authHeader = req.headers.get('Authorization')

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
    return jsonResponse({ error: 'Faltan variables de entorno de Supabase en la function' }, origin, 500)
  }

  if (!authHeader) {
    return jsonResponse({ error: 'Falta el token de autenticacion' }, origin, 401)
  }

  const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false }
  })

  const serviceClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false }
  })

  const {
    data: { user: callerUser },
    error: callerError
  } = await callerClient.auth.getUser()

  if (callerError || !callerUser) {
    return jsonResponse({ error: 'Sesion invalida o expirada' }, origin, 401)
  }

  const { data: callerProfile, error: profileError } = await serviceClient
    .from('profiles')
    .select('role')
    .eq('id', callerUser.id)
    .single()

  if (profileError || callerProfile?.role !== 'admin') {
    return jsonResponse({ error: 'Solo un administrador puede crear usuarios' }, origin, 403)
  }

  let payload: CreateUserPayload
  try {
    payload = await req.json()
  } catch {
    return jsonResponse({ error: 'Body JSON invalido' }, origin, 400)
  }

  const email = payload.email?.trim().toLowerCase()
  const password = payload.password?.trim()
  const fullName = payload.full_name?.trim() || null
  const role: AppRole = payload.role === 'admin' ? 'admin' : 'empleado'

  if (!email) {
    return jsonResponse({ error: 'El correo es obligatorio' }, origin, 400)
  }

  if (!password || password.length < 8) {
    return jsonResponse({ error: 'La contrasena debe tener al menos 8 caracteres' }, origin, 400)
  }

  const { data: createdUserData, error: createUserError } = await serviceClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: fullName
      ? { full_name: fullName, name: fullName }
      : undefined
  })

  if (createUserError || !createdUserData.user) {
    return jsonResponse({ error: createUserError?.message || 'No se pudo crear el usuario' }, origin, 400)
  }

  const userId = createdUserData.user.id

  const { data: createdProfile, error: upsertError } = await serviceClient
    .from('profiles')
    .upsert(
      {
        id: userId,
        email,
        full_name: fullName,
        role
      },
      { onConflict: 'id' }
    )
    .select('id, email, full_name, role, created_at, updated_at')
    .single()

  if (upsertError || !createdProfile) {
    return jsonResponse({ error: upsertError?.message || 'No se pudo crear el perfil del usuario' }, origin, 500)
  }

  return jsonResponse({ profile: createdProfile }, origin, 201)
})