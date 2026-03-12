import {
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
} from "recharts"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import type { SubscriptionBreakdown } from "@/mocks/data"

const COLORS = {
  FREE: "#3B82F6", // slate-400
  PREMIUM: "#7FD991", // appleGreen
}

export function SubscriptionBreakdownCard({
  data,
}: {
  data: SubscriptionBreakdown[]
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm font-semibold text-muted-foreground">
          Subscription Breakdown
        </CardTitle>
      </CardHeader>
      <CardContent className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              outerRadius={80}
              fill="#8884d8"
              dataKey="count"
            >
              {data.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[entry.type]}
                />
              ))}
            </Pie>
            <Tooltip
              contentStyle={{
                borderRadius: "0.75rem",
                borderColor: "hsl(var(--border))",
                boxShadow: "var(--tw-shadow)",
              }}
              formatter={(value: number, _name: string, props: any) => [
                `${value} (${props.payload.percentage}%)`,
                props.payload.type,
              ]}
            />
            <Legend
              formatter={(_value, entry: any) => {
                const item = entry.payload
                return `${item.type}: ${item.count} (${item.percentage}%)`
              }}
            />
          </PieChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  )
}
