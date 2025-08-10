import React from "react";

type SidebarProps = {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
};

export default function Sidebar({ children, className = "", style }: SidebarProps) {
  return (
    <aside className={["sidebar", className].filter(Boolean).join(" ")} style={style}>
      {children}
    </aside>
  );
}


