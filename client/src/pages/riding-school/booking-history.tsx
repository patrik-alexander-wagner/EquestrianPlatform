import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { DataTable } from "@/components/data-table";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import type { LessonTemplate, Rider, Customer } from "@shared/schema";

interface BookingHistoryRow {
  id: string;
  scheduledLessonId: string;
  riderId: string;
  horseId: string | null;
  status: string;
  createdAt: string | null;
  lessonStartDatetime: string;
  lessonTemplateId: string;
}

function isoDate(d: Date) {
  return d.toISOString().slice(0, 10);
}

export default function BookingHistoryPage() {
  const [from, setFrom] = useState(() => isoDate(new Date(new Date().setDate(new Date().getDate() - 30))));
  const [to, setTo] = useState(() => isoDate(new Date(new Date().setDate(new Date().getDate() + 30))));
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "confirmed" | "cancelled">("all");

  const { data: bookings = [], isLoading } = useQuery<BookingHistoryRow[]>({
    queryKey: ["/api/riding-school/bookings/history", from, to],
    queryFn: () =>
      fetch(`/api/riding-school/bookings/history?from=${from}T00:00:00&to=${to}T23:59:59`, { credentials: "include" }).then((r) => r.json()),
  });

  const { data: templates = [] } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const { data: allRiders = [] } = useQuery<Rider[]>({ queryKey: ["/api/riding-school/riders"] });
  const { data: customersList = [] } = useQuery<Customer[]>({ queryKey: ["/api/customers"] });
  const { data: horses = [] } = useQuery<any[]>({ queryKey: ["/api/horses/"] });

  const templateById = useMemo(() => Object.fromEntries(templates.map((t) => [t.id, t])), [templates]);
  const riderById = useMemo(() => Object.fromEntries(allRiders.map((r) => [r.id, r])), [allRiders]);
  const customerById = useMemo(() => Object.fromEntries(customersList.map((c) => [c.id, c])), [customersList]);
  const horseById = useMemo(() => Object.fromEntries(horses.map((h: any) => [h.id, h])), [horses]);

  const rows = useMemo(() => {
    return bookings.map((b) => {
      const rider = riderById[b.riderId];
      const customer = rider ? customerById[rider.customerId] : undefined;
      const horse = b.horseId ? horseById[b.horseId] : undefined;
      return {
        ...b,
        lessonName: templateById[b.lessonTemplateId]?.name || "Lesson",
        riderName: rider?.fullName || b.riderId,
        customerName: customer?.fullname || "—",
        horseName: horse?.horseName || "—",
      };
    });
  }, [bookings, riderById, customerById, horseById, templateById]);

  const filteredRows = rows.filter((r) => {
    const matchesStatus = statusFilter === "all" || r.status === statusFilter;
    const matchesSearch = !search
      || r.riderName.toLowerCase().includes(search.toLowerCase())
      || r.customerName.toLowerCase().includes(search.toLowerCase())
      || r.lessonName.toLowerCase().includes(search.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const columns = [
    { key: "lessonName", label: "Lesson" },
    { key: "lessonStartDatetime", label: "Lesson Date", render: (r: any) => new Date(r.lessonStartDatetime).toLocaleString() },
    { key: "riderName", label: "Rider" },
    { key: "customerName", label: "Customer" },
    { key: "horseName", label: "Horse" },
    {
      key: "status", label: "Status",
      render: (r: any) => (
        <span className={r.status === "confirmed" ? "text-green-600" : "text-muted-foreground"}>
          {r.status === "confirmed" ? "Confirmed" : "Cancelled"}
        </span>
      ),
    },
    { key: "createdAt", label: "Booked On", render: (r: any) => r.createdAt ? new Date(r.createdAt).toLocaleString() : "—" },
  ];

  return (
    <div className="p-6">
      <PageHeader title="Booking History" description="Every customer interaction with a scheduled lesson — booked or cancelled" />

      <div className="flex flex-wrap items-end gap-4 mb-4">
        <div>
          <Label className="text-xs">From</Label>
          <Input type="date" value={from} onChange={(e) => setFrom(e.target.value)} data-testid="input-history-from" />
        </div>
        <div>
          <Label className="text-xs">To</Label>
          <Input type="date" value={to} onChange={(e) => setTo(e.target.value)} data-testid="input-history-to" />
        </div>
        <div className="w-48">
          <Label className="text-xs">Status</Label>
          <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as any)}>
            <SelectTrigger data-testid="select-history-status"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="confirmed">Confirmed</SelectItem>
              <SelectItem value="cancelled">Cancelled</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="flex-1 min-w-[200px]">
          <Label className="text-xs">Search</Label>
          <SearchBar value={search} onChange={setSearch} placeholder="Search rider, customer, or lesson..." data-testid="input-history-search" />
        </div>
      </div>

      <DataTable columns={columns} data={filteredRows} isLoading={isLoading} />
    </div>
  );
}
