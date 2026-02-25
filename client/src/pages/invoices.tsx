import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { StatusBadge } from "@/components/status-badge";

export default function InvoicesPage() {
  const { data: invoices = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/invoices"],
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

      <DataTable columns={columns} data={invoices} isLoading={isLoading} emptyMessage="No invoices yet" />
    </div>
  );
}
