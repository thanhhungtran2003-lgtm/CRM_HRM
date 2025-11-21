-- Migration: Add Daily Reports, Meeting Minutes, and Action Items tables

-- ============================================================================
-- 1. CREATE daily_reports TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.daily_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    report_date DATE NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    submitted_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, report_date)
);

-- Indexes for daily_reports
CREATE INDEX IF NOT EXISTS idx_daily_reports_user_id ON public.daily_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_reports_report_date ON public.daily_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_daily_reports_status ON public.daily_reports(status);

-- ============================================================================
-- 2. CREATE meeting_minutes TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.meeting_minutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    meeting_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    location TEXT,
    attendees UUID[] DEFAULT ARRAY[]::UUID[],
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'archived')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for meeting_minutes
CREATE INDEX IF NOT EXISTS idx_meeting_minutes_created_by ON public.meeting_minutes(created_by);
CREATE INDEX IF NOT EXISTS idx_meeting_minutes_meeting_date ON public.meeting_minutes(meeting_date);
CREATE INDEX IF NOT EXISTS idx_meeting_minutes_status ON public.meeting_minutes(status);

-- ============================================================================
-- 3. CREATE action_items TABLE (from meeting minutes)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.action_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meeting_id UUID REFERENCES public.meeting_minutes(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    due_date DATE,
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for action_items
CREATE INDEX IF NOT EXISTS idx_action_items_meeting_id ON public.action_items(meeting_id);
CREATE INDEX IF NOT EXISTS idx_action_items_task_id ON public.action_items(task_id);
CREATE INDEX IF NOT EXISTS idx_action_items_assigned_to ON public.action_items(assigned_to);
CREATE INDEX IF NOT EXISTS idx_action_items_status ON public.action_items(status);

-- ============================================================================
-- 4. CREATE team_workload TABLE (for real-time team workload tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.team_workload (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    total_tasks_assigned INT DEFAULT 0,
    total_tasks_in_progress INT DEFAULT 0,
    total_tasks_overdue INT DEFAULT 0,
    total_tasks_completed INT DEFAULT 0,
    workload_percentage NUMERIC(5, 2) DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Indexes for team_workload
CREATE INDEX IF NOT EXISTS idx_team_workload_user_id ON public.team_workload(user_id);
CREATE INDEX IF NOT EXISTS idx_team_workload_team_id ON public.team_workload(team_id);

-- ============================================================================
-- 5. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_minutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.action_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_workload ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. CREATE RLS POLICIES FOR daily_reports
-- ============================================================================

-- Users can view their own daily reports
CREATE POLICY "Users can view own daily reports" ON public.daily_reports
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin'::app_role, 'hr'::app_role, 'leader'::app_role))
    );

-- Users can create their own daily reports
CREATE POLICY "Users can create own daily reports" ON public.daily_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own reports if not approved
CREATE POLICY "Users can update own pending daily reports" ON public.daily_reports
    FOR UPDATE USING (
        auth.uid() = user_id AND status IN ('draft', 'rejected')
    );

-- Admins and HR can approve/reject reports
CREATE POLICY "Admins and HR can manage all daily reports" ON public.daily_reports
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin'::app_role, 'hr'::app_role))
    );

-- ============================================================================
-- 7. CREATE RLS POLICIES FOR meeting_minutes
-- ============================================================================

-- Anyone can view meeting minutes
CREATE POLICY "Anyone can view meeting minutes" ON public.meeting_minutes
    FOR SELECT USING (true);

-- Only creator or admins can create/edit/delete meeting minutes
CREATE POLICY "Users can create meeting minutes" ON public.meeting_minutes
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own meeting minutes" ON public.meeting_minutes
    FOR UPDATE USING (
        auth.uid() = created_by OR
        EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin'::app_role, 'hr'::app_role))
    );

-- ============================================================================
-- 8. CREATE RLS POLICIES FOR action_items
-- ============================================================================

-- Users can view action items assigned to them or created by them
CREATE POLICY "Users can view assigned action items" ON public.action_items
    FOR SELECT USING (
        auth.uid() = assigned_to OR
        auth.uid() = created_by OR
        EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role IN ('admin'::app_role, 'hr'::app_role, 'leader'::app_role))
    );

-- Users can create action items (for meetings)
CREATE POLICY "Users can create action items" ON public.action_items
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Users can update assigned action items
CREATE POLICY "Users can update assigned action items" ON public.action_items
    FOR UPDATE USING (
        auth.uid() = assigned_to OR
        auth.uid() = created_by
    );

-- ============================================================================
-- 9. CREATE RLS POLICIES FOR team_workload
-- ============================================================================

-- Users can view team workload for their team
CREATE POLICY "Users can view team workload" ON public.team_workload
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.user_roles ur
            WHERE ur.user_id = auth.uid() AND ur.role IN ('admin'::app_role, 'hr'::app_role, 'leader'::app_role)
        )
    );

-- System can insert/update workload records
CREATE POLICY "System can manage workload records" ON public.team_workload
    FOR ALL USING (true);

-- ============================================================================
-- 10. CREATE TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE TRIGGER update_daily_reports_updated_at BEFORE UPDATE ON public.daily_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_meeting_minutes_updated_at BEFORE UPDATE ON public.meeting_minutes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_action_items_updated_at BEFORE UPDATE ON public.action_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
