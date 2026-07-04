import { storage } from "../../storage";

export interface CreateChargeInput {
  customerId: string;
  amount: string;
  description: string;
}

export interface PaymentProvider {
  createCharge(input: CreateChargeInput): Promise<{ invoiceId: string }>;
  refund(input: CreateChargeInput): Promise<void>;
  issueCredit(input: CreateChargeInput): Promise<void>;
}

// Phase 1: no real payment capture. A package purchase creates an invoice
// (APPROVED, same convention as livery invoices today) and finance
// reconciles from there — mirrors the existing livery flow.
//
// NOTE: this intentionally does NOT push a NetSuite Sales Order yet. The
// existing SO generation/push (server/routes.ts ~1203 and ~1500) is live
// production financial integration code; refactoring it into a shared
// helper is real work with real risk, and there's no riding-school UI
// consuming it yet (that lands in M4/M5). Once the package-purchase UI
// exists to actually exercise this end-to-end, extract that logic into a
// shared helper and call it from here — the PaymentProvider boundary below
// is exactly what makes that a contained, later change.
export const simulatedPaymentProvider: PaymentProvider = {
  async createCharge({ customerId, amount, description }): Promise<{ invoiceId: string }> {
    const poNumber = await storage.getNextPoNumber();
    const invoice = await storage.createInvoice({
      customerId,
      invoiceDate: new Date().toISOString().slice(0, 10),
      billingMonth: new Date().toISOString().slice(0, 7),
      totalAmount: amount,
      status: "APPROVED",
      soGenerated: false,
      sentToNetsuite: false,
      poNumber,
      netsuiteJson: null,
    } as any);
    void description; // reserved for the real SO push (see note above)
    return { invoiceId: invoice.id };
  },

  async refund({ customerId }): Promise<void> {
    // Phase 1: no real money movement to reverse. Cancellation credit is
    // handled entirely via rs_package_purchases.lessonsRemaining or
    // rs_credit_vouchers (see scheduling.ts cancelBooking) — this hook
    // exists for when a real payment rail (Stripe) is wired in.
    void customerId;
  },

  async issueCredit({ customerId, description }): Promise<void> {
    // Phase 1: cancellation vouchers are issued directly in
    // scheduling.ts's cancelBooking (rs_credit_vouchers), not through this
    // interface. Reserved for Phase 3 when a real payment rail is wired in.
    void customerId;
    void description;
  },
};
