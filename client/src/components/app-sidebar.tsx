import { useState } from "react";
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
  LayoutDashboard,
  CalendarRange,
  HeartPulse,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Horseshoe } from "@/components/icons/horseshoe";
import { usePermissions } from "@/hooks/use-permissions";

const stableManagementNavGroups = [
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
];

const ridingSchoolNavGroups = [
  {
    label: "Riding School",
    items: [
      { title: "Overview", url: "/riding-school/overview", icon: LayoutDashboard, view: "riding_school.view" },
      { title: "Calendar", url: "/riding-school/calendar", icon: CalendarRange, view: "riding_school.view" },
      { title: "Horse Management", url: "/riding-school/horse-management", icon: HeartPulse, view: "riding_school.view" },
      { title: "Arenas", url: "/riding-school/arenas", icon: LandPlot, view: "shared_resources.view" },
      { title: "Instructors", url: "/riding-school/instructors", icon: GraduationCap, view: "shared_resources.view" },
      { title: "Customers", url: "/customers", icon: Users, view: "customers.view" },
      { title: "Reports", url: "/riding-school/reports", icon: BarChart3, view: "riding_school.view" },
      { title: "Rider Levels", url: "/riding-school/rider-levels", icon: Tags, view: "riding_school.settings.manage" },
      { title: "Settings", url: "/riding-school/settings", icon: Settings, view: "riding_school.settings.manage" },
    ],
  },
];

interface AppSidebarProps {
  onLogout: () => void;
}

const MODE_STORAGE_KEY = "stablemaster.sidebarMode";

export function AppSidebar({ onLogout }: AppSidebarProps) {
  const [location] = useLocation();
  const { isAdmin, permissions } = usePermissions();
  const [mode, setMode] = useState<"stable" | "riding-school">(() => {
    if (typeof window === "undefined") return "stable";
    return (localStorage.getItem(MODE_STORAGE_KEY) as "stable" | "riding-school") || "stable";
  });

  const canView = (key: string) => isAdmin || permissions.includes(key);
  const canViewRidingSchool = isAdmin || permissions.includes("riding_school.view") || permissions.includes("shared_resources.view");

  const setModeAndPersist = (next: "stable" | "riding-school") => {
    setMode(next);
    localStorage.setItem(MODE_STORAGE_KEY, next);
  };

  const activeNavGroups = mode === "riding-school" ? ridingSchoolNavGroups : stableManagementNavGroups;

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
              <p className="text-xs text-muted-foreground">{mode === "riding-school" ? "Riding School" : "Stable Management"}</p>
            </div>
          </div>
        </Link>
        {canViewRidingSchool && (
          <div className="flex mt-3 rounded-md border p-0.5 text-xs">
            <button
              type="button"
              onClick={() => setModeAndPersist("stable")}
              data-testid="button-mode-stable"
              className={`flex-1 rounded px-2 py-1 ${mode === "stable" ? "bg-primary text-primary-foreground" : "text-muted-foreground"}`}
            >
              Stable Mgmt
            </button>
            <button
              type="button"
              onClick={() => setModeAndPersist("riding-school")}
              data-testid="button-mode-riding-school"
              className={`flex-1 rounded px-2 py-1 ${mode === "riding-school" ? "bg-primary text-primary-foreground" : "text-muted-foreground"}`}
            >
              Riding School
            </button>
          </div>
        )}
      </SidebarHeader>
      <SidebarContent>
        {activeNavGroups
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
