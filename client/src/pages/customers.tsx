import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { StatusBadge } from "@/components/status-badge";
import type { Customer } from "@shared/schema";

export default function CustomersPage() {
  const [search, setSearch] = useState("");

  const { data: customers = [], isLoading } = useQuery<Customer[]>({
    queryKey: ["/api/customers", search ? `?search=${search}` : ""],
  });

  const columns = [
    { key: "fullname", label: "Full Name" },
    {
      key: "isInactive",
      label: "Status",
      render: (c: Customer) => (
        <StatusBadge status={c.isInactive ? "inactive" : "active"} />
      ),
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Customers"
        description="View customers synced from NetSuite"
      />

      <div className="mb-4">
        <SearchBar
          placeholder="Search by name..."
          value={search}
          onChange={setSearch}
          className="max-w-sm"
        />
      </div>

      <DataTable columns={columns} data={customers} isLoading={isLoading} />
    </div>
  );
}
