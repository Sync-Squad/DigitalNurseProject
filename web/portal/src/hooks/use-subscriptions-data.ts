import { useEffect, useState } from "react"
import type { SubscriptionRecord } from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

export function useSubscriptionsData() {
  const [subscriptions, setSubscriptions] = useState<SubscriptionRecord[]>([])
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
            patient: string
            plan: string
            renewalDate: string
            paymentStatus: SubscriptionRecord["paymentStatus"]
            lastInvoice?: string
            addOns?: string[]
          }>
        >(API_ENDPOINTS.subscriptions.active)

        if (!isMounted) return

        setSubscriptions(
          response.map((record) => ({
            id: record.id,
            patient: record.patient,
            plan: (record.plan as SubscriptionRecord["plan"]) || "Essential",
            renewalDate: new Date(record.renewalDate),
            paymentStatus: record.paymentStatus || "Paid",
            lastInvoice: record.lastInvoice || "-",
            addOns: record.addOns || [],
          })),
        )
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load subscriptions"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [])

  return { subscriptions, loading, error }
}

