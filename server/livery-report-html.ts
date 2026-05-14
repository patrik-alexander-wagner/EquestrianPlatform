// Server-rendered print-ready HTML for the Livery Report.
// Mirrors design_handoff_livery_report/livery-report-pdf-reference.html
// and is fed live data from storage.getLiveryReport().

type Roster = {
  index: number;
  customerId: string;
  customerName: string;
  stable: string;
  boxId: string;
  horseName: string | null;
  breedingName: string | null;
  arrivalDate: string;
  departureDate: string | null;
  packageMonthly: number;
  tags: string[];
};

type ReportData = {
  month: string;
  generatedAt: string;
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
  revenue: { total: number; livery: number; service: number };
  trends: {
    perMonth: Array<{ label: string; livery: number; service: number; mtd?: boolean }>;
    topByContract: Array<{ name: string; horses: number; monthlyValue: number }>;
  };
  stables: Array<{ name: string; occupied: number; capacity: number }>;
  arrivals: Roster[];
  departures: Roster[];
  roster: Roster[];
};

const esc = (v: unknown): string =>
  String(v ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");

const fmtAmt = (n: number): string => Math.round(n).toLocaleString("en-US");

const fmtDate = (iso: string | null | undefined): string => {
  if (!iso) return "—";
  const [y, m, d] = iso.slice(0, 10).split("-").map(Number);
  if (!y || !m || !d || m < 1 || m > 12) return esc(iso);
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return `${d} ${months[m - 1]} ${y}`;
};

const monthLabel = (ym: string): string => {
  const [y, m] = ym.split("-").map(Number);
  return `${["January","February","March","April","May","June","July","August","September","October","November","December"][m - 1]} ${y}`;
};

const shortMonthLabel = (ym: string): string => {
  const [y, m] = ym.split("-").map(Number);
  return `${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m - 1]} ${String(y).slice(2)}`;
};

const periodRange = (ym: string): string => {
  const [y, m] = ym.split("-").map(Number);
  const last = new Date(y, m, 0).getDate();
  const monthName = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m - 1];
  return `1 – ${last} ${monthName} ${y}`;
};

const STABLEMASTER_LOGO = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4c-2 1.5-3 4-3 7 0 4.5 2.5 8 5 9M17 4c2 1.5 3 4 3 7 0 4.5-2.5 8-5 9"/></svg>`;

function renderRunnerTop(periodLabel: string, sectionName: string): string {
  return `<header class="runner-top">
    <div class="left">
      <div class="logo">${STABLEMASTER_LOGO}</div>
      <span class="title">Livery Report <small>· ${esc(periodLabel)}</small></span>
    </div>
    <span>${esc(sectionName)}</span>
  </header>`;
}

function renderRunnerBottom(page: number, total: number): string {
  return `<div class="runner-bottom">
    <span>Stable Master · ADEC Livery</span>
    <span>Page <strong>${page}</strong> of ${total}</span>
  </div>`;
}

function renderKpis(d: ReportData, periodLabel: string): string {
  const op = d.operational;
  const biz = d.business;
  const adecPct = op.totalCheckedIn > 0 ? Math.round((op.adecHorses / op.totalCheckedIn) * 100) : 0;
  const custPct = 100 - adecPct;
  const top = biz.topCustomer;
  return `<div class="kpis">
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Checked-In Horses</span>
        <span class="kpi-icon green">${STABLEMASTER_LOGO}</span>
      </div>
      <div class="kpi-value tnum">${op.totalCheckedIn}</div>
      <div class="bar">
        <span class="b-navy" style="width:${adecPct}%"></span>
        <span class="b-green" style="width:${custPct}%"></span>
      </div>
      <div class="legend">
        <span><span class="sw" style="background:#1E3A5F"></span>ADEC ${op.adecHorses}</span>
        <span><span class="sw" style="background:#1F9D55"></span>Customer ${op.customerHorses}</span>
      </div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">ADEC Horses</span>
        <span class="kpi-icon navy"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l8 2v6c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V5l8-2z"/><path d="M9 12l2 2 4-4"/></svg></span>
      </div>
      <div class="kpi-value tnum">${op.adecHorses}</div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Customer Livery Horses</span>
        <span class="kpi-icon green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M21 19c0-2.2-1.5-4-3.5-4.5"/></svg></span>
      </div>
      <div class="kpi-value tnum">${op.customerHorses}</div>
      <div class="kpi-foot"><span>${op.arrivalsThisMonth} new arrival${op.arrivalsThisMonth === 1 ? "" : "s"} this month</span></div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Occupancy Rate</span>
        <span class="kpi-icon purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 1 18 0"/><path d="M12 12l4-3"/></svg></span>
      </div>
      <div class="kpi-value tnum">${op.occupancyRate}<span class="unit">%</span></div>
      <div class="bar"><span class="b-green" style="width:${op.occupancyRate}%"></span></div>
      <div class="kpi-foot"><span>${op.totalCheckedIn} / ${op.totalCapacity} boxes occupied</span></div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Active Customers</span>
        <span class="kpi-icon green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="3.5"/><path d="M5 21c0-3.9 3.1-7 7-7s7 3.1 7 7"/></svg></span>
      </div>
      <div class="kpi-value tnum">${biz.activeCustomers}</div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Active Agreements</span>
        <span class="kpi-icon orange"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h9l4 4v14H6z"/><path d="M15 3v4h4"/><path d="M9 13h7M9 17h5"/></svg></span>
      </div>
      <div class="kpi-value tnum">${biz.activeAgreements}</div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Monthly Revenue (MTD)</span>
        <span class="kpi-icon purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M15 9.5C14.2 8.5 13.2 8 12 8c-1.7 0-3 1-3 2.2 0 1.3 1.3 1.8 3 2.3 1.7.5 3 1 3 2.3 0 1.2-1.3 2.2-3 2.2-1.2 0-2.2-.5-3-1.5"/><path d="M12 7v10"/></svg></span>
      </div>
      <div class="kpi-value tnum"><span class="prefix">AED</span>${fmtAmt(biz.revenueMTD)}</div>
      <div class="kpi-foot"><strong>Prev: AED ${fmtAmt(biz.revenuePrevMonth)}</strong></div>
    </div>
    <div class="kpi">
      <div class="kpi-head">
        <span class="kpi-label">Top Customer</span>
        <span class="kpi-icon orange"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 4h8v3a4 4 0 0 1-8 0V4z"/><path d="M16 5h3v2a3 3 0 0 1-3 3M8 5H5v2a3 3 0 0 0 3 3"/><path d="M9 13h6l-.5 4h-5z"/><path d="M7 20h10"/></svg></span>
      </div>
      <div class="kpi-name">${esc(top?.name || "—")}</div>
      ${top ? `<div class="kpi-foot"><span>${top.horses} horse${top.horses === 1 ? "" : "s"}</span><strong>AED ${fmtAmt(top.monthlyValue)} / mo</strong></div>` : ""}
    </div>
  </div>`;
}

function renderObservations(d: ReportData, periodLabel: string): string {
  const items: string[] = [];
  items.push(`<strong>Occupancy at ${d.operational.occupancyRate}%</strong> — ${d.operational.totalCapacity - d.operational.totalCheckedIn} boxes remain available across ${d.stables.length} stable${d.stables.length === 1 ? "" : "s"}.`);
  items.push(`<strong>${d.arrivals.length} arrival${d.arrivals.length === 1 ? "" : "s"} recorded</strong> in ${periodLabel}.`);
  items.push(`<strong>${d.departures.length} departure${d.departures.length === 1 ? "" : "s"}</strong> recorded for the period.`);
  items.push(`<strong>Current MTD revenue</strong> AED ${fmtAmt(d.revenue.total)} — Livery AED ${fmtAmt(d.revenue.livery)}, Service AED ${fmtAmt(d.revenue.service)}.`);
  if (d.business.topCustomer) {
    items.push(`<strong>Top revenue customer</strong> by active contract value is ${esc(d.business.topCustomer.name)} (${d.business.topCustomer.horses} horses, AED ${fmtAmt(d.business.topCustomer.monthlyValue)}/mo); previous month total revenue closed at AED ${fmtAmt(d.business.revenuePrevMonth)}.`);
  }
  return `<div style="border:1px solid var(--border); border-radius:6pt; padding:11pt 14pt; font-size:9.5pt; line-height:1.55;">
    <ul style="margin:0; padding-left:14pt; color:var(--text-2);">
      ${items.map(i => `<li>${i}</li>`).join("")}
    </ul>
  </div>`;
}

function renderRevBreakdown(d: ReportData): string {
  return `<div class="rev-grid">
    <div class="rev-cell total">
      <div class="lbl">Total Revenue</div>
      <div class="amt"><span class="cur">AED</span>${fmtAmt(d.revenue.total)}</div>
      <div class="note">All sources</div>
    </div>
    <div class="rev-cell">
      <div class="lbl">Livery Revenue</div>
      <div class="amt"><span class="cur">AED</span>${d.revenue.livery > 0 ? fmtAmt(d.revenue.livery) : '<span style="color:var(--muted-2)">0</span>'}</div>
      <div class="note">Livery package</div>
    </div>
    <div class="rev-cell">
      <div class="lbl">Service Revenue</div>
      <div class="amt"><span class="cur">AED</span>${fmtAmt(d.revenue.service)}</div>
      <div class="note">Clinic, Farrier, Stores &amp; Extras</div>
    </div>
  </div>`;
}

function renderTopList(d: ReportData): string {
  const list = d.trends.topByContract;
  if (!list.length) return `<div class="top-customers"><div class="row"><span class="rank" style="grid-column:1/-1; text-align:center; color:var(--muted)">No customers</span></div></div>`;
  return `<div class="top-customers">
    ${list.map((c, i) => `
      <div class="row">
        <span class="rank">${String(i + 1).padStart(2, "0")}</span>
        <span class="name">${esc(c.name)}</span>
        <span class="horses">${c.horses} ${c.horses === 1 ? "horse" : "horses"}</span>
        <span class="amt">AED ${fmtAmt(c.monthlyValue)}</span>
      </div>
    `).join("")}
  </div>`;
}

function renderMovementRow(r: Roster): string {
  const horseTitle = r.horseName ? `${esc(r.horseName)}${r.breedingName && r.breedingName !== r.horseName ? ` <span style="color:var(--muted); font-weight:400;">(${esc(r.breedingName)})</span>` : ""}` : "<span style='color:var(--muted-2)'>—</span>";
  const dateLabel = r.departureDate ? `departed ${fmtDate(r.departureDate)}` : `arrived ${fmtDate(r.arrivalDate)}`;
  return `<div class="move-row">
    <div class="ico">${STABLEMASTER_LOGO}</div>
    <div>
      <div class="title">${horseTitle}</div>
      <div class="sub">${esc(r.customerId)} · ${esc(r.customerName)} · ${dateLabel}</div>
    </div>
    <div class="right">
      AED ${fmtAmt(r.packageMonthly)}
      <span class="small">/mo · ${esc(r.boxId)}</span>
    </div>
  </div>`;
}

function renderArrivals(d: ReportData): string {
  if (d.arrivals.length === 0) {
    return `<div class="move-card"><div class="move-empty">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 17l-5-5 5-5"/><path d="M3 12h12"/><path d="M15 4h4v16h-4"/></svg>
      No arrivals recorded for ${esc(monthLabel(d.month))}.
    </div></div>`;
  }
  return `<div class="move-card">${d.arrivals.map(renderMovementRow).join("")}</div>`;
}

function renderDepartures(d: ReportData): string {
  if (d.departures.length === 0) {
    return `<div class="move-card"><div class="move-empty">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/><path d="M9 4H5v16h4"/></svg>
      No departures recorded for ${esc(monthLabel(d.month))}.
    </div></div>`;
  }
  return `<div class="move-card">${d.departures.map(renderMovementRow).join("")}</div>`;
}

function renderStableMix(d: ReportData): string {
  if (!d.stables.length) return "";
  return `<div class="two-col">
    ${d.stables.map(s => {
      const pct = s.capacity > 0 ? Math.round((s.occupied / s.capacity) * 100) : 0;
      return `<div style="border:1px solid var(--border); border-radius:6pt; padding:12pt 14pt;">
        <div style="font-size:8pt; color:var(--muted); letter-spacing:.06em; text-transform:uppercase; margin-bottom:6pt;">${esc(s.name)} Stable</div>
        <div style="font-size:22pt; font-weight:700; font-variant-numeric:tabular-nums; letter-spacing:-.01em;">${s.occupied} / ${s.capacity}</div>
        <div style="font-size:8.5pt; color:var(--muted); margin:4pt 0 8pt;">boxes occupied · ${pct}%</div>
        <div class="bar"><span class="b-green" style="width:${pct}%"></span></div>
      </div>`;
    }).join("")}
  </div>`;
}

function renderRosterRows(d: ReportData): string {
  if (!d.roster.length) {
    return `<tr><td colspan="6" style="text-align:center; padding:24pt; color:var(--muted)">No active agreements for the selected period.</td></tr>`;
  }
  return d.roster.map((r, i) => {
    const isNew = (r.tags || []).includes("new");
    const horseLine = r.horseName
      ? `<div class="horse-name">${esc(r.horseName)}</div>${r.breedingName && r.breedingName !== r.horseName ? `<div class="horse-sub">${esc(r.breedingName)}</div>` : ""}`
      : `<div class="horse-name"><span class="empty">—</span></div>`;
    return `<tr>
      <td class="idx">${i + 1}</td>
      <td>
        <div class="cust-name">${esc(r.customerName)}${isNew ? '<span class="badge-new">New</span>' : ""}</div>
        <div class="cust-id">${esc(r.customerId)}</div>
      </td>
      <td>
        <div class="box-name">${esc(r.stable)}</div>
        <div class="box-id">${esc(r.boxId)}</div>
      </td>
      <td>${horseLine}</td>
      <td class="date">${fmtDate(r.arrivalDate)}</td>
      <td class="num"><span class="pkg">AED ${fmtAmt(r.packageMonthly)}<span class="per"> /mo</span></span></td>
    </tr>`;
  }).join("");
}

export function renderLiveryReportHtml(d: ReportData, opts: { autoPrint?: boolean } = {}): string {
  const periodLabel = monthLabel(d.month);
  const periodShort = periodLabel;
  const generatedDate = fmtDate(d.generatedAt.slice(0, 10));
  const TOTAL_PAGES = 5;
  const perMonthForChart = d.trends.perMonth.map(p => ({
    label: shortMonthLabel(p.label),
    livery: p.livery,
    service: p.service,
    mtd: !!p.mtd,
  }));

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>Livery Report · ${esc(periodLabel)}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
  @page { size: A4 portrait; margin: 16mm 14mm 18mm 14mm; }
  @page :first { margin: 0; }
  :root {
    --bg: #FFFFFF; --surface: #FFFFFF; --surface-2: #F4F5F7;
    --border: #E5E7EB; --border-soft: #EEF0F2;
    --text: #111827; --text-2: #374151; --muted: #6B7280; --muted-2: #9CA3AF;
    --navy: #1E3A5F; --green: #1F9D55; --green-700: #167A40; --green-50: #E8F5EE;
    --orange: #D97706; --purple: #7C3AED;
  }
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; background: #E5E7EB; }
  body {
    font-family: 'Open Sans', ui-sans-serif, sans-serif;
    color: var(--text); font-size: 10pt; line-height: 1.5;
    -webkit-font-smoothing: antialiased;
    print-color-adjust: exact; -webkit-print-color-adjust: exact;
  }
  .tnum { font-variant-numeric: tabular-nums; }
  .page {
    width: 210mm; min-height: 297mm;
    margin: 12mm auto; background: #fff;
    padding: 16mm 14mm 22mm 14mm; position: relative;
    box-shadow: 0 4px 20px rgba(0,0,0,.08); overflow: hidden;
  }
  .page.cover { padding: 0; }
  .runner-top {
    display: flex; align-items: center; justify-content: space-between;
    padding-bottom: 10pt; border-bottom: 1px solid var(--border);
    margin-bottom: 16pt; font-size: 8.5pt; color: var(--muted);
  }
  .runner-top .left { display: flex; align-items: center; gap: 8pt; }
  .runner-top .logo {
    width: 22pt; height: 22pt; background: var(--green);
    border-radius: 5pt; display: grid; place-items: center; color: #fff;
  }
  .runner-top .logo svg { width: 14pt; height: 14pt; }
  .runner-top .title { font-weight: 600; color: var(--text); font-size: 9pt; }
  .runner-top .title small { color: var(--muted); font-weight: 400; margin-left: 4pt; }
  .runner-bottom {
    position: absolute; left: 14mm; right: 14mm; bottom: 10mm;
    display: flex; justify-content: space-between;
    font-size: 8pt; color: var(--muted);
    padding-top: 6pt; border-top: 1px solid var(--border-soft);
  }
  @media print {
    html, body { background: #fff; }
    .page {
      margin: 0; box-shadow: none;
      width: auto; min-height: auto; padding: 0;
      page-break-after: always; page-break-inside: avoid;
    }
    .page.cover { padding: 0; }
    .page:last-of-type { page-break-after: auto; }
    .no-print { display: none !important; }
    .roster-page { page-break-inside: auto; }
    table.roster { page-break-inside: auto; }
    table.roster thead { display: table-header-group; }
    table.roster tr { page-break-inside: avoid; page-break-after: auto; }
    @page { margin: 16mm 14mm 18mm 14mm; }
  }
  .print-bar {
    position: fixed; top: 12px; right: 12px; z-index: 100;
    display: flex; gap: 8px; background: #fff;
    border: 1px solid var(--border); border-radius: 10px;
    padding: 6px; box-shadow: 0 8px 24px rgba(0,0,0,.12);
  }
  .print-bar button {
    background: var(--green); border: 0; color: #fff;
    padding: 8px 14px; border-radius: 6px;
    font: 600 12px 'Open Sans', sans-serif; cursor: pointer;
    display: inline-flex; align-items: center; gap: 6px;
  }
  .print-bar button svg { width: 14px; height: 14px; }
  .print-bar .hint {
    font: 11px 'Open Sans', sans-serif; color: var(--muted);
    display: flex; align-items: center; padding: 0 8px;
  }
  /* Cover */
  .cover-inner { height: 297mm; display: grid; grid-template-rows: 1.05fr 1fr; color: var(--text); }
  .cover-top {
    background: var(--green); color: #fff;
    padding: 22mm 18mm 18mm; position: relative; overflow: hidden;
  }
  .cover-top::after {
    content: ''; position: absolute; right: -40mm; top: -40mm;
    width: 140mm; height: 140mm;
    border: 1.5pt solid rgba(255,255,255,.15); border-radius: 50%;
  }
  .cover-top::before {
    content: ''; position: absolute; right: -10mm; bottom: -50mm;
    width: 100mm; height: 100mm;
    border: 1.5pt solid rgba(255,255,255,.12); border-radius: 50%;
  }
  .cover-brand { display: flex; align-items: center; gap: 10pt; margin-bottom: 30mm; }
  .cover-brand .mark {
    width: 36pt; height: 36pt; background: rgba(255,255,255,.18);
    border: 1pt solid rgba(255,255,255,.4); border-radius: 8pt;
    display: grid; place-items: center;
  }
  .cover-brand .mark svg { width: 22pt; height: 22pt; color: #fff; }
  .cover-brand .name { font-weight: 700; font-size: 14pt; color: #fff; line-height: 1.1; }
  .cover-brand .role { font-size: 9pt; color: rgba(255,255,255,.85); margin-top: 2pt; }
  .cover-kicker {
    font-size: 10pt; letter-spacing: .18em; text-transform: uppercase;
    color: rgba(255,255,255,.7); font-weight: 500; margin-bottom: 8pt;
  }
  .cover-title { font-size: 48pt; font-weight: 700; line-height: 1; letter-spacing: -.02em; margin: 0 0 14pt; }
  .cover-period { font-size: 22pt; font-weight: 500; color: rgba(255,255,255,.92); letter-spacing: -.005em; }
  .cover-bottom { padding: 16mm 18mm; display: grid; grid-template-rows: auto 1fr auto; gap: 10mm; }
  .cover-meta {
    display: grid; grid-template-columns: repeat(3, 1fr); gap: 0;
    border-top: 1px solid var(--border); border-bottom: 1px solid var(--border);
    padding: 10pt 0;
  }
  .cover-meta > div { padding: 0 10pt; border-right: 1px solid var(--border-soft); }
  .cover-meta > div:last-child { border-right: none; }
  .cover-meta .lbl { font-size: 8pt; letter-spacing: .2em; text-transform: uppercase; color: var(--muted); margin-bottom: 4pt; }
  .cover-meta .val { font-size: 12pt; font-weight: 600; color: var(--text); }
  .cover-toc { display: flex; flex-direction: column; }
  .cover-toc h3 { font-size: 9pt; letter-spacing: .2em; text-transform: uppercase; color: var(--muted); margin: 0 0 8pt; font-weight: 500; }
  .cover-toc ol { list-style: none; padding: 0; margin: 0; counter-reset: tocnum; }
  .cover-toc li {
    counter-increment: tocnum;
    display: grid; grid-template-columns: 22pt 1fr auto; gap: 8pt;
    padding: 7pt 0; border-bottom: 1px dashed var(--border-soft);
    align-items: baseline;
  }
  .cover-toc li::before {
    content: counter(tocnum, decimal-leading-zero);
    font-variant-numeric: tabular-nums;
    color: var(--green); font-weight: 600; font-size: 10pt;
  }
  .cover-toc li .name { font-size: 11pt; font-weight: 500; color: var(--text); }
  .cover-toc li .pg { font-size: 9pt; color: var(--muted); font-variant-numeric: tabular-nums; }
  .cover-foot { display: flex; justify-content: space-between; align-items: end; font-size: 8.5pt; color: var(--muted); }
  .cover-foot strong { color: var(--text); font-weight: 600; }
  /* Section heading */
  .h-section { margin: 0 0 12pt; }
  .h-section .eyebrow { font-size: 8pt; letter-spacing: .2em; text-transform: uppercase; color: var(--green-700); font-weight: 600; margin-bottom: 4pt; }
  .h-section h2 { margin: 0; font-size: 18pt; font-weight: 700; letter-spacing: -.005em; }
  .h-section .sub { margin: 4pt 0 0; color: var(--muted); font-size: 9.5pt; }
  .subhead { display: flex; align-items: baseline; justify-content: space-between; margin: 14pt 0 8pt; }
  .subhead h3 { margin: 0; font-size: 11pt; font-weight: 700; }
  .subhead .meta { color: var(--muted); font-size: 8.5pt; letter-spacing: .14em; text-transform: uppercase; }
  /* KPI grid */
  .kpis { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0; border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; }
  .kpi {
    padding: 10pt 11pt 11pt;
    border-right: 1px solid var(--border-soft);
    border-bottom: 1px solid var(--border-soft);
    min-height: 80pt; display: flex; flex-direction: column; gap: 6pt; background: #fff;
  }
  .kpis .kpi:nth-child(4n) { border-right: none; }
  .kpis .kpi:nth-last-child(-n+4) { border-bottom: none; }
  .kpi-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 8pt; }
  .kpi-label { font-size: 8pt; color: var(--muted); font-weight: 500; letter-spacing: .04em; text-transform: uppercase; }
  .kpi-icon { color: var(--muted-2); flex-shrink: 0; }
  .kpi-icon svg { width: 13pt; height: 13pt; }
  .kpi-icon.green { color: var(--green); }
  .kpi-icon.orange { color: var(--orange); }
  .kpi-icon.purple { color: var(--purple); }
  .kpi-icon.navy { color: var(--navy); }
  .kpi-value { font-size: 22pt; font-weight: 700; line-height: 1.05; letter-spacing: -.015em; font-variant-numeric: tabular-nums; color: var(--text); }
  .kpi-value .unit { font-size: 11pt; color: var(--muted); font-weight: 500; margin-left: 3pt; }
  .kpi-value .prefix { font-size: 10pt; color: var(--muted); font-weight: 500; margin-right: 4pt; }
  .kpi-name { font-size: 13pt; font-weight: 700; color: var(--navy); letter-spacing: -.005em; line-height: 1.15; }
  .kpi-foot { margin-top: auto; font-size: 8pt; color: var(--muted); display: flex; justify-content: space-between; gap: 8pt; }
  .kpi-foot strong { color: var(--text-2); font-weight: 600; }
  .bar { height: 4pt; background: var(--surface-2); border-radius: 99pt; overflow: hidden; display: flex; }
  .bar > span { display: block; height: 100%; }
  .bar .b-green { background: var(--green); }
  .bar .b-navy { background: var(--navy); }
  .legend { display: flex; gap: 10pt; font-size: 8pt; color: var(--muted); }
  .legend .sw { width: 6pt; height: 6pt; border-radius: 1.5pt; display: inline-block; margin-right: 4pt; vertical-align: middle; }
  /* Revenue */
  .rev-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0; border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; margin-bottom: 14pt; }
  .rev-cell { padding: 12pt 14pt; border-right: 1px solid var(--border-soft); background: #fff; }
  .rev-cell:last-child { border-right: none; }
  .rev-cell.total { background: linear-gradient(180deg, rgba(31,157,85,.05), rgba(31,157,85,0)); }
  .rev-cell .lbl { font-size: 8pt; color: var(--muted); font-weight: 500; letter-spacing: .04em; text-transform: uppercase; }
  .rev-cell .amt { font-size: 22pt; font-weight: 700; margin: 6pt 0 3pt; font-variant-numeric: tabular-nums; letter-spacing: -.01em; }
  .rev-cell .amt .cur { font-size: 10pt; color: var(--muted); font-weight: 500; margin-right: 4pt; }
  .rev-cell .note { font-size: 8.5pt; color: var(--muted); }
  /* Chart */
  .chart-card { border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; margin-bottom: 14pt; }
  .chart-head { padding: 9pt 14pt; border-bottom: 1px solid var(--border-soft); display: flex; align-items: center; justify-content: space-between; }
  .chart-head h4 { margin: 0; font-size: 10pt; font-weight: 700; }
  .chart-head .legend { font-size: 8.5pt; }
  .chart-wrap { padding: 10pt 14pt 14pt; }
  .chart-svg { width: 100%; height: 200pt; display: block; }
  .chart-svg .grid-line { stroke: var(--border-soft); stroke-width: .6; }
  .chart-svg .axis-label { fill: var(--muted); font-size: 7pt; font-family: 'Open Sans', sans-serif; }
  .chart-svg .bar-livery { fill: #1F9D55; }
  .chart-svg .bar-service { fill: #1E3A5F; }
  .chart-svg .bar-value { fill: var(--text-2); font-size: 6.5pt; font-family: 'Open Sans', sans-serif; font-weight: 600; text-anchor: middle; }
  /* Top customers list */
  .top-customers { border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; }
  .top-customers .row {
    display: grid; grid-template-columns: 14pt 1fr auto auto;
    align-items: center; gap: 10pt; padding: 8pt 12pt;
    border-bottom: 1px solid var(--border-soft); font-size: 9.5pt;
  }
  .top-customers .row:last-child { border-bottom: none; }
  .top-customers .row .rank { font-size: 8pt; color: var(--muted); font-variant-numeric: tabular-nums; }
  .top-customers .row .name { font-weight: 600; color: var(--navy); }
  .top-customers .row .horses { color: var(--muted); font-size: 8.5pt; }
  .top-customers .row .amt { font-weight: 600; font-variant-numeric: tabular-nums; }
  /* Movement */
  .move-card { border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; margin-bottom: 10pt; }
  .move-row {
    display: grid; grid-template-columns: 26pt 1fr auto;
    align-items: center; gap: 12pt; padding: 9pt 14pt;
    border-bottom: 1px solid var(--border-soft);
  }
  .move-row:last-child { border-bottom: none; }
  .move-row .ico { width: 24pt; height: 24pt; border-radius: 4pt; background: var(--green); color: #fff; display: grid; place-items: center; }
  .move-row .ico svg { width: 14pt; height: 14pt; }
  .move-row .title { font-weight: 700; font-size: 10pt; color: var(--navy); }
  .move-row .sub { font-size: 8.5pt; color: var(--muted); margin-top: 2pt; }
  .move-row .right { text-align: right; font-size: 9.5pt; font-weight: 600; font-variant-numeric: tabular-nums; }
  .move-row .right .small { display: block; font-size: 8pt; color: var(--muted); font-weight: 400; margin-top: 2pt; }
  .move-empty { padding: 18pt 14pt; text-align: center; color: var(--muted); font-size: 9pt; }
  .move-empty svg { width: 18pt; height: 18pt; color: var(--muted-2); display: block; margin: 0 auto 6pt; }
  /* Roster */
  table.roster { width: 100%; border-collapse: collapse; font-size: 8.5pt; border: 1px solid var(--border); border-radius: 6pt; overflow: hidden; }
  table.roster thead th { text-align: left; background: var(--surface-2); color: var(--muted); font-size: 7.5pt; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; padding: 7pt 8pt; border-bottom: 1px solid var(--border); white-space: nowrap; }
  table.roster thead th.num { text-align: right; }
  table.roster tbody td { padding: 6pt 8pt; border-bottom: 1px solid var(--border-soft); vertical-align: top; color: var(--text-2); }
  table.roster tbody tr:nth-child(even) td { background: #FCFCFD; }
  table.roster tbody td.num { text-align: right; font-variant-numeric: tabular-nums; }
  table.roster .idx { color: var(--muted-2); font-size: 7.5pt; font-variant-numeric: tabular-nums; }
  table.roster .cust-name { font-weight: 600; color: var(--navy); font-size: 9pt; }
  table.roster .cust-id { color: var(--muted); font-size: 7.5pt; margin-top: 1pt; }
  table.roster .box-name { font-weight: 500; color: var(--text-2); }
  table.roster .box-id { color: var(--muted); font-size: 7.5pt; margin-top: 1pt; }
  table.roster .horse-name { font-weight: 500; color: var(--text); }
  table.roster .horse-sub { color: var(--muted); font-size: 7.5pt; font-style: italic; margin-top: 1pt; }
  table.roster .date { color: var(--muted); white-space: nowrap; font-size: 8pt; font-variant-numeric: tabular-nums; }
  table.roster .pkg { font-weight: 600; color: var(--text); font-variant-numeric: tabular-nums; }
  table.roster .pkg .per { color: var(--muted); font-weight: 400; font-size: 7.5pt; }
  table.roster .empty { color: var(--muted-2); }
  table.roster .badge-new {
    display: inline-block; padding: 1pt 5pt; border-radius: 99pt;
    background: var(--green-50); color: var(--green-700);
    border: .5pt solid var(--green); font-size: 6.5pt; font-weight: 600;
    letter-spacing: .04em; text-transform: uppercase;
    margin-left: 4pt; vertical-align: middle;
  }
  .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 10pt; }
</style>
</head>
<body>

<div class="print-bar no-print">
  <span class="hint">Use <strong>Print</strong> → Save as PDF</span>
  <button id="btnPrint" type="button">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 9V3h12v6"/><rect x="3" y="9" width="18" height="9" rx="1"/><rect x="6" y="14" width="12" height="7"/></svg>
    Print / Save PDF
  </button>
</div>

<!-- PAGE 1 · COVER -->
<section class="page cover">
  <div class="cover-inner">
    <div class="cover-top">
      <div class="cover-brand">
        <div class="mark">${STABLEMASTER_LOGO}</div>
        <div>
          <div class="name">StableMaster</div>
          <div class="role">Stable Management · ADEC</div>
        </div>
      </div>
      <div class="cover-kicker">Monthly Livery Report</div>
      <h1 class="cover-title">Livery Report</h1>
      <div class="cover-period">${esc(periodLabel)}</div>
    </div>
    <div class="cover-bottom">
      <div class="cover-meta">
        <div><div class="lbl">Period</div><div class="val">${esc(periodRange(d.month))}</div></div>
        <div><div class="lbl">Generated</div><div class="val">${esc(generatedDate)}</div></div>
        <div><div class="lbl">Prepared by</div><div class="val">Stable Master · ADEC</div></div>
      </div>
      <div class="cover-toc">
        <h3>Contents</h3>
        <ol>
          <li><span class="name">Executive Summary</span><span class="pg">p. 2</span></li>
          <li><span class="name">Revenue &amp; Trends</span><span class="pg">p. 3</span></li>
          <li><span class="name">Movement — Arrivals &amp; Departures</span><span class="pg">p. 4</span></li>
          <li><span class="name">Customer Roster — Active Agreements</span><span class="pg">p. 5</span></li>
        </ol>
      </div>
      <div class="cover-foot">
        <span><strong>Confidential.</strong> For internal stable operations use only.</span>
        <span>Page <strong>1</strong> of ${TOTAL_PAGES}</span>
      </div>
    </div>
  </div>
</section>

<!-- PAGE 2 · EXECUTIVE SUMMARY -->
<section class="page">
  ${renderRunnerTop(periodShort, "Executive Summary")}
  <div class="h-section">
    <div class="eyebrow">Section 01</div>
    <h2>Executive Summary</h2>
    <p class="sub">A snapshot of stable operations and business performance as of ${esc(generatedDate)}.</p>
  </div>
  <div class="subhead">
    <h3>Operational &amp; Business Overview</h3>
    <span class="meta">Stable status — current</span>
  </div>
  ${renderKpis(d, periodShort)}
  <div class="subhead" style="margin-top:14pt;">
    <h3>Key Observations</h3>
    <span class="meta">Highlights</span>
  </div>
  ${renderObservations(d, periodLabel)}
  ${renderRunnerBottom(2, TOTAL_PAGES)}
</section>

<!-- PAGE 3 · REVENUE & TRENDS -->
<section class="page">
  ${renderRunnerTop(periodShort, "Revenue & Trends")}
  <div class="h-section">
    <div class="eyebrow">Section 02</div>
    <h2>Revenue &amp; Trends</h2>
    <p class="sub">Income breakdown for ${esc(periodLabel)} and 12-month trailing performance.</p>
  </div>
  <div class="subhead">
    <h3>Revenue Breakdown · Month to Date</h3>
    <span class="meta">As of ${esc(generatedDate)}</span>
  </div>
  ${renderRevBreakdown(d)}
  <div class="chart-card">
    <div class="chart-head">
      <h4>12-Month Revenue Trend · Stacked</h4>
      <div class="legend">
        <span><span class="sw" style="background:#1F9D55"></span>Livery</span>
        <span><span class="sw" style="background:#1E3A5F"></span>Service</span>
      </div>
    </div>
    <div class="chart-wrap">
      <svg class="chart-svg" id="monthChart" viewBox="0 0 720 200" preserveAspectRatio="none"></svg>
    </div>
  </div>
  <div class="subhead">
    <h3>Top 10 Customers · By Active Monthly Value</h3>
    <span class="meta">Active monthly contract value</span>
  </div>
  ${renderTopList(d)}
  ${renderRunnerBottom(3, TOTAL_PAGES)}
</section>

<!-- PAGE 4 · MOVEMENT -->
<section class="page">
  ${renderRunnerTop(periodShort, "Movement")}
  <div class="h-section">
    <div class="eyebrow">Section 03</div>
    <h2>Movement — ${esc(periodLabel)}</h2>
    <p class="sub">Arrivals and departures recorded during the reporting period.</p>
  </div>
  <div class="subhead">
    <h3>Arrivals</h3>
    <span class="meta">${d.arrivals.length} check-in${d.arrivals.length === 1 ? "" : "s"}</span>
  </div>
  ${renderArrivals(d)}
  <div class="subhead">
    <h3>Departures</h3>
    <span class="meta">${d.departures.length} check-out${d.departures.length === 1 ? "" : "s"}</span>
  </div>
  ${renderDepartures(d)}
  <div class="subhead">
    <h3>Stable Capacity &amp; Mix</h3>
    <span class="meta">As of ${esc(generatedDate)}</span>
  </div>
  ${renderStableMix(d)}
  ${renderRunnerBottom(4, TOTAL_PAGES)}
</section>

<!-- PAGE 5+ · ROSTER -->
<section class="page roster-page">
  ${renderRunnerTop(periodShort, "Customer Roster")}
  <div class="h-section">
    <div class="eyebrow">Section 04</div>
    <h2>Customer Roster</h2>
    <p class="sub">All active livery agreements at ${esc(generatedDate)} · ${d.roster.length} record${d.roster.length === 1 ? "" : "s"} total.</p>
  </div>
  <table class="roster">
    <thead>
      <tr>
        <th style="width:18pt;">#</th>
        <th>Customer</th>
        <th>Box</th>
        <th>Horse</th>
        <th>Arrival</th>
        <th class="num">Package</th>
      </tr>
    </thead>
    <tbody>${renderRosterRows(d)}</tbody>
  </table>
  ${renderRunnerBottom(TOTAL_PAGES, TOTAL_PAGES)}
</section>

<script>
const monthData = ${JSON.stringify(perMonthForChart)};

function fmtK(n) {
  if (n === 0) return '0';
  if (n >= 1000) {
    const v = n / 1000;
    return (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1)) + 'K';
  }
  return String(Math.round(n));
}

function renderMonthChart() {
  const svg = document.getElementById('monthChart');
  if (!svg) return;
  const W = 720, H = 200;
  const m = { top: 12, right: 12, bottom: 30, left: 36 };
  const innerW = W - m.left - m.right;
  const innerH = H - m.top - m.bottom;
  const data = monthData;
  if (!data.length) return;
  const maxV = Math.max(1, ...data.map(d => d.livery + d.service)) * 1.08;
  const ticks = 4;
  const target = maxV / ticks;
  const mag = Math.pow(10, Math.floor(Math.log10(target)));
  const norm = target / mag;
  const nice = norm <= 1 ? 1 : norm <= 1.5 ? 1.5 : norm <= 2 ? 2 : norm <= 2.5 ? 2.5 : norm <= 3 ? 3 : norm <= 4 ? 4 : norm <= 5 ? 5 : norm <= 7.5 ? 7.5 : 10;
  const tickStep = nice * mag;
  const gridMax = tickStep * ticks;
  const slot = innerW / data.length;
  const barW = slot * 0.7;
  const off = (slot - barW) / 2;
  let html = '';
  for (let i = 0; i <= ticks; i++) {
    const y = m.top + innerH - (innerH * i / ticks);
    html += '<line class="grid-line" x1="' + m.left + '" x2="' + (m.left + innerW) + '" y1="' + y + '" y2="' + y + '"/>';
    html += '<text class="axis-label" x="' + (m.left - 5) + '" y="' + (y + 2.5) + '" text-anchor="end">' + fmtK(tickStep * i) + '</text>';
  }
  data.forEach((d, i) => {
    const x = m.left + i * slot + off;
    const lh = (d.livery / gridMax) * innerH;
    const sh = (d.service / gridMax) * innerH;
    const yL = m.top + innerH - lh;
    const yS = yL - sh;
    if (sh > 0) html += '<rect class="bar-service" x="' + x + '" y="' + yS + '" width="' + barW + '" height="' + sh + '" rx="1.5"/>';
    if (lh > 0) html += '<rect class="bar-livery" x="' + x + '" y="' + yL + '" width="' + barW + '" height="' + lh + '" rx="1.5"/>';
    const total = d.livery + d.service;
    if (total > 0) {
      html += '<text class="bar-value" x="' + (x + barW / 2) + '" y="' + (yS - 3) + '">' + fmtK(total) + (d.mtd ? ' MTD' : '') + '</text>';
    }
    html += '<text class="axis-label" x="' + (x + barW / 2) + '" y="' + (m.top + innerH + 12) + '" text-anchor="middle">' + d.label + '</text>';
  });
  svg.innerHTML = html;
}
renderMonthChart();
document.getElementById('btnPrint').addEventListener('click', function(){ window.print(); });
${opts.autoPrint ? `setTimeout(function(){ window.print(); }, 350);` : ""}
</script>

</body>
</html>`;
}
