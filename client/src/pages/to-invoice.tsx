import { useState, useMemo, useCallback } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { FileText, Trash2 } from "lucide-react";
import type { Customer } from "@shared/schema";

type LineItem = {
  key: string;
  type: "livery" | "billing";
  description: string;
  horseName: string | null;
  date: string;
  qty: number;
  unitPrice: number;
  amount: number;
  proRateLabel?: string;
  agreementId?: string;
  billingElementId?: string;
  horseId?: string;
  boxId?: string;
  itemId?: string;
  billingMonth?: string;
};

function getProRateFraction(agreement: any, billingMonth: string): { fraction: number; label: string } {
  const [bmYear, bmMonth] = billingMonth.split("-").map(Number);
  const daysInMonth = new Date(bmYear, bmMonth, 0).getDate();

  const startDate = agreement.startDate ? new Date(agreement.startDate) : null;
  const endDate = agreement.endDate ? new Date(agreement.endDate) : null;

  let firstDay = 1;
  let lastDay = daysInMonth;

  if (startDate && startDate.getFullYear() === bmYear && startDate.getMonth() + 1 === bmMonth && startDate.getDate() > 1) {
    firstDay = startDate.getDate();
  }

  if (endDate && endDate.getFullYear() === bmYear && endDate.getMonth() + 1 === bmMonth && endDate.getDate() < daysInMonth) {
    lastDay = endDate.getDate();
  }

  const activeDays = lastDay - firstDay + 1;
  if (activeDays >= daysInMonth) return { fraction: 1, label: "" };
  if (activeDays <= 0) return { fraction: 0, label: "" };
  return { fraction: activeDays / daysInMonth, label: `${activeDays}/${daysInMonth} days` };
}

function isMonthInAgreementRange(agreement: any, billingMonth: string): boolean {
  const [bmYear, bmMonth] = billingMonth.split("-").map(Number);
  const bmDate = new Date(bmYear, bmMonth - 1, 1);
  const bmEnd = new Date(bmYear, bmMonth, 0);

  if (agreement.startDate) {
    const start = new Date(agreement.startDate);
    if (start > bmEnd) return false;
  }

  if (agreement.endDate) {
    const end = new Date(agreement.endDate);
    const bmStart = new Date(bmYear, bmMonth - 1, 1);
    if (end < bmStart) return false;
  }

  return true;
}

export default function ToInvoicePage() {
  const [customerSearch, setCustomerSearch] = useState("");
  const [billingMonth, setBillingMonth] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  });
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  const { toast } = useToast();

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: agreements = [] } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements"],
  });

  const { data: billingElements = [] } = useQuery<any[]>({
    queryKey: ["/api/billing-elements", "?billed=false"],
  });

  const agreementIds = useMemo(() => agreements.map((a: any) => a.id), [agreements]);

  const { data: billedMonths = {} } = useQuery<Record<string, string[]>>({
    queryKey: ["/api/billed-months", agreementIds.join(",")],
    queryFn: async () => {
      if (agreementIds.length === 0) return {};
      const res = await fetch(`/api/billed-months?agreementIds=${agreementIds.join(",")}`);
      return res.json();
    },
    enabled: agreementIds.length > 0,
  });

  const generateMutation = useMutation({
    mutationFn: async ({ customerId, lineItems }: { customerId: string; lineItems: LineItem[] }) => {
      const selected = lineItems.filter(li => selectedItems.has(li.key));
      if (selected.length === 0) return;

      let total = 0;
      const billingElementIds: string[] = [];
      const liveryItems: any[] = [];

      for (const li of selected) {
        total += li.amount;
        if (li.type === "billing" && li.billingElementId) {
          billingElementIds.push(li.billingElementId);
        } else if (li.type === "livery" && li.agreementId) {
          liveryItems.push({
            agreementId: li.agreementId,
            horseId: li.horseId,
            boxId: li.boxId,
            itemId: li.itemId,
            price: li.amount.toFixed(2),
            billingMonth: li.billingMonth,
          });
        }
      }

      return apiRequest("POST", "/api/invoices", {
        customerId,
        invoiceDate: new Date().toISOString().split("T")[0],
        billingMonth,
        totalAmount: total.toFixed(2),
        billingElementIds,
        liveryItems,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/invoices"] });
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/billed-months"] });
      setSelectedItems(new Set());
      toast({ title: "Invoice generated successfully" });
    },
  });

  const deleteBillingMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/billing-elements/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      toast({ title: "Billing element deleted" });
    },
    onError: () => {
      toast({ title: "Failed to delete billing element", variant: "destructive" });
    },
  });

  const billingMonthLabel = useMemo(() => {
    if (!billingMonth) return "";
    const [y, m] = billingMonth.split("-");
    const date = new Date(parseInt(y), parseInt(m) - 1);
    return date.toLocaleString("en-US", { month: "long", year: "numeric" });
  }, [billingMonth]);

  const activeAgreements = useMemo(() => {
    return agreements.filter((a: any) => a.status === "active" || a.status === "ended");
  }, [agreements]);

  const invoiceableCustomers = useMemo(() => {
    const customerIds = new Set<string>();
    activeAgreements.forEach((a: any) => customerIds.add(a.customerId));
    billingElements.forEach((b: any) => customerIds.add(b.customerId));

    return Array.from(customerIds).map(id => {
      const customer = customers.find(c => c.id === id);
      const customerAgreements = activeAgreements.filter((a: any) => a.customerId === id);
      const customerBilling = billingElements.filter((b: any) => b.customerId === id);

      const lineItems: LineItem[] = [];

      for (const a of customerAgreements) {
        if (!isMonthInAgreementRange(a, billingMonth)) continue;
        const alreadyBilled = billedMonths[a.id]?.includes(billingMonth);
        if (alreadyBilled) continue;

        const monthlyAmount = parseFloat(a.monthlyAmount || "0");
        const { fraction, label } = getProRateFraction(a, billingMonth);
        if (fraction <= 0) continue;

        const amount = monthlyAmount * fraction;

        lineItems.push({
          key: `livery-${a.id}-${billingMonth}`,
          type: "livery",
          description: a.itemName + (label ? ` (${label})` : ""),
          horseName: a.horseName,
          date: billingMonthLabel,
          qty: 1,
          unitPrice: monthlyAmount,
          amount,
          proRateLabel: label,
          agreementId: a.id,
          horseId: a.horseId,
          boxId: a.boxId,
          itemId: a.itemId,
          billingMonth,
        });
      }

      for (const b of customerBilling) {
        const bMonth = b.billingMonth || (b.transactionDate ? b.transactionDate.substring(0, 7) : null);
        if (bMonth && bMonth !== billingMonth) continue;
        const qty = b.quantity || 1;
        const totalPrice = parseFloat(b.price || "0");
        lineItems.push({
          key: `billing-${b.id}`,
          type: "billing",
          description: b.itemName,
          horseName: b.horseName,
          date: b.transactionDate,
          qty,
          unitPrice: qty > 0 ? totalPrice / qty : totalPrice,
          amount: totalPrice,
          billingElementId: b.id,
        });
      }

      const total = lineItems.reduce((sum, li) => sum + li.amount, 0);

      return {
        customerId: id,
        customerName: customer ? customer.fullname : "Unknown",
        lineItems,
        total,
      };
    }).filter(c => {
      if (c.lineItems.length === 0) return false;
      if (!customerSearch) return true;
      return c.customerName.toLowerCase().includes(customerSearch.toLowerCase());
    });
  }, [customers, activeAgreements, billingElements, customerSearch, billingMonth, billingMonthLabel, billedMonths]);

  const toggleItem = useCallback((key: string) => {
    setSelectedItems(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }, []);

  const toggleAll = useCallback((customerLineItems: LineItem[]) => {
    setSelectedItems(prev => {
      const next = new Set(prev);
      const allSelected = customerLineItems.every(li => next.has(li.key));
      if (allSelected) {
        customerLineItems.forEach(li => next.delete(li.key));
      } else {
        customerLineItems.forEach(li => next.add(li.key));
      }
      return next;
    });
  }, []);

  const getSelectedTotal = (lineItems: LineItem[]) => {
    return lineItems.filter(li => selectedItems.has(li.key)).reduce((sum, li) => sum + li.amount, 0);
  };

  return (
    <div className="p-6">
      <PageHeader
        title="To Invoice"
        description="Select billable items and generate invoices for customers"
      />

      <div className="flex gap-3 mb-6 flex-wrap items-end">
        <SearchBar
          placeholder="Search customer..."
          value={customerSearch}
          onChange={setCustomerSearch}
          className="max-w-sm"
        />
        <div>
          <Label className="text-xs text-muted-foreground mb-1 block">Billing Month</Label>
          <Input
            type="month"
            value={billingMonth}
            onChange={(e) => setBillingMonth(e.target.value)}
            className="w-48"
            data-testid="input-billing-month"
          />
        </div>
      </div>

      {invoiceableCustomers.length === 0 ? (
        <div className="text-center text-muted-foreground py-12">
          No invoiceable items found
        </div>
      ) : (
        <div className="space-y-4">
          {invoiceableCustomers.map((c) => {
            const allSelected = c.lineItems.length > 0 && c.lineItems.every(li => selectedItems.has(li.key));
            const someSelected = c.lineItems.some(li => selectedItems.has(li.key));
            const selectedTotal = getSelectedTotal(c.lineItems);

            return (
              <Card key={c.customerId}>
                <CardHeader className="flex flex-row items-center justify-between gap-2 pb-3">
                  <div className="flex items-center gap-3">
                    <Checkbox
                      checked={allSelected}
                      className={!allSelected && someSelected ? "opacity-70" : ""}
                      onCheckedChange={() => toggleAll(c.lineItems)}
                      data-testid={`checkbox-select-all-${c.customerId}`}
                    />
                    <CardTitle className="text-lg">{c.customerName}</CardTitle>
                  </div>
                  <Button
                    onClick={() => generateMutation.mutate({ customerId: c.customerId, lineItems: c.lineItems })}
                    disabled={generateMutation.isPending || !someSelected}
                    data-testid={`button-generate-invoice-${c.customerId}`}
                  >
                    <FileText className="w-4 h-4 mr-2" />
                    Generate Invoice
                  </Button>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="w-10"></TableHead>
                        <TableHead>Type</TableHead>
                        <TableHead>Description</TableHead>
                        <TableHead>Horse</TableHead>
                        <TableHead>Date</TableHead>
                        <TableHead className="text-right">Qty</TableHead>
                        <TableHead className="text-right">Unit Price</TableHead>
                        <TableHead className="text-right">Amount</TableHead>
                        <TableHead className="w-10"></TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {c.lineItems.map((li) => (
                        <TableRow key={li.key}>
                          <TableCell>
                            <Checkbox
                              checked={selectedItems.has(li.key)}
                              onCheckedChange={() => toggleItem(li.key)}
                              data-testid={`checkbox-item-${li.key}`}
                            />
                          </TableCell>
                          <TableCell>{li.type === "livery" ? "Livery Fee" : "Billing Element"}</TableCell>
                          <TableCell>{li.description}</TableCell>
                          <TableCell>{li.horseName || "—"}</TableCell>
                          <TableCell>{li.date}</TableCell>
                          <TableCell className="text-right">{li.qty}</TableCell>
                          <TableCell className="text-right">AED {li.unitPrice.toFixed(2)}</TableCell>
                          <TableCell className="text-right">AED {li.amount.toFixed(2)}</TableCell>
                          <TableCell>
                            {li.type === "billing" && li.billingElementId && (
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-destructive hover:text-destructive"
                                onClick={() => deleteBillingMutation.mutate(li.billingElementId!)}
                                disabled={deleteBillingMutation.isPending}
                                data-testid={`button-delete-billing-${li.billingElementId}`}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                      {someSelected && (
                        <TableRow>
                          <TableCell />
                          <TableCell colSpan={6} className="font-semibold">Selected Total</TableCell>
                          <TableCell className="text-right font-semibold">AED {selectedTotal.toFixed(2)}</TableCell>
                          <TableCell />
                        </TableRow>
                      )}
                      <TableRow>
                        <TableCell />
                        <TableCell colSpan={6} className="font-semibold text-muted-foreground">Grand Total (all items)</TableCell>
                        <TableCell className="text-right font-semibold text-muted-foreground">AED {c.total.toFixed(2)}</TableCell>
                        <TableCell />
                      </TableRow>
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
