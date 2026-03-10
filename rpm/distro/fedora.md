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
