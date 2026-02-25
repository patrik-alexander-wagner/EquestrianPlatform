import { useMutation, useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Trash2 } from "lucide-react";

export default function InvoicesPage() {
  const { toast } = useToast();

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

  const columns = [
    { key: "id", label: "Invoice ID", render: (item: any) => item.id.substring(0, 8) + "..." },
    { key: "netsuiteId", label: "NetSuite ID", render: (item: any) => item.netsuiteId || "-" },
    { key: "customerName", label: "Customer" },
    { key: "invoiceDate", label: "Invoice Date" },
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
        )}
      />
    </div>
  );
}
