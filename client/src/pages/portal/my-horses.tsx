import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import type { Horse } from "@shared/schema";

type PortalHorse = Horse & { stable: string | null; box: string | null; since: string | null };

export default function MyHorsesPage() {
  const { data: horses = [], isLoading } = useQuery<PortalHorse[]>({ queryKey: ["/api/portal/horses"] });

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "breed", label: "Breed", render: (h: PortalHorse) => h.breed || "—" },
    { key: "color", label: "Color", render: (h: PortalHorse) => h.color || "—" },
    { key: "stable", label: "Stable", render: (h: PortalHorse) => h.stable || "—" },
    { key: "box", label: "Box", render: (h: PortalHorse) => h.box || "—" },
    { key: "since", label: "Since", render: (h: PortalHorse) => h.since || "—" },
    { key: "status", label: "Status" },
  ];

  return (
    <div className="p-6">
      <PageHeader title="My Horses" description="Horses registered to your account in our livery system" />
      <DataTable columns={columns} data={horses} isLoading={isLoading} />
    </div>
  );
}
