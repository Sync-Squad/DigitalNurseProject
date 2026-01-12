import { useMemo, useState } from "react"
import { useNotificationsData } from "@/hooks/use-notifications-data"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { BellRing, Filter, Inbox, Plus } from "lucide-react"
import { cn } from "@/lib/utils"

const severityTone = {
  info: "bg-muted text-muted-foreground",
  warning: "bg-amber-500/10 text-amber-600",
  critical: "bg-rose-500/10 text-rose-600",
} as const

export default function NotificationsPage() {
  const [query, setQuery] = useState("")
  const [tab, setTab] = useState<"all" | "info" | "warning" | "critical">("all")
  const { notifications, loading, error } = useNotificationsData()

  const filtered = useMemo(() => {
    return notifications.filter((notification) => {
      const matchesTab = tab === "all" || notification.severity === tab
      const matchesQuery =
        notification.title.toLowerCase().includes(query.toLowerCase()) ||
        notification.summary.toLowerCase().includes(query.toLowerCase())
      return matchesTab && matchesQuery
    })
  }, [tab, query])

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">
            Notifications & Alerts
          </h1>
          <p className="text-sm text-muted-foreground">
            Review automated alerts, compose manual broadcasts, and triage
            escalation tags.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Filter className="size-4" />
            Saved filters
          </Button>
          <Button className="gap-2">
            <Plus className="size-4" />
            Compose alert
          </Button>
        </div>
      </div>

      <Tabs value={tab} onValueChange={(value) => setTab(value as typeof tab)}>
        <TabsList className="flex w-full justify-start gap-2 bg-muted/40">
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="critical">Critical</TabsTrigger>
          <TabsTrigger value="warning">Warning</TabsTrigger>
          <TabsTrigger value="info">Informational</TabsTrigger>
        </TabsList>
      </Tabs>

      <Card>
        <CardHeader className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              Notification inbox
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Most recent 30 events synchronized with mobile push history.
            </p>
          </div>
          <Input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Search by title or message contents"
            className="md:w-80"
          />
        </CardHeader>
        <CardContent className="space-y-4">
          <Card>
            <CardContent className="flex flex-wrap items-center gap-3 py-3 text-xs text-muted-foreground">
              <Badge variant="secondary" className="gap-1">
                <BellRing className="size-3.5" />
                Unread
              </Badge>
              <span>
                {notifications.filter((item) => !item.read).length} pending
                acknowledgements
              </span>
              <Button variant="ghost" size="sm">
                Mark all as read
              </Button>
            </CardContent>
          </Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Recipients</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((notification) => (
                <TableRow key={notification.id}>
                  <TableCell className="space-y-1">
                    <p className="font-medium">{notification.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {notification.summary}
                    </p>
                  </TableCell>
                  <TableCell>
                    <Badge
                      className={cn("gap-1", severityTone[notification.severity])}
                    >
                      <Inbox className="size-3.5" />
                      {notification.category}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {notification.recipients.map((recipient) => (
                        <Badge
                          key={recipient}
                          variant="outline"
                          className="text-[10px]"
                        >
                          {recipient}
                        </Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {notification.createdAt.toLocaleString()}
                  </TableCell>
                  <TableCell>
                    <Badge variant={notification.read ? "outline" : "secondary"}>
                      {notification.read ? "Read" : "Unread"}
                    </Badge>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          {loading ? (
            <div className="rounded-lg border border-dashed border-border/60 py-12 text-center text-sm text-muted-foreground">
              Loading notifications...
            </div>
          ) : filtered.length === 0 ? (
            <div className="rounded-lg border border-dashed border-border/60 py-12 text-center text-sm text-muted-foreground">
              No notifications match the filter criteria.
            </div>
          ) : null}
        </CardContent>
      </Card>

      {error ? (
        <div className="rounded-lg border border-destructive/40 bg-destructive/5 p-4 text-sm text-destructive">
          {error}
        </div>
      ) : null}
    </section>
  )
}

