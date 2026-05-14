import * as React from "react";
import { Card, CardContent } from "@/components/ui/card";

export function KpiCard({
  label,
  icon,
  iconColor,
  iconBg,
  children,
  testId,
}: {
  label: string;
  icon: React.ReactNode;
  iconColor: string;
  iconBg: string;
  children: React.ReactNode;
  testId?: string;
}) {
  return (
    <Card className="min-h-[124px]" data-testid={testId}>
      <CardContent className="p-[18px] flex flex-col h-full">
        <div className="flex items-start justify-between gap-2 mb-2">
          <span className="text-[13px] font-medium text-muted-foreground">{label}</span>
          <div className={`w-8 h-8 rounded-md flex items-center justify-center ${iconBg} ${iconColor}`}>
            {icon}
          </div>
        </div>
        <div className="flex-1 flex flex-col justify-center">{children}</div>
      </CardContent>
    </Card>
  );
}

export function BigNumber({ value, testId }: { value: React.ReactNode; testId?: string }) {
  return (
    <div className="text-[32px] leading-none font-bold tabular-nums tracking-tight" data-testid={testId}>
      {value}
    </div>
  );
}

export function formatAed(n: number): string {
  return Math.round(n).toLocaleString();
}
