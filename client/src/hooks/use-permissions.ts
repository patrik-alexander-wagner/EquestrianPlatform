import { useQuery } from "@tanstack/react-query";

export interface MeResponse {
  id: string;
  username: string;
  role: string;
  isAdmin: boolean;
  permissions: string[];
}

export function usePermissions() {
  const { data, isLoading } = useQuery<MeResponse>({
    queryKey: ["/api/me"],
  });
  return {
    role: data?.role ?? "",
    isAdmin: data?.isAdmin ?? false,
    permissions: data?.permissions ?? [],
    isLoading,
  };
}

/**
 * Returns true if the current user may perform the given action key.
 * Admins (isAdmin) implicitly have every permission.
 */
export function useCan(actionKey: string): boolean {
  const { isAdmin, permissions } = usePermissions();
  if (isAdmin) return true;
  return permissions.includes(actionKey);
}
