import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { viewInvoicePDF, downloadInvoicePDF } from "@/lib/invoice-pdf";
import { Trash2, FileText, Eye, Download, FileJson, Zap, Send, CheckCircle } from "lucide-react";
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
  const [generatingSo, setGeneratingSo] = useState<string | null>(null);
  const [sendingToNetsuite, setSendingToNetsuite] = useState<string | null>(null);

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

  const handleGenerateSO = async (invoiceId: string) => {
    setGeneratingSo(invoiceId);
    try {
      const res = await apiRequest("POST", `/api/invoices/${invoiceId}/generate-so`);
      const data = await res.json();
      queryClient.invalidateQueries({ queryKey: ["/api/invoices"] });
      toast({ title: `NetSuite SO generated (PO: ${data.poNumber})` });
    } catch {
      toast({ title: "Failed to generate SO", variant: "destructive" });
    } finally {
      setGeneratingSo(null);
    }
  };

  const handleSendToNetsuite = async (invoiceId: string) => {
    setSendingToNetsuite(invoiceId);
    try {
      const res = await apiRequest("POST", `/api/invoices/${invoiceId}/send-to-netsuite`);
      const data = await res.json();
      queryClient.invalidateQueries({ queryKey: ["/api/invoices"] });
      toast({ title: data.netsuiteId ? `Sent to NetSuite (ID: ${data.netsuiteId})` : "Successfully sent to NetSuite" });
    } catch (e: any) {
      let msg = "Failed to send to NetSuite";
      try {
        const errData = e?.message || "";
        if (errData) msg = errData;
      } catch {}
      toast({ title: msg, variant: "destructive" });
    } finally {
      setSendingToNetsuite(null);
    }
  };

  const handleDownloadJson = (invoice: any) => {
    if (!invoice.netsuiteJson) return;
    const blob = new Blob([invoice.netsuiteJson], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    const invoiceNo = invoice.poNumber || invoice.id.substring(0, 8);
    a.href = url;
    a.download = `Invoice_${invoiceNo}_NetSuiteSO.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const columns = [
    { key: "id", label: "Invoice No", render: (item: any) => item.poNumber || item.id.substring(0, 8) + "..." },
    { key: "customerName", label: "Customer" },
    {
      key: "billingMonth",
      label: "Invoice Month",
      render: (item: any) => formatBillingMonth(item.billingMonth),
    },
    {
      key: "totalAmount",
      label: "Amount",
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

            {!item.soGenerated ? (
              <Button
                size="sm"
                variant="outline"
                className="text-blue-600 border-blue-300 hover:bg-blue-50 dark:text-blue-400 dark:border-blue-700 dark:hover:bg-blue-950"
                onClick={() => handleGenerateSO(item.id)}
                disabled={generatingSo === item.id}
                data-testid={`button-generate-so-${item.id}`}
              >
                <Zap className="w-4 h-4 mr-1" />
                Generate SO
              </Button>
            ) : (
              <>
                <Button
                  size="sm"
                  variant="outline"
                  className="text-green-600 border-green-300 hover:bg-green-50 dark:text-green-400 dark:border-green-700 dark:hover:bg-green-950"
                  onClick={() => handleDownloadJson(item)}
                  data-testid={`button-download-json-${item.id}`}
                >
                  <FileJson className="w-4 h-4 mr-1" />
                  JSON
                </Button>

                {!item.sentToNetsuite ? (
                  <Button
                    size="sm"
                    variant="outline"
                    className="text-purple-600 border-purple-300 hover:bg-purple-50 dark:text-purple-400 dark:border-purple-700 dark:hover:bg-purple-950"
                    onClick={() => handleSendToNetsuite(item.id)}
                    disabled={sendingToNetsuite === item.id}
                    data-testid={`button-send-netsuite-${item.id}`}
                  >
                    <Send className="w-4 h-4 mr-1" />
                    {sendingToNetsuite === item.id ? "Sending..." : "Send"}
                  </Button>
                ) : (
                  <span
                    className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-green-700 bg-green-100 rounded-md dark:text-green-300 dark:bg-green-900/30"
                    data-testid={`badge-sent-netsuite-${item.id}`}
                  >
                    <CheckCircle className="w-3 h-3" />
                    Sent
                  </span>
                )}
              </>
            )}

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
