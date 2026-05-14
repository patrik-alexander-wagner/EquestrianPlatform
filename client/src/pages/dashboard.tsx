import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { PageHeader } from "@/components/page-header";
import { Skeleton } from "@/components/ui/skeleton";
import { Progress } from "@/components/ui/progress";
import {
  ShieldCheck,
  Users,
  Gauge,
  User as UserIcon,
  FileText,
  CircleDollarSign,
  Trophy,
} from "lucide-react";
import { Horseshoe } from "@/components/icons/horseshoe";
import { KpiCard, BigNumber, formatAed } from "@/components/kpi-card";

interface DashboardSummary {
  month: string;
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
}

const COLOR_LIVERY = "#1F9D55";
const COLOR_SERVICE = "#1E3A5F";

function pad(n: number) { return String(n).padStart(2, "0"); }
function getCurrentMonth() {
  const n = new Date();
  return `${n.getFullYear()}-${pad(n.getMonth() + 1)}`;
}

export default function DashboardPage() {
  const month = getCurrentMonth();
  const { data, isLoading } = useQuery<DashboardSummary>({
    queryKey: ["/api/reports/dashboard-summary", `?month=${month}`],
  });
  const { data: agreements = [], isLoading: loadingAgreements } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", "?status=active"],
  });

  const op = data?.operational;
  const biz = data?.business;
  const adecPct = op && op.totalCheckedIn > 0 ? (op.adecHorses / op.totalCheckedIn) * 100 : 0;

  return (
    <div className="p-6 space-y-8">
      <PageHeader title="Dashboard" description="Welcome to StableMaster" />

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
              <BigNumber value={op?.adecHorses ?? 0} testId="text-adec-horses" />
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
              <BigNumber value={biz?.activeCustomers ?? 0} testId="text-active-customers" />
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
              <BigNumber value={biz?.activeAgreements ?? 0} testId="text-active-agreements" />
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

      <div>
        <h2 className="text-lg font-semibold mb-4">Recent Active Agreements</h2>
        {loadingAgreements ? (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-16 w-full" />)}
          </div>
        ) : agreements.length === 0 ? (
          <p className="text-muted-foreground">No active agreements</p>
        ) : (
          <div className="space-y-2">
            {agreements.slice(0, 5).map((agreement: any) => (
              <Card key={agreement.id}>
                <CardContent className="flex items-center justify-between gap-4 py-4">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-md bg-primary flex items-center justify-center">
                      <Horseshoe className="w-5 h-5" inverted />
                    </div>
                    <div>
                      <p className="font-medium">{agreement.horseName || "No Horse"}</p>
                      <p className="text-sm text-muted-foreground">{agreement.customerName}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">
                      {agreement.monthlyAmount ? `AED ${parseFloat(agreement.monthlyAmount).toFixed(2)}/mo` : "-"}
                    </p>
                    <p className="text-sm text-muted-foreground">{agreement.stableName} / {agreement.boxName}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
