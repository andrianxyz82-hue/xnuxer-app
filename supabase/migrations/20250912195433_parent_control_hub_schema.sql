-- Location: supabase/migrations/20250912195433_parent_control_hub_schema.sql
-- Schema Analysis: Fresh project - no existing schema
-- Integration Type: Complete new schema creation for Parent Control Hub
-- Dependencies: None (fresh project)
-- Module: Authentication + Device Management

-- 1. Create custom types
CREATE TYPE public.user_role AS ENUM ('admin', 'user');
CREATE TYPE public.device_status AS ENUM ('online', 'offline', 'connecting', 'disconnected');
CREATE TYPE public.command_type AS ENUM ('flash', 'camera', 'audio', 'wallpaper', 'system');
CREATE TYPE public.command_status AS ENUM ('pending', 'executing', 'success', 'failed', 'timeout');
CREATE TYPE public.connection_status AS ENUM ('secure', 'unsecure', 'connecting', 'failed');

-- 2. Create user_profiles table (intermediary for auth.users)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'user'::public.user_role,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create connected_devices table
CREATE TABLE public.connected_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL UNIQUE,
    child_name TEXT NOT NULL,
    device_model TEXT NOT NULL,
    status public.device_status DEFAULT 'offline'::public.device_status,
    last_activity TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    battery_level INTEGER CHECK (battery_level >= 0 AND battery_level <= 100),
    location TEXT,
    pairing_code TEXT,
    connection_status public.connection_status DEFAULT 'connecting'::public.connection_status,
    app_version TEXT,
    is_paired BOOLEAN DEFAULT false,
    paired_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create device_commands table
CREATE TABLE public.device_commands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES public.connected_devices(id) ON DELETE CASCADE,
    admin_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    command_type public.command_type NOT NULL,
    command_data JSONB,
    status public.command_status DEFAULT 'pending'::public.command_status,
    executed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create command_history table for audit trail
CREATE TABLE public.command_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    command_id UUID REFERENCES public.device_commands(id) ON DELETE SET NULL,
    device_id UUID REFERENCES public.connected_devices(id) ON DELETE CASCADE,
    admin_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    command_type public.command_type NOT NULL,
    status public.command_status NOT NULL,
    device_name TEXT NOT NULL,
    execution_time INTEGER, -- in milliseconds
    error_details TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Create device_settings table
CREATE TABLE public.device_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES public.connected_devices(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value JSONB NOT NULL,
    is_system_setting BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(device_id, setting_key)
);

-- 7. Create essential indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_connected_devices_user_id ON public.connected_devices(user_id);
CREATE INDEX idx_connected_devices_device_id ON public.connected_devices(device_id);
CREATE INDEX idx_connected_devices_status ON public.connected_devices(status);
CREATE INDEX idx_device_commands_device_id ON public.device_commands(device_id);
CREATE INDEX idx_device_commands_admin_user_id ON public.device_commands(admin_user_id);
CREATE INDEX idx_device_commands_status ON public.device_commands(status);
CREATE INDEX idx_device_commands_created_at ON public.device_commands(created_at);
CREATE INDEX idx_command_history_device_id ON public.command_history(device_id);
CREATE INDEX idx_command_history_admin_user_id ON public.command_history(admin_user_id);
CREATE INDEX idx_command_history_created_at ON public.command_history(created_at);
CREATE INDEX idx_device_settings_device_id ON public.device_settings(device_id);

-- 8. Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.connected_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_commands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.command_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_settings ENABLE ROW LEVEL SECURITY;

-- 9. Create helper functions before RLS policies
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

CREATE OR REPLACE FUNCTION public.has_role(required_role TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role::TEXT = required_role
)
$$;

CREATE OR REPLACE FUNCTION public.owns_device(device_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.connected_devices cd
    WHERE cd.id = device_uuid AND cd.user_id = auth.uid()
)
$$;

-- 10. Create RLS policies using correct patterns

-- Pattern 1: Core user table - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 6A: Role-based access using auth metadata for connected_devices
CREATE POLICY "admin_full_access_connected_devices"
ON public.connected_devices
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "users_view_own_connected_devices"
ON public.connected_devices
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Pattern 2: Simple ownership for device_commands (admins manage all)
CREATE POLICY "admin_full_access_device_commands"
ON public.device_commands
FOR ALL
TO authenticated
USING (public.has_role('admin'))
WITH CHECK (public.has_role('admin'));

-- Pattern 2: Simple ownership for command_history (admins can view all, users can view their device commands)
CREATE POLICY "admin_view_all_command_history"
ON public.command_history
FOR SELECT
TO authenticated
USING (public.has_role('admin'));

CREATE POLICY "users_view_own_device_command_history"
ON public.command_history
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.connected_devices cd
        WHERE cd.id = command_history.device_id AND cd.user_id = auth.uid()
    )
);

-- Pattern 6A: Role-based + ownership for device_settings
CREATE POLICY "admin_full_access_device_settings"
ON public.device_settings
FOR ALL
TO authenticated
USING (public.has_role('admin'))
WITH CHECK (public.has_role('admin'));

CREATE POLICY "users_view_own_device_settings"
ON public.device_settings
FOR SELECT
TO authenticated
USING (public.owns_device(device_id));

-- 11. Create trigger function for automatic profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')::public.user_role
  );  
  RETURN NEW;
END;
$$;

-- 12. Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- 14. Add update timestamp triggers
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_connected_devices_updated_at
  BEFORE UPDATE ON public.connected_devices
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_device_commands_updated_at
  BEFORE UPDATE ON public.device_commands
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_device_settings_updated_at
  BEFORE UPDATE ON public.device_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 15. Create mock data for testing
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    user_uuid UUID := gen_random_uuid();
    device1_uuid UUID := gen_random_uuid();
    device2_uuid UUID := gen_random_uuid();
    device3_uuid UUID := gen_random_uuid();
    command1_uuid UUID := gen_random_uuid();
    command2_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@parentcontrol.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'user@freefire.com', crypt('user123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Regular User", "role": "user"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create connected devices
    INSERT INTO public.connected_devices (
        id, user_id, device_id, child_name, device_model, status,
        last_activity, battery_level, location, connection_status, is_paired, paired_at
    ) VALUES
        (device1_uuid, user_uuid, 'device_001', 'Andi Pratama', 'Samsung Galaxy A54', 'online'::public.device_status,
         NOW() - INTERVAL '2 minutes', 85, 'Rumah', 'secure'::public.connection_status, true, NOW() - INTERVAL '1 day'),
        (device2_uuid, user_uuid, 'device_002', 'Sari Dewi', 'Xiaomi Redmi Note 12', 'offline'::public.device_status,
         NOW() - INTERVAL '1 hour', 45, 'Sekolah', 'unsecure'::public.connection_status, true, NOW() - INTERVAL '2 days'),
        (device3_uuid, user_uuid, 'device_003', 'Budi Santoso', 'Oppo A78', 'online'::public.device_status,
         NOW() - INTERVAL '5 minutes', 92, 'Taman', 'secure'::public.connection_status, true, NOW() - INTERVAL '3 days');

    -- Create device commands
    INSERT INTO public.device_commands (
        id, device_id, admin_user_id, command_type, status, executed_at, completed_at
    ) VALUES
        (command1_uuid, device1_uuid, admin_uuid, 'flash'::public.command_type, 'success'::public.command_status,
         NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '4 minutes'),
        (command2_uuid, device3_uuid, admin_uuid, 'camera'::public.command_type, 'executing'::public.command_status,
         NOW() - INTERVAL '2 minutes', NULL);

    -- Create command history
    INSERT INTO public.command_history (
        command_id, device_id, admin_user_id, command_type, status, device_name, execution_time
    ) VALUES
        (command1_uuid, device1_uuid, admin_uuid, 'flash'::public.command_type, 'success'::public.command_status,
         'Samsung Galaxy A54 (Andi)', 1200),
        (command2_uuid, device3_uuid, admin_uuid, 'camera'::public.command_type, 'executing'::public.command_status,
         'Oppo A78 (Budi)', NULL),
        (NULL, device2_uuid, admin_uuid, 'wallpaper'::public.command_type, 'failed'::public.command_status,
         'Xiaomi Redmi Note 12 (Sari)', NULL),
        (NULL, device1_uuid, admin_uuid, 'audio'::public.command_type, 'success'::public.command_status,
         'Samsung Galaxy A54 (Andi)', 2400);

    -- Create some device settings
    INSERT INTO public.device_settings (device_id, setting_key, setting_value, is_system_setting) VALUES
        (device1_uuid, 'auto_flash_enabled', 'true'::jsonb, false),
        (device1_uuid, 'camera_quality', '"high"'::jsonb, false),
        (device2_uuid, 'notification_enabled', 'true'::jsonb, false),
        (device3_uuid, 'location_tracking', 'true'::jsonb, true);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;

-- 16. Create cleanup function for development
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs first
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@parentcontrol.com' OR email LIKE '%@freefire.com';

    -- Delete in dependency order (children first, then auth.users last)
    DELETE FROM public.device_settings WHERE device_id IN (
        SELECT id FROM public.connected_devices WHERE user_id = ANY(auth_user_ids_to_delete)
    );
    DELETE FROM public.command_history WHERE admin_user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.device_commands WHERE admin_user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.connected_devices WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);

    -- Delete auth.users last (after all references are removed)
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;