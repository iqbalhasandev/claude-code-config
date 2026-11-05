# Browser Checks — Full Permission

Applies to every project and every session.

- When a change needs checking in a real browser (UI, report output, end-to-end flow), do it yourself with the
  browser tools: Claude in Chrome extension, Chrome DevTools MCP, or Playwright MCP. Do not ask first and do not
  hand the check back to the user.
- The user has granted full permission for these browser checks.
- Still never trigger destructive actions in the app (deletes, payroll runs, sending notifications) as part of a
  check, and never enter credentials the user has not provided.

Reason: the user wants browser verification done end to end without being asked each time.
