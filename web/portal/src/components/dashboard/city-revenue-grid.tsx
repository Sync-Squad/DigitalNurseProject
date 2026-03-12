import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import type { CityRevenueData } from "@/mocks/data"

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-PK", {
    style: "currency",
    currency: "PKR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

function formatGrowth(growth: number): string {
  const sign = growth >= 0 ? "+" : ""
  return `${sign}${growth.toFixed(1)}%`
}

export function CityRevenueGrid({
  data,
}: {
  data: CityRevenueData[]
}) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm font-semibold text-muted-foreground">
          Revenue by City
        </CardTitle>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>City</TableHead>
              <TableHead className="text-right">Revenue</TableHead>
              <TableHead className="text-right">Subscriptions</TableHead>
              <TableHead className="text-right">Growth</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((row) => (
              <TableRow key={row.city}>
                <TableCell className="font-medium">{row.city}</TableCell>
                <TableCell className="text-right">{formatCurrency(row.revenue)}</TableCell>
                <TableCell className="text-right">{row.subscriptions}</TableCell>
                <TableCell className="text-right">
                  <Badge
                    variant={row.growth >= 0 ? "default" : "secondary"}
                    className={
                      row.growth >= 0
                        ? "bg-emerald-500/10 text-emerald-600"
                        : "bg-rose-500/10 text-rose-600"
                    }
                  >
                    {formatGrowth(row.growth)}
                  </Badge>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}

