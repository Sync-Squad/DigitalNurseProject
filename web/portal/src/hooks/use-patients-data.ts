import { useEffect, useState } from "react"
import type { PatientRosterRow } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

export function usePatientsData() {
  const [patients, setPatients] = useState<PatientRosterRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true
    ;(async () => {
      try {
        setLoading(true)
        const response = await api.get<PatientRosterRow[]>(API_ENDPOINTS.users.patients)
        if (!isMounted) return

        setPatients(
          response.map((patient) => ({
            ...patient,
            risk: patient.risk || "low",
            adherence: patient.adherence ?? 100,
            alerts: patient.alerts ?? 0,
            unreadDocs: patient.unreadDocs ?? 0,
            careTeam: patient.careTeam || [],
            subscription: patient.subscription || "Essential",
            lastActivity: patient.lastActivity || "",
          })),
        )
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load patients"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [])

  return { patients, loading, error }
}

