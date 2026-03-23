import { useState, useEffect } from "react";
import { Switch, Route, Redirect } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import LoginPage from "@/pages/login";
import NotFound from "@/pages/not-found";
import DashboardPage from "@/pages/dashboard";
import CustomersPage from "@/pages/customers";
import HorsesPage from "@/pages/horses";
import StablesPage from "@/pages/stables";
import BoxesPage from "@/pages/boxes";
import ItemsPage from "@/pages/items";
import CurrentAgreementsPage from "@/pages/current-agreements";
import NewAgreementPage from "@/pages/new-agreement";
import AgreementHistoryPage from "@/pages/agreement-history";
import BillingElementsPage from "@/pages/billing-elements";
import ToInvoicePage from "@/pages/to-invoice";
import InvoicesPage from "@/pages/invoices";
import ReportsPage from "@/pages/reports";
import AdminUsersPage from "@/pages/admin-users";
import AdminSettingsPage from "@/pages/admin-settings";
import AdminAuditLogsPage from "@/pages/admin-audit-logs";

function AdminRoute({ component: Component, userRole }: { component: React.ComponentType; userRole: string }) {
  if (userRole !== "ADMIN") {
    return <Redirect to="/" />;
  }
  return <Component />;
}

function Router({ userRole }: { userRole: string }) {
  return (
    <Switch>
      <Route path="/" component={DashboardPage} />
      <Route path="/customers" component={CustomersPage} />
      <Route path="/horses" component={HorsesPage} />
      <Route path="/stables" component={StablesPage} />
      <Route path="/boxes" component={BoxesPage} />
      <Route path="/items" component={ItemsPage} />
      <Route path="/agreements/current" component={CurrentAgreementsPage} />
      <Route path="/agreements/new" component={NewAgreementPage} />
      <Route path="/agreements/history" component={AgreementHistoryPage} />
      <Route path="/billing-elements" component={BillingElementsPage} />
      <Route path="/billing/to-invoice" component={ToInvoicePage} />
      <Route path="/billing/invoices" component={InvoicesPage} />
      <Route path="/reports/livery" component={ReportsPage} />
      <Route path="/admin/users">{() => <AdminRoute component={AdminUsersPage} userRole={userRole} />}</Route>
      <Route path="/admin/settings">{() => <AdminRoute component={AdminSettingsPage} userRole={userRole} />}</Route>
      <Route path="/admin/audit-logs">{() => <AdminRoute component={AdminAuditLogsPage} userRole={userRole} />}</Route>
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  const [authState, setAuthState] = useState<"loading" | "authenticated" | "unauthenticated">("loading");
  const [userRole, setUserRole] = useState<string>("user");

  const checkAuth = async () => {
    try {
      const res = await fetch("/api/me");
      if (res.ok) {
        const data = await res.json();
        setUserRole(data.role || "user");
        setAuthState("authenticated");
      } else {
        setAuthState("unauthenticated");
      }
    } catch {
      setAuthState("unauthenticated");
    }
  };

  useEffect(() => {
    checkAuth();
  }, []);

  const handleLogin = async () => {
    await checkAuth();
    queryClient.clear();
  };

  const handleLogout = async () => {
    await fetch("/api/logout", { method: "POST" });
    setAuthState("unauthenticated");
    setUserRole("user");
    queryClient.clear();
  };

  if (authState === "loading") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <p className="text-muted-foreground">Loading...</p>
      </div>
    );
  }

  if (authState === "unauthenticated") {
    return (
      <QueryClientProvider client={queryClient}>
        <TooltipProvider>
          <LoginPage onLogin={handleLogin} />
          <Toaster />
        </TooltipProvider>
      </QueryClientProvider>
    );
  }

  const style = {
    "--sidebar-width": "16rem",
    "--sidebar-width-icon": "3rem",
  };

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <SidebarProvider style={style as React.CSSProperties}>
          <div className="flex h-screen w-full">
            <AppSidebar onLogout={handleLogout} userRole={userRole} />
            <div className="flex flex-col flex-1 min-w-0">
              <header className="flex items-center gap-2 p-2 border-b shrink-0">
                <SidebarTrigger data-testid="button-sidebar-toggle" />
              </header>
              <main className="flex-1 overflow-auto">
                <Router userRole={userRole} />
              </main>
            </div>
          </div>
        </SidebarProvider>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
