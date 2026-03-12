import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { CityPatientData } from "@/mocks/data"

const barColor = "#7FD991" // appleGreen

export function CityPatientsBarChart({
  data,
}: {
  data: CityPatientData[]
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm font-semibold text-muted-foreground">
          Patients by City
        </CardTitle>
      </CardHeader>
      <CardContent className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} opacity={0.3} />
            <XAxis
              dataKey="city"
              tickLine={false}
              axisLine={false}
              tick={{ fontSize: 12 }}
              angle={-45}
              textAnchor="end"
              height={80}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              width={50}
              tick={{ fontSize: 12 }}
            />
            <Tooltip
              cursor={{ fill: "rgba(127, 217, 145, 0.1)" }}
              contentStyle={{
                borderRadius: "0.75rem",
                borderColor: "hsl(var(--border))",
                boxShadow: "var(--tw-shadow)",
              }}
              formatter={(value: number) => [value, "Patients"]}
            />
            <Bar
              dataKey="patients"
              fill={barColor}
              radius={[4, 4, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}

