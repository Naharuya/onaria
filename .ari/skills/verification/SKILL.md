# Verification Skill

Use after implementation and before claiming completion.

Preferred project checks:
- `flutter analyze lib test example --no-fatal-infos`
- `flutter test`
- `cd backend && npm test`

Then:
1. inspect git diff
2. check secrets are not introduced
3. distinguish local test, CI, device, and production evidence
4. never report PASS for anything not executed
