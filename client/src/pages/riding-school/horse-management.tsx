import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import type { Horse } from "@shared/schema";

// Note: per-horse "max lessons per day/week" limits are not implemented yet —
// there's no column or enforcement for this in the scheduling engine (M3).
// This page currently surfaces horses + a link into the existing wellbeing
// history (see the Horses page edit dialog, added in M2) as a starting point;
// daily/weekly usage limits are a follow-up once real usage volume from both
// livery movements and riding-school bookings needs aggregating together.
export default function HorseManagementPage() {
  const [search, setSearch] = useState("");
  const { data: horses = [], isLoading } = useQuery<Horse[]>({
    queryKey: ["/api/horses/", search ? `?search=${encodeURIComponent(search)}` : ""],
  });

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "breed", label: "Breed" },
    { key: "status", label: "Status" },
  ];

  return (
    <div className="p-6">
      <PageHeader title="Horse Management" description="Horse wellbeing and usage — open a horse from the Horses page to view/record status" />
      <SearchBar value={search} onChange={setSearch} placeholder="Search horses..." />
      <div className="mt-4">
        <DataTable columns={columns} data={horses} isLoading={isLoading} />
      </div>
    </div>
  );
}
