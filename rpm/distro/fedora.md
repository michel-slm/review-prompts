# Fedora Packaging Guidelines

## When to Load

Load this file when the target distribution is Fedora (detected by .fc* dist
tag, %{?fedora} macro, rawhide branch, or f* branch names).

## Fedora Packaging Guidelines Reference

The authoritative source is:
https://docs.fedoraproject.org/en-US/packaging-guidelines/

## Fedora-Specific Requirements

### License
- SPDX license identifiers mandatory since Fedora 38
- Reference: https://docs.fedoraproject.org/en-US/legal/allowed-licenses/

### Naming Conventions
- Python packages: `python3-*`
- Rust packages: `rust-*` (with `rust-*-devel` for library crates)
- Go packages: `golang-*`
- Ruby packages: `rubygem-*`
- Perl packages: `perl-*`
- Compatibility packages: `compat-*`

### Source Handling
- `%forgemeta` / `%forgesource` for GitHub/GitLab/etc. hosted projects
- `%pyproject_*` macros for Python packages
- `%cargo_*` macros for Rust packages
- `%gometa` / `%golist` for Go packages

### Build Requirements
- Use `%generate_buildrequires` with `%pyproject_buildrequires` for Python
- Dynamic BuildRequires supported and encouraged

### Filesystem
- `/usr/lib/` for noarch data, `/usr/lib64/` for 64-bit libraries
- No `/usr/lib/` for 64-bit libraries (use `%{_libdir}`)
- `/usr/libexec/` for internal executables

## Fedora Review Process

### Package Review Checklist
A Fedora package review typically checks:
1. Spec file follows naming guidelines
2. License is correct and allowed
3. Source URL works and matches upstream
4. Package builds in mock
5. rpmlint output is clean (or false positives documented)
6. File permissions are correct
7. Scriptlets are safe
8. Dependencies are correct and minimal
9. %check section runs tests (if available)
10. Documentation and license files are packaged

### Common Fedora-Specific Issues
- Missing `%{?_isa}` on library dependencies
- Using `%{_lib}` instead of `%{_libdir}`
- Not using `%pyproject_*` macros for Python packages
- Missing `%check` when upstream has tests
- Static libraries shipped without `-static` subpackage

## AI-Assisted Contributions

Fedora's AI-Assisted Contributions Policy (Fedora Council, v1.0,
2025-10-24) applies to anything contributed to the Fedora Project,
including EPEL: dist-git commits, pull requests to Fedora-hosted tooling
and docs, Bugzilla comments, and package reviews.

https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/

### Commits
- The human contributor is the author and is fully accountable. Never set
  an AI agent as the commit author or co-author
- Disclose AI assistance with an `Assisted-by:` trailer. It is required
  when a significant part of the contribution is taken from the tool
  without changes, and recommended otherwise
- Use `Assisted-by:`, NOT `Co-Authored-By:`, even if the agent's default
  attribution says otherwise. This matches the Linux kernel convention
- Recommended format, following the kernel's
  `Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]`:
  ```
  Assisted-by: Claude Code:claude-opus-5-5
  ```
  Name the agent and the exact model actually in use, not the model
  family or a guess. Additional non-obvious tools may follow; everyday
  tooling (git, editors, the build system) does not belong there.
  Fedora's own examples are free-form (`Assisted-by: generic LLM
  chatbot`), so any format that identifies the tool is acceptable
- The agent must never add a `Signed-off-by:` of its own: a DCO sign-off
  is a certification only a person can make. If the human directs the
  agent to commit with sign-off (`git commit -s`), the sign-off and the
  certification are the human's, so ask before each commit rather than
  committing unprompted
- With `%autochangelog` (rpmautospec), the commit message feeds the RPM
  changelog; keep the subject line a meaningful changelog entry and put the
  trailer at the end of the message body

### Other contributions
- Where authorship is normally indicated but there is no git history
  (Bugzilla comments, review reports, wiki pages, docs without trailers),
  disclose AI assistance in the text itself, e.g. a short note at the top
  or bottom of the comment
- Routine grammar/spelling/wording help does not need disclosure

### Reviews and evaluation
- AI analysis MAY assist human reviewers
- AI MUST NOT be the sole or final arbiter of a substantive or subjective
  judgment on a contribution. In package reviews, the decision to approve
  (setting `fedora-review+`) and to sponsor a packager stays with the
  human reviewer
- AI MUST NOT be used to evaluate a person's standing in the community
- Objective automated checks (CI, rpmlint, fedora-review tooling, tests)
  are not affected

## Reference Data

### Fedora Spec Archive
An archive of all current Fedora spec files is available at:
https://src.fedoraproject.org/lookaside/rpm-specs-latest.tar.xz

When you need to:
- Find real-world examples of a packaging pattern
- Verify how existing Fedora packages handle a specific case
- Check whether a macro or convention is widely used
- Compare a spec file against common Fedora conventions

Download and search this archive. It contains the latest spec files for all
Fedora packages and is the most comprehensive reference for actual packaging
practice in the distribution.

## Current Fedora Macros

### Recently Introduced
- `%bcond` shorthand (replaces `%bcond_with`/`%bcond_without` pair)
- `%conf` section for ./configure-like steps
- `%generate_buildrequires` for dynamic BuildRequires
- `%pyproject_*` family for Python packaging

### Still Available but Discouraged
- `%{?_smp_mflags}` - prefer `%make_build`
- `%setup -q` alone - prefer `%autosetup` when using patches
- `%{__rm}`, `%{__install}` - just use `rm`, `install` directly
