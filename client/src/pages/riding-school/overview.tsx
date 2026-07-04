import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { KpiCard, BigNumber } from "@/components/kpi-card";
import { CalendarDays, Users, BookOpen, LandPlot } from "lucide-react";
import type { LessonTemplate, Instructor, Arena } from "@shared/schema";

export default function RidingSchoolOverviewPage() {
  const from = new Date();
  const to = new Date(from.getTime() + 7 * 24 * 60 * 60 * 1000);

  const { data: lessons = [] } = useQuery<any[]>({
    queryKey: ["/api/riding-school/scheduled-lessons", "overview", from.toISOString(), to.toISOString()],
    queryFn: () => fetch(`/api/riding-school/scheduled-lessons?from=${from.toISOString()}&to=${to.toISOString()}`, { credentials: "include" }).then((r) => r.json()),
  });
  const { data: templates = [] } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const { data: instructors = [] } = useQuery<Instructor[]>({ queryKey: ["/api/instructors"] });
  const { data: arenas = [] } = useQuery<Arena[]>({ queryKey: ["/api/arenas"] });

  return (
    <div className="p-6">
      <PageHeader title="Overview" description="Riding school activity at a glance" />
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard label="Lessons (next 7 days)" icon={<CalendarDays className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-upcoming-lessons">
          <BigNumber value={lessons.length} testId="value-upcoming-lessons" />
        </KpiCard>
        <KpiCard label="Lesson Templates" icon={<BookOpen className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-templates">
          <BigNumber value={templates.length} testId="value-templates" />
        </KpiCard>
        <KpiCard label="Instructors" icon={<Users className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-instructors">
          <BigNumber value={instructors.length} testId="value-instructors" />
        </KpiCard>
        <KpiCard label="Arenas" icon={<LandPlot className="w-4 h-4" />} iconColor="text-primary" iconBg="bg-primary/10" testId="kpi-arenas">
          <BigNumber value={arenas.length} testId="value-arenas" />
        </KpiCard>
      </div>
    </div>
  );
}
