import { useState, useMemo, useRef, useCallback } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from "recharts";
import { Download } from "lucide-react";
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import html2canvas from "html2canvas";

function formatMonthLabel(month: string) {
  if (!month) return "";
  const [y, m] = month.split("-").map(Number);
  const date = new Date(y, m - 1);
  return date.toLocaleString("en-US", { month: "long", year: "numeric" });
}

function formatDate(dateStr: string) {
  if (!dateStr) return "";
  const [y, m, d] = dateStr.split("-").map(Number);
  const date = new Date(y, m - 1, d);
  const day = date.getDate();
  const suffix = day === 1 || day === 21 || day === 31 ? "st" : day === 2 || day === 22 ? "nd" : day === 3 || day === 23 ? "rd" : "th";
  return `${day}${suffix} ${date.toLocaleString("en-US", { month: "long", year: "numeric" })}`;
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

export default function ReportsPage() {
  const [groupBy, setGroupBy] = useState("month");
  const [metric, setMetric] = useState("totalRevenue");
  const [detailReport, setDetailReport] = useState("new_livery");
  const [selectedMonth, setSelectedMonth] = useState(getCurrentMonth());
  const [downloadingChart, setDownloadingChart] = useState(false);
  const [downloadingDetail, setDownloadingDetail] = useState(false);
  const chartRef = useRef<HTMLDivElement>(null);

  const { data: reportData = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/reports/livery", `?groupBy=${groupBy}`],
  });

  const { data: newLiveryData = [], isLoading: loadingNew } = useQuery<any[]>({
    queryKey: ["/api/reports/new-livery-horses", `?month=${selectedMonth}`],
    enabled: detailReport === "new_livery",
  });

  const { data: departedData = [], isLoading: loadingDeparted } = useQuery<any[]>({
    queryKey: ["/api/reports/departed-livery-horses", `?month=${selectedMonth}`],
    enabled: detailReport === "departed",
  });

  const { data: customersInfoData = [], isLoading: loadingCustomers } = useQuery<any[]>({
    queryKey: ["/api/reports/livery-customers-info"],
    enabled: detailReport === "customers_info",
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

  const monthOptions = useMemo(() => generateMonthOptions(), []);
  const showMonthFilter = detailReport === "new_livery" || detailReport === "departed";

  const downloadChartPdf = useCallback(async () => {
    if (!chartRef.current) return;
    setDownloadingChart(true);
    try {
      const canvas = await html2canvas(chartRef.current, {
        scale: 2,
        backgroundColor: "#ffffff",
        useCORS: true,
      });
      const imgData = canvas.toDataURL("image/png");
      const pdf = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.text("StableMaster - Livery Report", pageWidth / 2, 15, { align: "center" });

      pdf.setFontSize(11);
      pdf.setFont("helvetica", "normal");
      const subtitle = `${metricLabels[metric]} by ${groupBy === "month" ? "Month" : "Customer"}`;
      pdf.text(subtitle, pageWidth / 2, 22, { align: "center" });

      const imgWidth = pageWidth - 30;
      const imgHeight = (canvas.height / canvas.width) * imgWidth;
      const maxHeight = pageHeight - 40;
      const finalHeight = Math.min(imgHeight, maxHeight);
      const finalWidth = imgHeight > maxHeight ? (canvas.width / canvas.height) * finalHeight : imgWidth;
      const xOffset = (pageWidth - finalWidth) / 2;

      pdf.addImage(imgData, "PNG", xOffset, 28, finalWidth, finalHeight);

      pdf.setFontSize(8);
      pdf.setTextColor(128);
      pdf.text(`Generated on ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}`, pageWidth / 2, pageHeight - 5, { align: "center" });

      pdf.save(`livery-chart-${groupBy}-${metric}.pdf`);
    } finally {
      setDownloadingChart(false);
    }
  }, [groupBy, metric]);

  const addDetailFooter = (pdf: jsPDF, pageWidth: number, pageHeight: number) => {
    pdf.setFontSize(8);
    pdf.setTextColor(128);
    pdf.text(`Generated on ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}`, pageWidth / 2, pageHeight - 5, { align: "center" });
    pdf.setTextColor(0);
  };

  const downloadDetailPdf = useCallback(() => {
    setDownloadingDetail(true);
    try {
      const pdf = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
      const pageWidth = pdf.internal.pageSize.getWidth();
      const pageHeight = pdf.internal.pageSize.getHeight();

      pdf.setFontSize(16);
      pdf.setFont("helvetica", "bold");
      pdf.text("StableMaster", pageWidth / 2, 15, { align: "center" });

      if (detailReport === "new_livery") {
        const title = `New Livery Horses - ${formatMonthLabel(selectedMonth)}`;
        pdf.setFontSize(13);
        pdf.text(title, pageWidth / 2, 23, { align: "center" });

        if (newLiveryData.length === 0) {
          pdf.setFontSize(11);
          pdf.setFont("helvetica", "normal");
          pdf.text("No new livery horses for this month", pageWidth / 2, 40, { align: "center" });
        } else {
          const rows: any[][] = [];
          newLiveryData.forEach((group: any, idx: number) => {
            group.horses.forEach((h: any, i: number) => {
              rows.push([
                i === 0 ? String(idx + 1) : "",
                i === 0 ? group.customerName : "",
                h.horseName,
                i === 0 ? String(group.horseCount) : "",
                formatDate(h.arrivalDate),
                `${parseFloat(h.liveryPrice).toLocaleString()} AED`,
              ]);
            });
          });

          autoTable(pdf, {
            startY: 28,
            head: [["#", "Name of Owner", "Name of Livery Horse", "No. of Horses", "Arrival Date", "Livery Price"]],
            body: rows,
            headStyles: { fillColor: [41, 128, 185], textColor: 255, fontStyle: "bold", fontSize: 9 },
            bodyStyles: { fontSize: 9 },
            alternateRowStyles: { fillColor: [245, 245, 245] },
            columnStyles: {
              0: { cellWidth: 12, halign: "center" },
              3: { halign: "center" },
              5: { halign: "right" },
            },
            margin: { left: 15, right: 15 },
          });
        }

        addDetailFooter(pdf, pageWidth, pageHeight);
        pdf.save(`new-livery-horses-${selectedMonth}.pdf`);
      } else if (detailReport === "departed") {
        const title = `Departure of Livery Horses - ${formatMonthLabel(selectedMonth)}`;
        pdf.setFontSize(13);
        pdf.text(title, pageWidth / 2, 23, { align: "center" });

        if (departedData.length === 0) {
          pdf.setFontSize(11);
          pdf.setFont("helvetica", "normal");
          pdf.text("No departures for this month", pageWidth / 2, 40, { align: "center" });
        } else {
          const rows: any[][] = [];
          departedData.forEach((group: any, idx: number) => {
            group.horses.forEach((h: any, i: number) => {
              rows.push([
                i === 0 ? String(idx + 1) : "",
                i === 0 ? group.customerName : "",
                h.horseName,
                i === 0 ? String(group.horseCount) : "",
                formatDate(h.departureDate),
                h.checkoutReason || "—",
              ]);
            });
          });

          autoTable(pdf, {
            startY: 28,
            head: [["#", "Name of Owner", "Name of Livery Horse", "No. of Horses", "Departure Date", "Reason"]],
            body: rows,
            headStyles: { fillColor: [41, 128, 185], textColor: 255, fontStyle: "bold", fontSize: 9 },
            bodyStyles: { fontSize: 9 },
            alternateRowStyles: { fillColor: [245, 245, 245] },
            columnStyles: {
              0: { cellWidth: 12, halign: "center" },
              3: { halign: "center" },
            },
            margin: { left: 15, right: 15 },
          });
        }

        addDetailFooter(pdf, pageWidth, pageHeight);
        pdf.save(`departed-livery-horses-${selectedMonth}.pdf`);
      } else if (detailReport === "customers_info") {
        const title = "Livery Customers - Information File";
        pdf.setFontSize(13);
        pdf.text(title, pageWidth / 2, 23, { align: "center" });

        if (customersInfoData.length === 0) {
          pdf.setFontSize(11);
          pdf.setFont("helvetica", "normal");
          pdf.text("No livery customers found", pageWidth / 2, 40, { align: "center" });
        } else {
          const rows: any[][] = [];
          customersInfoData.forEach((group: any, idx: number) => {
            group.horses.forEach((h: any, i: number) => {
              rows.push([
                i === 0 ? String(idx + 1) : "",
                i === 0 ? group.customerName : "",
                i === 0 ? String(group.horseCount) : "",
                h.horseName,
                `${h.monthlyPrice.toLocaleString()} AED`,
              ]);
            });
          });

          autoTable(pdf, {
            startY: 28,
            head: [["#", "Name of Customer", "No. of Horses", "Name of Horses", "Monthly Livery Price"]],
            body: rows,
            headStyles: { fillColor: [41, 128, 185], textColor: 255, fontStyle: "bold", fontSize: 9 },
            bodyStyles: { fontSize: 9 },
            alternateRowStyles: { fillColor: [245, 245, 245] },
            columnStyles: {
              0: { cellWidth: 12, halign: "center" },
              2: { halign: "center" },
              4: { halign: "right" },
            },
            margin: { left: 15, right: 15 },
          });
        }

        addDetailFooter(pdf, pageWidth, pageHeight);
        pdf.save(`livery-customers-info.pdf`);
      }
    } finally {
      setDownloadingDetail(false);
    }
  }, [detailReport, selectedMonth, newLiveryData, departedData, customersInfoData]);

  return (
    <div className="p-6">
      <PageHeader
        title="Livery Reports"
        description="Visual analysis of livery data"
      />

      <div className="flex gap-4 mb-6 flex-wrap items-end">
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
        <Button
          variant="outline"
          size="sm"
          onClick={downloadChartPdf}
          disabled={downloadingChart || isLoading || reportData.length === 0}
          data-testid="button-download-chart-pdf"
        >
          <Download className="w-4 h-4 mr-1" />
          {downloadingChart ? "Generating..." : "Download PDF"}
        </Button>
      </div>

      <Card>
        <CardContent className="pt-6" ref={chartRef}>
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

      <div className="mt-8">
        <div className="flex gap-4 mb-6 flex-wrap items-end">
          <div>
            <Label className="text-sm text-muted-foreground mb-1 block">Detail Report</Label>
            <Select value={detailReport} onValueChange={setDetailReport}>
              <SelectTrigger className="w-72" data-testid="select-detail-report">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="new_livery">New Livery Horses</SelectItem>
                <SelectItem value="departed">Departure of Livery Horses</SelectItem>
                <SelectItem value="customers_info">Livery Customers - Information File</SelectItem>
              </SelectContent>
            </Select>
          </div>
          {showMonthFilter && (
            <div>
              <Label className="text-sm text-muted-foreground mb-1 block">Month / Year</Label>
              <Select value={selectedMonth} onValueChange={setSelectedMonth}>
                <SelectTrigger className="w-52" data-testid="select-detail-month">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {monthOptions.map(m => (
                    <SelectItem key={m} value={m}>{formatMonthLabel(m)}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
          <Button
            variant="outline"
            size="sm"
            onClick={downloadDetailPdf}
            disabled={downloadingDetail || loadingNew || loadingDeparted || loadingCustomers}
            data-testid="button-download-detail-pdf"
          >
            <Download className="w-4 h-4 mr-1" />
            {downloadingDetail ? "Generating..." : "Download PDF"}
          </Button>
        </div>

        {detailReport === "new_livery" && (
          <Card>
            <CardContent className="pt-6">
              <h3 className="text-lg font-bold text-center mb-4" data-testid="text-detail-report-title">
                New Livery Horses – {formatMonthLabel(selectedMonth)}
              </h3>
              {loadingNew ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">Loading...</div>
              ) : newLiveryData.length === 0 ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">No new livery horses for this month</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm" data-testid="table-new-livery">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white rounded-tl-md">#</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white">Name of Owner</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(25,95%,53%)] text-white">Name of Livery Horse</th>
                        <th className="text-center py-3 px-4 font-semibold bg-[hsl(142,76%,36%)] text-white">Number of Horses</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(142,50%,30%)] text-white">Arrival Date</th>
                        <th className="text-right py-3 px-4 font-semibold bg-[hsl(25,60%,40%)] text-white rounded-tr-md">Livery Price</th>
                      </tr>
                    </thead>
                    <tbody>
                      {newLiveryData.map((group: any, idx: number) => (
                        <tr key={idx} className="border-b last:border-b-0 hover:bg-muted/50" data-testid={`row-new-livery-${idx}`}>
                          <td className="py-3 px-4 font-semibold bg-primary/10 rounded-l-md">{idx + 1}</td>
                          <td className="py-3 px-4 font-medium">{group.customerName}</td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{h.horseName}</div>
                            ))}
                          </td>
                          <td className="py-3 px-4 text-center font-semibold">{group.horseCount}</td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{formatDate(h.arrivalDate)}</div>
                            ))}
                          </td>
                          <td className="py-3 px-4 text-right">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{parseFloat(h.liveryPrice).toLocaleString()} AED</div>
                            ))}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {detailReport === "departed" && (
          <Card>
            <CardContent className="pt-6">
              <h3 className="text-lg font-bold text-center mb-4" data-testid="text-detail-report-title">
                Departure of Livery Horses – {formatMonthLabel(selectedMonth)}
              </h3>
              {loadingDeparted ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">Loading...</div>
              ) : departedData.length === 0 ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">No departures for this month</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm" data-testid="table-departed-livery">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white rounded-tl-md">#</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white">Name of Owner</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(25,95%,53%)] text-white">Name of Livery Horse</th>
                        <th className="text-center py-3 px-4 font-semibold bg-[hsl(142,76%,36%)] text-white">Number of Horses</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(142,50%,30%)] text-white">Departure Date</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(0,60%,45%)] text-white rounded-tr-md">Reason</th>
                      </tr>
                    </thead>
                    <tbody>
                      {departedData.map((group: any, idx: number) => (
                        <tr key={idx} className="border-b last:border-b-0 hover:bg-muted/50" data-testid={`row-departed-${idx}`}>
                          <td className="py-3 px-4 font-semibold bg-primary/10 rounded-l-md">{idx + 1}</td>
                          <td className="py-3 px-4 font-medium">{group.customerName}</td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{h.horseName}</div>
                            ))}
                          </td>
                          <td className="py-3 px-4 text-center font-semibold">{group.horseCount}</td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{formatDate(h.departureDate)}</div>
                            ))}
                          </td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{h.checkoutReason || "—"}</div>
                            ))}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {detailReport === "customers_info" && (
          <Card>
            <CardContent className="pt-6">
              <h3 className="text-lg font-bold text-center mb-4" data-testid="text-detail-report-title">
                Livery Customers – Information File
              </h3>
              {loadingCustomers ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">Loading...</div>
              ) : customersInfoData.length === 0 ? (
                <div className="h-40 flex items-center justify-center text-muted-foreground">No livery customers found</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm" data-testid="table-livery-customers">
                    <thead>
                      <tr className="border-b">
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white rounded-tl-md">#</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(197,84%,42%)] text-white">Name of Customer</th>
                        <th className="text-center py-3 px-4 font-semibold bg-[hsl(25,95%,53%)] text-white">Number of Horses</th>
                        <th className="text-left py-3 px-4 font-semibold bg-[hsl(142,76%,36%)] text-white">Name of Horses</th>
                        <th className="text-right py-3 px-4 font-semibold bg-[hsl(280,65%,60%)] text-white rounded-tr-md">Monthly Livery Price</th>
                      </tr>
                    </thead>
                    <tbody>
                      {customersInfoData.map((group: any, idx: number) => (
                        <tr key={idx} className="border-b last:border-b-0 hover:bg-muted/50" data-testid={`row-customer-info-${idx}`}>
                          <td className="py-3 px-4 font-semibold bg-primary/10 rounded-l-md">{idx + 1}</td>
                          <td className="py-3 px-4 font-medium">{group.customerName}</td>
                          <td className="py-3 px-4 text-center font-semibold">{group.horseCount}</td>
                          <td className="py-3 px-4">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{h.horseName}</div>
                            ))}
                          </td>
                          <td className="py-3 px-4 text-right">
                            {group.horses.map((h: any, i: number) => (
                              <div key={i}>{h.monthlyPrice.toLocaleString()} AED</div>
                            ))}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}
