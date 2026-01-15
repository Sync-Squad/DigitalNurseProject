import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"
import {
  Activity,
  Bell,
  ClipboardList,
  FileBarChart,
  FileText,
  HeartPulse,
  Settings,
  Shield,
  Users,
} from "lucide-react"
import { NavLink, useNavigate, useLocation } from "react-router-dom"
import { useAuth } from "@/contexts/auth-context"

type NavItem = {
  title: string
  icon: React.ComponentType<{ className?: string }>
  to: string
  badge?: string
}

const mainNav: NavItem[] = [
  {
    title: "Dashboard",
    icon: Activity,
    to: "/",
  },
  {
    title: "Patients",
    icon: Users,
    to: "/patients",
  },
  {
    title: "Caregivers",
    icon: HeartPulse,
    to: "/caregivers",
  },
  // {
  //   title: "Notifications",
  //   icon: Bell,
  //   to: "/notifications",
  //   badge: "12",
  // },
  // {
  //   title: "Documents",
  //   icon: FileText,
  //   to: "/documents",
  // },
]

const operationsNav: NavItem[] = [
  {
    title: "Subscriptions",
    icon: ClipboardList,
    to: "/subscriptions",
  },
  // {
  //   title: "Reports",
  //   icon: FileBarChart,
  //   to: "/reports",
  // },
  // {
  //   title: "Settings",
  //   icon: Settings,
  //   to: "/settings",
  // },
  // {
  //   title: "Audit Trail",
  //   icon: Shield,
  //   to: "/audit",
  // },
]

export function AppSidebar() {
  const { user, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()

  const role = user?.role?.toLowerCase() || "patient"
  const isSuperAdmin = role === "super_admin"
  const isAdmin = ["super_admin", "admin", "clinician", "coordinator", "provider"].includes(role)
  const isCaregiver = role === "caregiver"

  // Filter navigation items based on role
  const filteredMainNav = mainNav.filter(item => {
    if (item.to === "/caregivers") {
      return isAdmin // Only admins see caregivers list
    }
    if (item.to === "/patients") {
      return isAdmin || isCaregiver // Admins and caregivers see patients roster
    }
    return true // Everyone sees dashboard
  })

  const filteredOperationsNav = operationsNav.filter(item => {
    if (item.to === "/subscriptions") {
      return isAdmin // Only admins see subscriptions
    }
    return isAdmin
  })

  const handleLogout = () => {
    logout()
    navigate("/login")
  }

  const renderNav = (items: NavItem[]) =>
    items.map((item) => {
      const isActive =
        item.to === "/"
          ? location.pathname === "/"
          : location.pathname.startsWith(item.to)

      const Icon = item.icon

      return (
        <SidebarMenuItem key={item.title}>
          <SidebarMenuButton
            asChild
            isActive={isActive}
            tooltip={item.title}
            aria-label={item.title}
            className="group-data-[collapsible=icon]/sidebar:px-0"
          >
            <NavLink
              to={item.to}
              className={({ isActive: navActive }) =>
                cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-all",
                  "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                  navActive
                    ? "bg-sidebar-primary text-sidebar-primary-foreground shadow-sm"
                    : "text-sidebar-foreground/80"
                )
              }
              end={item.to === "/"}
            >
              <Icon className="size-4 shrink-0" />
              <span className="flex-1 truncate transition-[margin,opacity] duration-200 ease-linear group-data-[collapsible=icon]/sidebar:hidden">
                {item.title}
              </span>
              {item.badge ? (
                <Badge variant="secondary" className="ml-auto h-5 px-1 text-xs group-data-[collapsible=icon]/sidebar:hidden">
                  {item.badge}
                </Badge>
              ) : null}
            </NavLink>
          </SidebarMenuButton>
        </SidebarMenuItem>
      )
    })

  return (
    <Sidebar collapsible="icon" className="group/sidebar">
      <SidebarHeader className="px-3 py-4 group-data-[collapsible=icon]/sidebar:px-1">
        <Button
          variant="secondary"
          size="sm"
          className={cn(
            "h-auto w-full items-center justify-between rounded-xl px-3 py-2 text-left shadow-sm",
            "transition-all duration-200 ease-linear",
            "group-data-[collapsible=icon]/sidebar:h-12 group-data-[collapsible=icon]/sidebar:w-12 group-data-[collapsible=icon]/sidebar:justify-center group-data-[collapsible=icon]/sidebar:rounded-full group-data-[collapsible=icon]/sidebar:p-0"
          )}
        >
          <span className="flex flex-col text-xs leading-tight text-muted-foreground group-data-[collapsible=icon]/sidebar:hidden">
            Digital Nurse
            <span className="text-base font-semibold text-foreground">
              Care Portal
            </span>
          </span>
          <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-sidebar-primary text-sidebar-primary-foreground text-sm font-semibold">
            DN
          </span>
        </Button>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel className="text-[0.65rem] uppercase tracking-wide text-white group-data-[collapsible=icon]/sidebar:hidden">
            Main
          </SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu className="gap-1.5">{renderNav(filteredMainNav)}</SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
        {isAdmin && (
          <SidebarGroup>
            <SidebarGroupLabel className="text-[0.65rem] uppercase tracking-wide text-white group-data-[collapsible=icon]/sidebar:hidden">
              Operations
            </SidebarGroupLabel>
            <SidebarGroupContent>
              <SidebarMenu className="gap-1.5">
                {renderNav(filteredOperationsNav)}
              </SidebarMenu>
            </SidebarGroupContent>
          </SidebarGroup>
        )}
      </SidebarContent>
      <SidebarFooter className="mt-auto px-3 pb-4 group-data-[collapsible=icon]/sidebar:px-1">
        <Separator className="mb-3 group-data-[collapsible=icon]/sidebar:hidden" />
        <Button
          variant="ghost"
          onClick={handleLogout}
          className={cn(
            "flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left hover:bg-sidebar-accent/70",
            "transition-all duration-200 ease-linear",
            "group-data-[collapsible=icon]/sidebar:flex-col group-data-[collapsible=icon]/sidebar:gap-2 group-data-[collapsible=icon]/sidebar:px-0 group-data-[collapsible=icon]/sidebar:py-2 group-data-[collapsible=icon]/sidebar:text-center"
          )}
        >
          <Avatar className="size-10 rounded-2xl group-data-[collapsible=icon]/sidebar:size-12">
            <AvatarFallback className="rounded-2xl bg-sidebar-primary/20 text-white uppercase">
              {user?.name?.charAt(0) || "U"}
            </AvatarFallback>
          </Avatar>
          <div className="flex min-w-0 flex-1 flex-col text-xs group-data-[collapsible=icon]/sidebar:hidden">
            <span className="truncate font-medium text-white">
              {user?.name || "User"}
            </span>
            <span className="truncate text-white/70 capitalize">
              {isSuperAdmin ? "Super Admin" : user?.role || "Basic User"}
            </span>
          </div>
          <span className="hidden text-xs font-medium text-sidebar-primary group-data-[collapsible=icon]/sidebar:block">
            LO
          </span>
        </Button>
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
  )
}

