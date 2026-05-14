import { useState, useMemo, useCallback } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LabelList,
} from "recharts";
import {
  Calendar,
  FileDown,
  Download,
  Search,
  Users,
  ShieldCheck,
  Gauge,
  User as UserIcon,
  FileText,
  CircleDollarSign,
  Trophy,
  LogOut,
} from "lucide-react";
import { Horseshoe } from "@/components/icons/horseshoe";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

type Roster = {
  index: number;
  customerId: string;
  customerName: string;
  stable: string;
  boxId: string;
  horseName: string | null;
  breedingName: string | null;
  arrivalDate: string;
  departureDate: string | null;
  packageMonthly: number;
  tags: string[];
};

interface LiveryReport {
  month: string;
  generatedAt: string;
  operational: {
    totalCheckedIn: number;
    adecHorses: number;
    customerHorses: number;
    occupancyRate: number;
    totalCapacity: number;
    arrivalsThisMonth: number;
  };
  business: {
    activeCustomers: number;
    activeAgreements: number;
    revenueMTD: number;
    revenuePrevMonth: number;
    topCustomer: { name: string; horses: number; monthlyValue: number } | null;
  };
  revenue: { total: number; livery: number; service: number; liveryCycleDay: number };
  trends: {
    perMonth: Array<{ label: string; livery: number; service: number; mtd?: boolean }>;
    topCustomers: Array<{ label: string; livery: number; service: number }>;
    bottomCustomers: Array<{ label: string; livery: number; service: number }>;
  };
  stables: Array<{ name: string; occupied: number; capacity: number }>;
  arrivals: Roster[];
  departures: Roster[];
  roster: Roster[];
}

function pad(n: number) { return String(n).padStart(2, "0"); }
function getCurrentMonth() { const n = new Date(); return `${n.getFullYear()}-${pad(n.getMonth() + 1)}`; }
function generateMonthOptions() {
  const out: string[] = []; const now = new Date();
  for (let i = 0; i < 12; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    out.push(`${d.getFullYear()}-${pad(d.getMonth() + 1)}`);
  }
  return out;
}
function formatMonthLabel(month: string) {
  if (!month) return "";
  const [y, m] = month.split("-").map(Number);
  return new Date(y, m - 1).toLocaleString("en-US", { month: "long", year: "numeric" });
}
function formatMonthShort(month: string) {
  if (!month) return "";
  const [y, m] = month.split("-").map(Number);
  return new Date(y, m - 1).toLocaleString("en-US", { month: "short", year: "2-digit" });
}
function formatDate(s?: string | null) {
  if (!s) return "—";
  const [y, m, d] = s.split("-").map(Number);
  if (!y || !m || !d) return s;
  return new Date(y, m - 1, d).toLocaleString("en-US", { day: "numeric", month: "short", year: "numeric" });
}
function formatK(v: number) {
  if (v >= 1_000_000) return `${(v / 1_000_000).toFixed(1)}M`;
  if (v >= 1000) return `${Math.round(v / 1000)}K`;
  return String(Math.round(v));
}

import { KpiCard, BigNumber, formatAed } from "@/components/kpi-card";

const COLOR_LIVERY = "#1F9D55";
const COLOR_SERVICE = "#1E3A5F";

function ChartTooltip({ active, payload, label }: any) {
  if (!active || !payload || payload.length === 0) return null;
  const livery = payload.find((p: any) => p.dataKey === "livery")?.value || 0;
  const service = payload.find((p: any) => p.dataKey === "service")?.value || 0;
  return (
    <div className="rounded-md bg-slate-900 text-white text-[11.5px] px-3 py-2 shadow-lg">
      <div className="font-semibold mb-1">{label}</div>
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-sm" style={{ backgroundColor: COLOR_LIVERY }} /> Livery: AED {formatAed(livery)}
      </div>
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-sm" style={{ backgroundColor: COLOR_SERVICE }} /> Service: AED {formatAed(service)}
      </div>
      <div className="mt-1 pt-1 border-t border-white/20">Total: AED {formatAed(livery + service)}</div>
    </div>
  );
}

export default function ReportsPage() {
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonth());
  const [chartMode, setChartMode] = useState<"month" | "top" | "bottom">("month");
  const [search, setSearch] = useState("");
  const [rosterFilter, setRosterFilter] = useState<string>("all");
  const [downloadingPdf, setDownloadingPdf] = useState(false);

  const monthOptions = useMemo(() => generateMonthOptions(), []);

  const { data, isLoading } = useQuery<LiveryReport>({
    queryKey: ["/api/reports/livery-report", `?month=${selectedMonth}`],
  });

  const monthLabel = formatMonthLabel(selectedMonth);
  const generatedLabel = data ? formatDate(data.generatedAt.slice(0, 10)) : "—";

  // Roster filter chips and live counts
  const rosterAll = data?.roster ?? [];
  const newCount = rosterAll.filter(r => r.tags.includes("new")).length;
  const stableTagCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const r of rosterAll) {
      const tag = r.stable;
      counts[tag] = (counts[tag] || 0) + 1;
    }
    return counts;
  }, [rosterAll]);

  const filteredRoster = useMemo(() => {
    let rows = rosterAll;
    if (rosterFilter === "new") rows = rows.filter(r => r.tags.includes("new"));
    else if (rosterFilter !== "all") rows = rows.filter(r => r.stable === rosterFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      rows = rows.filter(r =>
        r.customerName.toLowerCase().includes(q) ||
        r.customerId.toLowerCase().includes(q) ||
        r.boxId.toLowerCase().includes(q) ||
        (r.horseName || "").toLowerCase().includes(q) ||
        (r.breedingName || "").toLowerCase().includes(q)
      );
    }
    return rows;
  }, [rosterAll, rosterFilter, search]);

  // Chart data based on mode
  const chartData = useMemo(() => {
    if (!data) return [];
    if (chartMode === "month") {
      return data.trends.perMonth.map(p => ({
        ...p,
        displayLabel: formatMonthShort(p.label) + (p.mtd ? " MTD" : ""),
      }));
    }
    const arr = chartMode === "top" ? data.trends.topCustomers : data.trends.bottomCustomers;
    return arr.map(p => ({ ...p, displayLabel: p.label }));
  }, [data, chartMode]);

  const chartTotals = useMemo(
    () => chartData.map((d: any) => ({ ...d, _total: (d.livery || 0) + (d.service || 0) })),
    [chartData]
  );

  // CSV download for roster
  const downloadRosterCsv = useCallback(() => {
    const header = ["#", "Customer ID", "Customer", "Stable", "Box", "Horse", "Breeding", "Arrival", "Departure", "Package (AED/mo)"];
    const rows = filteredRoster.map((r, i) => [
      String(i + 1),
      r.customerId,
      r.customerName,
      r.stable,
      r.boxId,
      r.horseName || "",
      r.breedingName || "",
      r.arrivalDate || "",
      r.departureDate || "",
      String(r.packageMonthly),
    ]);
    const csv = [header, ...rows]
      .map(line => line.map(c => `"${String(c).replace(/"/g, '""')}"`).join(","))
      .join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `livery-roster-${selectedMonth}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }, [filteredRoster, selectedMonth]);

  // PDF download for roster only
  const downloadRosterPdf = useCallback(() => {
    const pdf = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
    pdf.setFontSize(14);
    pdf.setFont("helvetica", "bold");
    pdf.text(`Customer Roster — ${monthLabel}`, 15, 15);
    autoTable(pdf, {
      startY: 22,
      head: [["#", "Customer ID", "Customer", "Box", "Horse", "Arrival", "Departure", "Package /mo"]],
      body: filteredRoster.map((r, i) => [
        String(i + 1),
        r.customerId,
        r.customerName,
        r.boxId,
        r.horseName ? `${r.horseName}${r.breedingName ? ` (${r.breedingName})` : ""}` : "—",
        formatDate(r.arrivalDate),
        formatDate(r.departureDate),
        `AED ${formatAed(r.packageMonthly)}`,
      ]),
      headStyles: { fillColor: [31, 157, 85], textColor: 255, fontStyle: "bold", fontSize: 9 },
      alternateRowStyles: { fillColor: [240, 249, 240] },
      styles: { fontSize: 9 },
      margin: { left: 15, right: 15 },
    });
    pdf.save(`livery-roster-${selectedMonth}.pdf`);
  }, [filteredRoster, selectedMonth, monthLabel]);

  // Full report PDF — server renders the print-ready HTML to PDF via headless
  // Chromium and streams it back as a direct download (no print dialog).
  const downloadFullPdf = useCallback(async () => {
    if (!selectedMonth) return;
    setDownloadingPdf(true);
    try {
      const res = await fetch(
        `/api/reports/livery-report.pdf?month=${encodeURIComponent(selectedMonth)}`,
        { credentials: "include" }
      );
      if (!res.ok) {
        let msg = "Failed to generate PDF";
        let fallbackUrl: string | undefined;
        try {
          const j = await res.json();
          if (j?.message) msg = j.message;
          if (j?.fallbackUrl) fallbackUrl = j.fallbackUrl;
        } catch {}
        if (fallbackUrl) {
          window.open(fallbackUrl, "_blank", "noopener,noreferrer");
          return;
        }
        throw new Error(msg);
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `livery-report-${selectedMonth}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("PDF download failed:", err);
      alert(err instanceof Error ? err.message : "Failed to generate PDF");
    } finally {
      setDownloadingPdf(false);
    }
  }, [selectedMonth]);

  // Legacy jsPDF full report (no longer wired) — keep stub to satisfy imports
  const _legacyDownloadFullPdf = useCallback(async () => {
    if (!data) return;
    setDownloadingPdf(true);
    try {
      const pdf = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
      const pw = pdf.internal.pageSize.getWidth();

      pdf.setFontSize(20);
      pdf.setFont("helvetica", "bold");
      pdf.text("Livery Report", pw / 2, 18, { align: "center" });
      pdf.setFontSize(12);
      pdf.setFont("helvetica", "normal");
      pdf.setTextColor(31, 157, 85);
      pdf.text(monthLabel, pw / 2, 26, { align: "center" });
      pdf.setTextColor(0);

      const kpiRow1 = [
        ["Total Checked-In", String(data.operational.totalCheckedIn)],
        ["ADEC Horses", String(data.operational.adecHorses)],
        ["Customer Horses", String(data.operational.customerHorses)],
        ["Occupancy", `${data.operational.occupancyRate}%`],
      ];
      const kpiRow2 = [
        ["Active Customers", String(data.business.activeCustomers)],
        ["Active Agreements", String(data.business.activeAgreements)],
        ["Revenue MTD", `AED ${formatAed(data.business.revenueMTD)}`],
        ["Top Customer", data.business.topCustomer ? `${data.business.topCustomer.name} (AED ${formatAed(data.business.topCustomer.monthlyValue)}/mo)` : "—"],
      ];
      const drawKpiRow = (cards: string[][], y: number) => {
        const w = (pw - 30) / 4;
        cards.forEach((c, i) => {
          const x = 15 + i * w;
          pdf.setFillColor(248, 250, 252);
          pdf.roundedRect(x, y, w - 4, 22, 2, 2, "F");
          pdf.setFontSize(8);
          pdf.setTextColor(107, 114, 128);
          pdf.text(c[0], x + 3, y + 7);
          pdf.setFontSize(11);
          pdf.setTextColor(17, 24, 39);
          pdf.setFont("helvetica", "bold");
          pdf.text(c[1].length > 38 ? c[1].slice(0, 35) + "..." : c[1], x + 3, y + 16);
          pdf.setFont("helvetica", "normal");
        });
      };
      drawKpiRow(kpiRow1, 35);
      drawKpiRow(kpiRow2, 62);

      pdf.setTextColor(0);
      pdf.setFontSize(10);
      pdf.text(`Total Revenue: AED ${formatAed(data.revenue.total)}    Livery: AED ${formatAed(data.revenue.livery)}    Service: AED ${formatAed(data.revenue.service)}`, 15, 92);

      // Roster table
      pdf.addPage();
      pdf.setFontSize(14);
      pdf.setFont("helvetica", "bold");
      pdf.text(`Customer Roster — ${monthLabel}`, 15, 15);
      autoTable(pdf, {
        startY: 22,
        head: [["#", "Customer", "Box", "Horse", "Arrival", "Departure", "Package /mo"]],
        body: data.roster.map((r, i) => [
          String(i + 1),
          r.customerName,
          r.boxId,
          r.horseName || "—",
          formatDate(r.arrivalDate),
          formatDate(r.departureDate),
          `AED ${formatAed(r.packageMonthly)}`,
        ]),
        headStyles: { fillColor: [31, 157, 85], textColor: 255, fontStyle: "bold", fontSize: 9 },
        alternateRowStyles: { fillColor: [240, 249, 240] },
        styles: { fontSize: 9 },
        margin: { left: 15, right: 15 },
      });

      if (data.arrivals.length > 0) {
        pdf.addPage();
        pdf.setFontSize(14);
        pdf.text(`Arrivals — ${monthLabel}`, 15, 15);
        autoTable(pdf, {
          startY: 22,
          head: [["#", "Customer", "Horse", "Box", "Arrival", "Package /mo"]],
          body: data.arrivals.map((r, i) => [
            String(i + 1), r.customerName, r.horseName || "—", r.boxId, formatDate(r.arrivalDate), `AED ${formatAed(r.packageMonthly)}`,
          ]),
          headStyles: { fillColor: [31, 157, 85], textColor: 255, fontStyle: "bold", fontSize: 9 },
          alternateRowStyles: { fillColor: [240, 249, 240] },
          styles: { fontSize: 9 },
          margin: { left: 15, right: 15 },
        });
      }

      if (data.departures.length > 0) {
        pdf.addPage();
        pdf.setFontSize(14);
        pdf.text(`Departures — ${monthLabel}`, 15, 15);
        autoTable(pdf, {
          startY: 22,
          head: [["#", "Customer", "Horse", "Box", "Departure", "Package /mo"]],
          body: data.departures.map((r, i) => [
            String(i + 1), r.customerName, r.horseName || "—", r.boxId, formatDate(r.departureDate), `AED ${formatAed(r.packageMonthly)}`,
          ]),
          headStyles: { fillColor: [31, 157, 85], textColor: 255, fontStyle: "bold", fontSize: 9 },
          alternateRowStyles: { fillColor: [240, 249, 240] },
          styles: { fontSize: 9 },
          margin: { left: 15, right: 15 },
        });
      }

      pdf.save(`livery-report-${selectedMonth}.pdf`);
    } finally {
      setDownloadingPdf(false);
    }
  }, [data, monthLabel, selectedMonth]);

  const op = data?.operational;
  const biz = data?.business;
  const rev = data?.revenue;

  const adecPct = op && op.totalCheckedIn > 0 ? (op.adecHorses / op.totalCheckedIn) * 100 : 0;

  return (
    <div className="p-6 space-y-6">
      <PageHeader
        title="Livery Report"
        description={`Operational and business performance for ${monthLabel}`}
        actions={
          <div className="flex items-center gap-2">
            <Button onClick={downloadFullPdf} disabled={downloadingPdf || isLoading} data-testid="button-download-full-pdf">
              <FileDown className="w-4 h-4 mr-2" />
              {downloadingPdf ? "Generating..." : "Download Complete Report (PDF)"}
            </Button>
          </div>
        }
      />

      {/* Month picker + Generated pill */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full border bg-card">
          <Calendar className="w-4 h-4 text-muted-foreground" />
          <Select value={selectedMonth} onValueChange={setSelectedMonth}>
            <SelectTrigger className="w-44 h-7 border-0 shadow-none px-0" data-testid="select-month">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {monthOptions.map(m => (
                <SelectItem key={m} value={m}>{formatMonthLabel(m)}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="text-xs px-3 py-1.5 rounded-full border bg-card text-muted-foreground" data-testid="text-generated">
          Generated {generatedLabel}
        </div>
      </div>

      {/* Operational Overview */}
      <section className="space-y-3">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Operational Overview</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <KpiCard
            label="Total Checked-In Horses"
            icon={<Horseshoe className="w-5 h-5" />}
            iconColor="text-emerald-700"
            iconBg="bg-emerald-50"
            testId="card-total-checkedin"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={op?.totalCheckedIn ?? 0} testId="text-total-checkedin" />
                <div className="mt-3">
                  <div className="h-1.5 rounded-full overflow-hidden bg-muted flex">
                    <div className="h-full" style={{ width: `${adecPct}%`, backgroundColor: COLOR_SERVICE }} />
                    <div className="h-full" style={{ width: `${100 - adecPct}%`, backgroundColor: COLOR_LIVERY }} />
                  </div>
                  <div className="mt-2 flex items-center gap-3 text-[11.5px] text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <span className="w-2 h-2 rounded-sm" style={{ backgroundColor: COLOR_SERVICE }} />
                      ADEC {op?.adecHorses ?? 0}
                    </span>
                    <span className="flex items-center gap-1">
                      <span className="w-2 h-2 rounded-sm" style={{ backgroundColor: COLOR_LIVERY }} />
                      Customer {op?.customerHorses ?? 0}
                    </span>
                  </div>
                </div>
              </>
            )}
          </KpiCard>

          <KpiCard
            label="ADEC Horses (On-Site)"
            icon={<ShieldCheck className="w-5 h-5" />}
            iconColor="text-slate-700"
            iconBg="bg-slate-100"
            testId="card-adec-horses"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={op?.adecHorses ?? 0} testId="text-adec-horses" />
              </>
            )}
          </KpiCard>

          <KpiCard
            label="Customer Livery Horses"
            icon={<Users className="w-5 h-5" />}
            iconColor="text-emerald-700"
            iconBg="bg-emerald-50"
            testId="card-customer-horses"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={op?.customerHorses ?? 0} testId="text-customer-horses" />
                <div className="mt-3 text-[12.5px] text-muted-foreground">
                  {op?.arrivalsThisMonth ?? 0} new arrival{(op?.arrivalsThisMonth ?? 0) === 1 ? "" : "s"} this month
                </div>
              </>
            )}
          </KpiCard>

          <KpiCard
            label="Occupancy Rate"
            icon={<Gauge className="w-5 h-5" />}
            iconColor="text-purple-700"
            iconBg="bg-purple-50"
            testId="card-occupancy"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={`${op?.occupancyRate ?? 0}%`} testId="text-occupancy" />
                <div className="mt-3">
                  <Progress value={Math.min(op?.occupancyRate ?? 0, 100)} className="h-1.5" />
                  <div className="mt-2 text-[12.5px] text-muted-foreground">
                    {op?.totalCheckedIn ?? 0} / {op?.totalCapacity ?? 0} boxes occupied
                  </div>
                </div>
              </>
            )}
          </KpiCard>
        </div>
      </section>

      {/* Business Performance */}
      <section className="space-y-3">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Business Performance</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <KpiCard
            label="Active Livery Customers"
            icon={<UserIcon className="w-5 h-5" />}
            iconColor="text-emerald-700"
            iconBg="bg-emerald-50"
            testId="card-active-customers"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={biz?.activeCustomers ?? 0} testId="text-active-customers" />
              </>
            )}
          </KpiCard>

          <KpiCard
            label="Active Livery Agreements"
            icon={<FileText className="w-5 h-5" />}
            iconColor="text-orange-700"
            iconBg="bg-orange-50"
            testId="card-active-agreements"
          >
            {isLoading ? <Skeleton className="h-9 w-16" /> : (
              <>
                <BigNumber value={biz?.activeAgreements ?? 0} testId="text-active-agreements" />
              </>
            )}
          </KpiCard>

          <KpiCard
            label="Monthly Revenue (MTD)"
            icon={<CircleDollarSign className="w-5 h-5" />}
            iconColor="text-purple-700"
            iconBg="bg-purple-50"
            testId="card-revenue-mtd"
          >
            {isLoading ? <Skeleton className="h-9 w-32" /> : (
              <>
                <div className="flex items-baseline gap-1.5">
                  <span className="text-[13px] text-muted-foreground">AED</span>
                  <span className="text-[28px] leading-none font-bold tabular-nums tracking-tight" data-testid="text-revenue-mtd">
                    {formatAed(biz?.revenueMTD ?? 0)}
                  </span>
                </div>
                <div className="mt-3 flex items-center justify-end gap-2 text-[11.5px]">
                  <span className="font-medium text-foreground" data-testid="text-prev-month-revenue">
                    Prev month: AED {formatAed(biz?.revenuePrevMonth ?? 0)}
                  </span>
                </div>
              </>
            )}
          </KpiCard>

          <KpiCard
            label="Top Customer (This Month)"
            icon={<Trophy className="w-5 h-5" />}
            iconColor="text-orange-700"
            iconBg="bg-orange-50"
            testId="card-top-customer"
          >
            {isLoading ? <Skeleton className="h-9 w-32" /> : biz?.topCustomer ? (
              <>
                <div className="text-[18px] font-bold leading-tight" data-testid="text-top-customer-name">
                  {biz.topCustomer.name}
                </div>
                <div className="mt-1.5 text-[12.5px] text-muted-foreground" data-testid="text-top-customer-detail">
                  {biz.topCustomer.horses} horse{biz.topCustomer.horses === 1 ? "" : "s"} · AED {formatAed(biz.topCustomer.monthlyValue)} / mo
                </div>
              </>
            ) : (
              <div className="text-sm text-muted-foreground">No active customer</div>
            )}
          </KpiCard>
        </div>
      </section>

      {/* Revenue & Movement */}
      <section className="space-y-3">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Revenue & Movement</h2>

        {/* Revenue Breakdown */}
        <Card>
          <CardContent className="p-0">
            <div className="grid grid-cols-1 md:grid-cols-3 divide-y md:divide-y-0 md:divide-x">
              {[
                { label: "Total Revenue", value: rev?.total ?? 0, note: "", testId: "text-rev-total" },
                { label: "Livery Revenue", value: rev?.livery ?? 0, note: "Livery package", testId: "text-rev-livery" },
                { label: "Service Revenue", value: rev?.service ?? 0, note: "Clinic, Farrier, Stores & Extras", testId: "text-rev-service" },
              ].map((c) => (
                <div key={c.label} className="p-5">
                  <div className="text-[13px] text-muted-foreground font-medium">{c.label}</div>
                  <div className="mt-2 flex items-baseline gap-1.5">
                    <span className="text-[13px] text-muted-foreground">AED</span>
                    {isLoading ? <Skeleton className="h-7 w-24" /> : (
                      <span className="text-[28px] leading-none font-bold tabular-nums tracking-tight" data-testid={c.testId}>
                        {formatAed(c.value)}
                      </span>
                    )}
                  </div>
                  <div className="mt-2 text-[12px] text-muted-foreground">{c.note}</div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Revenue Trend chart */}
        <Card>
          <CardHeader className="pb-2">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <CardTitle className="text-base">Revenue Trend</CardTitle>
                <div className="text-[12px] text-muted-foreground mt-0.5">Stacked: Livery + Service</div>
              </div>
              <div className="flex items-center gap-3">
                <div className="inline-flex rounded-md border p-0.5 bg-muted/30">
                  {[
                    { k: "month", label: "Per Month · Last 12" },
                    { k: "top", label: "Top 10 Customers" },
                    { k: "bottom", label: "Bottom 10 Customers" },
                  ].map(o => (
                    <button
                      key={o.k}
                      onClick={() => setChartMode(o.k as any)}
                      className={`px-3 py-1 text-[12px] rounded ${chartMode === o.k ? "bg-background shadow-sm font-medium" : "text-muted-foreground"}`}
                      data-testid={`chart-mode-${o.k}`}
                    >
                      {o.label}
                    </button>
                  ))}
                </div>
                <div className="hidden md:flex items-center gap-3 text-[12px] text-muted-foreground">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: COLOR_LIVERY }} /> Livery
                  </span>
                  <span className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: COLOR_SERVICE }} /> Service
                  </span>
                </div>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-80 w-full" />
            ) : chartTotals.length === 0 ? (
              <div className="h-80 flex items-center justify-center text-muted-foreground">No data</div>
            ) : (
              <ResponsiveContainer width="100%" height={340}>
                <BarChart data={chartTotals} margin={{ top: 28, right: 16, left: 8, bottom: chartMode === "month" ? 8 : 70 }} barCategoryGap="28%">
                  <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
                  <XAxis
                    dataKey="displayLabel"
                    tick={{ fontSize: 11, fill: "#6B7280" }}
                    angle={chartMode === "month" ? 0 : -22}
                    textAnchor={chartMode === "month" ? "middle" : "end"}
                    interval={0}
                    height={chartMode === "month" ? 30 : 80}
                  />
                  <YAxis tick={{ fontSize: 11, fill: "#6B7280" }} tickFormatter={(v) => formatK(v)} width={50} />
                  <Tooltip cursor={{ fill: "rgba(31,157,85,0.06)" }} content={<ChartTooltip />} />
                  <Bar dataKey="livery" stackId="a" fill={COLOR_LIVERY} radius={[0, 0, 0, 0]} />
                  <Bar dataKey="service" stackId="a" fill={COLOR_SERVICE} radius={[3, 3, 0, 0]}>
                    <LabelList
                      dataKey="_total"
                      position="top"
                      offset={6}
                      formatter={(v: number, _entry: any, _idx?: number) => v > 0 ? formatK(v) : ""}
                      style={{ fontSize: 11, fill: "#374151", fontWeight: 600 }}
                    />
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      </section>

      {/* Customer Roster */}
      <section className="space-y-3">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Customer Roster</h2>

        {/* Arrivals + Departures */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <Card data-testid="card-arrivals">
            <CardHeader className="pb-2">
              <div className="flex items-baseline justify-between">
                <CardTitle className="text-base">Arrivals — {monthLabel}</CardTitle>
                <span className="text-[12px] text-muted-foreground">{data?.arrivals.length ?? 0} check-ins</span>
              </div>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="space-y-2">{Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-14 w-full" />)}</div>
              ) : (data?.arrivals.length ?? 0) === 0 ? (
                <div className="text-sm text-muted-foreground py-6 text-center">No arrivals this month.</div>
              ) : (
                <div className="space-y-2">
                  {data!.arrivals.map(r => (
                    <div key={`${r.index}-${r.customerId}`} className="flex items-center justify-between gap-3 p-2 rounded-md hover:bg-muted/40">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-10 h-10 rounded-md bg-emerald-600 flex items-center justify-center shrink-0">
                          <Horseshoe className="w-5 h-5" inverted />
                        </div>
                        <div className="min-w-0">
                          <div className="text-[14px] font-bold text-slate-800 truncate">
                            {(r.horseName || "—").toUpperCase()}
                            {r.breedingName && r.breedingName !== r.horseName && (
                              <span className="font-normal text-muted-foreground"> ({r.breedingName.toUpperCase()})</span>
                            )}
                          </div>
                          <div className="text-[12.5px] text-muted-foreground flex items-center gap-2 flex-wrap">
                            <span className="truncate">{r.customerId} {r.customerName}</span>
                            <Badge variant="outline" className="text-emerald-700 border-emerald-200 bg-emerald-50 text-[10px] px-1.5 py-0">
                              New · {formatDate(r.arrivalDate)}
                            </Badge>
                          </div>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-[13px] font-medium tabular-nums">AED {formatAed(r.packageMonthly)}/mo</div>
                        <div className="text-[11px] text-muted-foreground">{r.boxId}</div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          <Card data-testid="card-departures">
            <CardHeader className="pb-2">
              <div className="flex items-baseline justify-between">
                <CardTitle className="text-base">Departures — {monthLabel}</CardTitle>
                <span className="text-[12px] text-muted-foreground">{data?.departures.length ?? 0} check-outs</span>
              </div>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="space-y-2">{Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-14 w-full" />)}</div>
              ) : (data?.departures.length ?? 0) === 0 ? (
                <div className="py-8 flex flex-col items-center gap-2 text-muted-foreground">
                  <div className="w-12 h-12 rounded-md bg-muted flex items-center justify-center">
                    <LogOut className="w-5 h-5" />
                  </div>
                  <div className="text-sm">No departures recorded this month.</div>
                </div>
              ) : (
                <div className="space-y-2">
                  {data!.departures.map(r => (
                    <div key={`${r.index}-${r.customerId}`} className="flex items-center justify-between gap-3 p-2 rounded-md hover:bg-muted/40">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-10 h-10 rounded-md bg-emerald-600 flex items-center justify-center shrink-0">
                          <Horseshoe className="w-5 h-5" inverted />
                        </div>
                        <div className="min-w-0">
                          <div className="text-[14px] font-bold text-slate-800 truncate">
                            {(r.horseName || "—").toUpperCase()}
                          </div>
                          <div className="text-[12.5px] text-muted-foreground truncate">
                            {r.customerId} {r.customerName}
                          </div>
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-[13px] font-medium tabular-nums">AED {formatAed(r.packageMonthly)}/mo</div>
                        <div className="text-[11px] text-muted-foreground">{formatDate(r.departureDate)}</div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Roster table */}
        <Card>
          <CardContent className="p-4">
            <div className="flex flex-wrap items-center gap-3 mb-4">
              <div className="relative flex-1 min-w-[240px] max-w-[320px]">
                <Search className="w-4 h-4 absolute left-2.5 top-1/2 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search customer, horse or box..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="pl-8 h-9"
                  data-testid="input-roster-search"
                />
              </div>
              <div className="inline-flex rounded-md border p-0.5 bg-muted/30 flex-wrap">
                <button
                  onClick={() => setRosterFilter("all")}
                  className={`px-3 py-1 text-[12px] rounded ${rosterFilter === "all" ? "bg-background shadow-sm font-medium" : "text-muted-foreground"}`}
                  data-testid="filter-all"
                >
                  All ({rosterAll.length})
                </button>
                {(data?.stables ?? []).map(s => (
                  <button
                    key={s.name}
                    onClick={() => setRosterFilter(s.name)}
                    className={`px-3 py-1 text-[12px] rounded ${rosterFilter === s.name ? "bg-background shadow-sm font-medium" : "text-muted-foreground"}`}
                    data-testid={`filter-stable-${s.name}`}
                  >
                    {s.name} ({stableTagCounts[s.name] || 0})
                  </button>
                ))}
              </div>
              <div className="ml-auto flex items-center gap-2">
                <Button variant="outline" size="sm" onClick={downloadRosterCsv} data-testid="button-roster-csv">
                  <Download className="w-4 h-4 mr-1.5" /> CSV
                </Button>
                <Button variant="outline" size="sm" onClick={downloadRosterPdf} data-testid="button-roster-pdf">
                  <Download className="w-4 h-4 mr-1.5" /> PDF
                </Button>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-[13px] border-collapse">
                <thead>
                  <tr className="border-b text-muted-foreground text-[11.5px] uppercase tracking-wide">
                    <th className="text-left py-2 px-2 w-10">#</th>
                    <th className="text-left py-2 px-2">Customer</th>
                    <th className="text-left py-2 px-2">Box</th>
                    <th className="text-left py-2 px-2">Horse</th>
                    <th className="text-left py-2 px-2 whitespace-nowrap">Arrival</th>
                    <th className="text-left py-2 px-2 whitespace-nowrap">Departure</th>
                    <th className="text-right py-2 px-2 whitespace-nowrap">Package</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRoster.length === 0 ? (
                    <tr><td colSpan={7} className="text-center py-8 text-muted-foreground">No matching agreements</td></tr>
                  ) : filteredRoster.map((r, i) => (
                    <tr key={`${r.index}-${r.customerId}`} className="border-b hover:bg-muted/30" data-testid={`row-roster-${i}`}>
                      <td className="py-2.5 px-2 text-muted-foreground tabular-nums">{i + 1}</td>
                      <td className="py-2.5 px-2">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded bg-emerald-50 flex items-center justify-center shrink-0">
                            <Horseshoe className="w-4 h-4 text-emerald-700" />
                          </div>
                          <div className="min-w-0">
                            <div className="font-semibold text-slate-800 flex items-center gap-1.5">
                              <span className="truncate">{r.customerName}</span>
                              {r.tags.includes("new") && (
                                <Badge variant="outline" className="text-emerald-700 border-emerald-200 bg-emerald-50 text-[10px] px-1 py-0">New</Badge>
                              )}
                            </div>
                            <div className="text-[11.5px] text-muted-foreground">{r.customerId}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-2.5 px-2">
                        <div className="text-foreground">{r.stable}</div>
                        <div className="text-[11.5px] text-muted-foreground">{r.boxId}</div>
                      </td>
                      <td className="py-2.5 px-2">
                        <div className="font-medium">{r.horseName || "—"}</div>
                        {r.breedingName && r.breedingName !== r.horseName && (
                          <div className="text-[11.5px] italic text-muted-foreground">{r.breedingName}</div>
                        )}
                      </td>
                      <td className="py-2.5 px-2 text-muted-foreground whitespace-nowrap">{formatDate(r.arrivalDate)}</td>
                      <td className="py-2.5 px-2 text-muted-foreground whitespace-nowrap">{r.departureDate ? formatDate(r.departureDate) : "—"}</td>
                      <td className="py-2.5 px-2 text-right whitespace-nowrap">
                        <span className="font-semibold tabular-nums">AED {formatAed(r.packageMonthly)}</span>
                        <span className="text-[11.5px] text-muted-foreground"> /mo</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="mt-3 flex items-center justify-between text-[12px] text-muted-foreground">
              <span data-testid="text-roster-count">Showing {filteredRoster.length} of {rosterAll.length} agreements</span>
              <span>Source: Livery Report · {monthLabel}</span>
            </div>
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
