import type { SVGProps } from "react";

export function Horseshoe(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 100 100"
      fill="currentColor"
      {...props}
    >
      <path d="M25 8 L20 8 L20 15 L25 12 Z" />
      <path d="M75 8 L80 8 L80 15 L75 12 Z" />
      <path
        d="M20 15 C10 15, 5 30, 5 50 C5 70, 10 85, 15 95 L25 95 C20 85, 15 70, 15 50 C15 35, 20 22, 35 18 L50 16 L65 18 C80 22, 85 35, 85 50 C85 70, 80 85, 75 95 L85 95 C90 85, 95 70, 95 50 C95 30, 90 15, 80 15 Z"
      />
      <circle cx="12" cy="55" r="3" opacity="0.4" />
      <circle cx="13" cy="70" r="3" opacity="0.4" />
      <circle cx="16" cy="83" r="3" opacity="0.4" />
      <circle cx="88" cy="55" r="3" opacity="0.4" />
      <circle cx="87" cy="70" r="3" opacity="0.4" />
      <circle cx="84" cy="83" r="3" opacity="0.4" />
      <circle cx="25" cy="25" r="2.5" opacity="0.4" />
      <circle cx="75" cy="25" r="2.5" opacity="0.4" />
      <circle cx="38" cy="18" r="2.5" opacity="0.4" />
      <circle cx="62" cy="18" r="2.5" opacity="0.4" />
    </svg>
  );
}
