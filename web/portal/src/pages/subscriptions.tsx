import { useMemo, useState } from "react"
import { useSubscriptionsData } from "@/hooks/use-subscriptions-data"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { addDays, format } from "date-fns"
import { CalendarClock } from "lucide-react"

const statusTone = {
  Paid: "bg-emerald-500/10 text-emerald-600",
  Due: "bg-amber-500/10 text-amber-600",
  "Past Due": "bg-rose-500/10 text-rose-600",
} as const

export default function SubscriptionsPage() {
  const [plan, setPlan] = useState<"All" | "Essential" | "Premium">("All")
  const [search, setSearch] = useState("")
  const { subscriptions, loading, error } = useSubscriptionsData()

  const filtered = useMemo(() => {
    return subscriptions.filter((record) => {
      const matchesPlan = plan === "All" || record.plan === plan
      const matchesSearch =
        search.length === 0 ||
        record.patient.toLowerCase().includes(search.toLowerCase()) ||
        record.lastInvoice.toLowerCase().includes(search.toLowerCase())
      return matchesPlan && matchesSearch
    })
  }, [plan, search])

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">
            Subscription Oversight
          </h1>
          <p className="text-sm text-muted-foreground">
            Monitor plan tiers, renewals, payment health, and billing actions.
          </p>
        </div>
        {/* <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <DollarSign className="size-4" />
            Issue credit
          </Button>
          <Button className="gap-2">
            <CreditCard className="size-4" />
            Upgrade plan
          </Button>
        </div> */}
      </div>

    
      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-semibold text-muted-foreground">
            Renewal forecast
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          {[
            { label: "Week", days: 7, color: "bg-blue-500/10 border-blue-500/30 text-blue-600" },
            { label: "Month", days: 30, color: "bg-purple-500/10 border-purple-500/30 text-purple-600" },
            { label: "Quarter", days: 90, color: "bg-emerald-500/10 border-emerald-500/30 text-emerald-600" },
          ].map(({ label, days, color }) => (
            <div
              key={label}
              className={`rounded-xl border ${color} p-4 text-sm`}
            >
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <CalendarClock className="size-4" />
                Upcoming renewals · {label}
              </div>
              <p className="mt-2 text-2xl font-semibold tracking-tight">
                {
                  subscriptions.filter((record) => {
                    const daysAhead =
                      (record.renewalDate.getTime() - new Date().getTime()) /
                      (1000 * 60 * 60 * 24)
                    return daysAhead >= 0 && daysAhead <= days
                  }).length
                }
              </p>
              <p className="text-xs text-muted-foreground">
                Next cohort milestone:{" "}
                {format(addDays(new Date(), days), "MMM dd")}
              </p>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <CardTitle className="text-sm font-semibold text-muted-foreground">
            Filters
          </CardTitle>
          <div className="flex flex-wrap items-center gap-2">
            <Input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search by patient or invoice"
              className="md:w-64"
            />
            <Select
              value={plan}
              onValueChange={(value) => setPlan(value as typeof plan)}
            >
              <SelectTrigger className="w-36">
                <SelectValue placeholder="Plan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="All">All plans</SelectItem>
                <SelectItem value="Essential">Essential</SelectItem>
                <SelectItem value="Premium">Premium</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Patient</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Renewal Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Add-ons</TableHead>
                <TableHead>Invoice</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((record) => (
                <TableRow key={record.id}>
                  <TableCell className="font-medium">{record.patient}</TableCell>
                  <TableCell>{record.plan}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {format(record.renewalDate, "MMM dd, yyyy")}
                  </TableCell>
                  <TableCell>
                    <Badge className={statusTone[record.paymentStatus]}>
                      {record.paymentStatus}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {record.addOns.map((addOn) => (
                        <Badge key={addOn} variant="outline" className="text-[10px]">
                          {addOn}
                        </Badge>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell>{record.lastInvoice}</TableCell>
                  <TableCell>
                    <Button variant="default" size="sm" color="primary">
                      Manage
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          {loading ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              Loading subscriptions...
            </div>
          ) : filtered.length === 0 ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              No subscriptions found for the selected filters.
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

