import { CLUB_UTC_OFFSET_HOURS } from "@shared/timezone";

// Pure functions extracted from scheduling.ts specifically so the tricky
// math (recurrence date generation, timezone conversion, cancellation
// credit-tier matching) can be unit tested without a database — these are
// exactly the areas that produced real bugs during manual testing.

export function parseDaysOfWeek(daysOfWeek: string): number[] {
  return daysOfWeek.split(",").map((d) => parseInt(d.trim(), 10)).filter((d) => d >= 0 && d <= 6);
}

// Converts a club wall-clock date+time (Asia/Dubai, fixed UTC+4, no DST) to
// the correct UTC instant, independent of the server process's own local
// timezone.
export function clubWallClockToUtc(year: number, month: number, day: number, hour: number, minute: number): Date {
  return new Date(Date.UTC(year, month, day, hour - CLUB_UTC_OFFSET_HOURS, minute, 0));
}

export interface RecurrenceInstance {
  start: Date;
  end: Date;
}

// Materializes the {start, end} pairs for a recurrence, from `now` through
// `until` (hard-capped at `maxMonths` regardless of what `until` claims).
// `now` and `maxMonths` are explicit parameters (rather than reading
// `new Date()` / a module constant internally) specifically so this is
// deterministic and unit-testable.
export function computeRecurrenceInstanceDates(
  daysOfWeek: string,
  startTime: string,
  until: Date,
  durationMinutes: number,
  now: Date,
  maxMonths: number,
): RecurrenceInstance[] {
  const days = parseDaysOfWeek(daysOfWeek);
  const [hh, mm] = startTime.split(":").map((n) => parseInt(n, 10));

  const cap = new Date(now);
  cap.setUTCMonth(cap.getUTCMonth() + maxMonths);
  const endDate = until < cap ? until : cap;

  // Cursor walks whole UTC calendar days — day-of-week matching only needs
  // to be internally consistent, not tied to any particular timezone; the
  // actual instant of each instance is computed via clubWallClockToUtc.
  const instances: RecurrenceInstance[] = [];
  const cursor = new Date(now);
  cursor.setUTCHours(0, 0, 0, 0);
  while (cursor <= endDate) {
    if (days.includes(cursor.getUTCDay())) {
      const start = clubWallClockToUtc(cursor.getUTCFullYear(), cursor.getUTCMonth(), cursor.getUTCDate(), hh, mm);
      const end = new Date(start.getTime() + durationMinutes * 60 * 1000);
      instances.push({ start, end });
    }
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return instances;
}

// Binary cancellation rule: cancelling with at least `noticeHours` notice
// gets a full refund (credit/voucher); any later cancellation gets nothing.
// Replaces the old tiered percentage table with the single-field policy the
// product settled on.
export function getsFullRefund(hoursUntilLesson: number, noticeHours: number): boolean {
  return hoursUntilLesson >= noticeHours;
}

// A rider qualifies for a lesson template if their level's sortOrder falls
// within [minSortOrder, maxSortOrder] (either bound may be null/undefined to
// mean "unrestricted on that side"). A template with no restriction at all
// (both bounds null) is open to every rider, including one with no level
// set; a template with ANY restriction excludes a rider with no level.
export function riderLevelAllowed(
  riderSortOrder: number | null | undefined,
  minSortOrder: number | null | undefined,
  maxSortOrder: number | null | undefined,
): boolean {
  if (minSortOrder == null && maxSortOrder == null) return true;
  if (riderSortOrder == null) return false;
  if (minSortOrder != null && riderSortOrder < minSortOrder) return false;
  if (maxSortOrder != null && riderSortOrder > maxSortOrder) return false;
  return true;
}
