import { addDays, subDays } from "date-fns"

export type RiskLevel = "low" | "moderate" | "high" | "critical"

export type DashboardMetric = {
  title: string
  label: string
  value: string
  change: string
  changeLabel: string
  trend: "up" | "down" | "flat"
  icon?: string
  color?: string
  description?: string
}

export const dashboardMetrics: DashboardMetric[] = [
  {
    title: "Number of Patient",
    label: "",
    value: "5",
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
    value: "3",
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
    value: "150",
    change: "",
    changeLabel: "",
    trend: "flat",
    icon: "Activity",
    color: "green",
    description: "Vitals recorded this period",
  },
  {
    title: "Medication added",
    label: "",
    value: "85",
    change: "",
    changeLabel: "",
    trend: "flat",
    icon: "Pill",
    color: "orange",
    description: "Medications logged this period",
  },
]

export type MedicationReminder = {
  id: string
  patient: string
  medication: string
  schedule: string
  dueAt: string
  status: "upcoming" | "overdue" | "taken"
}

export const medicationReminders: MedicationReminder[] = [
  {
    id: "mr-1",
    patient: "Ayesha Khan",
    medication: "Metformin 500mg",
    schedule: "Daily · 8:00 AM",
    dueAt: "in 12 min",
    status: "upcoming",
  },
  {
    id: "mr-2",
    patient: "Hassan Raza",
    medication: "Lisinopril 10mg",
    schedule: "Daily · 7:00 AM",
    dueAt: "overdue by 25 min",
    status: "overdue",
  },
  {
    id: "mr-3",
    patient: "Mahnoor Ali",
    medication: "Atorvastatin 20mg",
    schedule: "Daily · 9:00 PM",
    dueAt: "logged 32 min ago",
    status: "taken",
  },
]

export type VitalTrendPoint = {
  date: string
  systolic: number
  diastolic: number
  heartRate: number
}

export const vitalTrend: VitalTrendPoint[] = Array.from({ length: 10 }).map(
  (_, index) => {
    const date = subDays(new Date(), 9 - index)
    return {
      date: date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
      systolic: 118 + Math.round(Math.sin(index) * 6),
      diastolic: 76 + Math.round(Math.cos(index) * 4),
      heartRate: 72 + Math.round(Math.sin(index / 2) * 8),
    }
  }
)

export type PatientGrowthPoint = {
  date: string
  count: number
}

// Generate 7-day patient growth data (cumulative)
const basePatientCount = 120
export const patientGrowth7Days: PatientGrowthPoint[] = Array.from({ length: 7 }).map(
  (_, index) => {
    const date = subDays(new Date(), 6 - index)
    // Simulate growth: start with base count and add 2-5 patients per day
    const dailyGrowth = 2 + Math.round(Math.random() * 3)
    const cumulativeCount = basePatientCount + (index + 1) * dailyGrowth
    return {
      date: date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
      count: cumulativeCount,
    }
  }
)

// Generate 30-day patient growth data (cumulative)
export const patientGrowth30Days: PatientGrowthPoint[] = Array.from({ length: 30 }).map(
  (_, index) => {
    const date = subDays(new Date(), 29 - index)
    // Simulate growth: start with lower base and add 1-4 patients per day
    const dailyGrowth = 1 + Math.round(Math.random() * 3)
    const cumulativeCount = basePatientCount - 50 + (index + 1) * dailyGrowth
    return {
      date: date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
      count: cumulativeCount,
    }
  }
)

export type SubscriptionBreakdown = {
  type: "FREE" | "PREMIUM"
  count: number
  percentage: number
}

// Calculate subscription breakdown
const totalPatients = 150
const freeCount = Math.round(totalPatients * 0.72) // 72% free
const premiumCount = totalPatients - freeCount // 28% premium

export const subscriptionBreakdown: SubscriptionBreakdown[] = [
  {
    type: "FREE",
    count: freeCount,
    percentage: 72,
  },
  {
    type: "PREMIUM",
    count: premiumCount,
    percentage: 28,
  },
]

export type DashboardAlert = {
  id: string
  title: string
  patient: string
  severity: "low" | "medium" | "high"
  createdAt: string
  description: string
}

export const dashboardAlerts: DashboardAlert[] = [
  {
    id: "alert-1",
    title: "Missed evening insulin dose",
    patient: "Hassan Raza",
    severity: "high",
    createdAt: "12 min ago",
    description: "Escalate if no confirmation within 30 minutes.",
  },
  {
    id: "alert-2",
    title: "Elevated blood pressure trend",
    patient: "Mahnoor Ali",
    severity: "medium",
    createdAt: "1 hr ago",
    description: "3 consecutive systolic readings above safe threshold.",
  },
  {
    id: "alert-3",
    title: "Document awaiting approval",
    patient: "Ayesha Khan",
    severity: "low",
    createdAt: "2 hrs ago",
    description: "Care plan update submitted by caregiver needs review.",
  },
]

export type PatientRosterRow = {
  id: string
  name: string
  slug: string
  age: number
  risk: RiskLevel
  adherence: number
  alerts: number
  unreadDocs: number
  subscription: "Essential" | "Premium"
  careTeam: string[]
  lastActivity: string
}

export const patientRoster: PatientRosterRow[] = [
  {
    id: "patient-1",
    name: "Ayesha Khan",
    slug: "ayesha-khan",
    age: 68,
    risk: "moderate",
    adherence: 94,
    alerts: 1,
    unreadDocs: 0,
    subscription: "Premium",
    careTeam: ["Dr. Maria Aslam", "Caregiver: Bilal"],
    lastActivity: "10 min ago",
  },
  {
    id: "patient-2",
    name: "Hassan Raza",
    slug: "hassan-raza",
    age: 74,
    risk: "high",
    adherence: 81,
    alerts: 3,
    unreadDocs: 2,
    subscription: "Essential",
    careTeam: ["Dr. Zohaib Malik", "Caregiver: Sara"],
    lastActivity: "25 min ago",
  },
  {
    id: "patient-3",
    name: "Mahnoor Ali",
    slug: "mahnoor-ali",
    age: 65,
    risk: "moderate",
    adherence: 89,
    alerts: 0,
    unreadDocs: 1,
    subscription: "Premium",
    careTeam: ["Dr. Ahmed Farooq", "Caregiver: Anika"],
    lastActivity: "1 hr ago",
  },
  {
    id: "patient-4",
    name: "Nadeem Qureshi",
    slug: "nadeem-qureshi",
    age: 78,
    risk: "critical",
    adherence: 67,
    alerts: 5,
    unreadDocs: 4,
    subscription: "Premium",
    careTeam: ["Dr. Maria Aslam", "Caregiver: Omar"],
    lastActivity: "2 hrs ago",
  },
  {
    id: "patient-5",
    name: "Sana Arif",
    slug: "sana-arif",
    age: 71,
    risk: "low",
    adherence: 97,
    alerts: 0,
    unreadDocs: 0,
    subscription: "Essential",
    careTeam: ["Dr. Zohaib Malik"],
    lastActivity: "35 min ago",
  },
]

export type CaregiverRow = {
  id: string
  name: string
  status: "active" | "pending" | "declined"
  assignments: number
  escalations: number
  lastInteraction: string
  notes: string
}

export const caregivers: CaregiverRow[] = [
  {
    id: "cg-1",
    name: "Bilal Hussain",
    status: "active",
    assignments: 4,
    escalations: 1,
    lastInteraction: "Today, 08:15",
    notes: "Specializes in diabetes adherence coaching.",
  },
  {
    id: "cg-2",
    name: "Sara Imran",
    status: "active",
    assignments: 3,
    escalations: 0,
    lastInteraction: "Today, 07:40",
    notes: "High caregiver satisfaction ratings.",
  },
  {
    id: "cg-3",
    name: "Omar Siddiqui",
    status: "pending",
    assignments: 1,
    escalations: 2,
    lastInteraction: "Yesterday, 21:10",
    notes: "Pending background check completion.",
  },
]

export type DocumentRecord = {
  id: string
  patient: string
  type: "Lab Result" | "Care Plan" | "Discharge Summary" | "Prescription"
  author: string
  createdAt: string
  visibility: "Team" | "Caregiver" | "Private"
  status: "In Review" | "Published" | "Requires Signature"
}

export const documents: DocumentRecord[] = [
  {
    id: "doc-1",
    patient: "Ayesha Khan",
    type: "Care Plan",
    author: "Dr. Maria Aslam",
    createdAt: "Feb 12 · 09:24",
    visibility: "Team",
    status: "Published",
  },
  {
    id: "doc-2",
    patient: "Hassan Raza",
    type: "Lab Result",
    author: "Downtown Diagnostics",
    createdAt: "Feb 11 · 18:02",
    visibility: "Team",
    status: "Requires Signature",
  },
  {
    id: "doc-3",
    patient: "Mahnoor Ali",
    type: "Discharge Summary",
    author: "Dr. Ahmed Farooq",
    createdAt: "Feb 10 · 16:11",
    visibility: "Caregiver",
    status: "In Review",
  },
]

export type PortalNotification = {
  id: string
  category: "Vitals" | "Medication" | "Document" | "System"
  title: string
  summary: string
  recipients: string[]
  createdAt: Date
  severity: "info" | "warning" | "critical"
  read: boolean
}

export const notifications: PortalNotification[] = [
  {
    id: "notif-1",
    category: "Vitals",
    title: "Blood pressure outside range",
    summary:
      "Systolic readings for Hassan Raza exceeded safe range 3 times today.",
    recipients: ["Care Team", "Primary Caregiver"],
    createdAt: subDays(new Date(), 0),
    severity: "critical",
    read: false,
  },
  {
    id: "notif-2",
    category: "Medication",
    title: "Missed evening dose",
    summary: "Mahnoor Ali missed Atorvastatin yesterday evening.",
    recipients: ["Primary Caregiver"],
    createdAt: subDays(new Date(), 1),
    severity: "warning",
    read: false,
  },
  {
    id: "notif-3",
    category: "Document",
    title: "Lab result available",
    summary: "New lipid panel uploaded for Ayesha Khan.",
    recipients: ["Provider"],
    createdAt: subDays(new Date(), 1),
    severity: "info",
    read: true,
  },
  {
    id: "notif-4",
    category: "System",
    title: "Scheduled maintenance",
    summary: "Portal updates planned for Feb 16, 02:00-04:00 PKT.",
    recipients: ["All Admins"],
    createdAt: subDays(new Date(), 3),
    severity: "info",
    read: true,
  },
]

export type SubscriptionRecord = {
  id: string
  patient: string
  plan: "Essential" | "Premium"
  renewalDate: Date
  paymentStatus: "Paid" | "Due" | "Past Due"
  lastInvoice: string
  addOns: string[]
}

export const subscriptions: SubscriptionRecord[] = [
  {
    id: "sub-1",
    patient: "Ayesha Khan",
    plan: "Premium",
    renewalDate: addDays(new Date(), 24),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2031",
    addOns: ["Caregiver Analytics", "Bilingual Support"],
  },
  {
    id: "sub-2",
    patient: "Hassan Raza",
    plan: "Essential",
    renewalDate: addDays(new Date(), 6),
    paymentStatus: "Due",
    lastInvoice: "INV-2025-2022",
    addOns: ["Medication Insights"],
  },
  {
    id: "sub-3",
    patient: "Mahnoor Ali",
    plan: "Premium",
    renewalDate: addDays(new Date(), 14),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2017",
    addOns: ["Caregiver Analytics"],
  },
  {
    id: "sub-4",
    patient: "Nadeem Qureshi",
    plan: "Premium",
    renewalDate: addDays(new Date(), 3),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2019",
    addOns: ["Caregiver Analytics", "Bilingual Support", "Priority Support"],
  },
  {
    id: "sub-5",
    patient: "Sana Arif",
    plan: "Essential",
    renewalDate: addDays(new Date(), 12),
    paymentStatus: "Due",
    lastInvoice: "INV-2025-2025",
    addOns: ["Medication Insights"],
  },
  {
    id: "sub-6",
    patient: "Ahmed Malik",
    plan: "Premium",
    renewalDate: addDays(new Date(), 28),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2035",
    addOns: ["Caregiver Analytics"],
  },
  {
    id: "sub-7",
    patient: "Fatima Sheikh",
    plan: "Essential",
    renewalDate: addDays(new Date(), 5),
    paymentStatus: "Past Due",
    lastInvoice: "INV-2025-2018",
    addOns: [],
  },
  {
    id: "sub-8",
    patient: "Zain Ali",
    plan: "Premium",
    renewalDate: addDays(new Date(), 45),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2042",
    addOns: ["Bilingual Support", "Priority Support"],
  },
  {
    id: "sub-9",
    patient: "Hina Rizvi",
    plan: "Essential",
    renewalDate: addDays(new Date(), 20),
    paymentStatus: "Due",
    lastInvoice: "INV-2025-2027",
    addOns: ["Medication Insights"],
  },
  {
    id: "sub-10",
    patient: "Omar Khan",
    plan: "Premium",
    renewalDate: addDays(new Date(), 65),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2062",
    addOns: ["Caregiver Analytics", "Bilingual Support"],
  },
  {
    id: "sub-11",
    patient: "Sara Ahmed",
    plan: "Essential",
    renewalDate: addDays(new Date(), 2),
    paymentStatus: "Due",
    lastInvoice: "INV-2025-2015",
    addOns: [],
  },
  {
    id: "sub-12",
    patient: "Bilal Hassan",
    plan: "Premium",
    renewalDate: addDays(new Date(), 35),
    paymentStatus: "Paid",
    lastInvoice: "INV-2025-2040",
    addOns: ["Priority Support"],
  },
]

export type ReportSchedule = {
  id: string
  title: string
  frequency: "Daily" | "Weekly" | "Monthly"
  recipients: string[]
  nextRun: Date
  scope: string
}

export const reportSchedules: ReportSchedule[] = [
  {
    id: "rep-1",
    title: "Medication Adherence Digest",
    frequency: "Daily",
    recipients: ["maria.aslam@digitalnurse.app"],
    nextRun: addDays(new Date(), 1),
    scope: "All premium patients",
  },
  {
    id: "rep-2",
    title: "Vitals Escalation Summary",
    frequency: "Weekly",
    recipients: ["carecoordination@digitalnurse.app"],
    nextRun: addDays(new Date(), 2),
    scope: "High & critical risk cohorts",
  },
  {
    id: "rep-3",
    title: "Caregiver Engagement Report",
    frequency: "Monthly",
    recipients: ["ops@digitalnurse.app"],
    nextRun: addDays(new Date(), 12),
    scope: "Active caregivers",
  },
]

export type NotificationTemplate = {
  id: string
  name: string
  channel: "Email" | "SMS" | "Push"
  updatedAt: Date
  status: "Active" | "Draft"
}

export const notificationTemplates: NotificationTemplate[] = [
  {
    id: "tmpl-1",
    name: "Missed Dose Escalation",
    channel: "Push",
    updatedAt: subDays(new Date(), 4),
    status: "Active",
  },
  {
    id: "tmpl-2",
    name: "Subscription Renewal Reminder",
    channel: "Email",
    updatedAt: subDays(new Date(), 1),
    status: "Active",
  },
  {
    id: "tmpl-3",
    name: "Vitals Alert · High BP",
    channel: "SMS",
    updatedAt: subDays(new Date(), 9),
    status: "Draft",
  },
]

export const patientWorkspace = {
  demographics: {
    name: "Ayesha Khan",
    age: 68,
    gender: "Female",
    subscription: "Premium",
    riskLevel: "Moderate",
    primaryProvider: "Dr. Maria Aslam",
    emergencyContact: "+92 345 1112223",
    lastSynced: "10 minutes ago",
  },
  careTeam: [
    { name: "Bilal Hussain", role: "Caregiver", status: "Active" },
    { name: "Dr. Maria Aslam", role: "Primary Care", status: "Active" },
    { name: "Nurse Sidra Khan", role: "Care Coordinator", status: "On leave" },
  ],
  medications: [
    {
      id: "med-1",
      name: "Metformin",
      dosage: "500 mg",
      schedule: "08:00 AM · Daily",
      adherence: 96,
      status: "In range",
    },
    {
      id: "med-2",
      name: "Lisinopril",
      dosage: "10 mg",
      schedule: "07:00 PM · Daily",
      adherence: 88,
      status: "2 misses",
    },
  ],
  medicationLog: [
    {
      date: subDays(new Date(), 1).toISOString(),
      time: "08:05 AM",
      medication: "Metformin",
      status: "Taken",
      recordedBy: "Ayesha Khan",
    },
    {
      date: subDays(new Date(), 1).toISOString(),
      time: "07:18 PM",
      medication: "Lisinopril",
      status: "Missed",
      recordedBy: "Bilal Hussain",
    },
  ],
  vitals: {
    recent: [
      { type: "Blood Pressure", value: "124 / 78", status: "Stable" },
      { type: "Heart Rate", value: "74 bpm", status: "Stable" },
      { type: "Blood Glucose", value: "106 mg/dL", status: "Stable" },
    ],
    abnormalEvents: [
      {
        id: "abn-1",
        recordedAt: subDays(new Date(), 2).toISOString(),
        note: "Systolic 142 detected. Resolved after 15 mins.",
      },
    ],
  },
  lifestyle: {
    diet: {
      compliance: 82,
      highlights: [
        "High fiber breakfast logged",
        "Hydration below target on 2 days",
      ],
    },
    exercise: {
      compliance: 74,
      highlights: [
        "Completed 4 of 5 recommended walks",
        "Physio session scheduled for Thu",
      ],
    },
  },
  documents: documents.filter((doc) => doc.patient === "Ayesha Khan"),
  notifications: notifications.slice(0, 3),
}

export type CityPatientData = {
  city: string
  patients: number
}

export const cityPatientData: CityPatientData[] = [
  { city: "Karachi", patients: 45 },
  { city: "Lahore", patients: 38 },
  { city: "Islamabad", patients: 32 },
  { city: "Rawalpindi", patients: 18 },
  { city: "Faisalabad", patients: 12 },
  { city: "Multan", patients: 8 },
  { city: "Peshawar", patients: 7 },
]

export type CityRevenueData = {
  city: string
  revenue: number
  subscriptions: number
  growth: number
}

export const cityRevenueData: CityRevenueData[] = [
  { city: "Karachi", revenue: 1250000, subscriptions: 45, growth: 12.5 },
  { city: "Lahore", revenue: 980000, subscriptions: 38, growth: 8.3 },
  { city: "Islamabad", revenue: 850000, subscriptions: 32, growth: 15.2 },
  { city: "Rawalpindi", revenue: 420000, subscriptions: 18, growth: 5.7 },
  { city: "Faisalabad", revenue: 280000, subscriptions: 12, growth: 3.1 },
  { city: "Multan", revenue: 195000, subscriptions: 8, growth: 2.4 },
  { city: "Peshawar", revenue: 175000, subscriptions: 7, growth: 1.8 },
]

