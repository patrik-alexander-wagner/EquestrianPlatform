import { useMemo } from "react";
import { Calendar, dateFnsLocalizer, type View } from "react-big-calendar";
import { format, parse, startOfWeek, getDay } from "date-fns";
import { enUS } from "date-fns/locale";
import "react-big-calendar/lib/css/react-big-calendar.css";

// Thin wrapper around react-big-calendar so all scheduling business logic
// (capacity, recurrence, booking rules) stays server-side and only this
// component would need to change if the calendar library is ever swapped.

const locales = { "en-US": enUS };

const localizer = dateFnsLocalizer({
  format,
  parse,
  startOfWeek: () => startOfWeek(new Date(), { weekStartsOn: 1 }),
  getDay,
  locales,
});

export interface CalendarEvent {
  id: string;
  title: string;
  start: Date;
  end: Date;
  resourceId?: string;
  isException?: boolean;
  isFull?: boolean;
}

export interface CalendarResource {
  resourceId: string;
  resourceTitle: string;
}

interface RidingSchoolCalendarProps {
  events: CalendarEvent[];
  resources?: CalendarResource[];
  view: View;
  date: Date;
  onNavigate: (date: Date) => void;
  onView: (view: View) => void;
  onSelectSlot?: (slot: { start: Date; end: Date; resourceId?: string }) => void;
  onSelectEvent?: (event: CalendarEvent) => void;
}

export function RidingSchoolCalendar({
  events, resources, view, date, onNavigate, onView, onSelectSlot, onSelectEvent,
}: RidingSchoolCalendarProps) {
  const eventPropGetter = useMemo(() => (event: CalendarEvent) => ({
    style: {
      backgroundColor: event.isFull ? "hsl(0 72% 51%)" : event.isException ? "hsl(38 92% 50%)" : "hsl(142 71% 35%)",
    },
  }), []);

  return (
    <div className="bg-background rounded-md border p-2" style={{ height: 700 }}>
      <Calendar
        localizer={localizer}
        events={events}
        resources={resources}
        resourceIdAccessor="resourceId"
        resourceTitleAccessor="resourceTitle"
        startAccessor="start"
        endAccessor="end"
        titleAccessor="title"
        views={["month", "week", "day"]}
        view={view}
        date={date}
        onNavigate={onNavigate}
        onView={onView}
        selectable
        onSelectSlot={onSelectSlot as any}
        onSelectEvent={onSelectEvent as any}
        eventPropGetter={eventPropGetter}
        style={{ height: "100%" }}
      />
    </div>
  );
}
