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
import HorseMovementsPage from "@/pages/horse-movements";
import AdminRolesPage from "@/pages/admin-roles";
import { usePermissions, useCan } from "@/hooks/use-permissions";

function PermissionRoute({ component: Component, action }: { component: React.ComponentType; action: string }) {
  const { isLoading } = usePermissions();
  const allowed = useCan(action);
  if (isLoading) return null;
  if (!allowed) return <Redirect to="/" />;
  return <Component />;
}

function Router() {
  return (
    <Switch>
      <Route path="/" component={DashboardPage} />
      <Route path="/customers">{() => <PermissionRoute component={CustomersPage} action="customers.view" />}</Route>
      <Route path="/horses">{() => <PermissionRoute component={HorsesPage} action="horses.view" />}</Route>
      <Route path="/stables">{() => <PermissionRoute component={StablesPage} action="stables.view" />}</Route>
      <Route path="/boxes">{() => <PermissionRoute component={BoxesPage} action="boxes.view" />}</Route>
      <Route path="/items">{() => <PermissionRoute component={ItemsPage} action="items.view" />}</Route>
      <Route path="/agreements/current">{() => <PermissionRoute component={CurrentAgreementsPage} action="agreements.view" />}</Route>
      <Route path="/agreements/new">{() => <PermissionRoute component={NewAgreementPage} action="agreements.view" />}</Route>
      <Route path="/agreements/history">{() => <PermissionRoute component={AgreementHistoryPage} action="agreements.view" />}</Route>
      <Route path="/billing-elements">{() => <PermissionRoute component={BillingElementsPage} action="billing_elements.view" />}</Route>
      <Route path="/billing/to-invoice">{() => <PermissionRoute component={ToInvoicePage} action="to_invoice.view" />}</Route>
      <Route path="/billing/invoices">{() => <PermissionRoute component={InvoicesPage} action="invoices.view" />}</Route>
      <Route path="/reports/livery">{() => <PermissionRoute component={ReportsPage} action="reports.view" />}</Route>
      <Route path="/stable-management/horse-movements">{() => <PermissionRoute component={HorseMovementsPage} action="movements.view" />}</Route>
      <Route path="/admin/users">{() => <PermissionRoute component={AdminUsersPage} action="admin.users" />}</Route>
      <Route path="/admin/settings">{() => <PermissionRoute component={AdminSettingsPage} action="admin.settings" />}</Route>
      <Route path="/admin/audit-logs">{() => <PermissionRoute component={AdminAuditLogsPage} action="admin.audit_logs" />}</Route>
      <Route path="/admin/roles">{() => <PermissionRoute component={AdminRolesPage} action="admin.roles" />}</Route>
      <Route component={NotFound} />
    </Switch>
  );
}

function getInitials(username: string): string {
  if (!username) return "?";
  const local = username.split("@")[0];
  const parts = local.split(/[._-]+/).filter(Boolean);
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return username.slice(0, 2).toUpperCase();
}

function App() {
  const [authState, setAuthState] = useState<"loading" | "authenticated" | "unauthenticated">("loading");
  const [userRole, setUserRole] = useState<string>("user");
  const [username, setUsername] = useState<string>("");

  const checkAuth = async () => {
    try {
      const res = await fetch("/api/me");
      if (res.ok) {
        const data = await res.json();
        setUserRole(data.role || "user");
        setUsername(data.username || "");
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
    setUsername("");
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
            <AppSidebar onLogout={handleLogout} />
            <div className="flex flex-col flex-1 min-w-0">
              <header className="flex items-center gap-2 p-2 border-b shrink-0">
                <SidebarTrigger data-testid="button-sidebar-toggle" />
                <div
                  className="ml-auto mr-2 w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs font-semibold cursor-default"
                  title={username}
                  data-testid="avatar-initials"
                >
                  {getInitials(username)}
                </div>
              </header>
              <main className="flex-1 overflow-auto">
                <Router />
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
