import { useQuery } from "@tanstack/react-query";

export interface MeResponse {
  id: string;
  username: string;
  roles: string[];
  isAdmin: boolean;
  permissions: string[];
  customerId: string | null;
}

export function usePermissions() {
  const { data, isLoading } = useQuery<MeResponse>({
    queryKey: ["/api/me"],
  });
  return {
    roles: data?.roles ?? [],
    isAdmin: data?.isAdmin ?? false,
    permissions: data?.permissions ?? [],
    isLoading,
  };
}

/**
 * Returns true if the current user may perform the given action key (or, if
 * given an array, ANY one of them — matching the backend's requirePermission
 * "any of these keys" semantics). Admins (isAdmin) implicitly have every
 * permission.
 */
export function useCan(actionKey: string | string[]): boolean {
  const { isAdmin, permissions } = usePermissions();
  if (isAdmin) return true;
  const keys = Array.isArray(actionKey) ? actionKey : [actionKey];
  return keys.some((k) => permissions.includes(k));
}
