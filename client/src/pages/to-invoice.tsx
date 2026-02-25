import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
import { FileText } from "lucide-react";
import type { Customer } from "@shared/schema";

export default function ToInvoicePage() {
  const [customerSearch, setCustomerSearch] = useState("");
  const { toast } = useToast();

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: agreements = [] } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", "?status=active"],
  });

  const { data: billingElements = [] } = useQuery<any[]>({
    queryKey: ["/api/billing-elements", "?billed=false"],
  });

  const generateMutation = useMutation({
    mutationFn: async (customerId: string) => {
      const customerAgreements = agreements.filter((a: any) => a.customerId === customerId);
      const customerBillingElements = billingElements.filter((b: any) => b.customerId === customerId);

      let total = 0;
      for (const a of customerAgreements) {
        total += parseFloat(a.monthlyAmount || "0");
      }
      for (const b of customerBillingElements) {
        total += parseFloat(b.price || "0") * (b.quantity || 1);
      }

      return apiRequest("POST", "/api/invoices", {
        customerId,
        invoiceDate: new Date().toISOString().split("T")[0],
        totalAmount: total.toFixed(2),
        status: "pending",
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/invoices"] });
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      toast({ title: "Invoice generated successfully" });
    },
  });

  const invoiceableCustomers = useMemo(() => {
    const customerIds = new Set<string>();
    agreements.forEach((a: any) => customerIds.add(a.customerId));
    billingElements.forEach((b: any) => customerIds.add(b.customerId));

    return Array.from(customerIds).map(id => {
      const customer = customers.find(c => c.id === id);
      const customerAgreements = agreements.filter((a: any) => a.customerId === id);
      const customerBilling = billingElements.filter((b: any) => b.customerId === id);

      let liveryTotal = 0;
      customerAgreements.forEach((a: any) => { liveryTotal += parseFloat(a.monthlyAmount || "0"); });
      let otherTotal = 0;
      customerBilling.forEach((b: any) => { otherTotal += parseFloat(b.price || "0") * (b.quantity || 1); });

      return {
        customerId: id,
        customerName: customer ? `${customer.firstname} ${customer.lastname}` : "Unknown",
        agreements: customerAgreements,
        billingElements: customerBilling,
        liveryTotal,
        otherTotal,
        total: liveryTotal + otherTotal,
      };
    }).filter(c => {
      if (!customerSearch) return true;
      return c.customerName.toLowerCase().includes(customerSearch.toLowerCase());
    });
  }, [customers, agreements, billingElements, customerSearch]);

  return (
    <div className="p-6">
      <PageHeader
        title="To Invoice"
        description="Prepare and generate invoices for customers"
      />

      <div className="mb-6">
        <SearchBar
          placeholder="Search customer..."
          value={customerSearch}
          onChange={setCustomerSearch}
          className="max-w-sm"
        />
      </div>

      {invoiceableCustomers.length === 0 ? (
        <div className="text-center text-muted-foreground py-12">
          No invoiceable items found
        </div>
      ) : (
        <div className="space-y-4">
          {invoiceableCustomers.map((c) => (
            <Card key={c.customerId}>
              <CardHeader className="flex flex-row items-center justify-between gap-2 pb-3">
                <CardTitle className="text-lg">{c.customerName}</CardTitle>
                <Button
                  onClick={() => generateMutation.mutate(c.customerId)}
                  disabled={generateMutation.isPending}
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
                      <TableHead>Type</TableHead>
                      <TableHead>Description</TableHead>
                      <TableHead>Horse</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {c.agreements.map((a: any) => (
                      <TableRow key={`agreement-${a.id}`}>
                        <TableCell>Livery Fee</TableCell>
                        <TableCell>{a.itemName}</TableCell>
                        <TableCell>{a.horseName}</TableCell>
                        <TableCell className="text-right">${parseFloat(a.monthlyAmount || "0").toFixed(2)}</TableCell>
                      </TableRow>
                    ))}
                    {c.billingElements.map((b: any) => (
                      <TableRow key={`billing-${b.id}`}>
                        <TableCell>Billing Element</TableCell>
                        <TableCell>{b.itemName} x{b.quantity}</TableCell>
                        <TableCell>{b.horseName}</TableCell>
                        <TableCell className="text-right">
                          ${(parseFloat(b.price || "0") * (b.quantity || 1)).toFixed(2)}
                        </TableCell>
                      </TableRow>
                    ))}
                    <TableRow>
                      <TableCell colSpan={3} className="font-semibold">Total</TableCell>
                      <TableCell className="text-right font-semibold">${c.total.toFixed(2)}</TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
