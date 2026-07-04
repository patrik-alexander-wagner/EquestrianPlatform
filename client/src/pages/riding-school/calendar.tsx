import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import type { View } from "react-big-calendar";
import { PageHeader } from "@/components/page-header";
import { RidingSchoolCalendar, type CalendarEvent } from "@/components/riding-school-calendar";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Trash2 } from "lucide-react";
import type { LessonTemplate, Instructor, Arena } from "@shared/schema";
import { CLUB_UTC_OFFSET_ISO } from "@shared/timezone";

const DAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function rangeForView(view: View, date: Date): { from: Date; to: Date } {
  if (view === "month") {
    const from = new Date(date.getFullYear(), date.getMonth(), 1);
    const to = new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59);
    return { from, to };
  }
  if (view === "week") {
    const from = new Date(date);
    from.setDate(from.getDate() - from.getDay());
    from.setHours(0, 0, 0, 0);
    const to = new Date(from);
    to.setDate(to.getDate() + 7);
    return { from, to };
  }
  const from = new Date(date); from.setHours(0, 0, 0, 0);
  const to = new Date(date); to.setHours(23, 59, 59, 999);
  return { from, to };
}

export default function RidingSchoolCalendarPage() {
  const canManage = useCan("riding_school.calendar.manage");
  const { toast } = useToast();

  const [view, setView] = useState<View>("week");
  const [date, setDate] = useState(new Date());
  const [groupByInstructor, setGroupByInstructor] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [createSlot, setCreateSlot] = useState<{ start: Date; resourceId?: string } | null>(null);
  const [isRecurring, setIsRecurring] = useState(false);
  const [selectedDays, setSelectedDays] = useState<number[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [editScope, setEditScope] = useState<"instance" | "series">("instance");
  const [newRiderId, setNewRiderId] = useState("");
  const [newHorseId, setNewHorseId] = useState("");

  const { from, to } = useMemo(() => rangeForView(view, date), [view, date]);

  const { data: lessons = [] } = useQuery<any[]>({
    queryKey: ["/api/riding-school/scheduled-lessons", from.toISOString(), to.toISOString()],
    queryFn: () => fetch(`/api/riding-school/scheduled-lessons?from=${from.toISOString()}&to=${to.toISOString()}`, { credentials: "include" }).then((r) => r.json()),
  });

  const { data: templates = [] } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const { data: instructors = [] } = useQuery<Instructor[]>({ queryKey: ["/api/instructors"] });
  const { data: arenas = [] } = useQuery<Arena[]>({ queryKey: ["/api/arenas"] });

  const { data: bookings = [] } = useQuery<any[]>({
    queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`],
    enabled: !!selectedEvent,
  });

  const templateById = useMemo(() => Object.fromEntries(templates.map((t) => [t.id, t])), [templates]);
  const instructorById = useMemo(() => Object.fromEntries(instructors.map((i) => [i.id, i])), [instructors]);

  const events: CalendarEvent[] = useMemo(() => lessons.map((l) => ({
    id: l.id,
    title: `${templateById[l.templateId]?.name || "Lesson"}${l.isPublic ? "" : " (private)"}`,
    start: new Date(l.startDatetime),
    end: new Date(l.endDatetime),
    resourceId: groupByInstructor ? l.instructorId : undefined,
    isException: l.isException,
  })), [lessons, templateById, groupByInstructor]);

  const resources = useMemo(() => instructors.map((i) => ({ resourceId: i.id, resourceTitle: i.name })), [instructors]);

  const createRecurrenceMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/recurrences", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/scheduled-lessons"] });
      setShowCreateDialog(false);
      toast({ title: "Recurring series scheduled" });
    },
    onError: (e: any) => toast({ title: "Failed to schedule series", description: e.message, variant: "destructive" as any }),
  });

  const createSingleMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/scheduled-lessons", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/scheduled-lessons"] });
      setShowCreateDialog(false);
      toast({ title: "Lesson scheduled" });
    },
    onError: (e: any) => toast({ title: "Failed to schedule lesson", description: e.message, variant: "destructive" as any }),
  });

  const updateLessonMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/riding-school/scheduled-lessons/${selectedEvent!.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/scheduled-lessons"] });
      setSelectedEvent(null);
      toast({ title: "Lesson updated" });
    },
    onError: (e: any) => toast({ title: "Failed to update lesson", description: e.message, variant: "destructive" as any }),
  });

  const addBookingMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/bookings", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`] });
      setNewRiderId("");
      setNewHorseId("");
      toast({ title: "Rider booked" });
    },
    onError: (e: any) => toast({ title: "Booking failed", description: e.message, variant: "destructive" as any }),
  });

  const cancelBookingMutation = useMutation({
    mutationFn: (bookingId: string) => apiRequest("POST", `/api/riding-school/bookings/${bookingId}/cancel`),
    onSuccess: (res: any) => {
      queryClient.invalidateQueries({ queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`] });
      toast({ title: "Booking cancelled" });
    },
    onError: (e: any) => toast({ title: "Failed to cancel booking", description: e.message, variant: "destructive" as any }),
  });

  const toggleDay = (d: number) => {
    setSelectedDays((prev) => prev.includes(d) ? prev.filter((x) => x !== d) : [...prev, d].sort());
  };

  return (
    <div className="p-6 flex flex-col h-full">
      <PageHeader
        title="Calendar"
        description="Schedule and manage riding lessons"
        actions={canManage ? (
          <Button
            onClick={() => {
              setCreateSlot({ start: new Date() });
              setIsRecurring(false);
              setSelectedDays([]);
              setShowCreateDialog(true);
            }}
            data-testid="button-new-lesson"
          >
            <Plus className="w-4 h-4 mr-2" />
            New Lesson
          </Button>
        ) : undefined}
      />

      <div className="flex items-center gap-4 mb-3">
        <div className="flex items-center gap-2">
          <Switch checked={groupByInstructor} onCheckedChange={setGroupByInstructor} data-testid="switch-group-by-instructor" />
          <Label className="text-sm">Group by instructor</Label>
        </div>
      </div>

      <RidingSchoolCalendar
        events={events}
        resources={groupByInstructor && view !== "month" ? resources : undefined}
        view={view}
        date={date}
        onNavigate={setDate}
        onView={setView}
        onSelectSlot={(slot) => {
          if (!canManage) return;
          setCreateSlot({ start: slot.start, resourceId: slot.resourceId });
          setIsRecurring(false);
          setSelectedDays([]);
          setShowCreateDialog(true);
        }}
        onSelectEvent={(event) => {
          setSelectedEvent(event);
          setEditScope("instance");
        }}
      />

      {/* Create lesson dialog */}
      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>New Lesson</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              const templateId = fd.get("templateId") as string;
              const instructorId = fd.get("instructorId") as string;
              const arenaId = fd.get("arenaId") as string;
              const isPublic = fd.get("isPublic") === "on";
              const template = templateById[templateId];

              if (isRecurring) {
                createRecurrenceMutation.mutate({
                  templateId, instructorId, arenaId,
                  daysOfWeek: selectedDays.join(","),
                  startTime: fd.get("startTime"),
                  until: fd.get("until"),
                  isPublic,
                });
              } else {
                const startDatetime = new Date(`${fd.get("date")}T${fd.get("startTime")}:00${CLUB_UTC_OFFSET_ISO}`);
                const endDatetime = new Date(startDatetime.getTime() + (template?.durationMinutes || 60) * 60000);
                createSingleMutation.mutate({
                  templateId, instructorId, arenaId,
                  startDatetime: startDatetime.toISOString(),
                  endDatetime: endDatetime.toISOString(),
                  capacity: template?.maxRiders || 1,
                  isPublic,
                  isException: false,
                  status: "scheduled",
                });
              }
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Lesson Template</Label>
                <Select name="templateId" required>
                  <SelectTrigger data-testid="select-template"><SelectValue placeholder="Select a template" /></SelectTrigger>
                  <SelectContent>
                    {templates.map((t) => <SelectItem key={t.id} value={t.id}>{t.name} ({t.durationMinutes}min, max {t.maxRiders})</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Instructor</Label>
                <Select name="instructorId" defaultValue={createSlot?.resourceId} required>
                  <SelectTrigger data-testid="select-instructor"><SelectValue placeholder="Select an instructor" /></SelectTrigger>
                  <SelectContent>
                    {instructors.map((i) => <SelectItem key={i.id} value={i.id}>{i.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label>Arena</Label>
                <Select name="arenaId" required>
                  <SelectTrigger data-testid="select-arena"><SelectValue placeholder="Select an arena" /></SelectTrigger>
                  <SelectContent>
                    {arenas.map((a) => <SelectItem key={a.id} value={a.id}>{a.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex items-center gap-2">
                <Checkbox checked={isRecurring} onCheckedChange={(v) => setIsRecurring(!!v)} data-testid="checkbox-recurring" />
                <Label>Recurring (up to 12 months)</Label>
              </div>

              {isRecurring ? (
                <>
                  <div>
                    <Label>Repeat on</Label>
                    <div className="flex gap-2 flex-wrap mt-1">
                      {DAY_LABELS.map((label, idx) => (
                        <button
                          key={idx}
                          type="button"
                          onClick={() => toggleDay(idx)}
                          data-testid={`button-day-${idx}`}
                          className={`px-2 py-1 rounded text-xs border ${selectedDays.includes(idx) ? "bg-primary text-primary-foreground" : ""}`}
                        >
                          {label}
                        </button>
                      ))}
                    </div>
                  </div>
                  <div>
                    <Label>Start Time</Label>
                    <Input name="startTime" type="time" required data-testid="input-start-time" />
                  </div>
                  <div>
                    <Label>Until</Label>
                    <Input name="until" type="date" required data-testid="input-until" />
                  </div>
                </>
              ) : (
                <>
                  <div>
                    <Label>Date</Label>
                    <Input name="date" type="date" defaultValue={createSlot?.start.toISOString().slice(0, 10)} required data-testid="input-date" />
                  </div>
                  <div>
                    <Label>Start Time</Label>
                    <Input name="startTime" type="time" defaultValue={createSlot?.start.toTimeString().slice(0, 5)} required data-testid="input-single-start-time" />
                  </div>
                </>
              )}

              <div className="flex items-center gap-2">
                <Checkbox name="isPublic" defaultChecked data-testid="checkbox-public" />
                <Label>Visible to customers</Label>
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createRecurrenceMutation.isPending || createSingleMutation.isPending} data-testid="button-submit-lesson">
                Schedule
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Lesson details / edit dialog */}
      <Dialog open={!!selectedEvent} onOpenChange={(open) => !open && setSelectedEvent(null)}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{selectedEvent?.title}</DialogTitle>
          </DialogHeader>
          {selectedEvent && (
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                {selectedEvent.start.toLocaleString()} — {selectedEvent.end.toLocaleTimeString()}
              </p>

              <div>
                <Label className="text-sm font-medium">Bookings ({bookings.length})</Label>
                <ul className="mt-1 space-y-1 max-h-32 overflow-auto text-sm">
                  {bookings.map((b: any) => (
                    <li key={b.id} className="flex justify-between items-center gap-2">
                      <span>{b.riderId}{b.horseId ? ` (horse: ${b.horseId})` : ""}</span>
                      {canManage && (
                        <Button variant="ghost" size="icon" onClick={() => cancelBookingMutation.mutate(b.id)} data-testid={`button-cancel-booking-${b.id}`}>
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      )}
                    </li>
                  ))}
                  {bookings.length === 0 && <li className="text-muted-foreground">No bookings yet.</li>}
                </ul>
              </div>

              {canManage && (
                <form
                  className="flex gap-2"
                  onSubmit={(e) => {
                    e.preventDefault();
                    if (!newRiderId) return;
                    addBookingMutation.mutate({
                      scheduledLessonId: selectedEvent.id,
                      riderId: newRiderId,
                      horseId: newHorseId || undefined,
                    });
                  }}
                >
                  <Input placeholder="Rider ID" value={newRiderId} onChange={(e) => setNewRiderId(e.target.value)} data-testid="input-new-booking-rider-id" className="flex-1" />
                  <Input placeholder="Horse ID (optional)" value={newHorseId} onChange={(e) => setNewHorseId(e.target.value)} data-testid="input-new-booking-horse-id" className="flex-1" />
                  <Button type="submit" size="sm" disabled={addBookingMutation.isPending} data-testid="button-add-booking">Book</Button>
                </form>
              )}

              {canManage && (
                <div className="pt-3 border-t space-y-2">
                  <Label className="text-sm font-medium">Edit</Label>
                  <Select value={editScope} onValueChange={(v) => setEditScope(v as any)}>
                    <SelectTrigger data-testid="select-edit-scope"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="instance">This event only</SelectItem>
                      <SelectItem value="series">This and following events</SelectItem>
                    </SelectContent>
                  </Select>
                  <form
                    className="flex gap-2"
                    onSubmit={(e) => {
                      e.preventDefault();
                      const fd = new FormData(e.currentTarget);
                      const capacity = Number(fd.get("capacity"));
                      updateLessonMutation.mutate({ scope: editScope, capacity });
                    }}
                  >
                    <Input name="capacity" type="number" min={1} placeholder="New capacity" data-testid="input-edit-capacity" className="flex-1" />
                    <Button type="submit" size="sm" disabled={updateLessonMutation.isPending} data-testid="button-submit-edit-lesson">Apply</Button>
                  </form>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
