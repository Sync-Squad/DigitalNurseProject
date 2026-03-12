import { useMemo } from "react"
import { Link, Navigate, useParams } from "react-router-dom"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Progress } from "@/components/ui/progress"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import {
  BellRing,
  ExternalLink,
  FileText,
  HeartPulse,
  Pill,
  Search,
  Shield,
  Stethoscope,
  Users,
} from "lucide-react"
import { notificationTemplates } from "@/mocks/data"
import { VitalsTrendCard } from "@/components/dashboard/vitals-trend-card"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { usePatientsData } from "@/hooks/use-patients-data"
import { usePatientWorkspaceData } from "@/hooks/use-patient-workspace-data"
import { useState } from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Video } from "lucide-react"

const riskTone = {
  low: "bg-emerald-500/10 text-emerald-600",
  moderate: "bg-amber-500/10 text-amber-600",
  high: "bg-rose-500/10 text-rose-600",
  critical: "bg-rose-500/20 text-rose-700 border border-rose-500/40",
} as const

export default function PatientWorkspacePage() {
  const { slug } = useParams<{ slug: string }>()
  const { patients, loading: patientsLoading, error: patientsError } = usePatientsData()
  const rosterPatient = useMemo(
    () => patients.find((patient) => patient.slug === slug),
    [patients, slug],
  )
  const {
    data: workspace,
    loading: workspaceLoading,
    error: workspaceError,
  } = usePatientWorkspaceData(rosterPatient?.id, {
    careTeamNames: rosterPatient?.careTeam,
  })

  const demographics = workspace?.demographics || {
    name: rosterPatient?.name || "Patient",
    age: rosterPatient?.age ?? null,
    gender: null,
    subscription: rosterPatient?.subscription || "Essential",
    riskLevel: rosterPatient?.risk || "low",
    emergencyContact: null,
    lastSynced: rosterPatient?.lastActivity || "",
  }

  const [isTelevisitOpen, setIsTelevisitOpen] = useState(false)
  const [abnormalSearch, setAbnormalSearch] = useState("")

  const handleDownloadSummary = () => {
    const summary = `
Patient Summary: ${demographics.name}
Age: ${demographics.age ?? '—'}
Risk level: ${demographics.riskLevel}
Subscription: ${demographics.subscription}
Last Synced: ${lastSynced}

Vitals Overview:
${vitalsRecent.map(v => `- ${v.type}: ${v.value} (${v.status})`).join('\n')}

Medications:
${medications.map(m => `- ${m.name}: ${m.dosage} (${m.adherence}% adherence)`).join('\n')}

Emergency Contact: ${demographics.emergencyContact ?? 'No contact listed'}
    `.trim();

    const blob = new Blob([summary], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${demographics.name.replace(/\s+/g, '_')}_Summary.txt`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const handleStartTelevisit = () => {
    setIsTelevisitOpen(true)
  }

  const careTeam =
    workspace?.careTeam ||
    (rosterPatient?.careTeam || []).map((member) => ({
      name: member,
      role: "Caregiver",
      status: "Active",
    }))

  const medications = workspace?.medications || []
  const medicationLog = workspace?.medicationLog || []
  const vitalsRecent = workspace?.vitalsRecent || []
  const abnormalEvents = workspace?.abnormalEvents || []
  const documents = workspace?.documents || []
  const notificationsList = workspace?.notifications || []

  const vitalTrendData = (vitalsRecent || []).map((vital, index) => {
    const v1 = parseFloat(String(vital.value1 || (Array.isArray(vital.value) ? vital.value[0] : vital.value)));
    const v2 = parseFloat(String(vital.value2 || 0));
    const type = String(vital.type).toLowerCase();

    return {
      date: `Day ${index + 1}`,
      systolic: type.includes("pressure") ? v1 : 0,
      diastolic: type.includes("pressure") ? v2 : 0,
      heartRate: type.includes("heart") ? v1 : 0,
      value: v1 // Fallback for other vitals
    }
  })

  const riskKey = (demographics.riskLevel || "low").toLowerCase() as keyof typeof riskTone
  const lastSynced = demographics.lastSynced
    ? new Date(demographics.lastSynced).toLocaleString()
    : rosterPatient?.lastActivity || ""
  const lifestyle = workspace?.lifestyle

  const filteredAbnormal = useMemo(() => {
    return abnormalEvents.filter(event =>
      event.type.toLowerCase().includes(abnormalSearch.toLowerCase()) ||
      event.note.toLowerCase().includes(abnormalSearch.toLowerCase()) ||
      event.status.toLowerCase().includes(abnormalSearch.toLowerCase())
    )
  }, [abnormalEvents, abnormalSearch])

  if (patientsLoading) {
    return (
      <section className="space-y-6">
        <div className="rounded-lg border border-dashed border-border/60 p-6 text-sm text-muted-foreground">
          Loading patient directory...
        </div>
      </section>
    )
  }

  if (!rosterPatient) {
    return <Navigate to="/patients" replace />
  }

  return (
    <section className="space-y-6">
      <header className="space-y-4 rounded-2xl border border-border/70 bg-card/70 p-6 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="text-3xl font-semibold tracking-tight">
                {demographics.name}
              </h1>
              <Badge variant="outline">
                {demographics.subscription} plan
              </Badge>
              <Badge className={cn("uppercase", riskTone[riskKey])}>
                {demographics.riskLevel}
              </Badge>
            </div>
            <p className="mt-2 text-sm text-muted-foreground">
              {`Age ${demographics.age ?? "—"}${demographics.gender ? ` · ${demographics.gender}` : ""} · Last synced ${lastSynced}`}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="outline" onClick={handleDownloadSummary}>Download summary</Button>
            <Button className="gap-2" onClick={handleStartTelevisit}>
              <Stethoscope className="size-4" />
              Start televisit
            </Button>
          </div>
        </div>
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <InfoTile
            icon={<Users className="size-4 text-primary" />}
            label="Care team"
            value={`${careTeam.length} members`}
          />
          <InfoTile
            icon={<Pill className="size-4 text-primary" />}
            label="Medication adherence"
            value={`${medications.length
              ? Math.round(
                medications.reduce((acc, med) => acc + med.adherence, 0) /
                medications.length
              )
              : rosterPatient.adherence
              }%`}
          />
          <InfoTile
            icon={<HeartPulse className="size-4 text-primary" />}
            label="Active alerts"
            value={`${rosterPatient.alerts}`}
            hint="Across vitals & medication"
          />
          <InfoTile
            icon={<FileText className="size-4 text-primary" />}
            label="Documents pending"
            value={`${rosterPatient.unreadDocs}`}
          />
        </div>
      </header>

      {(patientsError || workspaceError) ? (
        <div className="rounded-lg border border-destructive/40 bg-destructive/5 p-4 text-sm text-destructive">
          {patientsError || workspaceError}
        </div>
      ) : null}

      <Tabs defaultValue="medications" className="space-y-6">
        <TabsList className="flex w-full justify-start gap-2 overflow-x-auto bg-muted/40 p-1">
          <TabsTrigger value="medications">Medications</TabsTrigger>
          <TabsTrigger value="vitals">Vitals</TabsTrigger>
          <TabsTrigger value="lifestyle">Lifestyle</TabsTrigger>
          <TabsTrigger value="documents">Documents</TabsTrigger>
          <TabsTrigger value="care-network">Care Network</TabsTrigger>
          <TabsTrigger value="notifications">Notifications</TabsTrigger>
        </TabsList>

        <TabsContent value="medications" className="space-y-4">
          {workspaceLoading ? (
            <div className="rounded-lg border border-dashed border-border/60 p-6 text-sm text-muted-foreground">
              Loading medications...
            </div>
          ) : medications.length ? (
            <>
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-semibold text-muted-foreground">
                    Active schedules
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Medication</TableHead>
                        <TableHead>Dosage</TableHead>
                        <TableHead>Schedule</TableHead>
                        <TableHead>Adherence</TableHead>
                        <TableHead>Status</TableHead>
                        <TableHead />
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {medications.map((med) => (
                        <TableRow key={med.id}>
                          <TableCell>{med.name}</TableCell>
                          <TableCell>{med.dosage}</TableCell>
                          <TableCell>{med.schedule}</TableCell>
                          <TableCell>{med.adherence}%</TableCell>
                          <TableCell>
                            <Badge variant="outline">{med.status}</Badge>
                          </TableCell>
                          <TableCell>
                            <Button variant="ghost" size="sm">
                              Audit trail
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-semibold text-muted-foreground">
                    Intake log · last 7 days
                  </CardTitle>
                </CardHeader>
                <CardContent className="grid gap-3 md:grid-cols-2">
                  {medicationLog.map((entry) => (
                    <div
                      key={`${entry.medication}-${entry.time}`}
                      className="rounded-xl border border-border/70 bg-muted/20 p-4"
                    >
                      <div className="flex items-center justify-between text-xs text-muted-foreground">
                        <span>
                          {new Date(entry.date).toLocaleDateString("en-US", {
                            month: "short",
                            day: "numeric",
                          })}
                        </span>
                        <span>{entry.time}</span>
                      </div>
                      <p className="mt-2 font-medium">{entry.medication}</p>
                      <p className="text-xs text-muted-foreground">
                        Status: {entry.status} · Recorded by {entry.recordedBy}
                      </p>
                    </div>
                  ))}
                </CardContent>
              </Card>
            </>
          ) : (
            <EmptyState
              title="No detailed medication data"
              description="This patient does not have medication history yet."
            />
          )}
        </TabsContent>

        <TabsContent value="vitals" className="space-y-4">
          <div className="grid gap-4 lg:grid-cols-4">
            <VitalsTrendCard data={vitalTrendData} />
            <Card className="lg:col-span-1">
              <CardHeader>
                <CardTitle className="text-sm font-semibold text-muted-foreground">
                  Recent vitals
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {vitalsRecent.map((vital, index) => (
                  <div
                    key={`${vital.type}-${index}`}
                    className="rounded-lg border border-border/60 p-3 text-sm"
                  >
                    <div className="flex items-center justify-between">
                      <p className="font-medium">{vital.type}</p>
                      <span className="text-[10px] text-muted-foreground">
                        {new Date(vital.recordedAt).toLocaleString([], {
                          month: "short",
                          day: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </div>
                    <div className="mt-1 flex items-baseline gap-1">
                      <p className="text-lg font-semibold">{vital.value}</p>
                      <span className="text-[10px] font-medium uppercase text-muted-foreground">
                        {vital.unit}
                      </span>
                    </div>
                    {vital.notes && (
                      <p className="mt-1.5 text-[11px] leading-snug text-muted-foreground/80 italic">
                        &quot;{vital.notes}&quot;
                      </p>
                    )}
                    <Badge
                      variant="outline"
                      className={cn(
                        "mt-2 uppercase text-[10px]",
                        vital.status === "High" || vital.status === "Low"
                          ? "border-rose-500/50 bg-rose-500/10 text-rose-600"
                          : "border-emerald-500/50 bg-emerald-500/10 text-emerald-600"
                      )}
                    >
                      {vital.status}
                    </Badge>
                  </div>
                ))}
              </CardContent>
            </Card>
            <Card className="lg:col-span-1 h-[450px] overflow-hidden flex flex-col">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-sm font-semibold text-muted-foreground">
                    Abnormal events
                  </CardTitle>
                  <Badge variant="secondary" className="text-[10px]">
                    {filteredAbnormal.length}
                  </Badge>
                </div>
                <div className="relative mt-2">
                  <Search className="absolute left-2 top-2.5 h-3.5 w-3.5 text-muted-foreground" />
                  <input
                    placeholder="Filter events..."
                    className="w-full rounded-md border border-input bg-background pl-8 py-1.5 text-xs ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    value={abnormalSearch}
                    onChange={(e) => setAbnormalSearch(e.target.value)}
                  />
                </div>
              </CardHeader>
              <CardContent className="flex-1 overflow-y-auto">
                {filteredAbnormal.length ? (
                  <Accordion type="single" collapsible className="w-full">
                    {filteredAbnormal.map((event) => (
                      <AccordionItem key={event.id} value={event.id} className="border-b border-border/40 last:border-0">
                        <AccordionTrigger className="py-3 text-left hover:no-underline">
                          <div className="flex flex-col gap-1 pr-4">
                            <div className="flex items-center gap-2">
                              <span className="text-xs font-semibold">{event.type}</span>
                              <Badge className={cn("text-[9px] px-1 h-3.5 uppercase",
                                event.status === "High" ? "bg-rose-500/10 text-rose-600 border-rose-500/20" : "bg-amber-500/10 text-amber-600 border-amber-500/20")}>
                                {event.status}
                              </Badge>
                            </div>
                            <span className="text-[10px] text-muted-foreground">
                              {new Date(event.recordedAt).toLocaleString([], { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })}
                            </span>
                          </div>
                        </AccordionTrigger>
                        <AccordionContent className="text-[11px] leading-relaxed text-muted-foreground pb-4">
                          <div className="rounded-lg bg-muted/30 p-2 space-y-2">
                            <div className="flex justify-between items-center">
                              <span>Value: <span className="font-medium text-foreground">{event.value} {event.unit}</span></span>
                              <Badge variant="outline" className="text-[9px] h-4">Active</Badge>
                            </div>
                            <p className="border-t border-border/40 pt-2 italic leading-normal">
                              {event.note}
                            </p>
                          </div>
                        </AccordionContent>
                      </AccordionItem>
                    ))}
                  </Accordion>
                ) : (
                  <div className="flex flex-col items-center justify-center h-full py-8 text-center">
                    <p className="text-xs text-muted-foreground italic">
                      {abnormalSearch ? "No events match your filter" : "All readings stable"}
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="lifestyle" className="space-y-4">
          {workspace ? (
            <div className="grid gap-4 md:grid-cols-2">
              <LifestyleCard
                title="Diet adherence"
                compliance={lifestyle?.diet.compliance ?? 0}
                highlights={lifestyle?.diet.highlights ?? []}
              />
              <LifestyleCard
                title="Exercise adherence"
                compliance={lifestyle?.exercise.compliance ?? 0}
                highlights={lifestyle?.exercise.highlights ?? []}
              />
            </div>
          ) : (
            <EmptyState
              title="Lifestyle insights unavailable"
              description="Sync with the mobile app to populate dietary and activity summaries."
            />
          )}
        </TabsContent>

        <TabsContent value="documents" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-muted-foreground">
                Document history
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Title</TableHead>
                    <TableHead>Author</TableHead>
                    <TableHead>Visibility</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead />
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {documents.map((doc) => (
                    <TableRow key={doc.id}>
                      <TableCell className="font-medium">
                        {doc.type}
                      </TableCell>
                      <TableCell>{doc.author}</TableCell>
                      <TableCell>{doc.visibility}</TableCell>
                      <TableCell>
                        <Badge variant="secondary">{doc.status}</Badge>
                      </TableCell>
                      <TableCell>
                        <Button variant="ghost" size="sm" className="gap-1">
                          <ExternalLink className="size-3.5" />
                          Preview
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="care-network" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-muted-foreground">
                Care team
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {careTeam.map((member) => (
                <div
                  key={member.name}
                  className="flex items-center justify-between rounded-xl border border-border/70 bg-muted/20 p-3"
                >
                  <div>
                    <p className="font-medium">{member.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {member.role}
                    </p>
                  </div>
                  <Badge variant="outline">{member.status}</Badge>
                </div>
              ))}
              <Button variant="outline" className="w-full">
                Invite caregiver
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-muted-foreground">
                Messaging & automation
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {notificationsList.slice(0, 4).map((notification) => (
                <div
                  key={notification.id}
                  className="rounded-xl border border-border/70 bg-muted/20 p-3"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <Badge variant="secondary" className="gap-1">
                        <BellRing className="size-3.5" />
                        {notification.category}
                      </Badge>
                      <span className="text-sm font-medium">
                        {notification.title}
                      </span>
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {notification.createdAt.toLocaleDateString()}
                    </span>
                  </div>
                  <p className="mt-2 text-sm text-muted-foreground">
                    {notification.summary}
                  </p>
                  <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                    Recipients:
                    {notification.recipients.map((recipient) => (
                      <Badge key={recipient} variant="outline" className="text-[10px]">
                        {recipient}
                      </Badge>
                    ))}
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-muted-foreground">
                Notification templates
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-3 md:grid-cols-3">
              {notificationTemplates.map((template) => (
                <div
                  key={template.id}
                  className="rounded-xl border border-border/70 bg-muted/20 p-4 text-sm"
                >
                  <p className="font-medium">{template.name}</p>
                  <p className="text-xs text-muted-foreground">
                    Channel: {template.channel}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    Updated{" "}
                    {template.updatedAt.toLocaleDateString("en-US", {
                      month: "short",
                      day: "numeric",
                    })}
                  </p>
                  <Badge className="mt-2" variant="secondary">
                    {template.status}
                  </Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <div className="text-xs text-muted-foreground">
        <Shield className="mr-1 inline size-3.5" />
        All actions are logged. View{" "}
        <Link to="/audit" className="text-primary underline">
          audit trail
        </Link>
        .
      </div>

      <Dialog open={isTelevisitOpen} onOpenChange={setIsTelevisitOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Start Televisit</DialogTitle>
            <DialogDescription>
              Connect with {demographics.name} via a secure video consultation.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col items-center justify-center gap-6 py-8">
            <div className="relative flex h-24 w-24 items-center justify-center rounded-full bg-primary/10">
              <Video className="h-12 w-12 text-primary animate-pulse" />
              <div className="absolute inset-0 rounded-full border-4 border-primary/20 animate-ping" />
            </div>
            <div className="space-y-2 text-center">
              <p className="text-sm font-medium">Ready to start the session</p>
              <p className="text-xs text-muted-foreground">
                Ensure your camera and microphone are accessible.
              </p>
            </div>
          </div>
          <DialogFooter className="sm:justify-center gap-2">
            <Button variant="outline" onClick={() => setIsTelevisitOpen(false)}>
              Cancel
            </Button>
            <Button className="gap-2" onClick={() => {
              window.open(`https://meet.jit.si/DigitalNurse-${demographics.name.replace(/\s+/g, '-')}`, '_blank');
              setIsTelevisitOpen(false);
            }}>
              Join Call Now
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </section>
  )
}

function InfoTile({
  icon,
  label,
  value,
  hint,
}: {
  icon: React.ReactNode
  label: string
  value: string
  hint?: string
}) {
  return (
    <Card className="bg-background/80">
      <CardContent className="flex flex-col gap-2 p-4">
        <div className="flex items-center gap-2 text-xs text-muted-foreground">
          {icon}
          {label}
        </div>
        <span className="text-xl font-semibold tracking-tight">{value}</span>
        {hint ? <span className="text-xs text-muted-foreground">{hint}</span> : null}
      </CardContent>
    </Card>
  )
}

function LifestyleCard({
  title,
  compliance,
  highlights,
}: {
  title: string
  compliance: number
  highlights: string[]
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm font-semibold text-muted-foreground">
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="font-medium">{compliance}% adherence</span>
            <span className="text-xs text-muted-foreground">Past 7 days</span>
          </div>
          <Progress value={compliance} />
        </div>
        <ul className="space-y-2 text-sm text-muted-foreground">
          {highlights.map((highlight) => (
            <li key={highlight}>• {highlight}</li>
          ))}
        </ul>
      </CardContent>
    </Card>
  )
}

function EmptyState({
  title,
  description,
}: {
  title: string
  description: string
}) {
  return (
    <div className="rounded-xl border border-dashed border-border/70 p-10 text-center">
      <p className="text-sm font-medium">{title}</p>
      <p className="mt-2 text-sm text-muted-foreground">{description}</p>
    </div>
  )
}

