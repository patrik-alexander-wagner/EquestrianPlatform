import { test, expect } from "@playwright/test";

// Golden-path coverage for the Customer Portal booking flow. Uses the
// test.customer account created during Phase 1 development (see
// PLATFORM_ROADMAP.md / M5 commit) — a dedicated seeded test account is a
// Phase 2 CI concern. Creates its own uniquely-named rider each run so
// repeated runs don't depend on or collide with prior state.

test.describe("Customer Portal — booking golden path", () => {
  test("staff login reaches the livery dashboard", async ({ page }) => {
    await page.goto("/");
    await page.fill("#username", "admin");
    await page.fill('input[type="password"]', "LocalDev123!");
    await page.click('button[type="submit"]');
    await expect(page.getByText("Total Checked-In Horses")).toBeVisible({ timeout: 10000 });
  });

  test("customer can add a rider, book a class, see it on the dashboard, then cancel it", async ({ page }) => {
    const riderName = `E2E Test Rider ${Date.now()}`;

    // Log in as the customer
    await page.goto("/");
    await page.fill("#username", "test.customer");
    await page.fill('input[type="password"]', "CustomerPass123!");
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL(/\/portal$/);

    // Add a rider — must set a riding level, since the available lessons in
    // this environment are level-gated (Beginner Group Lesson requires
    // Beginner), and a rider with no level assigned can't book any
    // level-gated class (correct app behavior, not a test artifact).
    await page.goto("/portal/my-riders");
    await page.click('[data-testid="button-new-rider"]');
    await page.fill('[data-testid="input-rider-name"]', riderName);
    await page.click('[data-testid="select-rider-level"]');
    await page.getByRole("option", { name: "Beginner" }).click();
    await page.click('[data-testid="button-submit-rider"]');
    await expect(page.getByText(riderName)).toBeVisible();

    // Book the first available class for this rider
    await page.goto("/portal/calendar");
    const firstBookButton = page.locator('button[data-testid^="button-book-lesson-"]').first();
    await firstBookButton.click();
    await page.click('[data-testid="select-booking-rider"]');
    await page.getByRole("option", { name: riderName }).click();
    await page.click('[data-testid="button-confirm-booking"]');
    await expect(page.getByText(`— ${riderName}`)).toBeVisible();

    // Dashboard reflects it
    await page.goto("/portal");
    await expect(page.getByText(riderName)).toBeVisible();

    // Cancel it from the calendar — scope to this specific booking's card
    // (not just any div containing the rider's name) and check only that
    // one disappears; the account may have other, unrelated active
    // bookings from prior sessions/demo data.
    await page.goto("/portal/calendar");
    const bookingCard = page.locator('[data-testid^="card-booking-"]', { hasText: riderName });
    await bookingCard.getByTestId(/^button-cancel-booking-/).click();
    await expect(page.getByText(`— ${riderName}`)).not.toBeVisible();
  });
});
