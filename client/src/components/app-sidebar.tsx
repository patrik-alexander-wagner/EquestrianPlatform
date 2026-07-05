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
  ListChecks,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Horseshoe } from "@/components/icons/horseshoe";
import { LogoMark } from "@/components/icons/logo-mark";
import { usePermissions } from "@/hooks/use-permissions";

interface NavItem {
  title: string;
  url: string;
  icon: React.ComponentType<{ className?: string }>;
  view: string | string[];
}

interface NavGroup {
  label: string;
  items: NavItem[];
}

const stableManagementNavGroups: NavGroup[] = [
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
];

const ridingSchoolNavGroups: NavGroup[] = [
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
      { title: "Booking History", url: "/riding-school/booking-history", icon: ListChecks, view: "riding_school.view" },
      { title: "Rider Levels", url: "/riding-school/rider-levels", icon: Tags, view: "riding_school.settings.manage" },
    ],
  },
];

// Shared across both admin sub-modes so toggling Stable Mgmt <-> Riding
// School never hides Users/Roles/Settings/Audit Logs. Settings is a single
// shared page (client/src/pages/admin-settings.tsx) that itself shows/hides
// its livery vs. lesson-template/package/cancellation-notice sections per
// the viewer's specific permission — the nav link (and route) just need ANY
// one of those permissions to be reachable at all.
const administrationNavGroup: NavGroup = {
  label: "Administration",
  items: [
    { title: "Users", url: "/admin/users", icon: UserCog, view: "admin.users" },
    { title: "Roles", url: "/admin/roles", icon: ShieldCheck, view: "admin.roles" },
    {
      title: "Settings", url: "/admin/settings", icon: Settings,
      view: ["admin.settings", "riding_school.templates.manage", "riding_school.packages.manage", "riding_school.settings.manage"],
    },
    { title: "Audit Logs", url: "/admin/audit-logs", icon: Shield, view: "admin.audit_logs" },
  ],
};

export type AdminMode = "stable" | "riding-school";

interface AppSidebarProps {
  onLogout: () => void;
  mode: AdminMode;
  onModeChange: (mode: AdminMode) => void;
}

export function AppSidebar({ onLogout, mode, onModeChange }: AppSidebarProps) {
  const [location] = useLocation();
  const { isAdmin, permissions } = usePermissions();

  const canView = (key: string | string[]) => {
    if (isAdmin) return true;
    const keys = Array.isArray(key) ? key : [key];
    return keys.some((k) => permissions.includes(k));
  };
  const canViewRidingSchool = isAdmin || permissions.includes("riding_school.view") || permissions.includes("shared_resources.view");

  const activeNavGroups = [
    ...(mode === "riding-school" ? ridingSchoolNavGroups : stableManagementNavGroups),
    administrationNavGroup,
  ];

  return (
    <Sidebar>
      <SidebarHeader className="p-4 border-b border-sidebar-border">
        <Link href="/">
          <div className="flex items-center gap-2 cursor-pointer">
            <div className="w-9 h-9 rounded-[10px] bg-white border border-sidebar-border flex items-center justify-center shrink-0">
              <LogoMark className="w-5 h-[26px]" />
            </div>
            <div>
              <h1 className="font-serif text-base font-semibold tracking-tight leading-none" data-testid="text-app-title">Saddle Hub</h1>
              <p className="text-xs text-muted-foreground">ADEC &middot; {mode === "riding-school" ? "Riding School" : "Stable Management"}</p>
            </div>
          </div>
        </Link>
        {canViewRidingSchool && (
          <div className="flex mt-3 rounded-md border p-0.5 text-xs">
            <button
              type="button"
              onClick={() => onModeChange("stable")}
              data-testid="button-mode-stable"
              className={`flex-1 rounded px-2 py-1 ${mode === "stable" ? "bg-primary text-primary-foreground" : "text-muted-foreground"}`}
            >
              Stable Mgmt
            </button>
            <button
              type="button"
              onClick={() => onModeChange("riding-school")}
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
