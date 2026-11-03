# Spec File Deep Dive

## When to Load

Load this file when reviewing or working with RPM spec files directly.

## Canonical Section Ordering

1. **Header** - Name, Version, Release, Summary, License, URL, Source, Patch,
   BuildRequires, Requires, and other metadata tags
2. **%description** - Package description (can be multi-line)
3. **%package** subpackages - Each with its own Summary, Requires, %description
4. **%prep** - Source unpacking and patch application
5. **%build** - Compilation
6. **%check** - Test suite execution
7. **%install** - Installation to buildroot
8. **%files** - File listing for main package and each subpackage
9. **%changelog** - Change history

## Header Field Reference

### Required Fields
- `Name:` - package name (lowercase, hyphens OK, no underscores)
- `Version:` - upstream version
- `Release:` - package release, must include `%{?dist}`
- `Summary:` - one-line description (no trailing period)
- `License:` - SPDX expression (Fedora 38+) or legacy tag
- `URL:` - upstream project URL
- `Source0:` - source tarball URL (use `%{version}` macro)

### Common Optional Fields
- `BuildArch: noarch` - for architecture-independent packages
- `ExclusiveArch:` - limit to specific architectures
- `Epoch:` - version epoch (avoid if possible)
- `BuildRoot:` - not needed in modern RPM

## Name-Version-Release Conventions

### Standard Release
```
Release: 1%{?dist}
```

### Snapshot/Pre-release Versioning
```
# For pre-release snapshots (0.x release so it sorts before 1)
%global commit abc123def456
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global snapdate 20240101

Version: 1.2.0
Release: 0.1.%{snapdate}git%{shortcommit}%{?dist}
```

### Pre-release Versions (alpha, beta, rc)
```
Version: 1.2.0
Release: 0.1.rc1%{?dist}
```

### Epoch
- Avoid epoch if at all possible
- Only use when upstream changes versioning scheme in a way that breaks
  RPM version comparison
- Once set, epoch can never be removed

## Source and Patch Management

### Source URL Best Practices
```
# Use macros for version in URL
Source0: https://example.com/releases/%{name}-%{version}.tar.gz

# GitHub sources
Source0: https://github.com/owner/repo/archive/v%{version}/%{name}-%{version}.tar.gz

# Forge macros (Fedora)
%forgemeta
Source0: %{forgesource}
```

### Patch Handling
```
# Named patches
Patch0: fix-build.patch
Patch1: add-feature.patch

# In %prep with %autosetup (applies all patches automatically)
%autosetup -p1

# Or manually
%setup -q
%patch 0 -p1
%patch 1 -p1
```

## Subpackage Organization

### Common Subpackage Patterns

```
# Development files
%package devel
Summary: Development files for %{name}
Requires: %{name}%{?_isa} = %{version}-%{release}

# Shared libraries (when main package has binaries too)
%package libs
Summary: Shared libraries for %{name}

# Documentation
%package doc
Summary: Documentation for %{name}
BuildArch: noarch
```

### When to Split
- `-devel` - when package ships headers and/or pkgconfig files
- `-libs` - when main package has binaries and also ships shared libraries
- `-doc` - for large documentation sets (reduces base install size)
- `-static` - for static library archives (not shipped by default)
- Language bindings - `-python3`, `-perl`, etc.

## Architecture Handling

### noarch Packages
- Pure data, scripts, or interpreted language modules
- Set `BuildArch: noarch` in the header

### Architecture-Specific Dependencies
```
# Use %{?_isa} for library dependencies
Requires: libfoo%{?_isa} >= 1.2

# But NOT for -devel packages requiring their own -libs
# (already implied by the build)
```

### Conditional Architecture Blocks
```
%ifarch x86_64
# x86_64-specific configuration
%endif

%ifnarch s390x
# everything except s390x
%endif
```

## Spec Feature Availability by RPM Version

Before using a newer spec construct on older branches (EPEL, CentOS
Stream), check which RPM version introduced it and which RPM version the
target release ships.

### RPM Version per Release

Checked 2026-11-02 with `fedrq pkgs -b <branch> -F nevra rpm`:

| Branch | RPM |
|--------|-----|
| EL8 (`al8`, AlmaLinux) | 4.14.3 |
| c9s | 4.16.1.3 |
| c10s | 4.19.1.1 |
| f44 | 6.0.2 |
| f45 | 6.1.0 |
| rawhide | 6.1.0 |

`c8s` and `c7` return nothing because they are EOL and their mirrors are
gone. EL7 (RPM 4.11) and EL6 (RPM 4.8) are unverified, and both releases
are EOL. Re-check with `fedrq` when it matters, since these move.

### Constructs and the RPM Version That Introduced Them

| Construct | Introduced | Notes |
|-----------|------------|-------|
| `OrderWithRequires:` | 4.9.0 | Upstream commit 5c43095e1 (2010-12-13, "Implement transaction ordering hinting"); absent in rpm-4.8.1-release. Parsed like `Requires:`, so it takes the same qualifiers (`(post)` etc.); `%{?systemd_ordering}` relies on this |

### Finding When a Construct Was Introduced

Use rpm's git history:
```
git log -S'<keyword>' --reverse          # first commit mentioning it
git tag --contains <commit>              # first release containing it
git grep -i '<keyword>' rpm-X.Y.Z-release -- build/   # present in a release?
```
Upstream docs and the manual give the version for some constructs, but
not all.
