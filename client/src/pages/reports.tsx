import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { DollarSign, TrendingUp, Zap, Users, Heart } from "lucide-react";

function formatMonthLabel(month: string) {
  if (!month) return "";
  const [y, m] = month.split("-").map(Number);
  const date = new Date(y, m - 1);
  return date.toLocaleString("en-US", { month: "long", year: "numeric" });
}

function formatDate(dateStr: string) {
  if (!dateStr) return "-";
  const [y, m, d] = dateStr.split("-").map(Number);
  const date = new Date(y, m - 1, d);
  return date.toLocaleDateString("en-US", { day: "numeric", month: "short", year: "numeric" });
}

function getCurrentMonth() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function generateMonthOptions() {
  const months: string[] = [];
  const now = new Date();
  for (let i = 12; i >= -12; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    months.push(`${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`);
  }
  return months;
}

function formatCurrency(value: number) {
  return `AED ${value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}`;
}

export default function ReportsPage() {
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonth());
  const [chartGroupBy, setChartGroupBy] = useState("month");

  const monthOptions = useMemo(() => generateMonthOptions(), []);

  const { data: kpis, isLoading: loadingKpis } = useQuery<any>({
    queryKey: ["/api/reports/kpis", `?month=${selectedMonth}`],
  });

  const { data: chartData = [], isLoading: loadingChart } = useQuery<any[]>({
    queryKey: ["/api/reports/livery", `?groupBy=${chartGroupBy}`],
  });

  const { data: newLiveryData = [], isLoading: loadingNew } = useQuery<any[]>({
    queryKey: ["/api/reports/new-livery-horses", `?month=${selectedMonth}`],
  });

  const { data: departedData = [], isLoading: loadingDeparted } = useQuery<any[]>({
    queryKey: ["/api/reports/departed-livery-horses", `?month=${selectedMonth}`],
  });

  const { data: allCustomersData = [], isLoading: loadingAllCustomers } = useQuery<any[]>({
    queryKey: ["/api/reports/all-customers"],
  });

  const arrivalRows = useMemo(() => {
    const rows: any[] = [];
    newLiveryData.forEach((group: any) => {
      group.horses.forEach((h: any) => {
        rows.push({
          customerName: group.customerName,
          horseName: h.horseName,
          horseCount: group.horseCount,
          arrivalDate: h.arrivalDate,
          departureDate: h.departureDate || "",
          liveryPackage: h.liveryPackage || "N/A",
        });
      });
    });
    return rows;
  }, [newLiveryData]);

  const departureRows = useMemo(() => {
    const rows: any[] = [];
    departedData.forEach((group: any) => {
      group.horses.forEach((h: any) => {
        rows.push({
          customerName: group.customerName,
          horseName: h.horseName,
          horseCount: group.horseCount,
          arrivalDate: "",
          departureDate: h.departureDate,
          liveryPackage: "",
        });
      });
    });
    return rows;
  }, [departedData]);

  const customerGrouped = useMemo(() => {
    const grouped: Record<string, any> = {};
    for (const row of allCustomersData) {
      if (!grouped[row.customerName]) {
        grouped[row.customerName] = { customerName: row.customerName, horses: [], horseCount: 0 };
      }
      grouped[row.customerName].horses.push(row);
      grouped[row.customerName].horseCount++;
    }
    return Object.values(grouped);
  }, [allCustomersData]);

  const formattedChartData = useMemo(() => {
    return chartData.map((d: any) => ({
      ...d,
      label: chartGroupBy === "month" ? formatMonthLabel(d.label) : d.label,
    }));
  }, [chartData, chartGroupBy]);

  const kpiCards = [
    {
      title: "Total Revenue",
      value: kpis ? formatCurrency(kpis.totalRevenue) : "-",
      icon: DollarSign,
      color: "text-emerald-600",
      bgColor: "bg-emerald-50 dark:bg-emerald-950/30",
    },
    {
      title: "Livery Revenue",
      value: kpis ? formatCurrency(kpis.liveryRevenue) : "-",
      icon: TrendingUp,
      color: "text-blue-600",
      bgColor: "bg-blue-50 dark:bg-blue-950/30",
    },
    {
      title: "Adhoc Revenue",
      value: kpis ? formatCurrency(kpis.adhocRevenue) : "-",
      icon: Zap,
      color: "text-orange-600",
      bgColor: "bg-orange-50 dark:bg-orange-950/30",
    },
    {
      title: "Livery Horses",
      value: kpis ? String(kpis.liveryHorses) : "-",
      icon: Heart,
      color: "text-purple-600",
      bgColor: "bg-purple-50 dark:bg-purple-950/30",
    },
    {
      title: "Livery Customers",
      value: kpis ? String(kpis.liveryCustomers) : "-",
      icon: Users,
      color: "text-pink-600",
      bgColor: "bg-pink-50 dark:bg-pink-950/30",
    },
  ];

  return (
    <div className="p-6 space-y-8">
      <PageHeader
        title="Reports"
        description="Key metrics, revenue analysis, and customer details"
      />

      {/* Month Filter */}
      <div className="flex items-end gap-4">
        <div>
          <Label className="text-sm text-muted-foreground mb-1 block">Month</Label>
          <Select value={selectedMonth} onValueChange={setSelectedMonth}>
            <SelectTrigger className="w-56" data-testid="select-report-month">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {monthOptions.map(m => (
                <SelectItem key={m} value={m}>{formatMonthLabel(m)}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4" data-testid="kpi-cards">
        {kpiCards.map((card) => (
          <Card key={card.title} className="relative overflow-hidden">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">{card.title}</span>
                <div className={`p-1.5 rounded-md ${card.bgColor}`}>
                  <card.icon className={`w-4 h-4 ${card.color}`} />
                </div>
              </div>
              <div className="text-xl font-bold" data-testid={`kpi-${card.title.toLowerCase().replace(/\s+/g, "-")}`}>
                {loadingKpis ? "..." : card.value}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Revenue Breakdown Chart */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-lg">Revenue Breakdown</CardTitle>
            <div className="flex items-center gap-2">
              <Label className="text-sm text-muted-foreground">View by</Label>
              <Select value={chartGroupBy} onValueChange={setChartGroupBy}>
                <SelectTrigger className="w-36" data-testid="select-chart-groupby">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="month">Per Month</SelectItem>
                  <SelectItem value="customer">Per Customer</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {loadingChart ? (
            <div className="h-80 flex items-center justify-center text-muted-foreground">Loading chart data...</div>
          ) : formattedChartData.length === 0 ? (
            <div className="h-80 flex items-center justify-center text-muted-foreground">No revenue data available</div>
          ) : (
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={formattedChartData} margin={{ top: 5, right: 30, left: 20, bottom: chartGroupBy === "customer" ? 80 : 5 }}>
                <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                <XAxis
                  dataKey="label"
                  tick={{ fontSize: 11 }}
                  angle={chartGroupBy === "customer" ? -45 : 0}
                  textAnchor={chartGroupBy === "customer" ? "end" : "middle"}
                  interval={0}
                  height={chartGroupBy === "customer" ? 100 : 30}
                />
                <YAxis tick={{ fontSize: 12 }} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
                <Tooltip
                  formatter={(value: number, name: string) => [formatCurrency(value), name]}
                  contentStyle={{
                    borderRadius: "6px",
                    border: "1px solid hsl(var(--border))",
                    backgroundColor: "hsl(var(--card))",
                    color: "hsl(var(--card-foreground))",
                  }}
                />
                <Legend />
                <Bar
                  dataKey="liveryRevenue"
                  name="Livery Revenue"
                  stackId="revenue"
                  fill="hsl(197, 84%, 42%)"
                  radius={[0, 0, 0, 0]}
                />
                <Bar
                  dataKey="adhocRevenue"
                  name="Adhoc Revenue"
                  stackId="revenue"
                  fill="hsl(25, 95%, 53%)"
                  radius={[4, 4, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

      {/* Bottom Lists Section */}
      <div className="space-y-6">
        {/* Livery Customers Arrival */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg" data-testid="text-arrival-title">
              Livery Customers Arrival — {formatMonthLabel(selectedMonth)}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loadingNew ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">Loading...</div>
            ) : arrivalRows.length === 0 ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">No new arrivals this month</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm" data-testid="table-arrivals">
                  <thead>
                    <tr className="border-b bg-muted/50">
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Customer</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Horse Name</th>
                      <th className="text-center py-2.5 px-4 font-semibold">No. of Horses</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Arrival Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Departure Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Package</th>
                    </tr>
                  </thead>
                  <tbody>
                    {arrivalRows.map((row: any, idx: number) => (
                      <tr key={idx} className="border-b last:border-b-0 hover:bg-muted/30" data-testid={`row-arrival-${idx}`}>
                        <td className="py-2.5 px-4 font-medium">{row.customerName}</td>
                        <td className="py-2.5 px-4">{row.horseName}</td>
                        <td className="py-2.5 px-4 text-center">{row.horseCount}</td>
                        <td className="py-2.5 px-4">{formatDate(row.arrivalDate)}</td>
                        <td className="py-2.5 px-4">{row.departureDate ? formatDate(row.departureDate) : "-"}</td>
                        <td className="py-2.5 px-4">{row.liveryPackage}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Livery Customers Departure */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg" data-testid="text-departure-title">
              Livery Customers Departure — {formatMonthLabel(selectedMonth)}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loadingDeparted ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">Loading...</div>
            ) : departureRows.length === 0 ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">No departures this month</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm" data-testid="table-departures">
                  <thead>
                    <tr className="border-b bg-muted/50">
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Customer</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Horse Name</th>
                      <th className="text-center py-2.5 px-4 font-semibold">No. of Horses</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Arrival Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Departure Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Package</th>
                    </tr>
                  </thead>
                  <tbody>
                    {departureRows.map((row: any, idx: number) => (
                      <tr key={idx} className="border-b last:border-b-0 hover:bg-muted/30" data-testid={`row-departure-${idx}`}>
                        <td className="py-2.5 px-4 font-medium">{row.customerName}</td>
                        <td className="py-2.5 px-4">{row.horseName}</td>
                        <td className="py-2.5 px-4 text-center">{row.horseCount}</td>
                        <td className="py-2.5 px-4">-</td>
                        <td className="py-2.5 px-4">{formatDate(row.departureDate)}</td>
                        <td className="py-2.5 px-4">-</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        {/* List of All Customers */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg" data-testid="text-all-customers-title">List of All Customers</CardTitle>
          </CardHeader>
          <CardContent>
            {loadingAllCustomers ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">Loading...</div>
            ) : customerGrouped.length === 0 ? (
              <div className="h-32 flex items-center justify-center text-muted-foreground">No active customers with agreements</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm" data-testid="table-all-customers">
                  <thead>
                    <tr className="border-b bg-muted/50">
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Customer</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Horse Name</th>
                      <th className="text-center py-2.5 px-4 font-semibold">No. of Horses</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Arrival Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Departure Date</th>
                      <th className="text-left py-2.5 px-4 font-semibold">Livery Package</th>
                    </tr>
                  </thead>
                  <tbody>
                    {customerGrouped.map((group: any, gIdx: number) => (
                      group.horses.map((h: any, hIdx: number) => (
                        <tr key={`${gIdx}-${hIdx}`} className="border-b last:border-b-0 hover:bg-muted/30" data-testid={`row-all-customer-${gIdx}-${hIdx}`}>
                          <td className="py-2.5 px-4 font-medium">{hIdx === 0 ? group.customerName : ""}</td>
                          <td className="py-2.5 px-4">{h.horseName}</td>
                          <td className="py-2.5 px-4 text-center">{hIdx === 0 ? group.horseCount : ""}</td>
                          <td className="py-2.5 px-4">{formatDate(h.arrivalDate)}</td>
                          <td className="py-2.5 px-4">{h.departureDate ? formatDate(h.departureDate) : "-"}</td>
                          <td className="py-2.5 px-4">{h.liveryPackage}</td>
                        </tr>
                      ))
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
