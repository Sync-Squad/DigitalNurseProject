import { useEffect, useState } from "react"
import type { CaregiverRow } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

export function useCaregiversData() {
  const [caregivers, setCaregivers] = useState<CaregiverRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true
    ;(async () => {
      try {
        setLoading(true)
        const response = await api.get<
          Array<{
            id: string
            name: string
            status?: string
            assignments?: number
            escalations?: number
            lastInteraction?: string
            notes?: string
          }>
        >(API_ENDPOINTS.caregivers.all)

        if (!isMounted) return

        setCaregivers(
          response.map((caregiver) => ({
            id: caregiver.id,
            name: caregiver.name,
            status: (caregiver.status as CaregiverRow["status"]) || "active",
            assignments: caregiver.assignments ?? 0,
            escalations: caregiver.escalations ?? 0,
            lastInteraction: caregiver.lastInteraction
              ? new Date(caregiver.lastInteraction).toLocaleString()
              : "",
            notes: caregiver.notes || "",
          })),
        )
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load caregivers"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [])

  return { caregivers, loading, error }
}

