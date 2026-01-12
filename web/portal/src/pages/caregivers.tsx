import { useMemo, useState } from "react"
import { useCaregiversData } from "@/hooks/use-caregivers-data"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { useDisclosure } from "@/hooks/use-disclosure"
import { Users, UserPlus } from "lucide-react"

const statusTone = {
  active: "bg-emerald-500/10 text-emerald-600",
  pending: "bg-amber-500/10 text-amber-600",
  declined: "bg-rose-500/10 text-rose-600",
} as const

export default function CaregiversPage() {
  const [search, setSearch] = useState("")
  const [status, setStatus] = useState<"all" | "active" | "pending" | "declined">(
    "all"
  )
  const assignDialog = useDisclosure()
  const { caregivers, loading, error } = useCaregiversData()

  const filteredCaregivers = useMemo(() => {
    return caregivers.filter((caregiver) => {
      const matchesSearch =
        caregiver.name.toLowerCase().includes(search.toLowerCase()) ||
        caregiver.notes.toLowerCase().includes(search.toLowerCase())
      const matchesStatus = status === "all" || caregiver.status === status
      return matchesSearch && matchesStatus
    })
  }, [search, status])

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-semibold tracking-tight">
            Caregiver Management
          </h1>
          <p className="text-sm text-muted-foreground">
            Track assignments, onboarding status, and escalation support history.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline">Export roster</Button>
          <Button className="gap-2" onClick={assignDialog.open}>
            <UserPlus className="size-4" />
            Invite caregiver
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-sm font-semibold text-muted-foreground">
            Filters
          </CardTitle>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-3">
          <Input
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder="Search caregivers or notes"
          />
          <Select
            value={status}
            onValueChange={(value) =>
              setStatus(value as typeof status)
            }
          >
            <SelectTrigger>
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All statuses</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="declined">Declined</SelectItem>
            </SelectContent>
          </Select>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle className="text-sm font-semibold text-muted-foreground">
              {filteredCaregivers.length} caregivers
            </CardTitle>
            <p className="text-xs text-muted-foreground">
              Includes caregiver app invitations and administrative staff with web access.
            </p>
          </div>
          <Badge variant="secondary" className="gap-1">
            <Users className="size-3.5" />
            Total assignments:{" "}
            {filteredCaregivers
              .map((item) => item.assignments)
              .reduce((a, b) => a + b, 0)}
          </Badge>
        </CardHeader>
        <CardContent className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Assignments</TableHead>
                <TableHead>Escalations</TableHead>
                <TableHead>Last Interaction</TableHead>
                <TableHead>Notes</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredCaregivers.map((caregiver) => (
                <TableRow key={caregiver.id}>
                  <TableCell className="font-medium">
                    {caregiver.name}
                  </TableCell>
                  <TableCell>
                    <Badge className={statusTone[caregiver.status]}>
                      {caregiver.status.toUpperCase()}
                    </Badge>
                  </TableCell>
                  <TableCell>{caregiver.assignments}</TableCell>
                  <TableCell>{caregiver.escalations}</TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {caregiver.lastInteraction}
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">
                    {caregiver.notes}
                  </TableCell>
                  <TableCell>
                    <Button variant="ghost" size="sm">
                      View record
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          {loading ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              Loading caregivers...
            </div>
          ) : filteredCaregivers.length === 0 ? (
            <div className="rounded-lg border border-dashed border-border/60 py-10 text-center text-sm text-muted-foreground">
              No caregivers found for the selected filters.
            </div>
          ) : null}
        </CardContent>
      </Card>

      <Dialog open={assignDialog.isOpen} onOpenChange={assignDialog.set}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Invite caregiver</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 text-sm text-muted-foreground">
            <p>
              Send an invitation email or SMS with caregiver onboarding steps.
              Acceptance routes to role approval for clinical admins.
            </p>
            <div className="space-y-2">
              <label className="text-xs font-medium text-foreground">
                Message to recipient
              </label>
              <Textarea rows={4} placeholder="Include patient context and expectations..." />
            </div>
            <label className="flex items-center gap-2 text-xs">
              <Checkbox />
              Require background check before activation
            </label>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={assignDialog.close}>
              Cancel
            </Button>
            <Button>Send invitation</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {error ? (
        <div className="rounded-lg border border-destructive/40 bg-destructive/5 p-4 text-sm text-destructive">
          {error}
        </div>
      ) : null}
    </section>
  )
}

