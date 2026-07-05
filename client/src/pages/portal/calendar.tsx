import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { SearchableSelect } from "@/components/ui/searchable-select";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { Rider } from "@shared/schema";

interface PortalLesson {
  id: string;
  templateName?: string;
  price?: string;
  startDatetime: string;
  endDatetime: string;
  capacity: number;
  bookedCount: number;
}

interface PortalBooking {
  id: string;
  status: string;
  riderName: string;
  lessonName?: string;
  startDatetime?: string;
  endDatetime?: string;
}

function formatWhen(iso: string) {
  return new Date(iso).toLocaleString([], { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}

export default function PortalCalendarPage() {
  const { toast } = useToast();
  const [bookingLesson, setBookingLesson] = useState<PortalLesson | null>(null);
  const [selectedRiderId, setSelectedRiderId] = useState("");

  const { data: lessons = [], isLoading } = useQuery<PortalLesson[]>({ queryKey: ["/api/portal/calendar"] });
  const { data: riders = [] } = useQuery<Rider[]>({ queryKey: ["/api/portal/riders"] });
  const { data: bookings = [] } = useQuery<PortalBooking[]>({ queryKey: ["/api/portal/bookings"] });

  const bookMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/portal/bookings", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/portal/calendar"] });
      queryClient.invalidateQueries({ queryKey: ["/api/portal/dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["/api/portal/bookings"] });
      setBookingLesson(null);
      setSelectedRiderId("");
      toast({ title: "Class booked!" });
    },
    onError: (e: any) => toast({ title: "Booking failed", description: e.message, variant: "destructive" as any }),
  });

  const cancelMutation = useMutation({
    mutationFn: (bookingId: string) => apiRequest("POST", `/api/portal/bookings/${bookingId}/cancel`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/portal/calendar"] });
      queryClient.invalidateQueries({ queryKey: ["/api/portal/dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["/api/portal/bookings"] });
      toast({ title: "Booking cancelled" });
    },
    onError: (e: any) => toast({ title: "Cancel failed", description: e.message, variant: "destructive" as any }),
  });

  const activeBookings = bookings.filter((b) => b.status === "confirmed");

  return (
    <div className="p-6">
      <PageHeader title="Calendar" description="Available classes for your riders' levels" />

      {activeBookings.length > 0 && (
        <div className="mb-6">
          <h2 className="text-base font-semibold mb-2">My Upcoming Bookings</h2>
          <div className="space-y-2">
            {activeBookings.map((b) => (
              <Card key={b.id} data-testid={`card-booking-${b.id}`}>
                <CardContent className="p-4 flex justify-between items-center">
                  <div>
                    <div className="font-medium">{b.lessonName} — {b.riderName}</div>
                    <div className="text-sm text-muted-foreground">{b.startDatetime && formatWhen(b.startDatetime)}</div>
                  </div>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => cancelMutation.mutate(b.id)}
                    disabled={cancelMutation.isPending}
                    data-testid={`button-cancel-booking-${b.id}`}
                  >
                    Cancel
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      <h2 className="text-base font-semibold mb-2">Available Classes</h2>
      {isLoading ? (
        <p className="text-sm text-muted-foreground">Loading...</p>
      ) : lessons.length === 0 ? (
        <p className="text-sm text-muted-foreground">No upcoming classes available right now.</p>
      ) : (
        <div className="space-y-2">
          {lessons.map((lesson) => {
            const full = lesson.bookedCount >= lesson.capacity;
            return (
              <Card key={lesson.id} data-testid={`card-lesson-${lesson.id}`}>
                <CardContent className="p-4 flex justify-between items-center">
                  <div>
                    <div className="font-medium">{lesson.templateName}</div>
                    <div className="text-sm text-muted-foreground">{formatWhen(lesson.startDatetime)} · AED {lesson.price}</div>
                    <div className="text-xs text-muted-foreground">{lesson.bookedCount}/{lesson.capacity} booked</div>
                  </div>
                  <Button
                    size="sm"
                    disabled={full}
                    onClick={() => setBookingLesson(lesson)}
                    data-testid={`button-book-lesson-${lesson.id}`}
                  >
                    {full ? "Full" : "Book"}
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      <Dialog open={!!bookingLesson} onOpenChange={(open) => !open && setBookingLesson(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Book {bookingLesson?.templateName}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">{bookingLesson && formatWhen(bookingLesson.startDatetime)}</p>
            <div>
              <Label>Rider</Label>
              <SearchableSelect
                value={selectedRiderId}
                onValueChange={setSelectedRiderId}
                options={riders.map((r) => ({ value: r.id, label: r.fullName }))}
                placeholder="Select a rider"
                searchPlaceholder="Search riders..."
                testId="select-booking-rider"
              />
              {riders.length === 0 && (
                <p className="text-xs text-muted-foreground mt-1">Add a rider on the My Riders page first.</p>
              )}
            </div>
          </div>
          <DialogFooter className="mt-4">
            <Button
              disabled={!selectedRiderId || bookMutation.isPending}
              onClick={() => bookingLesson && bookMutation.mutate({ scheduledLessonId: bookingLesson.id, riderId: selectedRiderId })}
              data-testid="button-confirm-booking"
            >
              Confirm Booking
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
