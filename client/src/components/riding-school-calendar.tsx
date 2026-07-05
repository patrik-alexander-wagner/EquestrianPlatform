import { Fragment } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

// Custom-built resource-grid calendar (react-big-calendar couldn't express
// the "switchable Y-axis resource dimension + nested hourly sub-rows"
// layout this needed, so this replaces it outright). Pure rendering +
// callbacks — all capacity/recurrence/booking logic stays server-side in
// the page that uses this component.

export type CalendarViewMode = "day" | "week" | "month";
export type CalendarGranularity = "full" | "hour";
export type CalendarResourceAxis = "horses" | "instructors" | "customers" | "facilities";

export interface CalendarEvent {
  id: string;
  title: string;
  start: Date;
  end: Date;
  isException?: boolean;
  isFull?: boolean;
}

export interface CalendarRow {
  id: string;
  title: string;
}

const HOUR_START = 6;
const HOUR_END = 20; // inclusive — matches the club's operating hours
const DAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

const AXIS_LABELS: Record<CalendarResourceAxis, { singular: string; plural: string }> = {
  horses: { singular: "Horse", plural: "Horses" },
  instructors: { singular: "Instructor", plural: "Instructors" },
  customers: { singular: "Customer", plural: "Customers" },
  facilities: { singular: "Facility", plural: "Facilities" },
};

export function startOfWeekMonday(date: Date): Date {
  const d = new Date(date);
  const dayIdx = (d.getDay() + 6) % 7; // Monday = 0
  d.setDate(d.getDate() - dayIdx);
  d.setHours(0, 0, 0, 0);
  return d;
}

export function rangeForCalendarView(viewMode: CalendarViewMode, date: Date): { from: Date; to: Date } {
  if (viewMode === "month") {
    const from = startOfWeekMonday(new Date(date.getFullYear(), date.getMonth(), 1));
    const lastOfMonth = new Date(date.getFullYear(), date.getMonth() + 1, 0);
    const to = new Date(startOfWeekMonday(lastOfMonth));
    to.setDate(to.getDate() + 7);
    to.setMilliseconds(-1);
    return { from, to };
  }
  if (viewMode === "week") {
    const from = startOfWeekMonday(date);
    const to = new Date(from);
    to.setDate(to.getDate() + 7);
    to.setMilliseconds(-1);
    return { from, to };
  }
  const from = new Date(date); from.setHours(0, 0, 0, 0);
  const to = new Date(date); to.setHours(23, 59, 59, 999);
  return { from, to };
}

export function shiftCalendarDate(viewMode: CalendarViewMode, date: Date, direction: 1 | -1): Date {
  const next = new Date(date);
  if (viewMode === "month") next.setMonth(next.getMonth() + direction);
  else if (viewMode === "week") next.setDate(next.getDate() + 7 * direction);
  else next.setDate(next.getDate() + direction);
  return next;
}

function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function eventPillClass(event: CalendarEvent): string {
  if (event.isFull) return "bg-destructive text-destructive-foreground";
  if (event.isException) return "bg-amber-500 text-white";
  return "bg-primary text-primary-foreground";
}

function EventPill({ event, onClick, compact }: { event: CalendarEvent; onClick: () => void; compact?: boolean }) {
  return (
    <button
      type="button"
      onClick={(e) => { e.stopPropagation(); onClick(); }}
      data-testid={`calendar-event-${event.id}`}
      className={cn(
        "w-full text-left rounded px-1.5 py-0.5 text-[11px] leading-tight truncate mb-0.5",
        eventPillClass(event),
      )}
      title={event.title}
    >
      {!compact && (
        <span className="opacity-90 mr-1">
          {event.start.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
        </span>
      )}
      {event.title}
    </button>
  );
}

interface GridProps {
  date: Date;
  rows: CalendarRow[];
  eventsByRow: Record<string, CalendarEvent[]>;
  allEvents: CalendarEvent[];
  onSelectSlot: (info: { start: Date; end: Date; rowId?: string }) => void;
  onSelectEvent: (event: CalendarEvent) => void;
}

function WeekFullGrid({ date, rows, eventsByRow, onSelectSlot, onSelectEvent }: GridProps) {
  const weekStart = startOfWeekMonday(date);
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart); d.setDate(d.getDate() + i); return d;
  });
  const today = new Date();

  return (
    <div className="overflow-auto border rounded-md">
      <table className="w-full border-collapse text-sm" style={{ tableLayout: "fixed" }}>
        <colgroup>
          <col style={{ width: "160px" }} />
          {days.map((_, i) => <col key={i} />)}
        </colgroup>
        <thead>
          <tr className="bg-muted/40">
            <th className="p-2 text-left font-medium text-muted-foreground text-xs border-b border-r"></th>
            {days.map((d, i) => (
              <th
                key={i}
                className={cn(
                  "p-2 text-center font-medium text-xs border-b border-r",
                  isSameDay(d, today) && "bg-primary/10 text-primary",
                )}
              >
                <div className="text-muted-foreground">{DAY_NAMES[i]}</div>
                <div className={cn(isSameDay(d, today) && "font-semibold")}>{d.getDate()}</div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td className="p-2 border-r border-b font-medium align-top">{row.title}</td>
              {days.map((d, i) => {
                const dayEvents = (eventsByRow[row.id] || []).filter((e) => isSameDay(e.start, d));
                const dayStart = new Date(d); dayStart.setHours(0, 0, 0, 0);
                const dayEnd = new Date(d); dayEnd.setHours(23, 59, 59, 999);
                return (
                  <td
                    key={i}
                    onClick={() => onSelectSlot({ start: dayStart, end: dayEnd, rowId: row.id })}
                    data-testid={`calendar-cell-${row.id}-${i}`}
                    className={cn("p-1 border-b border-r align-top cursor-pointer hover:bg-accent/40 min-h-[56px]", isSameDay(d, today) && "bg-primary/5")}
                  >
                    {dayEvents.map((ev) => (
                      <EventPill key={ev.id} event={ev} onClick={() => onSelectEvent(ev)} />
                    ))}
                  </td>
                );
              })}
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan={8} className="p-6 text-center text-muted-foreground">No entries for this resource.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function WeekHourGrid({ date, rows, eventsByRow, onSelectSlot, onSelectEvent }: GridProps) {
  const weekStart = startOfWeekMonday(date);
  const days = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart); d.setDate(d.getDate() + i); return d;
  });
  const hours = Array.from({ length: HOUR_END - HOUR_START + 1 }, (_, i) => HOUR_START + i);
  const today = new Date();

  return (
    <div className="overflow-auto border rounded-md">
      <table className="w-full border-collapse text-sm" style={{ tableLayout: "fixed" }}>
        <colgroup>
          <col style={{ width: "160px" }} />
          {days.map((_, i) => <col key={i} />)}
        </colgroup>
        <thead>
          <tr className="bg-muted/40">
            <th className="p-2 text-left font-medium text-muted-foreground text-xs border-b border-r"></th>
            {days.map((d, i) => (
              <th key={i} className={cn("p-2 text-center font-medium text-xs border-b border-r", isSameDay(d, today) && "bg-primary/10 text-primary")}>
                <div className="text-muted-foreground">{DAY_NAMES[i]}</div>
                <div className={cn(isSameDay(d, today) && "font-semibold")}>{d.getDate()}</div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <Fragment key={row.id}>
              <tr className="bg-muted/70">
                <td colSpan={8} className="p-1.5 px-2 font-semibold text-xs border-b border-t">{row.title}</td>
              </tr>
              {hours.map((hour) => (
                <tr key={hour}>
                  <td className="p-1.5 border-r border-b text-xs text-muted-foreground text-right pr-3">{String(hour).padStart(2, "0")}:00</td>
                  {days.map((d, i) => {
                    const cellEvents = (eventsByRow[row.id] || []).filter((e) => isSameDay(e.start, d) && e.start.getHours() === hour);
                    const cellStart = new Date(d); cellStart.setHours(hour, 0, 0, 0);
                    const cellEnd = new Date(d); cellEnd.setHours(hour, 59, 59, 999);
                    return (
                      <td
                        key={i}
                        onClick={() => onSelectSlot({ start: cellStart, end: cellEnd, rowId: row.id })}
                        data-testid={`calendar-cell-${row.id}-${hour}-${i}`}
                        className={cn("p-0.5 border-b border-r cursor-pointer hover:bg-accent/40 h-8", isSameDay(d, today) && "bg-primary/5")}
                      >
                        {cellEvents.map((ev) => (
                          <EventPill key={ev.id} event={ev} onClick={() => onSelectEvent(ev)} compact />
                        ))}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </Fragment>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan={8} className="p-6 text-center text-muted-foreground">No entries for this resource.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function DayGrid({ date, rows, eventsByRow, onSelectSlot, onSelectEvent }: GridProps) {
  const hours = Array.from({ length: HOUR_END - HOUR_START + 1 }, (_, i) => HOUR_START + i);

  return (
    <div className="overflow-auto border rounded-md">
      <table className="border-collapse text-sm" style={{ tableLayout: "fixed", minWidth: "100%" }}>
        <colgroup>
          <col style={{ width: "160px" }} />
          {hours.map((_, i) => <col key={i} style={{ width: "90px" }} />)}
        </colgroup>
        <thead>
          <tr className="bg-muted/40">
            <th className="p-2 text-left font-medium text-muted-foreground text-xs border-b border-r"></th>
            {hours.map((h) => (
              <th key={h} className="p-2 text-center font-medium text-xs border-b border-r">{String(h).padStart(2, "0")}:00</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td className="p-2 border-r border-b font-medium align-top">{row.title}</td>
              {hours.map((hour) => {
                const cellEvents = (eventsByRow[row.id] || []).filter((e) => isSameDay(e.start, date) && e.start.getHours() === hour);
                const cellStart = new Date(date); cellStart.setHours(hour, 0, 0, 0);
                const cellEnd = new Date(date); cellEnd.setHours(hour, 59, 59, 999);
                return (
                  <td
                    key={hour}
                    onClick={() => onSelectSlot({ start: cellStart, end: cellEnd, rowId: row.id })}
                    data-testid={`calendar-cell-${row.id}-${hour}`}
                    className="p-1 border-b border-r align-top cursor-pointer hover:bg-accent/40 h-14"
                  >
                    {cellEvents.map((ev) => (
                      <EventPill key={ev.id} event={ev} onClick={() => onSelectEvent(ev)} compact />
                    ))}
                  </td>
                );
              })}
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan={hours.length + 1} className="p-6 text-center text-muted-foreground">No entries for this resource.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

function MonthGrid({ date, allEvents, onSelectSlot, onSelectEvent }: Omit<GridProps, "rows" | "eventsByRow">) {
  const { from } = rangeForCalendarView("month", date);
  const days: Date[] = [];
  const cursor = new Date(from);
  while (days.length < 42) {
    days.push(new Date(cursor));
    cursor.setDate(cursor.getDate() + 1);
  }
  const today = new Date();
  const currentMonth = date.getMonth();

  return (
    <div className="overflow-auto border rounded-md">
      <table className="w-full border-collapse text-sm table-fixed">
        <thead>
          <tr className="bg-muted/40">
            {DAY_NAMES.map((d) => (
              <th key={d} className="p-2 text-center font-medium text-muted-foreground text-xs border-b border-r">{d}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {Array.from({ length: 6 }, (_, week) => (
            <tr key={week}>
              {days.slice(week * 7, week * 7 + 7).map((d, i) => {
                const dayEvents = allEvents.filter((e) => isSameDay(e.start, d));
                const dayStart = new Date(d); dayStart.setHours(0, 0, 0, 0);
                const dayEnd = new Date(d); dayEnd.setHours(23, 59, 59, 999);
                const inMonth = d.getMonth() === currentMonth;
                return (
                  <td
                    key={i}
                    onClick={() => onSelectSlot({ start: dayStart, end: dayEnd })}
                    data-testid={`calendar-month-cell-${d.toISOString().slice(0, 10)}`}
                    className={cn(
                      "p-1 border-b border-r align-top cursor-pointer hover:bg-accent/40 h-24",
                      !inMonth && "bg-muted/20 text-muted-foreground",
                      isSameDay(d, today) && "bg-primary/5",
                    )}
                  >
                    <div className={cn("text-xs mb-1", isSameDay(d, today) && "font-semibold text-primary")}>{d.getDate()}</div>
                    <div className="space-y-0.5 max-h-16 overflow-y-auto">
                      {dayEvents.map((ev) => (
                        <EventPill key={ev.id} event={ev} onClick={() => onSelectEvent(ev)} compact />
                      ))}
                    </div>
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

interface RidingSchoolCalendarProps {
  viewMode: CalendarViewMode;
  onViewModeChange: (mode: CalendarViewMode) => void;
  granularity: CalendarGranularity;
  onGranularityChange: (g: CalendarGranularity) => void;
  resourceAxis: CalendarResourceAxis;
  onResourceAxisChange: (axis: CalendarResourceAxis) => void;
  date: Date;
  onNavigate: (date: Date) => void;
  rows: CalendarRow[];
  eventsByRow: Record<string, CalendarEvent[]>;
  allEvents: CalendarEvent[];
  onSelectSlot: (info: { start: Date; end: Date; rowId?: string }) => void;
  onSelectEvent: (event: CalendarEvent) => void;
}

export function RidingSchoolCalendar({
  viewMode, onViewModeChange, granularity, onGranularityChange, resourceAxis, onResourceAxisChange,
  date, onNavigate, rows, eventsByRow, allEvents, onSelectSlot, onSelectEvent,
}: RidingSchoolCalendarProps) {
  const { from, to } = rangeForCalendarView(viewMode, date);
  const rangeLabel = viewMode === "month"
    ? date.toLocaleDateString([], { month: "long", year: "numeric" })
    : viewMode === "day"
    ? date.toLocaleDateString([], { weekday: "long", month: "short", day: "numeric", year: "numeric" })
    : `${from.toLocaleDateString([], { month: "short", day: "numeric" })} - ${new Date(to.getTime() + 1).toLocaleDateString([], { month: "short", day: "numeric", year: "numeric" })}`;

  // Month forces Full Day (no hourly breakdown) and hides the resource axis
  // (it's a plain month grid); Day forces By Hour (no Full Day option).
  const effectiveGranularity: CalendarGranularity = viewMode === "month" ? "full" : viewMode === "day" ? "hour" : granularity;

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center flex-wrap gap-3">
        <div className="flex items-center gap-1">
          <Button variant="outline" size="icon" onClick={() => onNavigate(shiftCalendarDate(viewMode, date, -1))} data-testid="button-calendar-prev">
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <Button variant="outline" size="sm" onClick={() => onNavigate(new Date())} data-testid="button-calendar-today">Today</Button>
          <Button variant="outline" size="icon" onClick={() => onNavigate(shiftCalendarDate(viewMode, date, 1))} data-testid="button-calendar-next">
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
        <div className="text-sm font-medium" data-testid="text-calendar-range">{rangeLabel}</div>

        <div className="flex rounded-md border p-0.5 text-xs ml-2">
          {(["day", "week", "month"] as const).map((mode) => (
            <button
              key={mode}
              type="button"
              onClick={() => onViewModeChange(mode)}
              data-testid={`button-view-${mode}`}
              className={cn("px-3 py-1.5 rounded capitalize", viewMode === mode ? "bg-primary text-primary-foreground" : "text-muted-foreground")}
            >
              {mode}
            </button>
          ))}
        </div>

        {viewMode !== "month" && (
          <div className="flex rounded-md border p-0.5 text-xs">
            <button
              type="button"
              onClick={() => onGranularityChange("full")}
              disabled={viewMode === "day"}
              data-testid="button-granularity-full"
              className={cn(
                "px-3 py-1.5 rounded",
                effectiveGranularity === "full" ? "bg-primary text-primary-foreground" : "text-muted-foreground",
                viewMode === "day" && "opacity-40 cursor-not-allowed",
              )}
            >
              Full Day
            </button>
            <button
              type="button"
              onClick={() => onGranularityChange("hour")}
              data-testid="button-granularity-hour"
              className={cn("px-3 py-1.5 rounded", effectiveGranularity === "hour" ? "bg-primary text-primary-foreground" : "text-muted-foreground")}
            >
              By Hour
            </button>
          </div>
        )}

        {viewMode !== "month" && (
          <div className="flex rounded-md border p-0.5 text-xs ml-auto">
            {(Object.keys(AXIS_LABELS) as CalendarResourceAxis[]).map((axis) => (
              <button
                key={axis}
                type="button"
                onClick={() => onResourceAxisChange(axis)}
                data-testid={`button-axis-${axis}`}
                className={cn("px-3 py-1.5 rounded", resourceAxis === axis ? "bg-primary text-primary-foreground" : "text-muted-foreground")}
              >
                {AXIS_LABELS[axis].plural}
              </button>
            ))}
          </div>
        )}
      </div>

      {viewMode === "month" && (
        <MonthGrid date={date} allEvents={allEvents} onSelectSlot={onSelectSlot} onSelectEvent={onSelectEvent} />
      )}
      {viewMode === "week" && effectiveGranularity === "full" && (
        <WeekFullGrid date={date} rows={rows} eventsByRow={eventsByRow} allEvents={allEvents} onSelectSlot={onSelectSlot} onSelectEvent={onSelectEvent} />
      )}
      {viewMode === "week" && effectiveGranularity === "hour" && (
        <WeekHourGrid date={date} rows={rows} eventsByRow={eventsByRow} allEvents={allEvents} onSelectSlot={onSelectSlot} onSelectEvent={onSelectEvent} />
      )}
      {viewMode === "day" && (
        <DayGrid date={date} rows={rows} eventsByRow={eventsByRow} allEvents={allEvents} onSelectSlot={onSelectSlot} onSelectEvent={onSelectEvent} />
      )}
    </div>
  );
}
