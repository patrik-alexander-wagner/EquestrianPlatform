import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";

export default function ReportsPage() {
  const [groupBy, setGroupBy] = useState("month");
  const [metric, setMetric] = useState("totalRevenue");

  const { data: reportData = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/reports/livery", `?groupBy=${groupBy}`],
  });

  const metricLabels: Record<string, string> = {
    horseCount: "Number of Horses",
    liveryRevenue: "Livery Package Revenue",
    otherRevenue: "Other Revenue",
    totalRevenue: "Total Revenue",
  };

  const metricColors: Record<string, string> = {
    horseCount: "hsl(142, 76%, 36%)",
    liveryRevenue: "hsl(197, 84%, 42%)",
    otherRevenue: "hsl(25, 95%, 53%)",
    totalRevenue: "hsl(280, 65%, 60%)",
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Livery Reports"
        description="Visual analysis of livery data"
      />

      <div className="flex gap-4 mb-6 flex-wrap">
        <div>
          <Label className="text-sm text-muted-foreground mb-1 block">X-Axis</Label>
          <Select value={groupBy} onValueChange={setGroupBy}>
            <SelectTrigger className="w-40" data-testid="select-report-groupby">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="month">Month</SelectItem>
              <SelectItem value="customer">Customer</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div>
          <Label className="text-sm text-muted-foreground mb-1 block">Metric</Label>
          <Select value={metric} onValueChange={setMetric}>
            <SelectTrigger className="w-52" data-testid="select-report-metric">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="horseCount">Number of Horses</SelectItem>
              <SelectItem value="liveryRevenue">Livery Revenue</SelectItem>
              <SelectItem value="otherRevenue">Other Revenue</SelectItem>
              <SelectItem value="totalRevenue">Total Revenue</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <Card>
        <CardContent className="pt-6">
          {isLoading ? (
            <div className="h-80 flex items-center justify-center text-muted-foreground">Loading report data...</div>
          ) : reportData.length === 0 ? (
            <div className="h-80 flex items-center justify-center text-muted-foreground">
              No data available for the selected criteria
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={reportData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip
                  contentStyle={{
                    borderRadius: "6px",
                    border: "1px solid hsl(var(--border))",
                    backgroundColor: "hsl(var(--card))",
                    color: "hsl(var(--card-foreground))",
                  }}
                />
                <Legend />
                <Bar
                  dataKey={metric}
                  name={metricLabels[metric]}
                  fill={metricColors[metric]}
                  radius={[4, 4, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
