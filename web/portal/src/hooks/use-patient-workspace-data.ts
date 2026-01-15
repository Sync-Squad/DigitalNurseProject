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
          const [userDetail, medicationsRes, vitalsRes, documentsRes, notificationsRes] =
            await Promise.all([
              api.get<any>(API_ENDPOINTS.users.detail(patientId)),
              api.get<any[]>(`${API_ENDPOINTS.medications.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.vitals.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.documents.list}?elderUserId=${patientId}`),
              api.get<any[]>(`${API_ENDPOINTS.notifications.list}?elderUserId=${patientId}`),
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
            type: vital.type || vital.kindCode || "Vital",
            value: vital.value,
            status: "Stable",
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

function isAbnormal(measurement: any): boolean {
  const kindCode = measurement.kindCode?.toLowerCase();
  const value1 = measurement.value1 ? parseFloat(measurement.value1.toString()) : null;
  const value2 = measurement.value2 ? parseFloat(measurement.value2.toString()) : null;

  if (kindCode === 'bp' && value1 && value2) {
    return value1 > 140 || value1 < 80 || value2 > 90 || value2 < 50;
  }
  if (kindCode === 'bs' && value1 !== null) {
    return value1 > 125 || value1 < 60;
  }
  if (kindCode === 'hr' && value1 !== null) {
    return value1 < 50 || value1 > 110;
  }
  if (kindCode === 'temp' && value1 !== null) {
    return value1 < 96.0 || value1 > 100.4;
  }
  if (kindCode === 'o2' && value1 !== null) {
    return value1 < 90;
  }
  return false;
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

