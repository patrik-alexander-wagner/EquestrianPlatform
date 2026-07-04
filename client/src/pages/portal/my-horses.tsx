import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import type { Horse } from "@shared/schema";

export default function MyHorsesPage() {
  const { data: horses = [], isLoading } = useQuery<Horse[]>({ queryKey: ["/api/portal/horses"] });

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "breed", label: "Breed", render: (h: Horse) => h.breed || "—" },
    { key: "color", label: "Color", render: (h: Horse) => h.color || "—" },
    { key: "status", label: "Status" },
  ];

  return (
    <div className="p-6">
      <PageHeader title="My Horses" description="Horses registered to your account in our livery system" />
      <DataTable columns={columns} data={horses} isLoading={isLoading} />
    </div>
  );
}
