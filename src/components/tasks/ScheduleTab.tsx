import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { supabase } from "@/integrations/supabase/client";
import { getCurrentUser } from "@/lib/auth";
import { useToast } from "@/hooks/use-toast";
import { Calendar, BarChart3, Loader2 } from "lucide-react";
import TaskCalendarView from "./TaskCalendarView";
import TaskGanttChart from "./TaskGanttChart";

interface Task {
  id: string;
  title: string;
  description: string | null;
  status: 'todo' | 'in_progress' | 'review' | 'done';
  priority: 'low' | 'medium' | 'high' | 'urgent';
  deadline: string | null;
  start_date: string | null;
  duration_days: number | null;
  progress_percentage: number;
  assignee_id: string | null;
  creator_id: string;
  team_id: string | null;
  created_at: string;
  assignee?: { first_name: string; last_name: string };
}

const ScheduleTab = () => {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'calendar' | 'gantt'>('calendar');
  const { toast } = useToast();

  useEffect(() => {
    fetchTasks();

    const channel = supabase
      .channel('tasks-schedule-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tasks' }, () => {
        fetchTasks();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchTasks = async () => {
    try {
      const user = await getCurrentUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('tasks')
        .select('*')
        .or(`assignee_id.eq.${user.id},creator_id.eq.${user.id}`)
        .order('deadline', { ascending: true });

      if (error) throw error;
      setTasks(data || []);
    } catch (error) {
      console.error('Error fetching tasks:', error);
      toast({
        title: "Error",
        description: "Failed to load tasks for scheduling",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const handleTaskReschedule = async (taskId: string, newStartDate: string | null, newDeadline: string | null) => {
    try {
      const { error } = await supabase
        .from('tasks')
        .update({
          start_date: newStartDate,
          deadline: newDeadline,
          updated_at: new Date().toISOString()
        })
        .eq('id', taskId);

      if (error) throw error;

      toast({
        title: "Success",
        description: "Task rescheduled successfully"
      });

      fetchTasks();
    } catch (error) {
      console.error('Error rescheduling task:', error);
      toast({
        title: "Error",
        description: "Failed to reschedule task",
        variant: "destructive"
      });
    }
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-96">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Lịch Biểu Công Việc
          </CardTitle>
          <CardDescription>
            Xem và quản lý lịch biểu của các công việc
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={viewMode} onValueChange={(v) => setViewMode(v as 'calendar' | 'gantt')} className="w-full">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="calendar" className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                Lịch
              </TabsTrigger>
              <TabsTrigger value="gantt" className="flex items-center gap-2">
                <BarChart3 className="h-4 w-4" />
                Biểu Đồ Gantt
              </TabsTrigger>
            </TabsList>

            <TabsContent value="calendar" className="mt-6">
              <TaskCalendarView 
                tasks={tasks} 
                onTaskReschedule={handleTaskReschedule}
              />
            </TabsContent>

            <TabsContent value="gantt" className="mt-6">
              <TaskGanttChart 
                tasks={tasks}
                onTaskReschedule={handleTaskReschedule}
              />
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      <div className="text-sm text-muted-foreground">
        <p>📊 Tổng cộng: <strong>{tasks.length}</strong> công việc</p>
      </div>
    </div>
  );
};

export default ScheduleTab;
