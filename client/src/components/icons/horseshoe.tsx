import type { SVGProps } from "react";

export function Horseshoe(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M5 20a1.5 1.5 0 1 1 0-3c.6 0 1.1.3 1.35.76C7.1 19 8 20 8 20" />
      <path d="M19 20a1.5 1.5 0 1 0 0-3c-.6 0-1.1.3-1.35.76C16.9 19 16 20 16 20" />
      <path d="M5 17C3.2 15 2 12 2 9a7 7 0 0 1 7-7h6a7 7 0 0 1 7 7c0 3-1.2 6-3 8" />
      <circle cx="7" cy="10" r="1" fill="currentColor" stroke="none" />
      <circle cx="12" cy="7" r="1" fill="currentColor" stroke="none" />
      <circle cx="17" cy="10" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}
