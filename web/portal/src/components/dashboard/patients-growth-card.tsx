import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import type { PatientGrowthPoint } from "@/mocks/data"

const lineColor = "#7FD991" // appleGreen

export function PatientsGrowthCard({
  data7Days,
  data30Days,
  timeframe,
  onTimeframeChange,
}: {
  data7Days: PatientGrowthPoint[]
  data30Days: PatientGrowthPoint[]
  timeframe: "7" | "30" | "90"
  onTimeframeChange: (value: "7" | "30" | "90") => void
}) {
  // Map timeframe to available data (90 days defaults to 30 days data)
  const effectiveTimeframe = timeframe === "90" ? "30" : timeframe
  const currentData = effectiveTimeframe === "7" ? data7Days : data30Days

  return (
    <Card className="col-span-1 lg:col-span-2">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-semibold text-muted-foreground">
          Patients Growth
        </CardTitle>
        <Select
          value={timeframe}
          onValueChange={(value) => onTimeframeChange(value as "7" | "30" | "90")}
        >
          <SelectTrigger className="w-32">
            <SelectValue placeholder="Timeframe" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="7">Last 7 days</SelectItem>
            <SelectItem value="30">Last 30 days</SelectItem>
            {/* <SelectItem value="90">Last quarter</SelectItem> */}
          </SelectContent>
        </Select>
      </CardHeader>
      <CardContent className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={currentData}>
            <defs>
              <linearGradient id="patientGrowth" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={lineColor} stopOpacity={0.25} />
                <stop offset="95%" stopColor={lineColor} stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} opacity={0.3} />
            <XAxis
              dataKey="date"
              tickLine={false}
              axisLine={false}
              tick={{ fontSize: 12 }}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              width={50}
              tick={{ fontSize: 12 }}
            />
            <Tooltip
              cursor={{ strokeDasharray: "4 4" }}
              contentStyle={{
                borderRadius: "0.75rem",
                borderColor: "hsl(var(--border))",
                boxShadow: "var(--tw-shadow)",
              }}
              formatter={(value: number) => [value, "Patients"]}
            />
            <Legend />
            <Line
              type="monotone"
              dataKey="count"
              stroke={lineColor}
              strokeWidth={2}
              dot={{ fill: lineColor, r: 4 }}
              activeDot={{ r: 6 }}
              name="Total Patients"
            />
          </LineChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
