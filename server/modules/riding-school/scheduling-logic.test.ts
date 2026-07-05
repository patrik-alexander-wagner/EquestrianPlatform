import { describe, it, expect } from "vitest";
import { parseDaysOfWeek, clubWallClockToUtc, computeRecurrenceInstanceDates, getsFullRefund, riderLevelAllowed } from "./scheduling-logic";

describe("parseDaysOfWeek", () => {
  it("parses a simple comma-separated list", () => {
    expect(parseDaysOfWeek("1,3,5")).toEqual([1, 3, 5]);
  });

  it("tolerates whitespace around values", () => {
    expect(parseDaysOfWeek("1, 3, 5")).toEqual([1, 3, 5]);
  });

  it("filters out-of-range values", () => {
    expect(parseDaysOfWeek("1,7,-1,3")).toEqual([1, 3]);
  });
});

describe("clubWallClockToUtc", () => {
  it("converts 9am club time (UTC+4) to 5am UTC", () => {
    const result = clubWallClockToUtc(2026, 6, 6, 9, 0); // month is 0-indexed: 6 = July
    expect(result.toISOString()).toBe("2026-07-06T05:00:00.000Z");
  });

  it("rolls over to the previous UTC day when club time is before 4am", () => {
    const result = clubWallClockToUtc(2026, 6, 6, 2, 0); // 2am Dubai = 10pm UTC the day before
    expect(result.toISOString()).toBe("2026-07-05T22:00:00.000Z");
  });

  it("is independent of the host process's own timezone (always computes via explicit offset)", () => {
    // Regression test for the real bug found during manual testing: this
    // must never depend on process.env.TZ or the OS's local timezone.
    const a = clubWallClockToUtc(2026, 0, 15, 9, 0);
    const b = clubWallClockToUtc(2026, 0, 15, 9, 0);
    expect(a.getTime()).toBe(b.getTime());
    expect(a.getUTCHours()).toBe(5);
  });
});

describe("computeRecurrenceInstanceDates", () => {
  const now = new Date("2026-07-04T00:00:00.000Z"); // a Saturday

  it("generates one instance per matching weekday within range", () => {
    const until = new Date("2026-07-18T00:00:00.000Z"); // two weeks out
    const instances = computeRecurrenceInstanceDates("1,3,5", "09:00", until, 45, now, 12);
    // Mon/Wed/Fri from 2026-07-04 through 2026-07-18: Jul 6, 8, 10, 13, 15, 17
    expect(instances).toHaveLength(6);
    expect(instances[0].start.toISOString()).toBe("2026-07-06T05:00:00.000Z");
    expect(instances[0].end.toISOString()).toBe("2026-07-06T05:45:00.000Z");
  });

  it("respects the duration when computing end times", () => {
    const until = new Date("2026-07-07T00:00:00.000Z");
    const instances = computeRecurrenceInstanceDates("1", "09:00", until, 90, now, 12);
    expect(instances).toHaveLength(1);
    const durationMs = instances[0].end.getTime() - instances[0].start.getTime();
    expect(durationMs).toBe(90 * 60 * 1000);
  });

  it("caps at maxMonths even when until is further out", () => {
    const farFutureUntil = new Date("2030-01-01T00:00:00.000Z");
    const instances = computeRecurrenceInstanceDates("1,3,5", "09:00", farFutureUntil, 45, now, 1);
    // With a 1-month cap, no instance should start more than ~31 days after `now`.
    const capMs = now.getTime() + 32 * 24 * 60 * 60 * 1000;
    for (const instance of instances) {
      expect(instance.start.getTime()).toBeLessThan(capMs);
    }
    expect(instances.length).toBeGreaterThan(0);
  });

  it("generates no instances when daysOfWeek matches nothing in range", () => {
    const until = new Date("2026-07-05T00:00:00.000Z"); // just one day out, a Sunday
    const instances = computeRecurrenceInstanceDates("1,3,5", "09:00", until, 45, now, 12); // now is Saturday
    expect(instances).toHaveLength(0);
  });
});

describe("getsFullRefund", () => {
  it("gives a full refund when notice meets the threshold exactly", () => {
    expect(getsFullRefund(24, 24)).toBe(true);
  });

  it("gives a full refund when notice exceeds the threshold", () => {
    expect(getsFullRefund(72, 24)).toBe(true);
  });

  it("gives no refund when notice falls short of the threshold", () => {
    expect(getsFullRefund(23.9, 24)).toBe(false);
    expect(getsFullRefund(1, 24)).toBe(false);
    expect(getsFullRefund(-5, 24)).toBe(false); // already started / in the past
  });
});

describe("riderLevelAllowed", () => {
  it("allows any rider (even with no level) when the template has no restriction", () => {
    expect(riderLevelAllowed(null, null, null)).toBe(true);
    expect(riderLevelAllowed(2, null, null)).toBe(true);
  });

  it("excludes a rider with no level when the template has any restriction", () => {
    expect(riderLevelAllowed(null, 1, null)).toBe(false);
    expect(riderLevelAllowed(null, null, 3)).toBe(false);
  });

  it("allows a rider whose level falls within a min/max range", () => {
    expect(riderLevelAllowed(2, 1, 3)).toBe(true);
    expect(riderLevelAllowed(1, 1, 3)).toBe(true);
    expect(riderLevelAllowed(3, 1, 3)).toBe(true);
  });

  it("excludes a rider whose level falls outside a min/max range", () => {
    expect(riderLevelAllowed(0, 1, 3)).toBe(false);
    expect(riderLevelAllowed(4, 1, 3)).toBe(false);
  });

  it("supports a one-sided range", () => {
    expect(riderLevelAllowed(5, 2, null)).toBe(true);
    expect(riderLevelAllowed(1, 2, null)).toBe(false);
    expect(riderLevelAllowed(1, null, 2)).toBe(true);
    expect(riderLevelAllowed(3, null, 2)).toBe(false);
  });

  it("allows an exact single-level requirement (min === max)", () => {
    expect(riderLevelAllowed(2, 2, 2)).toBe(true);
    expect(riderLevelAllowed(1, 2, 2)).toBe(false);
    expect(riderLevelAllowed(3, 2, 2)).toBe(false);
  });
});
