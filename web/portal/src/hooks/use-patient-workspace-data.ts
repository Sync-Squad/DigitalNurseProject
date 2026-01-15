import { useEffect, useState } from "react"
import type { DocumentRecord, PortalNotification } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

type WorkspaceMedication = {
  id: string
  name: string
  dosage: string
  schedule: string
  adherence: number
  status: string
}

type MedicationLogEntry = {
  date: string
  time: string
  medication: string
  status: string
  recordedBy: string
}

type VitalRecent = {
  type: string
  value: string
  status: string
  recordedAt: string
  value1?: number | string
  value2?: number | string
}

type VitalEvent = {
  id: string
  recordedAt: string
  note: string
}

type CareTeamMember = {
  name: string
  role: string
  status: string
}

export interface PatientWorkspaceData {
  demographics: {
    name: string
    age: number | null
    gender: string | null
    subscription: string
    riskLevel: string
    primaryProvider?: string
    emergencyContact?: string | null
    lastSynced?: string
  }
  careTeam: CareTeamMember[]
  medications: WorkspaceMedication[]
  medicationLog: MedicationLogEntry[]
  vitalsRecent: VitalRecent[]
  abnormalEvents: VitalEvent[]
  documents: DocumentRecord[]
  notifications: PortalNotification[]
  lifestyle: {
    diet: {
      compliance: number
      highlights: string[]
    }
    exercise: {
      compliance: number
      highlights: string[]
    }
  }
}

export function usePatientWorkspaceData(
  patientId?: string,
  options?: { careTeamNames?: string[] },
) {
  const [data, setData] = useState<PatientWorkspaceData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!patientId) return
    let isMounted = true

      ; (async () => {
        try {
          setLoading(true)
          const [userDetail, medicationsRes, vitalsRes, documentsRes, notificationsRes, lifestyleSummaryRes, dietLogsRes, exerciseLogsRes] =
            await Promise.all([
              api.get<any>(API_ENDPOINTS.users.detail(patientId)),
              api.get<any[]>(`${API_ENDPOINTS.medications.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.vitals.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.documents.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.notifications.list}?elderUserId=${patientId}`),
              api.get<any>(`${API_ENDPOINTS.lifestyle.summaryWeekly}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.lifestyle.dietLogs}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.lifestyle.exerciseLogs}?elderUserId=${patientId}`),
            ])

          if (!isMounted) return

          const medications: WorkspaceMedication[] = (medicationsRes || []).map((med) => {
            const times = (med.reminderTimes || []).map((t: any) => t.time).join(", ")
            return {
              id: med.id,
              name: med.name,
              dosage: med.dosage || med.doseAmount || "",
              schedule: times
                ? `${times} · ${med.frequency || ""}`
                : med.frequency || "Daily",
              adherence: med.adherence ?? 100,
              status: (med.adherence ?? 100) < 80 ? "Below target" : "In range",
            }
          })

          const medicationLog: MedicationLogEntry[] = (medicationsRes || []).flatMap((med) =>
            (med.reminderTimes || []).map((timeObj: any) => ({
              date: med.startDate || new Date().toISOString(),
              time: timeObj.time,
              medication: med.name,
              status: "Scheduled",
              recordedBy: userDetail?.name || "System",
            })),
          )

          const vitalsRecent: VitalRecent[] = (vitalsRes || []).slice(0, 5).map((vital) => ({
            type: formatVitalType(vital.type || vital.kindCode || "Vital"),
            value: vital.value,
            status: calculateVitalStatus(vital),
            recordedAt: vital.timestamp || vital.recordedAt || new Date().toISOString(),
            value1: vital.value1,
            value2: vital.value2,
          }))

          const abnormalEvents: VitalEvent[] = (vitalsRes || [])
            .filter((vital) => isAbnormal(vital))
            .map((vital) => ({
              id: vital.id || crypto.randomUUID(),
              recordedAt: vital.timestamp || vital.recordedAt || new Date().toISOString(),
              note: `Abnormal ${vital.type || vital.kindCode} value: ${vital.value}`,
            }))

          const documents: DocumentRecord[] = (documentsRes || []).map((doc) => ({
            id: doc.id,
            patient: doc.userId ? `User ${doc.userId}` : "Unknown",
            type: (doc.type as DocumentRecord["type"]) || "Care Plan",
            author: doc.title || "Uploaded file",
            createdAt: doc.uploadDate
              ? new Date(doc.uploadDate).toLocaleString()
              : new Date().toLocaleString(),
            visibility: (doc.visibility as DocumentRecord["visibility"]) || "Private",
            status: (doc.description as DocumentRecord["status"]) || "Published",
          }))

          const notifications: PortalNotification[] = (notificationsRes || []).map((item) => ({
            id: item.notificationId?.toString() || crypto.randomUUID(),
            category: mapCategory(item.notificationType),
            title: item.title,
            summary: item.message,
            recipients: [],
            createdAt: item.createdAt ? new Date(item.createdAt) : new Date(),
            severity: item.notificationType?.toLowerCase().includes("critical")
              ? "critical"
              : item.notificationType?.toLowerCase().includes("warning")
                ? "warning"
                : "info",
            read: item.isRead ?? false,
          }))

          const age = userDetail?.age
            ? Number(userDetail.age)
            : userDetail?.dob
              ? calculateAge(userDetail.dob)
              : null

          const careTeam: CareTeamMember[] = (options?.careTeamNames || []).map((name) => ({
            name,
            role: "Caregiver",
            status: "Active",
          }))

          setData({
            demographics: {
              name: userDetail?.name || userDetail?.full_name || "Patient",
              age,
              gender: userDetail?.gender ?? null,
              subscription: userDetail?.subscription || "Essential",
              riskLevel: "Moderate",
              emergencyContact: userDetail?.emergencyContact ?? null,
              lastSynced: new Date().toISOString(),
            },
            careTeam,
            medications,
            medicationLog,
            vitalsRecent,
            abnormalEvents,
            documents,
            notifications,
            lifestyle: {
              diet: {
                compliance: dietLogsRes?.length ? Math.min(Math.round((dietLogsRes.length / 21) * 100), 100) : 0,
                highlights: (dietLogsRes || []).slice(0, 3).map((log: any) => `${log.mealType}: ${log.description || 'Logged'}`),
              },
              exercise: {
                compliance: lifestyleSummaryRes?.totalExerciseMinutes ? Math.min(Math.round((lifestyleSummaryRes.totalExerciseMinutes / 150) * 100), 100) : 0,
                highlights: (exerciseLogsRes || []).slice(0, 3).map((log: any) => `${log.activityType}: ${log.durationMinutes} mins`),
              },
            },
          })
          setError(null)
        } catch (err) {
          const message =
            err instanceof Error ? err.message : "Unable to load patient workspace data"
          if (isMounted) setError(message)
        } finally {
          if (isMounted) setLoading(false)
        }
      })()

    return () => {
      isMounted = false
    }
  }, [patientId, options?.careTeamNames])

  return { data, loading, error }
}

function formatVitalType(type: string): string {
  // Handle some common mappings
  const mapping: Record<string, string> = {
    bloodPressure: "Blood Pressure",
    bloodSugar: "Blood Sugar",
    oxygenSaturation: "O2 Saturation",
    heartRate: "Heart Rate",
    bodyTemp: "Temperature",
    weight: "Weight",
  }

  if (mapping[type]) return mapping[type]

  // Fallback: convert camelCase to Title Case
  return type
    .replace(/([A-Z])/g, " $1")
    .replace(/^./, (str) => str.toUpperCase())
    .trim()
}

function calculateVitalStatus(measurement: any): string {
  const type = (measurement.type || measurement.kindCode || "").toLowerCase()
  let v1 = measurement.value1 ? parseFloat(measurement.value1.toString()) : null
  let v2 = measurement.value2 ? parseFloat(measurement.value2.toString()) : null

  // If specialized fields are missing, try to parse from the main value string
  if (v1 === null && measurement.value) {
    if (Array.isArray(measurement.value)) {
      v1 = parseFloat(measurement.value[0])
      v2 = measurement.value[1] ? parseFloat(measurement.value[1]) : null
    } else {
      const parts = String(measurement.value).split(/[/\s,]+/)
      v1 = parseFloat(parts[0])
      v2 = parts[1] ? parseFloat(parts[1]) : null
    }
  }

  if (v1 === null) return measurement.status || "In range"

  if (type.includes("bp") || type.includes("pressure")) {
    if (v1 > 140 || (v2 !== null && v2 > 90)) return "High"
    if (v1 < 80 || (v2 !== null && v2 < 50)) return "Low"
    return "In range"
  }
  if (type.includes("bs") || type.includes("glucose") || type.includes("sugar")) {
    if (v1 > 125) return "High"
    if (v1 < 60) return "Low"
    return "In range"
  }
  if (type.includes("hr") || type.includes("heart")) {
    if (v1 > 110) return "High"
    if (v1 < 50) return "Low"
    return "In range"
  }
  if (type.includes("temp")) {
    if (v1 > 100.4) return "High"
    if (v1 < 96.0) return "Low"
    return "In range"
  }
  if (type.includes("o2") || type.includes("oxygen") || type.includes("spo2")) {
    if (v1 < 90) return "Low"
    return "In range"
  }

  return measurement.status || "In range"
}

function isAbnormal(measurement: any): boolean {
  const status = calculateVitalStatus(measurement)
  return status === "High" || status === "Low"
}

function calculateAge(dob: string) {
  const birthDate = new Date(dob)
  return Math.floor(
    (Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000),
  )
}

function mapCategory(type?: string): PortalNotification["category"] {
  const normalized = (type || "").toLowerCase()
  if (normalized.includes("vital")) return "Vitals"
  if (normalized.includes("med")) return "Medication"
  if (normalized.includes("doc")) return "Document"
  return "System"
}

