import { Fragment, useState } from "react"
import { useDashboardData } from "@/hooks/use-dashboard-data"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { DashboardMetricCard } from "@/components/dashboard/dashboard-metric-card"
import { PatientsGrowthCard } from "@/components/dashboard/patients-growth-card"
import { SubscriptionBreakdownCard } from "@/components/dashboard/subscription-breakdown-card"
import { CityPatientsBarChart } from "@/components/dashboard/city-patients-bar-chart"
import { CityRevenueGrid } from "@/components/dashboard/city-revenue-grid"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

const riskTone = {
  low: "bg-emerald-500/10 text-emerald-600",
  moderate: "bg-amber-500/10 text-amber-600",
  high: "bg-rose-500/10 text-rose-600",
  critical: "bg-rose-500/20 text-rose-700 border border-rose-500/40",
} as const

export default function DashboardPage() {
  const [timeframe, setTimeframe] = useState<"7" | "30" | "90">("30")
  const {
    metrics,
    patientGrowth7Days,
    patientGrowth30Days,
    subscriptionBreakdown,
    cityPatients,
    cityRevenue,
    loading,
    error,
  } = useDashboardData()

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">Patient Overview</h1>
          <p className="text-sm text-muted-foreground">
            Monitor cohort health, escalations, and operational readiness across Digital Nurse roles.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Select value={timeframe} onValueChange={(value) => setTimeframe(value as "7" | "30" | "90")}>
            <SelectTrigger className="w-36">
              <SelectValue placeholder="Timeframe" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="7">Last 7 days</SelectItem>
              <SelectItem value="30">Last 30 days</SelectItem>
              {/* <SelectItem value="90">Last quarter</SelectItem> */}
            </SelectContent>
          </Select>
          {/* <Button variant="outline" className="gap-2">
            Export Insights
          </Button> */}
        </div>
      </div>

      {/* <Tabs defaultValue="all" className="w-full">
        <TabsList className="w-full justify-start gap-2 bg-muted/40">
          <TabsTrigger value="all">All Roles</TabsTrigger>
          <TabsTrigger value="admin">Clinical Admin</TabsTrigger>
          <TabsTrigger value="provider">Provider</TabsTrigger>
          <TabsTrigger value="coordinator">Care Coordinator</TabsTrigger>
        </TabsList>
      </Tabs> */}

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {(loading ? [] : metrics).map((metric) => (
          <DashboardMetricCard key={metric.title} metric={metric} />
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <PatientsGrowthCard
          data7Days={patientGrowth7Days}
          data30Days={patientGrowth30Days}
          timeframe={timeframe}
          onTimeframeChange={(value) => setTimeframe(value)}
        />
        <SubscriptionBreakdownCard data={subscriptionBreakdown} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <CityPatientsBarChart data={cityPatients} />
        <CityRevenueGrid data={cityRevenue} />
      </div>

      {error ? (
        <div className="rounded-lg border border-destructive/40 bg-destructive/5 p-4 text-sm text-destructive">
          {error}
        </div>
      ) : null}

      {/* <div className="grid gap-4 lg:grid-cols-2">
        <AlertsCard alerts={dashboardAlerts} />
        <DocumentsSummaryCard documents={documents.slice(0, 3)} />
      </div> */}

      {/* <Card>
        <CardHeader className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              Patient Cohort Snapshot
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Filtered by premium subscriptions · sorted by risk
            </p>
          </div>
          <Button variant="secondary" size="sm">
            Manage roster
          </Button>
        </CardHeader>
        <CardContent className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Patient</TableHead>
                <TableHead>Risk</TableHead>
                <TableHead>Adherence</TableHead>
                <TableHead>Alerts</TableHead>
                <TableHead>Care Team</TableHead>
                <TableHead>Last Activity</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {patientRoster.map((row) => (
                <TableRow key={row.id}>
                  <TableCell className="font-medium">{row.name}</TableCell>
                  <TableCell>
                    <Badge className={riskTone[row.risk]}>
                      {row.risk.toUpperCase()}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <span>{row.adherence}%</span>
                      <span className="text-xs text-muted-foreground">
                        {row.subscription}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Badge variant="secondary">{row.alerts}</Badge>
                      <span className="text-xs text-muted-foreground">
                        {row.unreadDocs} docs
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-col gap-1">
                      {row.careTeam.map((member) => (
                        <Fragment key={member}>
                          <span className="text-xs text-muted-foreground">
                            {member}
                          </span>
                        </Fragment>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {row.lastActivity}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card> */}
    </section>
  )
}

