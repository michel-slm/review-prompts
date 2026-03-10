# CentOS Stream Packaging Guidelines

## When to Load

Load this file when the target distribution is CentOS Stream or RHEL
(detected by .el* dist tag, %{?rhel} or %{?centos} macros, or c*s branch
names).

## Relationship to Fedora Guidelines

CentOS Stream follows RHEL packaging practices, which derive from but
diverge from Fedora guidelines. Key principle: CentOS Stream is more
conservative than Fedora -- newer RPM features and macros may not be
available.

## Key Differences from Fedora

### RPM and Macro Version
- CentOS Stream ships older RPM than Fedora
- Some Fedora macros may not be available:
  - `%forge*` macros: may need `forge-srpm-macros` from EPEL
  - `%pyproject_*`: available in CentOS Stream 9+ but may differ from Fedora
  - `%bcond` shorthand: check RPM version
  - `%conf` section: RPM 4.18+, may not be in older EL versions
  - Dynamic `%generate_buildrequires`: check availability
  - Boolean dependencies: `(pkgA or pkgB)` syntax

### License Field
- CentOS Stream 10+: SPDX identifiers (following Fedora)
- CentOS Stream 9: legacy license identifiers still commonly used
- When in doubt, check what existing packages in the target use

### Compiler Flags and Hardening
- `%{optflags}` values differ from Fedora
- Hardening defaults may differ
- Spec files should respect distribution defaults

### Weak Dependencies
- Supported in EL8+
- Used more conservatively than in Fedora
- `Recommends` is the most commonly used weak dependency

### No %check Requirement
- Running tests is encouraged but not as strictly required as in Fedora
- Build environment may not have all test dependencies available

## EPEL Considerations

When packaging for EPEL (Extra Packages for Enterprise Linux):

### EPEL-Specific Guidelines
- Packages must not conflict with base RHEL/CentOS Stream packages
- Must not replace or update base packages
- Should use `epel-rpm-macros` for compatibility shims

### Conditional Macros for EPEL
```
# Available in EPEL packages
%{?epel}

# Target EL version
%{?rhel}

# Example: use different dependency on EPEL vs Fedora
%if 0%{?rhel}
Requires: python3-foo
%else
Requires: python3-foo >= 2.0
%endif
```

### Macro Compatibility
- `epel-rpm-macros` provides compatibility macros for features missing
  in base EL
- Check if `%pyproject_*` macros are available via EPEL packages

## Build System Differences

### CentOS Stream Build Pipeline
- Uses different build infrastructure than Fedora (Brew/MBS vs Koji)
- Module builds may be relevant for some packages
- Side tags and build dependencies may work differently

### Mock Configuration
- Use the appropriate mock config for the target:
  - `centos-stream-9-x86_64`
  - `centos-stream-10-x86_64`
- Don't assume Fedora mock configs work for CentOS Stream

## Common CentOS Stream Issues

1. **Using Fedora-only macros** without checking availability
2. **SPDX identifiers** on older CentOS Stream (use legacy format)
3. **Boolean dependencies** not supported in older RPM versions
4. **Missing EPEL dependencies** when backporting Fedora packages
5. **Different Python version** than Fedora (especially on older EL)
