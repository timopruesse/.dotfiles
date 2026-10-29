// Registry order is display order. Match complete checkout path components.
export const GROUPS = [
  { id: "personal", label: "Personal", owners: ["timopruesse"] },
  { id: "work", label: "Work", owners: ["chewielabs"] },
];

function owner(path) {
  const parts = (path ?? "").replace(/\\/g, "/").split("/").filter(Boolean);
  const github = parts.indexOf("github");
  return github >= 0 && parts.length > github + 2 ? parts[github + 1] : null;
}

export function groupRows(rows) {
  const sections = [...GROUPS, { id: "other", label: "Other", owners: [] }]
    .map(group => ({ ...group, rows: [] }));
  let section;
  for (const row of rows) {
    // Keep a main checkout and its already-nested worktrees indivisible.
    if (!row.tree || !section) {
      const repoOwner = owner(row.repoPath);
      const pathOwner = owner(row.path);
      section = sections.find(group => group.owners.includes(repoOwner))
        ?? sections.find(group => group.owners.includes(pathOwner))
        ?? sections[sections.length - 1];
    }
    section.rows.push(row);
  }
  return sections.filter(group => group.rows.length);
}
