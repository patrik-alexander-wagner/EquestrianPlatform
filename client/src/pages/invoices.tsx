import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { viewInvoicePDF, downloadInvoicePDF } from "@/lib/invoice-pdf";
import { Trash2, FileText, Eye, Download } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

function formatBillingMonth(billingMonth: string | null | undefined): string {
  if (!billingMonth) return "-";
  const [y, m] = billingMonth.split("-");
  const date = new Date(parseInt(y), parseInt(m) - 1);
  return date.toLocaleString("en-US", { month: "long", year: "numeric" });
}

export default function InvoicesPage() {
  const { toast } = useToast();
  const [loadingPdf, setLoadingPdf] = useState<string | null>(null);

  const { data: invoices = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/invoices"],
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/invoices/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/invoices"] });
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/billed-months"] });
      toast({ title: "Invoice deleted" });
    },
    onError: () => {
      toast({ title: "Failed to delete invoice", variant: "destructive" });
    },
  });

  const handlePdfAction = async (invoiceId: string, action: "view" | "download") => {
    setLoadingPdf(invoiceId);
    try {
      const res = await fetch(`/api/invoices/${invoiceId}/details`);
      if (!res.ok) throw new Error("Failed to load invoice details");
      const details = await res.json();
      if (action === "view") {
        viewInvoicePDF(details);
      } else {
        downloadInvoicePDF(details);
      }
    } catch {
      toast({ title: "Failed to generate PDF", variant: "destructive" });
    } finally {
      setLoadingPdf(null);
    }
  };

  const columns = [
    { key: "id", label: "Invoice ID", render: (item: any) => item.id.substring(0, 8) + "..." },
    { key: "netsuiteId", label: "NetSuite ID", render: (item: any) => item.netsuiteId || "-" },
    { key: "customerName", label: "Customer" },
    { key: "invoiceDate", label: "Created Date" },
    {
      key: "billingMonth",
      label: "Invoice Month",
      render: (item: any) => formatBillingMonth(item.billingMonth),
    },
    {
      key: "totalAmount",
      label: "Total Amount",
      render: (item: any) => `AED ${parseFloat(item.totalAmount).toFixed(2)}`,
    },
    {
      key: "status",
      label: "Status",
      render: (item: any) => <StatusBadge status={item.status} />,
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Invoices"
        description="View generated invoices"
      />

      <div className="mb-4 p-3 rounded-md border border-orange-300 bg-orange-50 dark:bg-orange-950/20 dark:border-orange-800 text-sm text-orange-800 dark:text-orange-300" data-testid="text-temp-delete-notice">
        Temporary feature: Invoice deletion is enabled for testing purposes and will be removed in a future release.
      </div>

      <DataTable
        columns={columns}
        data={invoices}
        isLoading={isLoading}
        emptyMessage="No invoices yet"
        actions={(item) => (
          <div className="flex items-center gap-1">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={loadingPdf === item.id}
                  data-testid={`button-pdf-${item.id}`}
                >
                  <FileText className="w-4 h-4" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuItem
                  onClick={() => handlePdfAction(item.id, "view")}
                  data-testid={`button-view-pdf-${item.id}`}
                >
                  <Eye className="w-4 h-4 mr-2" />
                  View PDF
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => handlePdfAction(item.id, "download")}
                  data-testid={`button-download-pdf-${item.id}`}
                >
                  <Download className="w-4 h-4 mr-2" />
                  Download PDF
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>

            <Button
              size="sm"
              variant="destructive"
              onClick={() => {
                if (window.confirm("Delete this invoice? This will unbill associated billing elements.")) {
                  deleteMutation.mutate(item.id);
                }
              }}
              disabled={deleteMutation.isPending}
              data-testid={`button-delete-invoice-${item.id}`}
            >
              <Trash2 className="w-4 h-4" />
            </Button>
          </div>
        )}
      />
    </div>
  );
}
