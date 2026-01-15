import { Outlet, useNavigate } from "react-router-dom"
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import { ThemeToggle } from "@/components/theme-toggle"
import { AppSidebar } from "@/components/app-sidebar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Bell, Languages, UserCog } from "lucide-react"
import { Separator } from "@/components/ui/separator"
import { useAuth } from "@/contexts/auth-context"

export function AppLayout() {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset>
        <header className="border-b border-border/40 bg-background/70 backdrop-blur transition-[height] duration-200 ease-linear supports-[backdrop-filter]:bg-background/60 group-data-[collapsible=icon]/sidebar-wrapper:h-14">
          <div className="mx-auto flex h-16 w-full max-w-6xl items-center gap-2 px-4">
            <SidebarTrigger className="" />
            <Separator orientation="vertical" className="h-6" />
            {/* <div className="hidden flex-1 items-center gap-3 md:flex">
              <SidebarTrigger className="hidden h-9 w-9 items-center justify-center rounded-full border border-border/50 bg-background shadow-sm transition-all hover:bg-muted md:inline-flex" />
              <Input
                className="h-10 w-full max-w-lg rounded-full border border-border/50 bg-card/80 px-4 shadow-xs focus-visible:ring-2 focus-visible:ring-sidebar-ring/50"
                placeholder="Search patients, caregivers, alerts..."
              />
            </div> */}
            <div className="ml-auto flex items-center gap-2">
              {/* <LanguageToggle />
              <Badge variant="secondary" className="hidden rounded-full px-3 py-1 text-xs font-medium md:flex">
                Care Coordinator
              </Badge> */}
              {/* <Button variant="ghost" size="icon" className="relative rounded-full border border-border/50 bg-background/60 shadow-xs hover:bg-muted">
                <Bell className="size-4" />
                <span className="sr-only">Notifications</span>
                <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-destructive" />
              </Button> */}
              {/* <ThemeToggle /> */}
              <UserProfileMenu />
            </div>
          </div>
        </header>
        <main className="flex-1 overflow-y-auto bg-muted/10">
          <div className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-6">
            <Outlet />
          </div>
        </main>
      </SidebarInset>
    </SidebarProvider>
  )
}

function UserProfileMenu() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate("/login")
  }

  const userInitials = user?.name
    ? user.name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2)
    : "U"

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className="flex items-center gap-2 px-2 text-left"
        >
          <Avatar className="size-8">
            <AvatarFallback>{userInitials}</AvatarFallback>
          </Avatar>
          <div className="hidden text-xs md:flex md:flex-col">
            <span className="font-medium">{user?.name || "User"}</span>
            <span className="text-muted-foreground">{user?.role || "Role"}</span>
          </div>
          <UserCog className="hidden size-4 text-muted-foreground md:block" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel>Signed in as</DropdownMenuLabel>
        <div className="px-2 pb-2 text-sm text-muted-foreground">
          {user?.email || "user@example.com"}
        </div>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          {/* <DropdownMenuItem>My Profile</DropdownMenuItem> */}
          {/* <DropdownMenuItem>Care Teams</DropdownMenuItem> */}
          {/* <DropdownMenuItem>Security Settings</DropdownMenuItem> */}
        </DropdownMenuGroup>
        {/* <DropdownMenuSeparator /> */}
        <DropdownMenuItem className="text-destructive" onClick={handleLogout}>
          Sign out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

function LanguageToggle() {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="gap-2 px-2">
          <Languages className="size-4" />
          <span className="hidden text-xs font-medium md:inline-flex">EN</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-32">
        <DropdownMenuItem>English</DropdownMenuItem>
        <DropdownMenuItem>Urdu</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

