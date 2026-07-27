-- ==========================================
-- 1. LIMPIEZA TOTAL DEL ESQUEMA
-- ==========================================
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- Limpiar usuarios previos de Auth para evitar duplicados
SET session_replication_role = 'replica';
DELETE FROM auth.users;
SET session_replication_role = 'origin';

-- ==========================================
-- 2. ESTRUCTURA DE TABLAS (SCHEMA)
-- ==========================================

-- 2.1 Tabla de Perfiles (Vinculada a Supabase Auth)
CREATE TABLE public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    ci VARCHAR(20),
    rol VARCHAR(20) CHECK (rol IN ('Administrador', 'Operador', 'Supervisión', 'Cajero')) DEFAULT 'Cajero',
    turno VARCHAR(20) DEFAULT 'Mañana',
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2.2 Tabla de Surtidores y Tanques
CREATE TABLE public.surtidores (
    id SERIAL PRIMARY KEY,
    numero_surtidor INT NOT NULL UNIQUE,
    tipo_combustible VARCHAR(30) CHECK (tipo_combustible IN ('Gasolina Especial', 'Gasolina Premium', 'Diesel Olímpico', 'GNV')),
    capacidad_total_litros DECIMAL(10,2) NOT NULL,
    nivel_actual_litros DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) CHECK (estado IN ('Activo', 'Mantenimiento', 'Inactivo')) DEFAULT 'Activo'
);

-- 2.3 Tabla de Turnos
CREATE TABLE public.turnos (
    id SERIAL PRIMARY KEY,
    usuario_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
    fecha_inicio TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_fin TIMESTAMP WITH TIME ZONE,
    monto_inicial_caja DECIMAL(10,2) DEFAULT 0.00,
    monto_final_caja DECIMAL(10,2),
    estado VARCHAR(20) CHECK (estado IN ('Abierto', 'Cerrado')) DEFAULT 'Abierto'
);

-- 2.4 Tabla de Ventas
CREATE TABLE public.ventas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    surtidor_id INT REFERENCES public.surtidores(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
    turno_id INT REFERENCES public.turnos(id) ON DELETE SET NULL,
    litros DECIMAL(8,2) NOT NULL,
    precio_por_litro DECIMAL(6,2) NOT NULL,
    monto_total DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(20) CHECK (metodo_pago IN ('Efectivo', 'QR', 'Tarjeta', 'Vale')) DEFAULT 'Efectivo',
    placa_vehiculo VARCHAR(15),
    nit_ci_cliente VARCHAR(20),
    fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2.5 Tabla de Alertas
CREATE TABLE public.alertas (
    id SERIAL PRIMARY KEY,
    surtidor_id INT REFERENCES public.surtidores(id) ON DELETE CASCADE,
    tipo_alerta VARCHAR(50) CHECK (tipo_alerta IN ('Nivel Bajo', 'Fuga', 'Falla Manguera', 'Desconexión')),
    descripcion TEXT,
    prioridad VARCHAR(10) CHECK (prioridad IN ('Baja', 'Media', 'Alta', 'Critica')) DEFAULT 'Media',
    estado VARCHAR(20) CHECK (estado IN ('Pendiente', 'En Proceso', 'Resuelta')) DEFAULT 'Pendiente',
    fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- 3. TRIGGER AUTOMÁTICO DE USUARIOS
-- ==========================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre_completo, email, rol)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'nombre_completo', new.email), 
    new.email,
    COALESCE(new.raw_user_meta_data->>'rol', 'Cajero')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 4. POLÍTICAS RLS Y REALTIME
-- ==========================================
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir lectura a usuarios autenticados" 
ON public.perfiles FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Permitir actualización de perfil propio o admin" 
ON public.perfiles FOR UPDATE USING (auth.uid() = id OR auth.role() = 'authenticated');

ALTER PUBLICATION supabase_realtime ADD TABLE public.surtidores;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ventas;
ALTER PUBLICATION supabase_realtime ADD TABLE public.alertas;

-- ==========================================
-- 5. CREACIÓN DE USUARIOS DE PRUEBA
-- ==========================================

-- 5.1 Crear Administrador
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  'admin@gasflow.com', crypt('Admin123456', gen_salt('bf')), NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"nombre_completo":"Administrador Principal", "rol":"Administrador"}',
  NOW(), NOW()
);

-- 5.2 Crear Cajero
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  'cajero@gasflow.com', crypt('Cajero123456', gen_salt('bf')), NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"nombre_completo":"Cajero Turno Mañana", "rol":"Cajero"}',
  NOW(), NOW()
);

-- ==========================================
-- 6. DATOS DE PRUEBA (SEEDS)
-- ==========================================
INSERT INTO public.surtidores (numero_surtidor, tipo_combustible, capacidad_total_litros, nivel_actual_litros, estado)
VALUES 
(1, 'Gasolina Especial', 10000.00, 7500.00, 'Activo'),
(2, 'Diesel Olímpico', 12000.00, 2100.00, 'Activo'),
(3, 'Gasolina Premium', 8000.00, 500.00, 'Mantenimiento');

INSERT INTO public.alertas (surtidor_id, tipo_alerta, descripcion, prioridad, estado)
VALUES 
(3, 'Nivel Bajo', 'El tanque se encuentra por debajo del 10% de su capacidad total.', 'Critica', 'Pendiente');




-- 1. Permisos esenciales para que Supabase Auth consulte e inserte
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role, postgres;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role, postgres;

-- Permisos por defecto para futuras tablas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;




CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger 
SECURITY DEFINER 
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre_completo, email, rol)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'nombre_completo', new.email, 'Usuario Registrado'), 
    new.email,
    COALESCE(new.raw_user_meta_data->>'rol', 'Cajero')
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  -- Si ocurre cualquier error interno, permite que el usuario se cree/autentique en Auth sin bloquear Supabase
  RETURN new;
END;
$$;

-- Recrear el trigger limpiamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();





  -- 1. Asegurar extensión pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Limpiar registros previos de los usuarios de prueba si existían
DELETE FROM public.perfiles WHERE email IN ('admin@gasflow.com', 'cajero@gasflow.com');
DELETE FROM auth.users WHERE email IN ('admin@gasflow.com', 'cajero@gasflow.com');

-- 3. Crear Administrador en auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@gasflow.com',
  extensions.crypt('Admin123456', extensions.gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"nombre_completo":"Administrador Principal", "rol":"Administrador"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);

-- 4. Crear Cajero en auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'cajero@gasflow.com',
  extensions.crypt('Cajero123456', extensions.gen_salt('bf')),
  NOW(),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"nombre_completo":"Cajero Turno Mañana", "rol":"Cajero"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);







-- 1. Asegurar la tabla de Surtidores con ID entero
CREATE TABLE IF NOT EXISTS public.surtidores (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    numero INTEGER NOT NULL,
    tipo_combustible TEXT NOT NULL, -- Ej: 'Gasolina', 'Diesel', 'GNV'
    estado TEXT NOT NULL DEFAULT 'funcionando', -- 'funcionando', 'reparacion', 'mantenimiento'
    lectura_actual NUMERIC DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Tabla de Fallas / Accidentes con surtidor_id de tipo BIGINT (Compatible)
CREATE TABLE IF NOT EXISTS public.incidentes_surtidor (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    surtidor_id BIGINT REFERENCES public.surtidores(id) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente', -- 'pendiente', 'resuelto'
    reportado_por TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. Tabla de Reportes / Arqueos de Caja (Relacionada con el usuario de Supabase Auth)
CREATE TABLE IF NOT EXISTS public.reportes_caja (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cajero_id UUID REFERENCES auth.users(id), -- Los usuarios de Auth sí son tipo UUID por defecto
    cajero_nombre TEXT NOT NULL,
    monto_inicial NUMERIC NOT NULL,
    monto_final NUMERIC NOT NULL,
    total_ventas NUMERIC NOT NULL,
    estado TEXT NOT NULL DEFAULT 'enviado', -- 'enviado', 'revisado'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);