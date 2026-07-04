import { Link, useLocation } from "wouter";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarHeader,
  SidebarFooter,
} from "@/components/ui/sidebar";
import {
  Receipt,
  FileText,
  Users,
  Building2,
  Box,
  Package,
  ClipboardList,
  FilePlus,
  CreditCard,
  FileBarChart,
  BarChart3,
  Settings,
  UserCog,
  LogOut,
  Shield,
  ShieldCheck,
  History,
  ArrowRightLeft,
  LandPlot,
  GraduationCap,
  Tags,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Horseshoe } from "@/components/icons/horseshoe";
import { usePermissions } from "@/hooks/use-permissions";

const navGroups = [
  {
    label: "Billing Element",
    items: [
      { title: "Billing Elements", url: "/billing-elements", icon: Receipt, view: "billing_elements.view" },
    ],
  },
  {
    label: "Livery Agreements",
    items: [
      { title: "Current Agreements", url: "/agreements/current", icon: FileText, view: "agreements.view" },
      { title: "New Agreement", url: "/agreements/new", icon: FilePlus, view: "agreements.view" },
      { title: "History", url: "/agreements/history", icon: History, view: "agreements.view" },
    ],
  },
  {
    label: "Master Data",
    items: [
      { title: "Customers", url: "/customers", icon: Users, view: "customers.view" },
      { title: "Horses", url: "/horses", icon: Horseshoe, view: "horses.view" },
      { title: "Stables", url: "/stables", icon: Building2, view: "stables.view" },
      { title: "Boxes", url: "/boxes", icon: Box, view: "boxes.view" },
      { title: "Items", url: "/items", icon: Package, view: "items.view" },
    ],
  },
  {
    label: "Stable Management",
    items: [
      { title: "Horse Movements", url: "/stable-management/horse-movements", icon: ArrowRightLeft, view: "movements.view" },
    ],
  },
  {
    label: "Billing",
    items: [
      { title: "To Invoice", url: "/billing/to-invoice", icon: ClipboardList, view: "to_invoice.view" },
      { title: "Invoices", url: "/billing/invoices", icon: CreditCard, view: "invoices.view" },
    ],
  },
  {
    label: "Reports",
    items: [
      { title: "Livery Reports", url: "/reports/livery", icon: BarChart3, view: "reports.view" },
    ],
  },
  {
    label: "Administration",
    items: [
      { title: "Users", url: "/admin/users", icon: UserCog, view: "admin.users" },
      { title: "Roles", url: "/admin/roles", icon: ShieldCheck, view: "admin.roles" },
      { title: "Settings", url: "/admin/settings", icon: Settings, view: "admin.settings" },
      { title: "Audit Logs", url: "/admin/audit-logs", icon: Shield, view: "admin.audit_logs" },
    ],
  },
  {
    // Temporary home for these links — Milestone 4 replaces this with a full
    // Riding School / Stable Management mode toggle and dedicated sidebar.
    label: "Riding School (Shared Resources)",
    items: [
      { title: "Arenas", url: "/riding-school/arenas", icon: LandPlot, view: "shared_resources.view" },
      { title: "Instructors", url: "/riding-school/instructors", icon: GraduationCap, view: "shared_resources.view" },
      { title: "Rider Levels", url: "/riding-school/rider-levels", icon: Tags, view: "riding_school.settings.manage" },
    ],
  },
];

interface AppSidebarProps {
  onLogout: () => void;
}

export function AppSidebar({ onLogout }: AppSidebarProps) {
  const [location] = useLocation();
  const { isAdmin, permissions } = usePermissions();

  const canView = (key: string) => isAdmin || permissions.includes(key);

  return (
    <Sidebar>
      <SidebarHeader className="p-4 border-b border-sidebar-border">
        <Link href="/">
          <div className="flex items-center gap-2 cursor-pointer">
            <div className="w-8 h-8 rounded-md bg-primary flex items-center justify-center">
              <Horseshoe className="w-5 h-5" inverted />
            </div>
            <div>
              <h1 className="text-base font-semibold tracking-tight" data-testid="text-app-title">StableMaster</h1>
              <p className="text-xs text-muted-foreground">Stable Management</p>
            </div>
          </div>
        </Link>
      </SidebarHeader>
      <SidebarContent>
        {navGroups
          .map((group) => ({ ...group, items: group.items.filter((item) => canView(item.view)) }))
          .filter((group) => group.items.length > 0)
          .map((group) => (
          <SidebarGroup key={group.label}>
            <SidebarGroupLabel>{group.label}</SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu>
                {group.items.map((item) => (
                  <SidebarMenuItem key={item.title}>
                    <SidebarMenuButton
                      asChild
                      data-active={location === item.url || location.startsWith(item.url + "/")}
                    >
                      <Link href={item.url} data-testid={`link-nav-${item.title.toLowerCase().replace(/\s+/g, "-")}`}>
                        <item.icon className="w-4 h-4" />
                        <span>{item.title}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                ))}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        ))}
      </SidebarContent>
      <SidebarFooter className="p-3 border-t border-sidebar-border">
        <Button
          variant="ghost"
          className="w-full justify-start text-muted-foreground hover:text-foreground"
          onClick={onLogout}
          data-testid="button-logout"
        >
          <LogOut className="w-4 h-4 mr-2" />
          Sign Out
        </Button>
      </SidebarFooter>
    </Sidebar>
  );
}
