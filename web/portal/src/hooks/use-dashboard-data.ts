import { useEffect, useState } from "react"
import type {
  CityPatientData,
  CityRevenueData,
  DashboardMetric,
  PatientGrowthPoint,
  SubscriptionBreakdown,
} from "@/mocks/data"
import { api } from "@/lib/api/client"
import { API_ENDPOINTS } from "@/lib/api/config"

type MetricsResponse = {
  totalPatients: number
  totalCaregivers: number
  totalVitals: number
  totalMedications: number
  activeSubscriptions: number
  estimatedMonthlyRevenue: number
  currency: string
}

type StatsResponse = {
  patientGrowth: {
    last7Days: Array<{ date: string; count: number }>
    last30Days: Array<{ date: string; count: number }>
  }
  subscriptionBreakdown: Array<{ type: string; count: number; percentage: number }>
  cityPatients: CityPatientData[]
  cityRevenue: CityRevenueData[]
  revenue: { monthly: number; currency: string }
}

export function useDashboardData() {
  const [metrics, setMetrics] = useState<DashboardMetric[]>([])
  const [patientGrowth7Days, setPatientGrowth7Days] = useState<PatientGrowthPoint[]>([])
  const [patientGrowth30Days, setPatientGrowth30Days] = useState<PatientGrowthPoint[]>([])
  const [subscriptionBreakdown, setSubscriptionBreakdown] = useState<SubscriptionBreakdown[]>([])
  const [cityPatients, setCityPatients] = useState<CityPatientData[]>([])
  const [cityRevenue, setCityRevenue] = useState<CityRevenueData[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let isMounted = true
    ;(async () => {
      try {
        setLoading(true)
        const [metricsRes, statsRes] = await Promise.all([
          api.get<MetricsResponse>(API_ENDPOINTS.dashboard.metrics),
          api.get<StatsResponse>(API_ENDPOINTS.dashboard.stats),
        ])

        if (!isMounted) return

        setMetrics([
          {
            title: "Number of Patient",
            label: "",
            value: metricsRes.totalPatients.toString(),
            change: "",
            changeLabel: "",
            trend: "flat",
            icon: "Users",
            color: "blue",
            description: "Total active patients",
          },
          {
            title: "Number of Caregiver",
            label: "",
            value: metricsRes.totalCaregivers.toString(),
            change: "",
            changeLabel: "",
            trend: "flat",
            icon: "UserCog",
            color: "purple",
            description: "Active caregivers",
          },
          {
            title: "Vitals added",
            label: "",
            value: metricsRes.totalVitals.toString(),
            change: "",
            changeLabel: "",
            trend: "flat",
            icon: "Activity",
            color: "green",
            description: "Vitals recorded",
          },
          {
            title: "Medication added",
            label: "",
            value: metricsRes.totalMedications.toString(),
            change: "",
            changeLabel: "",
            trend: "flat",
            icon: "Pill",
            color: "orange",
            description: "Medications logged",
          },
        ])

        const formatGrowth = (points: Array<{ date: string; count: number }>) =>
          points.map((point) => ({
            date: new Date(point.date).toLocaleDateString("en-US", {
              month: "short",
              day: "numeric",
            }),
            count: point.count,
          }))

        setPatientGrowth7Days(formatGrowth(statsRes.patientGrowth.last7Days))
        setPatientGrowth30Days(formatGrowth(statsRes.patientGrowth.last30Days))

        // Consolidate breakdown to the two slices used in UI
        const breakdown: SubscriptionBreakdown[] = statsRes.subscriptionBreakdown.map(
          (slice) => ({
            type: slice.type === "PREMIUM" ? "PREMIUM" : "FREE",
            count: slice.count,
            percentage: slice.percentage,
          }),
        )
        setSubscriptionBreakdown(breakdown)

        setCityPatients(statsRes.cityPatients)
        setCityRevenue(statsRes.cityRevenue)
        setError(null)
      } catch (err) {
        const message =
          err instanceof Error ? err.message : "Unable to load dashboard data"
        if (isMounted) setError(message)
      } finally {
        if (isMounted) setLoading(false)
      }
    })()

    return () => {
      isMounted = false
    }
  }, [])

  return {
    metrics,
    patientGrowth7Days,
    patientGrowth30Days,
    subscriptionBreakdown,
    cityPatients,
    cityRevenue,
    loading,
    error,
  }
}

