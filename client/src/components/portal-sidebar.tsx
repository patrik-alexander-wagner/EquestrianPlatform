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
import { LayoutDashboard, CalendarRange, Users, Package, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Horseshoe } from "@/components/icons/horseshoe";
import { LogoMark } from "@/components/icons/logo-mark";

const navItems = [
  { title: "Dashboard", url: "/portal", icon: LayoutDashboard },
  { title: "Calendar", url: "/portal/calendar", icon: CalendarRange },
  { title: "My Riders", url: "/portal/my-riders", icon: Users },
  { title: "Riding Packages", url: "/portal/packages", icon: Package },
  { title: "My Horses", url: "/portal/my-horses", icon: Horseshoe },
];

interface PortalSidebarProps {
  onLogout: () => void;
}

export function PortalSidebar({ onLogout }: PortalSidebarProps) {
  const [location] = useLocation();

  return (
    <Sidebar>
      <SidebarHeader className="p-4">
        <Link href="/portal">
          <div className="flex items-center gap-2 cursor-pointer">
            <div className="w-[38px] h-[38px] rounded-[10px] bg-white border border-sidebar-border flex items-center justify-center shrink-0">
              <LogoMark className="w-5 h-[26px]" />
            </div>
            <div>
              <h1 className="font-serif text-lg font-semibold tracking-tight leading-none" data-testid="text-app-title">Saddle Hub</h1>
              <p className="text-xs text-muted-foreground">ADEC &middot; Member Portal</p>
            </div>
          </div>
        </Link>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>My Account</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton
                    asChild
                    data-active={location === item.url || (item.url !== "/portal" && location.startsWith(item.url + "/"))}
                  >
                    <Link href={item.url} data-testid={`link-portal-nav-${item.title.toLowerCase().replace(/\s+/g, "-")}`}>
                      <item.icon className="w-4 h-4" />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter className="p-3 border-t border-sidebar-border">
        <Button
          variant="ghost"
          className="w-full justify-start text-muted-foreground hover:text-foreground"
          onClick={onLogout}
          data-testid="button-portal-logout"
        >
          <LogOut className="w-4 h-4 mr-2" />
          Sign Out
        </Button>
      </SidebarFooter>
    </Sidebar>
  );
}
