import { Switch, Route } from "wouter";
import { queryClient } from "./lib/queryClient";
import { QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import NotFound from "@/pages/not-found";
import DashboardPage from "@/pages/dashboard";
import CustomersPage from "@/pages/customers";
import HorsesPage from "@/pages/horses";
import StablesPage from "@/pages/stables";
import BoxesPage from "@/pages/boxes";
import ItemsPage from "@/pages/items";
import CurrentAgreementsPage from "@/pages/current-agreements";
import NewAgreementPage from "@/pages/new-agreement";
import BillingElementsPage from "@/pages/billing-elements";
import ToInvoicePage from "@/pages/to-invoice";
import InvoicesPage from "@/pages/invoices";
import ReportsPage from "@/pages/reports";
import AdminUsersPage from "@/pages/admin-users";
import AdminSettingsPage from "@/pages/admin-settings";

function Router() {
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
      <Route path="/billing-elements" component={BillingElementsPage} />
      <Route path="/billing/to-invoice" component={ToInvoicePage} />
      <Route path="/billing/invoices" component={InvoicesPage} />
      <Route path="/reports/livery" component={ReportsPage} />
      <Route path="/admin/users" component={AdminUsersPage} />
      <Route path="/admin/settings" component={AdminSettingsPage} />
      <Route component={NotFound} />
    </Switch>
  );
}

function App() {
  const style = {
    "--sidebar-width": "16rem",
    "--sidebar-width-icon": "3rem",
  };

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <SidebarProvider style={style as React.CSSProperties}>
          <div className="flex h-screen w-full">
            <AppSidebar />
            <div className="flex flex-col flex-1 min-w-0">
              <header className="flex items-center gap-2 p-2 border-b shrink-0">
                <SidebarTrigger data-testid="button-sidebar-toggle" />
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
