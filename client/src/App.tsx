import { useState, useEffect } from "react";
import { Switch, Route, Redirect, useLocation } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar, type AdminMode } from "@/components/app-sidebar";
import { PortalSidebar } from "@/components/portal-sidebar";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuSeparator } from "@/components/ui/dropdown-menu";
import { LogOut, ArrowLeftRight } from "lucide-react";
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
import ArenasPage from "@/pages/riding-school/arenas";
import InstructorsPage from "@/pages/riding-school/instructors";
import RiderLevelsPage from "@/pages/riding-school/rider-levels";
import RidingSchoolOverviewPage from "@/pages/riding-school/overview";
import RidingSchoolCalendarPage from "@/pages/riding-school/calendar";
import HorseManagementPage from "@/pages/riding-school/horse-management";
import RidingSchoolReportsPage from "@/pages/riding-school/reports";
import BookingHistoryPage from "@/pages/riding-school/booking-history";
import PortalDashboardPage from "@/pages/portal/dashboard";
import PortalCalendarPage from "@/pages/portal/calendar";
import MyRidersPage from "@/pages/portal/my-riders";
import PortalPackagesPage from "@/pages/portal/packages";
import MyHorsesPage from "@/pages/portal/my-horses";
import { usePermissions, useCan } from "@/hooks/use-permissions";

function PermissionRoute({ component: Component, action }: { component: React.ComponentType; action: string | string[] }) {
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
      <Route path="/admin/settings">{() => <PermissionRoute component={AdminSettingsPage} action={["admin.settings", "riding_school.templates.manage", "riding_school.packages.manage", "riding_school.settings.manage"]} />}</Route>
      <Route path="/admin/audit-logs">{() => <PermissionRoute component={AdminAuditLogsPage} action="admin.audit_logs" />}</Route>
      <Route path="/admin/roles">{() => <PermissionRoute component={AdminRolesPage} action="admin.roles" />}</Route>
      <Route path="/riding-school/arenas">{() => <PermissionRoute component={ArenasPage} action="shared_resources.view" />}</Route>
      <Route path="/riding-school/instructors">{() => <PermissionRoute component={InstructorsPage} action="shared_resources.view" />}</Route>
      <Route path="/riding-school/rider-levels">{() => <PermissionRoute component={RiderLevelsPage} action="riding_school.settings.manage" />}</Route>
      <Route path="/riding-school/overview">{() => <PermissionRoute component={RidingSchoolOverviewPage} action="riding_school.view" />}</Route>
      <Route path="/riding-school/calendar">{() => <PermissionRoute component={RidingSchoolCalendarPage} action="riding_school.view" />}</Route>
      <Route path="/riding-school/horse-management">{() => <PermissionRoute component={HorseManagementPage} action="riding_school.view" />}</Route>
      <Route path="/riding-school/reports">{() => <PermissionRoute component={RidingSchoolReportsPage} action="riding_school.view" />}</Route>
      <Route path="/riding-school/booking-history">{() => <PermissionRoute component={BookingHistoryPage} action="riding_school.view" />}</Route>
      <Route component={NotFound} />
    </Switch>
  );
}

function PortalRouter() {
  return (
    <Switch>
      <Route path="/">{() => <Redirect to="/portal" />}</Route>
      <Route path="/portal" component={PortalDashboardPage} />
      <Route path="/portal/calendar" component={PortalCalendarPage} />
      <Route path="/portal/my-riders" component={MyRidersPage} />
      <Route path="/portal/packages" component={PortalPackagesPage} />
      <Route path="/portal/my-horses" component={MyHorsesPage} />
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
  const [, navigate] = useLocation();
  const [authState, setAuthState] = useState<"loading" | "authenticated" | "unauthenticated">("loading");
  const [username, setUsername] = useState<string>("");
  const [roles, setRoles] = useState<string[]>([]);
  const [customerId, setCustomerId] = useState<string | null>(null);
  // Only meaningful for a user who holds CUSTOMER alongside at least one
  // staff role (e.g. an admin who also wants the member-facing view). A user
  // who ONLY holds CUSTOMER always renders the portal — there is no admin
  // identity to switch back to.
  const [viewMode, setViewMode] = useState<"admin" | "portal">("admin");
  // Lifted out of AppSidebar so the whole shell (sidebar + header avatar) can
  // theme together — Riding School uses a near-black accent everywhere
  // Stable Management uses brand green.
  const [adminMode, setAdminMode] = useState<AdminMode>(() => {
    if (typeof window === "undefined") return "stable";
    return (localStorage.getItem("saddlehub.sidebarMode") as AdminMode) || "stable";
  });

  const handleAdminModeChange = (next: AdminMode) => {
    setAdminMode(next);
    localStorage.setItem("saddlehub.sidebarMode", next);
  };

  const hasCustomerRole = roles.includes("CUSTOMER") && !!customerId;
  const hasStaffRole = roles.some(r => r !== "CUSTOMER");
  const canSwitchPortal = hasCustomerRole && hasStaffRole;

  const checkAuth = async () => {
    try {
      const res = await fetch("/api/me");
      if (res.ok) {
        const data = await res.json();
        const fetchedRoles: string[] = data.roles || [];
        setUsername(data.username || "");
        setRoles(fetchedRoles);
        setCustomerId(data.customerId || null);
        const isPureCustomer = fetchedRoles.length > 0 && fetchedRoles.every((r: string) => r === "CUSTOMER");
        setViewMode(isPureCustomer ? "portal" : "admin");
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
    // The browser URL may still hold a path from a previous session (e.g. a
    // portal path if the last user was a customer). "/" is always valid:
    // Router renders the staff dashboard directly, PortalRouter redirects
    // "/" to "/portal" for customer sessions.
    navigate("/");
  };

  const handleLogout = async () => {
    await fetch("/api/logout", { method: "POST" });
    setAuthState("unauthenticated");
    setUsername("");
    setRoles([]);
    setCustomerId(null);
    setViewMode("admin");
    navigate("/");
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

  const showPortal = viewMode === "portal";
  const themeClass = showPortal ? "portal-theme" : adminMode === "riding-school" ? "riding-school-theme" : "";

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <SidebarProvider style={style as React.CSSProperties}>
          <div className={`flex h-screen w-full ${themeClass}`}>
            {showPortal ? <PortalSidebar onLogout={handleLogout} /> : <AppSidebar onLogout={handleLogout} mode={adminMode} onModeChange={handleAdminModeChange} />}
            <div className="flex flex-col flex-1 min-w-0">
              <header className="flex items-center gap-2 p-2 border-b shrink-0">
                <SidebarTrigger data-testid="button-sidebar-toggle" />
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <button
                      className="ml-auto mr-2 w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-xs font-semibold"
                      title={username}
                      data-testid="avatar-initials"
                    >
                      {getInitials(username)}
                    </button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    {canSwitchPortal && (
                      <DropdownMenuItem
                        onClick={() => {
                          const next = showPortal ? "admin" : "portal";
                          setViewMode(next);
                          navigate(next === "portal" ? "/portal" : "/");
                        }}
                        data-testid="menu-item-switch-portal"
                      >
                        <ArrowLeftRight className="w-4 h-4 mr-2" />
                        Switch to {showPortal ? "Admin Portal" : "Customer Portal"}
                      </DropdownMenuItem>
                    )}
                    {canSwitchPortal && <DropdownMenuSeparator />}
                    <DropdownMenuItem onClick={handleLogout} data-testid="menu-item-logout">
                      <LogOut className="w-4 h-4 mr-2" />
                      Logout
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </header>
              <main className="flex-1 overflow-auto">
                {showPortal ? <PortalRouter /> : <Router />}
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
