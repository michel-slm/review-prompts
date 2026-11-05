# Security Advisory Triage

## When to Load

Load this file when deciding whether a CVE or other security advisory
affects a package, especially one that bundles a copy of a library,
interpreter or runtime (`Provides: bundled(...)`, vendored sources), or
when answering CVE bugs filed against a package.

## Find the Fix

- NVD often records no fixed version; that is not the end of it. OSV
  (`https://api.osv.dev/v1/vulns/<CVE-ID>`) aggregates upstream
  advisories and usually gives the fix commits and the repository. For
  CPython these are the PSF's advisories (aliases `PSF-YYYY-N`), with a
  fix commit for each maintained branch
- Prefer the upstream advisory and the fix commits over version ranges
  copied between databases

## Judge a Bundled Copy by Its Own Release Line

- The question is whether the bundled version contains the fix, not
  whether it is older than the newest fixed release. Bundled Python
  3.13.9 is fixed by a 3.13.N release, not only by 3.15.0
- Report the first release on that line that has the fix, or "no fix on
  this line" when upstream fixed only the main branch

## Check Containment With Git

- Whether a fix is in a release is exact in git: is any of the fix
  commits (one per backport branch) an ancestor of the release tag?
  - Local clone: `git merge-base --is-ancestor <fix> <tag>` (exit 0 means
    the tag contains the fix)
  - GitHub: `gh api repos/<owner>/<repo>/compare/<tag>...<fix> --jq .status`;
    `behind` or `identical` means the tag contains the fix
- Lists derived from git are not exact. OSV's affected-version lists
  can miss tags, e.g. an expedited release whose tag is off the branch
  line, so a version missing from the list is not evidence that it is
  unaffected (or affected). Check the tag itself

## Version Facts and Reachability Are Separate

- A bundled copy can be affected by version while the vulnerable code
  is never used (e.g. a bundled Python that never imports the vulnerable
  module). Report the version facts, and state reachability as a
  judgement for the maintainer, with reasons; don't decide it from
  versions alone

## Report One Action

- When many advisories hit one bundled copy, sum them up as the action
  the maintainer can take, e.g. "bundling 3.13.18 or later fixes all but
  CVE-2025-15367 (fixed on main only)", rather than one verdict per CVE
- Link the evidence for each: the fix commit and how containment was
  checked

Example: asahi-installer bundles CPython 3.13.9 and had 36 CPython CVE
bugs. OSV's tag lists omitted v3.13.9 for every one of them; checking
the tag in git showed one bug (CVE-2025-8194) was already fixed, and the
rest resolve to one action: bundle 3.13.18 or later, except
CVE-2025-15367, which upstream fixed only on main.
