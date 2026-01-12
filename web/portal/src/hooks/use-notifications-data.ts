import { useEffect, useState } from "react"
import type { PortalNotification } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

export function useNotificationsData(elderUserId?: string) {
  const [notifications, setNotifications] = useState<PortalNotification[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true
    ;(async () => {
      try {
        setLoading(true)
        const endpoint = elderUserId
          ? `${API_ENDPOINTS.notifications.list}?elderUserId=${elderUserId}`
          : API_ENDPOINTS.notifications.list
        const response = await api.get<
          Array<{
            notificationId: string
            title: string
            message: string
            notificationType: string
            createdAt?: string
            isRead?: boolean
          }>
        >(endpoint)

        if (!isMounted) return

        setNotifications(
          response.map((item) => ({
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
          })),
        )
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load notifications"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [elderUserId])

  return { notifications, loading, error }
}

function mapCategory(type?: string): PortalNotification["category"] {
  const normalized = (type || "").toLowerCase()
  if (normalized.includes("vital")) return "Vitals"
  if (normalized.includes("med")) return "Medication"
  if (normalized.includes("doc")) return "Document"
  return "System"
}

