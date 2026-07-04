import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { KpiCard, BigNumber } from "@/components/kpi-card";
import { Card, CardContent } from "@/components/ui/card";
import { CalendarClock, Users, CalendarDays } from "lucide-react";

interface UpcomingLesson {
  bookingId: string;
  riderName: string;
  lessonName?: string;
  startDatetime: string;
  endDatetime: string;
}

interface DashboardData {
  nextLesson: UpcomingLesson | null;
  upcomingThisWeek: UpcomingLesson[];
  riderCount: number;
}

function formatWhen(iso: string) {
  return new Date(iso).toLocaleString([], { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

export default function PortalDashboardPage() {
  const { data } = useQuery<DashboardData>({ queryKey: ["/api/portal/dashboard"] });

  return (
    <div className="p-6">
      <PageHeader title="Dashboard" description="Your upcoming lessons at a glance" />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        <KpiCard label="Next Lesson" icon={<CalendarClock className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-next-lesson">
          {data?.nextLesson ? (
            <div>
              <div className="text-base font-semibold" data-testid="value-next-lesson-name">{data.nextLesson.lessonName} — {data.nextLesson.riderName}</div>
              <div className="text-sm text-muted-foreground">{formatWhen(data.nextLesson.startDatetime)}</div>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No upcoming lessons</p>
          )}
        </KpiCard>
        <KpiCard label="This Week" icon={<CalendarDays className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-this-week">
          <BigNumber value={data?.upcomingThisWeek.length ?? 0} testId="value-this-week-count" />
        </KpiCard>
        <KpiCard label="My Riders" icon={<Users className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-rider-count">
          <BigNumber value={data?.riderCount ?? 0} testId="value-rider-count" />
        </KpiCard>
      </div>

      <Card>
        <CardContent className="p-4">
          <h2 className="text-base font-semibold mb-3">Upcoming this week</h2>
          {data?.upcomingThisWeek.length ? (
            <ul className="space-y-2">
              {data.upcomingThisWeek.map((lesson) => (
                <li key={lesson.bookingId} className="flex justify-between text-sm border-b pb-2 last:border-0">
                  <span>{lesson.lessonName} — {lesson.riderName}</span>
                  <span className="text-muted-foreground">{formatWhen(lesson.startDatetime)}</span>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground">Nothing scheduled this week.</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
