---
name: rpm
description: Load anytime the working directory contains RPM spec files or packaging artifacts. RPM packaging knowledge, distribution-specific guidelines, spec file review, and build debugging protocols.
invocation_policy: automatic
---

## ALWAYS READ
1. Load `{{RPM_REVIEW_PROMPTS_DIR}}/technical-patterns.md`

These files are MANDATORY. This skill exists as a framework for loading
additional RPM packaging prompts.

## Configuration

The review prompts directory is configured during installation:
- **RPM_REVIEW_PROMPTS_DIR**: {{RPM_REVIEW_PROMPTS_DIR}}

This variable is set by the installation script when the skill is installed.

## Activation

This skill activates when working in an RPM packaging context, detected by:
- Presence of *.spec files
- Presence of sources/ or SOURCES/ directory
- Presence of .rpmlintrc or rpmlint.toml
- Presence of mock configuration files
- Working in a dist-git repository structure

## Capabilities

### Package Review
When asked to review an RPM spec file or built package:
1. Load `{{RPM_REVIEW_PROMPTS_DIR}}/review-core.md`
2. Follow the complete review protocol defined there
3. Load distribution-specific files as directed by review-core.md

### Build Debugging
When asked to debug a build failure or packaging issue:
1. Load `{{RPM_REVIEW_PROMPTS_DIR}}/review-core.md`
2. Identify the failure type (build, dependency, scriptlet, etc.)
3. Load relevant technical files

### Distribution Context
When working on RPM packages for specific distributions, load the appropriate
context files from `{{RPM_REVIEW_PROMPTS_DIR}}/`:

1. Always read `technical-patterns.md` before loading distro-specific files

2. Read `{{RPM_REVIEW_PROMPTS_DIR}}/distro/distro.md` and load matching
   distribution guides

3. Select topic-specific files as needed:

| Topic | Trigger | File |
|-------|---------|------|
| Spec file structure | *.spec files, spec sections | spec-file.md |
| Macro usage | %{macro}, %define, %global | macros.md |
| Scriptlets | %pre, %post, %preun, %postun | scriptlets.md |
| Dependencies | Requires, BuildRequires, Provides | dependencies.md |
| Licensing | License:, %license, SPDX | licensing.md |
| Fedora | .fc* dist, %{?fedora} | distro/fedora.md |
| CentOS Stream | .el* dist, %{?rhel} | distro/centos-stream.md |

## Reference Data

When looking up real-world packaging patterns or verifying conventions:
- **Fedora spec archive**: https://src.fedoraproject.org/lookaside/rpm-specs-latest.tar.xz
  Contains all current Fedora spec files. Download and search when you need
  concrete examples of how existing packages handle a specific pattern.

## Output

- Package reviews produce a report with severity-classified findings
- Build debugging produces diagnosis with suggested fixes
- Both outputs are plain text, suitable for Bugzilla or Pagure

## Key RPM Conventions

### Spec File Basics
- Use %global for top-level macro definitions, not %define
- Use path macros (%{_bindir}, etc.) instead of hardcoded paths
- Include %check section when test suite is available

### Dependencies
- Trust automatic dependency generation unless it fails
- Use %{?_isa} for architecture-specific library dependencies
- Use weak dependencies (Recommends) for optional features

### File Ownership
- Own all directories you create
- Do not own system directories (%{_bindir}, etc.)
- Use %license for license files, not %doc
