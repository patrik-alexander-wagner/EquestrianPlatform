import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { KpiCard, BigNumber } from "@/components/kpi-card";
import { CalendarCheck, XCircle, Package, Ticket } from "lucide-react";

interface ReportSummary {
  lessonsInRange: number;
  confirmedBookings: number;
  cancelledBookings: number;
  activePackagePurchases: number;
  activeVouchers: number;
}

export default function RidingSchoolReportsPage() {
  const { data } = useQuery<ReportSummary>({ queryKey: ["/api/riding-school/reports/summary"] });

  return (
    <div className="p-6">
      <PageHeader title="Riding School Reports" description="Bookings, packages, and credit vouchers (last 30 / next 30 days)" />
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard label="Confirmed Bookings" icon={<CalendarCheck className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-confirmed-bookings">
          <BigNumber value={data?.confirmedBookings ?? "—"} testId="value-confirmed-bookings" />
        </KpiCard>
        <KpiCard label="Cancelled Bookings" icon={<XCircle className="w-4 h-4" />} iconColor="text-destructive" iconBg="bg-destructive/10" testId="kpi-cancelled-bookings">
          <BigNumber value={data?.cancelledBookings ?? "—"} testId="value-cancelled-bookings" />
        </KpiCard>
        <KpiCard label="Active Package Purchases" icon={<Package className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-active-packages">
          <BigNumber value={data?.activePackagePurchases ?? "—"} testId="value-active-packages" />
        </KpiCard>
        <KpiCard label="Active Credit Vouchers" icon={<Ticket className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-active-vouchers">
          <BigNumber value={data?.activeVouchers ?? "—"} testId="value-active-vouchers" />
        </KpiCard>
      </div>
    </div>
  );
}
