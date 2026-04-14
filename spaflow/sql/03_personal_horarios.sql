-- ══════════════════════════════════════════════════════════════════
-- 03_personal_horarios.sql
-- SpaFlow — Personal (terapeutas), horarios y bloqueos de agenda
-- Ejecutar CUARTO
-- ══════════════════════════════════════════════════════════════════

-- ── PERSONAL ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.personal (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id         uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  profile_id     uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  nombre         text NOT NULL,
  especialidades text[] DEFAULT '{}',    -- ['MASAJE', 'FACIAL', ...]
  telefono       text,
  activo         boolean NOT NULL DEFAULT true,
  color_agenda   text NOT NULL DEFAULT '#8b5cf6',  -- color en FullCalendar
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_personal_spa_id    ON public.personal (spa_id);
CREATE INDEX IF NOT EXISTS idx_personal_activo    ON public.personal (spa_id, activo);
CREATE INDEX IF NOT EXISTS idx_personal_profile   ON public.personal (profile_id);

DROP TRIGGER IF EXISTS set_personal_updated_at ON public.personal;
CREATE TRIGGER set_personal_updated_at
BEFORE UPDATE ON public.personal
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── HORARIOS DEL PERSONAL ────────────────────────────────────────
-- Horario laboral semanal: un registro por día de la semana
CREATE TABLE IF NOT EXISTS public.horarios_personal (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  personal_id     uuid NOT NULL REFERENCES public.personal(id) ON DELETE CASCADE,
  dia_semana      int NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
                  -- 0 = Domingo, 1 = Lunes, ..., 6 = Sábado
  hora_inicio     time NOT NULL,
  hora_fin        time NOT NULL,
  activo          boolean NOT NULL DEFAULT true,
  CONSTRAINT horario_valido CHECK (hora_fin > hora_inicio),
  UNIQUE (personal_id, dia_semana)
);

CREATE INDEX IF NOT EXISTS idx_horarios_personal_id ON public.horarios_personal (personal_id);
CREATE INDEX IF NOT EXISTS idx_horarios_dia         ON public.horarios_personal (dia_semana);

-- ── BLOQUEOS DE AGENDA ───────────────────────────────────────────
-- Vacaciones, días libres, mantenimiento del spa
CREATE TABLE IF NOT EXISTS public.bloqueos_agenda (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id          uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  personal_id     uuid REFERENCES public.personal(id) ON DELETE CASCADE,
  -- NULL en personal_id = bloqueo que afecta a todo el spa (ej: spa cerrado)
  fecha_inicio    timestamptz NOT NULL,
  fecha_fin       timestamptz NOT NULL,
  motivo          text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT bloqueo_valido CHECK (fecha_fin > fecha_inicio)
);

CREATE INDEX IF NOT EXISTS idx_bloqueos_spa_id      ON public.bloqueos_agenda (spa_id);
CREATE INDEX IF NOT EXISTS idx_bloqueos_personal_id ON public.bloqueos_agenda (personal_id);
CREATE INDEX IF NOT EXISTS idx_bloqueos_fechas      ON public.bloqueos_agenda (spa_id, fecha_inicio, fecha_fin);

-- ── RLS — PERSONAL ───────────────────────────────────────────────
ALTER TABLE public.personal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "personal_tenant_select" ON public.personal;
CREATE POLICY "personal_tenant_select"
ON public.personal FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "personal_tenant_write" ON public.personal;
CREATE POLICY "personal_tenant_write"
ON public.personal FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
);

-- ── RLS — HORARIOS ───────────────────────────────────────────────
ALTER TABLE public.horarios_personal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "horarios_tenant_select" ON public.horarios_personal;
CREATE POLICY "horarios_tenant_select"
ON public.horarios_personal FOR SELECT TO authenticated
USING (
  personal_id IN (
    SELECT id FROM public.personal WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "horarios_tenant_write" ON public.horarios_personal;
CREATE POLICY "horarios_tenant_write"
ON public.horarios_personal FOR ALL TO authenticated
USING (
  personal_id IN (
    SELECT id FROM public.personal WHERE spa_id = public.current_spa_id()
  )
  AND public.current_app_role() = 'admin_spa'
)
WITH CHECK (
  personal_id IN (
    SELECT id FROM public.personal WHERE spa_id = public.current_spa_id()
  )
  AND public.current_app_role() = 'admin_spa'
);

-- ── RLS — BLOQUEOS ───────────────────────────────────────────────
ALTER TABLE public.bloqueos_agenda ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bloqueos_tenant_select" ON public.bloqueos_agenda;
CREATE POLICY "bloqueos_tenant_select"
ON public.bloqueos_agenda FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "bloqueos_tenant_write" ON public.bloqueos_agenda;
CREATE POLICY "bloqueos_tenant_write"
ON public.bloqueos_agenda FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
);

-- ── Permisos ─────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.personal TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.horarios_personal TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bloqueos_agenda TO authenticated;

COMMENT ON TABLE public.personal IS 'Terapeutas y staff del spa que ejecutan servicios.';
COMMENT ON COLUMN public.personal.color_agenda IS 'Color hex para mostrar en el calendario (FullCalendar).';
COMMENT ON COLUMN public.personal.especialidades IS 'Array de categorías: MASAJE, FACIAL, CORPORAL, UÑAS, CABELLO, OTRO.';
COMMENT ON TABLE public.horarios_personal IS 'Horario laboral semanal del terapeuta (por día de semana).';
COMMENT ON TABLE public.bloqueos_agenda IS 'Días/horas bloqueados: vacaciones, feriados, mantenimiento.';
COMMENT ON COLUMN public.bloqueos_agenda.personal_id IS 'NULL = bloqueo global del spa (todo el spa cerrado).';
