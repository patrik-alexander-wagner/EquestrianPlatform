import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import type { RsRidingPackage, RsPackagePurchase } from "@shared/schema";

export default function PortalPackagesPage() {
  const { toast } = useToast();
  const { data: packages = [] } = useQuery<RsRidingPackage[]>({ queryKey: ["/api/portal/packages"] });
  const { data: purchases = [] } = useQuery<RsPackagePurchase[]>({ queryKey: ["/api/portal/package-purchases"] });
  const packageById = Object.fromEntries(packages.map((p) => [p.id, p]));

  const purchaseMutation = useMutation({
    mutationFn: (packageId: string) => apiRequest("POST", "/api/portal/package-purchases", { packageId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/portal/package-purchases"] });
      toast({ title: "Package purchased — an invoice has been sent for payment" });
    },
    onError: (e: any) => toast({ title: "Purchase failed", description: e.message, variant: "destructive" as any }),
  });

  return (
    <div className="p-6">
      <PageHeader title="Riding Packages" description="Purchase a bundle of lessons for a specific class type" />

      <h2 className="text-base font-semibold mb-2">Available Packages</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {packages.map((pkg) => (
          <Card key={pkg.id} data-testid={`card-package-${pkg.id}`}>
            <CardContent className="p-4 space-y-2">
              <h3 className="font-semibold">{pkg.name}</h3>
              <p className="text-sm text-muted-foreground">{pkg.numberOfLessons} lessons · valid {pkg.validityDays} days</p>
              <p className="text-lg font-bold">AED {pkg.price}</p>
              <Button
                size="sm"
                className="w-full"
                onClick={() => purchaseMutation.mutate(pkg.id)}
                disabled={purchaseMutation.isPending}
                data-testid={`button-purchase-package-${pkg.id}`}
              >
                Purchase
              </Button>
            </CardContent>
          </Card>
        ))}
        {packages.length === 0 && <p className="text-sm text-muted-foreground">No packages available right now.</p>}
      </div>

      <h2 className="text-base font-semibold mb-2">My Packages</h2>
      {purchases.length === 0 ? (
        <p className="text-sm text-muted-foreground">You haven't purchased any packages yet.</p>
      ) : (
        <div className="space-y-2">
          {purchases.map((purchase) => (
            <Card key={purchase.id} data-testid={`card-purchase-${purchase.id}`}>
              <CardContent className="p-4 flex justify-between items-center">
                <div>
                  <div className="font-medium">{packageById[purchase.packageId]?.name || "Riding Package"}</div>
                  <div className="text-sm text-muted-foreground">Valid until {purchase.validUntil} · {purchase.status}</div>
                </div>
                <div className="text-2xl font-bold" data-testid={`value-lessons-remaining-${purchase.id}`}>{purchase.lessonsRemaining}</div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
