import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { 
  Users, CheckSquare, Calendar, TrendingUp, Shield, Zap,
  Settings, Bot 
} from "lucide-react"; // Đã thêm Settings và Bot cho AI/Workflow
import { getCurrentUser } from "@/lib/auth";

// --- Custom Constants ---
const APP_NAME = "LifeOS HRM";

// Danh sách các tính năng đã được tổ chức lại để bao gồm AI/Workflow
const FEATURES = [
  {
    icon: Users,
    title: "Organization & Roles",
    description: "Manage teams, departments, and user hierarchy with RLS security."
  },
  {
    icon: CheckSquare,
    title: "Geo-Attendance",
    description: "Real-time check-in/check-out with GPS validation (Haversine Formula)."
  },
  {
    icon: Bot,
    title: "AI Meeting Summary",
    description: "Generate instant, intelligent summaries from meeting transcripts."
  },
  {
    icon: Settings,
    title: "Workflow Automation",
    description: "Build n8n-like workflows for task and approval automation."
  },
  {
    icon: TrendingUp,
    title: "Performance Analytics",
    description: "Role-based dashboards, evaluation scoring, and performance reports."
  },
  {
    icon: Shield,
    title: "Enterprise Security",
    description: "Protected by Supabase RLS, JWT, and multi-level role access control."
  }
];

const Index = () => {
  const navigate = useNavigate();

  // Redirect Logic: Chuyển hướng người dùng đã đăng nhập về Dashboard
  useEffect(() => {
    const checkAuth = async () => {
      const user = await getCurrentUser();
      if (user) {
        navigate("/dashboard");
      }
    };
    checkAuth();
  }, [navigate]);

  return (
    <div className="min-h-screen bg-background text-foreground font-sans">
      
      {/* --- 1. HERO SECTION: Giới thiệu và Kêu gọi hành động --- */}
      <section className="relative overflow-hidden pt-24 pb-32 md:pt-36 md:pb-48 gradient-secondary">
        <div className="container mx-auto px-4 text-center animate-fade-in">
          <div className="flex flex-col items-center max-w-5xl mx-auto">
            
            {/* Logo/Icon */}
            <div className="w-16 h-16 rounded-3xl gradient-primary flex items-center justify-center mb-6 shadow-xl shadow-primary/30">
              <Zap className="w-9 h-9 text-white animate-pulse-slow" />
            </div>
            
            {/* Title */}
            <h1 className="text-5xl md:text-7xl font-extrabold mb-4 leading-tight tracking-tighter">
              <span className="bg-clip-text text-transparent bg-gradient-to-r from-primary to-primary-glow">
                Intelligent{" "}
              </span>
              HRM & Operations OS
            </h1>
            
            {/* Subtitle */}
            <p className="text-xl md:text-2xl text-muted-foreground mb-8 max-w-3xl">
              The modern, all-in-one platform for human resource management, powered by Supabase and AI.
            </p>
            
            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button 
                size="xl" // Giả sử bạn có size xl trong button
                className="text-lg px-10 h-14 shadow-2xl shadow-primary/40 gradient-primary transition-all hover:scale-[1.03] transform"
                onClick={() => navigate("/auth/login")}
              >
                Access Dashboard
              </Button>
              <Button 
                size="xl"
                variant="outline" 
                className="text-lg px-10 h-14 border-2 border-border/80 transition-all hover:bg-muted"
                onClick={() => navigate("/auth/login")}
              >
                Start Trial 
              </Button>
            </div>
          </div>
        </div>
      </section>

      <hr className="border-t border-border/50" />

      {/* --- 2. FEATURES GRID: Lưới tính năng --- */}
      <section className="container mx-auto px-4 py-24">
        <div className="text-center mb-16 max-w-3xl mx-auto">
          <p className="text-sm font-semibold uppercase text-primary mb-2 tracking-widest">
            CORE MODULES
          </p>
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4 tracking-tight">
            Comprehensive & Role-Specific
          </h2>
          <p className="text-lg text-muted-foreground">
            From seamless check-ins with GPS to automated workflows and performance scoring, we cover everything.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
          {FEATURES.map((feature, index) => (
            <div 
              key={index}
              className="p-8 rounded-2xl bg-card border border-border shadow-lg transition-all duration-300 hover:shadow-2xl hover:border-primary/50 transform hover:-translate-y-1"
              style={{ animationDelay: `${index * 150}ms` }}
            >
              <div className="w-14 h-14 rounded-xl gradient-primary flex items-center justify-center mb-6 shadow-medium">
                <feature.icon className="w-7 h-7 text-white" />
              </div>
              <h3 className="text-xl font-semibold mb-3 tracking-tight">
                {feature.title}
              </h3>
              <p className="text-base text-muted-foreground">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </section>

      <hr className="border-t border-border/50" />

      {/* --- 3. CTA SECTION: Kêu gọi hành động cuối cùng --- */}
      <section className="container mx-auto px-4 py-24">
        <div className="max-w-4xl mx-auto text-center bg-card rounded-3xl p-12 md:p-16 shadow-2xl border-2 border-border/70 transform hover:scale-[1.01] transition-all duration-500">
          <h2 className="text-3xl md:text-4xl font-extrabold mb-4 tracking-tight">
            Ready to Transform Your HR?
          </h2>
          <p className="text-lg text-muted-foreground mb-10 max-w-2xl mx-auto">
            Get instant access to your personalized, role-based dashboard. Secure, fast, and ready to scale.
          </p>
          <Button 
            size="xl" 
            className="text-lg px-12 h-14 shadow-2xl shadow-primary/40 gradient-primary transition-all hover:scale-105"
            onClick={() => navigate("/auth/login")}
          >
            Go to Login Now →
          </Button>
        </div>
      </section>

      <hr className="border-t border-border/50" />

      {/* --- 4. FOOTER --- */}
      <footer className="bg-card">
        <div className="container mx-auto px-4 py-8 text-center text-muted-foreground">
          <p className="text-sm">
            © {new Date().getFullYear()} {APP_NAME}. Built with Next.js, Supabase, and Tailwind CSS.
          </p>
        </div>
      </footer>
    </div>
  );
};

export default Index;