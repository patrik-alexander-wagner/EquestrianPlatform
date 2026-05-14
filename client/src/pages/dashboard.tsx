import { useQuery } from "@tanstack/react-query";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PageHeader } from "@/components/page-header";
import { Skeleton } from "@/components/ui/skeleton";
import { Progress } from "@/components/ui/progress";
import { Users, FileText, TrendingUp, TrendingDown, Trophy, Wallet, Gauge, Building2 } from "lucide-react";
import { Horseshoe } from "@/components/icons/horseshoe";
import { Link } from "wouter";

interface DashboardKpis {
  totalCheckedInHorses: number;
  adecCheckedInHorses: number;
  customerCheckedInHorses: number;
  totalBoxCapacity: number;
  activeCustomers: number;
  activeAgreements: number;
  monthlyRevenue: number;
  priorMonthRevenue: number;
  topCustomer: { name: string; revenue: number } | null;
  currentMonth: string;
  priorMonth: string;
}

function formatAed(n: number): string {
  return `AED ${Math.round(n).toLocaleString()}`;
}

function formatMonthLabel(ym: string): string {
  const [y, m] = ym.split("-").map(Number);
  if (!y || !m) return ym;
  return new Date(y, m - 1, 1).toLocaleString(undefined, { month: "short", year: "numeric" });
}

export default function DashboardPage() {
  const { data: kpis, isLoading: loadingKpis } = useQuery<DashboardKpis>({
    queryKey: ["/api/dashboard/kpis"],
  });
  const { data: agreements = [], isLoading: loadingAgreements } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", "?status=active"],
  });

  const occupancyPct =
    kpis && kpis.totalBoxCapacity > 0
      ? Math.round((kpis.totalCheckedInHorses / kpis.totalBoxCapacity) * 100)
      : 0;

  const revenueDelta =
    kpis && kpis.priorMonthRevenue > 0
      ? ((kpis.monthlyRevenue - kpis.priorMonthRevenue) / kpis.priorMonthRevenue) * 100
      : null;

  return (
    <div className="p-6">
      <PageHeader title="Dashboard" description="Welcome to StableMaster" />

      {/* Row 1 — Operational Overview */}
      <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">
        Operational Overview
      </h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <Link href="/stable-management/horse-movements">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Total Checked-In Horses
              </CardTitle>
              <Horseshoe className="w-5 h-5 text-primary" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-16" />
              ) : (
                <div className="text-3xl font-bold" data-testid="stat-total-checked-in">
                  {kpis?.totalCheckedInHorses ?? 0}
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Link href="/stable-management/horse-movements">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                ADEC Horses (On-Site)
              </CardTitle>
              <Horseshoe className="w-5 h-5 text-chart-2" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-16" />
              ) : (
                <div className="text-3xl font-bold" data-testid="stat-adec-horses">
                  {kpis?.adecCheckedInHorses ?? 0}
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Link href="/stable-management/horse-movements">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Customer Livery Horses
              </CardTitle>
              <Horseshoe className="w-5 h-5 text-chart-3" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-16" />
              ) : (
                <div className="text-3xl font-bold" data-testid="stat-customer-horses">
                  {kpis?.customerCheckedInHorses ?? 0}
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Card className="h-full">
          <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Occupancy Rate
            </CardTitle>
            <Gauge className="w-5 h-5 text-chart-4" />
          </CardHeader>
          <CardContent>
            {loadingKpis ? (
              <Skeleton className="h-8 w-full" />
            ) : (
              <div className="space-y-2">
                <div className="flex items-baseline justify-between">
                  <span className="text-3xl font-bold" data-testid="stat-occupancy-pct">
                    {occupancyPct}%
                  </span>
                  <span className="text-xs text-muted-foreground" data-testid="stat-occupancy-fraction">
                    {kpis?.totalCheckedInHorses ?? 0} / {kpis?.totalBoxCapacity ?? 0} boxes
                  </span>
                </div>
                <Progress value={Math.min(occupancyPct, 100)} className="h-2" />
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Row 2 — Business Performance */}
      <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide mb-3">
        Business Performance
      </h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <Link href="/customers">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Active Customers
              </CardTitle>
              <Users className="w-5 h-5 text-chart-3" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-16" />
              ) : (
                <div className="text-3xl font-bold" data-testid="stat-active-customers">
                  {kpis?.activeCustomers ?? 0}
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Link href="/agreements/current">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Active Livery Agreements
              </CardTitle>
              <FileText className="w-5 h-5 text-chart-4" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-16" />
              ) : (
                <div className="text-3xl font-bold" data-testid="stat-active-agreements">
                  {kpis?.activeAgreements ?? 0}
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Link href="/billing/invoices">
          <Card className="hover-elevate cursor-pointer transition-all h-full">
            <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Monthly Revenue ({kpis ? formatMonthLabel(kpis.currentMonth) : "Past Month"})
              </CardTitle>
              <Wallet className="w-5 h-5 text-primary" />
            </CardHeader>
            <CardContent>
              {loadingKpis ? (
                <Skeleton className="h-8 w-32" />
              ) : (
                <div className="space-y-1">
                  <div className="text-2xl font-bold" data-testid="stat-monthly-revenue">
                    {formatAed(kpis?.monthlyRevenue ?? 0)}
                  </div>
                  <div className="text-xs text-muted-foreground flex items-center gap-1" data-testid="stat-revenue-delta">
                    {revenueDelta === null ? (
                      <span>vs {kpis ? formatMonthLabel(kpis.priorMonth) : ""}: no prior data</span>
                    ) : revenueDelta >= 0 ? (
                      <>
                        <TrendingUp className="w-3 h-3 text-green-600 dark:text-green-400" />
                        <span className="text-green-700 dark:text-green-400 font-medium">
                          +{revenueDelta.toFixed(1)}%
                        </span>
                        <span>vs {formatMonthLabel(kpis!.priorMonth)}</span>
                      </>
                    ) : (
                      <>
                        <TrendingDown className="w-3 h-3 text-red-600 dark:text-red-400" />
                        <span className="text-red-700 dark:text-red-400 font-medium">
                          {revenueDelta.toFixed(1)}%
                        </span>
                        <span>vs {formatMonthLabel(kpis!.priorMonth)}</span>
                      </>
                    )}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </Link>

        <Card className="h-full">
          <CardHeader className="flex flex-row items-center justify-between gap-2 pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Top Customer ({kpis ? formatMonthLabel(kpis.priorMonth) : "Past Month"})
            </CardTitle>
            <Trophy className="w-5 h-5 text-chart-5" />
          </CardHeader>
          <CardContent>
            {loadingKpis ? (
              <Skeleton className="h-8 w-full" />
            ) : kpis?.topCustomer ? (
              <div className="space-y-1">
                <div className="text-base font-semibold truncate" data-testid="stat-top-customer-name" title={kpis.topCustomer.name}>
                  {kpis.topCustomer.name}
                </div>
                <div className="text-xl font-bold" data-testid="stat-top-customer-revenue">
                  {formatAed(kpis.topCustomer.revenue)}
                </div>
              </div>
            ) : (
              <div className="text-sm text-muted-foreground" data-testid="stat-top-customer-empty">
                No billed revenue last month
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <div className="mt-8">
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

// Building2 import kept for potential future use; suppress unused warning if any
void Building2;
