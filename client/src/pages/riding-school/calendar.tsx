import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import {
  RidingSchoolCalendar, rangeForCalendarView,
  type CalendarEvent, type CalendarRow, type CalendarViewMode, type CalendarGranularity, type CalendarResourceAxis,
} from "@/components/riding-school-calendar";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { SearchableSelect } from "@/components/ui/searchable-select";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Trash2 } from "lucide-react";
import type { LessonTemplate, Instructor, Arena, Customer, Rider } from "@shared/schema";
import { CLUB_UTC_OFFSET_ISO } from "@shared/timezone";

const DAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

function pushUnique(map: Record<string, CalendarEvent[]>, rowId: string, event: CalendarEvent) {
  const arr = (map[rowId] ||= []);
  if (!arr.some((e) => e.id === event.id)) arr.push(event);
}

export default function RidingSchoolCalendarPage() {
  const canManage = useCan("riding_school.calendar.manage");
  const { toast } = useToast();

  const [viewMode, setViewMode] = useState<CalendarViewMode>("week");
  const [granularity, setGranularity] = useState<CalendarGranularity>("full");
  const [resourceAxis, setResourceAxis] = useState<CalendarResourceAxis>("horses");
  const [date, setDate] = useState(new Date());
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [createSlot, setCreateSlot] = useState<{ start: Date; resourceId?: string } | null>(null);
  const [isRecurring, setIsRecurring] = useState(false);
  const [selectedDays, setSelectedDays] = useState<number[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [editScope, setEditScope] = useState<"instance" | "series">("instance");
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [deleteScope, setDeleteScope] = useState<"instance" | "series">("instance");
  const [newRiderId, setNewRiderId] = useState("");
  const [newHorseId, setNewHorseId] = useState("");
  const [newTemplateId, setNewTemplateId] = useState("");
  const [newInstructorId, setNewInstructorId] = useState("");
  const [newArenaId, setNewArenaId] = useState("");

  const { from, to } = useMemo(() => rangeForCalendarView(viewMode, date), [viewMode, date]);

  const { data: lessons = [] } = useQuery<any[]>({
    queryKey: ["/api/riding-school/scheduled-lessons", from.toISOString(), to.toISOString()],
    queryFn: () => fetch(`/api/riding-school/scheduled-lessons?from=${from.toISOString()}&to=${to.toISOString()}`, { credentials: "include" }).then((r) => r.json()),
  });

  const { data: bookings = [] } = useQuery<any[]>({
    queryKey: ["/api/riding-school/bookings", from.toISOString(), to.toISOString()],
    queryFn: () => fetch(`/api/riding-school/bookings?from=${from.toISOString()}&to=${to.toISOString()}`, { credentials: "include" }).then((r) => r.json()),
    enabled: resourceAxis === "horses" || resourceAxis === "customers",
  });

  const { data: templates = [] } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const { data: instructors = [] } = useQuery<Instructor[]>({ queryKey: ["/api/instructors"] });
  const { data: arenas = [] } = useQuery<Arena[]>({ queryKey: ["/api/arenas"] });
  const { data: horses = [] } = useQuery<any[]>({ queryKey: ["/api/horses/"], enabled: resourceAxis === "horses" });
  const { data: customersList = [] } = useQuery<Customer[]>({ queryKey: ["/api/customers"], enabled: resourceAxis === "customers" });
  const { data: allRiders = [] } = useQuery<Rider[]>({ queryKey: ["/api/riding-school/riders"], enabled: resourceAxis === "customers" });

  const { data: lessonBookings = [] } = useQuery<any[]>({
    queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`],
    enabled: !!selectedEvent,
  });

  const templateById = useMemo(() => Object.fromEntries(templates.map((t) => [t.id, t])), [templates]);
  const lessonById = useMemo(() => Object.fromEntries(lessons.map((l: any) => [l.id, l])), [lessons]);
  const selectedLesson = selectedEvent ? lessonById[selectedEvent.id] : undefined;

  const { data: seriesDeletePreview = [] } = useQuery<any[]>({
    queryKey: [`/api/riding-school/recurrences/${selectedLesson?.recurrenceId}/future-instances`],
    enabled: showDeleteDialog && deleteScope === "series" && !!selectedLesson?.recurrenceId,
  });

  const eventFromLesson = (l: any): CalendarEvent => ({
    id: l.id,
    title: `${templateById[l.templateId]?.name || "Lesson"}${l.isPublic ? "" : " (private)"}`,
    start: new Date(l.startDatetime),
    end: new Date(l.endDatetime),
    isException: l.isException,
  });

  const allEvents = useMemo(() => lessons.map(eventFromLesson), [lessons, templateById]);

  const { rows, eventsByRow } = useMemo<{ rows: CalendarRow[]; eventsByRow: Record<string, CalendarEvent[]> }>(() => {
    const eventsByRow: Record<string, CalendarEvent[]> = {};

    if (resourceAxis === "instructors") {
      for (const l of lessons) pushUnique(eventsByRow, l.instructorId, eventFromLesson(l));
      return { rows: instructors.map((i) => ({ id: i.id, title: i.name })), eventsByRow };
    }

    if (resourceAxis === "facilities") {
      for (const l of lessons) pushUnique(eventsByRow, l.arenaId, eventFromLesson(l));
      return { rows: arenas.map((a) => ({ id: a.id, title: a.name })), eventsByRow };
    }

    if (resourceAxis === "horses") {
      for (const b of bookings) {
        if (!b.horseId) continue;
        const lesson = lessonById[b.scheduledLessonId];
        if (!lesson) continue;
        pushUnique(eventsByRow, b.horseId, eventFromLesson(lesson));
      }
      return { rows: horses.map((h: any) => ({ id: h.id, title: h.horseName })), eventsByRow };
    }

    // customers
    const riderToCustomer = Object.fromEntries(allRiders.map((r) => [r.id, r.customerId]));
    const customerIdsWithRiders = new Set(allRiders.map((r) => r.customerId));
    for (const b of bookings) {
      const customerId = riderToCustomer[b.riderId];
      if (!customerId) continue;
      const lesson = lessonById[b.scheduledLessonId];
      if (!lesson) continue;
      pushUnique(eventsByRow, customerId, eventFromLesson(lesson));
    }
    return {
      rows: customersList.filter((c) => customerIdsWithRiders.has(c.id)).map((c) => ({ id: c.id, title: c.fullname })),
      eventsByRow,
    };
  }, [resourceAxis, instructors, arenas, horses, customersList, allRiders, bookings, lessons, lessonById, templateById]);

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

  const deleteLessonMutation = useMutation({
    mutationFn: () => apiRequest("DELETE", `/api/riding-school/scheduled-lessons/${selectedEvent!.id}?scope=${deleteScope}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/scheduled-lessons"] });
      setShowDeleteDialog(false);
      setSelectedEvent(null);
      toast({ title: "Lesson deleted" });
    },
    onError: (e: any) => toast({ title: "Failed to delete lesson", description: e.message, variant: "destructive" as any }),
  });

  const addBookingMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/bookings", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`] });
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/bookings"] });
      setNewRiderId("");
      setNewHorseId("");
      toast({ title: "Rider booked" });
    },
    onError: (e: any) => toast({ title: "Booking failed", description: e.message, variant: "destructive" as any }),
  });

  const cancelBookingMutation = useMutation({
    mutationFn: (bookingId: string) => apiRequest("POST", `/api/riding-school/bookings/${bookingId}/cancel`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/riding-school/scheduled-lessons/${selectedEvent?.id}/bookings`] });
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/bookings"] });
      toast({ title: "Booking cancelled" });
    },
    onError: (e: any) => toast({ title: "Failed to cancel booking", description: e.message, variant: "destructive" as any }),
  });

  const toggleDay = (d: number) => {
    setSelectedDays((prev) => prev.includes(d) ? prev.filter((x) => x !== d) : [...prev, d].sort());
  };

  const resetCreateForm = (slot: { start: Date; resourceId?: string }) => {
    setCreateSlot(slot);
    setIsRecurring(false);
    setSelectedDays([]);
    setNewTemplateId("");
    setNewInstructorId(resourceAxis === "instructors" ? (slot.resourceId || "") : "");
    setNewArenaId(resourceAxis === "facilities" ? (slot.resourceId || "") : "");
  };

  return (
    <div className="p-6 flex flex-col h-full">
      <PageHeader
        title="Calendar"
        description="Schedule and manage riding lessons"
        actions={canManage ? (
          <Button
            onClick={() => { resetCreateForm({ start: new Date() }); setShowCreateDialog(true); }}
            data-testid="button-new-lesson"
          >
            <Plus className="w-4 h-4 mr-2" />
            New Lesson
          </Button>
        ) : undefined}
      />

      <RidingSchoolCalendar
        viewMode={viewMode}
        onViewModeChange={setViewMode}
        granularity={granularity}
        onGranularityChange={setGranularity}
        resourceAxis={resourceAxis}
        onResourceAxisChange={setResourceAxis}
        date={date}
        onNavigate={setDate}
        rows={rows}
        eventsByRow={eventsByRow}
        allEvents={allEvents}
        onSelectSlot={(slot) => {
          if (!canManage) return;
          resetCreateForm({ start: slot.start, resourceId: slot.rowId });
          setShowCreateDialog(true);
        }}
        onSelectEvent={(event) => {
          setSelectedEvent(event);
          setEditScope("instance");
          setDeleteScope("instance");
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
              if (!templateId || !instructorId || !arenaId) {
                toast({ title: "Template, instructor, and arena are required", variant: "destructive" });
                return;
              }
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
                <input type="hidden" name="templateId" value={newTemplateId} />
                <SearchableSelect
                  value={newTemplateId}
                  onValueChange={setNewTemplateId}
                  options={templates.filter((t) => t.isActive).map((t) => ({ value: t.id, label: `${t.name} (${t.durationMinutes}min, max ${t.maxRiders})` }))}
                  placeholder="Select a template"
                  searchPlaceholder="Search templates..."
                  testId="select-template"
                />
              </div>
              <div>
                <Label>Instructor</Label>
                <input type="hidden" name="instructorId" value={newInstructorId} />
                <SearchableSelect
                  value={newInstructorId}
                  onValueChange={setNewInstructorId}
                  options={instructors.map((i) => ({ value: i.id, label: i.name }))}
                  placeholder="Select an instructor"
                  searchPlaceholder="Search instructors..."
                  testId="select-instructor"
                />
              </div>
              <div>
                <Label>Arena</Label>
                <input type="hidden" name="arenaId" value={newArenaId} />
                <SearchableSelect
                  value={newArenaId}
                  onValueChange={setNewArenaId}
                  options={arenas.map((a) => ({ value: a.id, label: a.name }))}
                  placeholder="Select an arena"
                  searchPlaceholder="Search arenas..."
                  testId="select-arena"
                />
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
                <Label className="text-sm font-medium">Bookings ({lessonBookings.length})</Label>
                <ul className="mt-1 space-y-1 max-h-32 overflow-auto text-sm">
                  {lessonBookings.map((b: any) => (
                    <li key={b.id} className="flex justify-between items-center gap-2">
                      <span>{b.riderId}{b.horseId ? ` (horse: ${b.horseId})` : ""}</span>
                      {canManage && (
                        <Button variant="ghost" size="icon" onClick={() => cancelBookingMutation.mutate(b.id)} data-testid={`button-cancel-booking-${b.id}`}>
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      )}
                    </li>
                  ))}
                  {lessonBookings.length === 0 && <li className="text-muted-foreground">No bookings yet.</li>}
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

              {canManage && (
                <div className="pt-3 border-t">
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => { setDeleteScope("instance"); setShowDeleteDialog(true); }}
                    data-testid="button-delete-lesson"
                  >
                    <Trash2 className="w-4 h-4 mr-2" />Delete Lesson
                  </Button>
                </div>
              )}
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Delete lesson confirmation dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Lesson</DialogTitle>
          </DialogHeader>
          {selectedEvent && (
            <div className="space-y-4">
              {lessonBookings.length > 0 && deleteScope === "instance" ? (
                <p className="text-sm text-destructive">
                  Cannot delete: {lessonBookings.length} rider(s) are booked on this lesson. Cancel their booking(s) first.
                </p>
              ) : (
                <p className="text-sm text-muted-foreground">This cannot be undone.</p>
              )}

              {selectedLesson?.recurrenceId && (
                <div>
                  <Label className="text-sm font-medium">What do you want to delete?</Label>
                  <Select value={deleteScope} onValueChange={(v) => setDeleteScope(v as any)}>
                    <SelectTrigger data-testid="select-delete-scope"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="instance">This occurrence only</SelectItem>
                      <SelectItem value="series">This and all following occurrences</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}

              {deleteScope === "instance" ? (
                <div className="text-sm border rounded-md p-2">
                  {selectedEvent.start.toLocaleString()} — {selectedEvent.end.toLocaleTimeString()}
                </div>
              ) : (
                <div>
                  <Label className="text-sm font-medium">
                    {seriesDeletePreview.length} occurrence{seriesDeletePreview.length !== 1 ? "s" : ""} will be deleted:
                  </Label>
                  <ul className="mt-1 space-y-1 max-h-40 overflow-auto text-sm border rounded-md p-2">
                    {seriesDeletePreview.map((l: any) => (
                      <li key={l.id}>{new Date(l.startDatetime).toLocaleString()}</li>
                    ))}
                    {seriesDeletePreview.length === 0 && <li className="text-muted-foreground">No upcoming occurrences.</li>}
                  </ul>
                </div>
              )}
            </div>
          )}
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setShowDeleteDialog(false)} data-testid="button-cancel-delete-lesson">Cancel</Button>
            <Button
              variant="destructive"
              onClick={() => deleteLessonMutation.mutate()}
              disabled={deleteLessonMutation.isPending || (deleteScope === "instance" && lessonBookings.length > 0)}
              data-testid="button-confirm-delete-lesson"
            >
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
