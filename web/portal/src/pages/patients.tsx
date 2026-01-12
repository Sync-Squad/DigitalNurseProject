import { useMemo, useState } from "react"
import type { PatientRosterRow, RiskLevel } from "@/mocks/data"
import { usePatientsData } from "@/hooks/use-patients-data"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { useDisclosure } from "@/hooks/use-disclosure"
import { cn } from "@/lib/utils"
import { Link } from "react-router-dom"

const riskTone: Record<RiskLevel, string> = {
  low: "bg-emerald-500/10 text-emerald-600",
  moderate: "bg-amber-500/10 text-amber-600",
  high: "bg-rose-500/10 text-rose-600",
  critical: "bg-rose-500/20 text-rose-700 border border-rose-500/40",
}

const plans = ["All plans", "Essential", "Premium"] as const
const riskFilters: Array<"all" | RiskLevel> = [
  "all",
  "low",
  "moderate",
  "high",
  "critical",
]

export default function PatientsPage() {
  const [search, setSearch] = useState("")
  const [planFilter, setPlanFilter] = useState<(typeof plans)[number]>("All plans")
  const [riskFilter, _setRiskFilter] = useState<(typeof riskFilters)[number]>("all")
  const [segment, _setSegment] = useState("all")
  const escalationsOnlyDisclosure = useDisclosure()
  const { patients, loading, error } = usePatientsData()

  const filteredPatients = useMemo(() => {
    return patients.filter((patient) => {
      const matchesSearch =
        search.length === 0 ||
        patient.name.toLowerCase().includes(search.toLowerCase())

      const matchesPlan =
        planFilter === "All plans" || patient.subscription === planFilter

      const matchesRisk =
        riskFilter === "all" || patient.risk.toLowerCase() === riskFilter

      const matchesSegment =
        segment === "all" ||
        (segment === "high-risk" && (patient.risk === "high" || patient.risk === "critical")) ||
        (segment === "adherence-drop" && patient.adherence < 85) ||
        (segment === "awaiting-docs" && patient.unreadDocs > 0)

      const matchesEscalations =
        !escalationsOnlyDisclosure.isOpen || patient.alerts > 0

      return (
        matchesSearch &&
        matchesPlan &&
        matchesRisk &&
        matchesSegment &&
        matchesEscalations
      )
    })
  }, [patients, search, planFilter, riskFilter, segment, escalationsOnlyDisclosure.isOpen])

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">
            Patient Directory
          </h1>
          <p className="text-sm text-muted-foreground">
            Filter by adherence, risk, subscription, or pending escalations to
            prioritize outreach.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">Export CSV</Button>
          {/* <Button className="gap-2">
            <Users className="size-4" />
            Bulk Assign Caregiver
          </Button> */}
        </div>
      </div>

      {/* <Tabs
        value={segment}
        onValueChange={setSegment}
        className="w-full"
      >
        <TabsList className="w-full justify-start gap-2 bg-muted/40">
          <TabsTrigger value="all">All patients</TabsTrigger>
          <TabsTrigger value="high-risk">High & critical risk</TabsTrigger>
          <TabsTrigger value="adherence-drop">Adherence dip</TabsTrigger>
          <TabsTrigger value="awaiting-docs">Awaiting documents</TabsTrigger>
        </TabsList>
      </Tabs> */}

      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-semibold text-muted-foreground">
            Filters
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-4">
          <Input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search by patient, caregiver, or provider"
            className="md:col-span-2"
          />
          <Select
            value={planFilter}
            onValueChange={(value) =>
              setPlanFilter(value as (typeof plans)[number])
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="Plan tier" />
            </SelectTrigger>
            <SelectContent>
              {plans.map((plan) => (
                <SelectItem key={plan} value={plan}>
                  {plan}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {/* <Select
            value={riskFilter}
            onValueChange={(value) =>
              setRiskFilter(value as (typeof riskFilters)[number])
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="Risk level" />
            </SelectTrigger>
            <SelectContent>
              {riskFilters.map((risk) => (
                <SelectItem key={risk} value={risk}>
                  {risk === "all" ? "All risk levels" : risk.toUpperCase()}
                </SelectItem>
              ))}
            </SelectContent>
          </Select> */}
          <label className="flex items-center gap-2 text-xs text-muted-foreground md:col-span-2">
            <Checkbox
              checked={escalationsOnlyDisclosure.isOpen}
              onCheckedChange={(checked) =>
                (checked
                  ? escalationsOnlyDisclosure.open
                  : escalationsOnlyDisclosure.close)()
              }
            />
            Show records with active escalations only
          </label>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              {filteredPatients.length} patients
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Surface-level view — drill into detail workspace for full medical
              history.
            </p>
          </div>
          <Dialog>
            <DialogContent className="max-w-lg">
              <DialogHeader>
                <DialogTitle>Save cohort filter</DialogTitle>
              </DialogHeader>
              <div className="space-y-4 text-sm text-muted-foreground">
                <p>
                  Persist this combination of filters for quick access from the
                  dashboard. Saved cohorts sync with mobile analytics.
                </p>
                <Button>Save cohort</Button>
              </div>
            </DialogContent>
            <Button variant="outline" size="sm">
              Save cohort
            </Button>
          </Dialog>
        </CardHeader>
        <CardContent className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Patient</TableHead>
                <TableHead>Risk</TableHead>
                <TableHead>Adherence</TableHead>
                <TableHead>Alerts</TableHead>
                <TableHead>Unread Docs</TableHead>
                <TableHead>Care Team</TableHead>
                <TableHead>Last Activity</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredPatients.map((patient) => (
                <PatientRow key={patient.id} patient={patient} />
              ))}
            </TableBody>
          </Table>
          {loading ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              Loading patients...
            </div>
          ) : filteredPatients.length === 0 ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              No patients match the selected filters.
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

function PatientRow({ patient }: { patient: PatientRosterRow }) {
  return (
    <TableRow>
      <TableCell className="font-medium">{patient.name}</TableCell>
      <TableCell>
        <Badge className={cn("uppercase", riskTone[patient.risk])}>
          {patient.risk}
        </Badge>
      </TableCell>
      <TableCell>
        <div className="flex flex-col">
          <span>{patient.adherence}%</span>
          <span className="text-xs text-muted-foreground">
            Subscription: {patient.subscription}
          </span>
        </div>
      </TableCell>
      <TableCell>{patient.alerts}</TableCell>
      <TableCell>{patient.unreadDocs}</TableCell>
      <TableCell>
        <div className="flex flex-col gap-1">
          {patient.careTeam.map((member) => (
            <span key={member} className="text-xs text-muted-foreground">
              {member}
            </span>
          ))}
        </div>
      </TableCell>
      <TableCell className="text-xs text-muted-foreground">
        {patient.lastActivity}
      </TableCell>
      <TableCell>
        <Button variant="ghost" size="sm" asChild>
          <Link to={`/patients/${patient.slug}`}>View workspace</Link>
        </Button>
      </TableCell>
    </TableRow>
  )
}

