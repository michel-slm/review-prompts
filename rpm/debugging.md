# RPM Build Debugging Protocol

## Overview

This protocol guides systematic debugging of RPM build failures (local
rpmbuild, mock, koji, copr) and packaging issues that surface after the
build (dependency resolution, install-time scriptlet failures).

## Pre-Debug Setup

1. ALWAYS load `technical-patterns.md` first
2. Load `distro/distro.md` and detect the target distribution and release
3. Load `ecosystem/ecosystem.md` and the matching ecosystem file, if any
4. Identify the failing phase (DEBUG.1) and load topic files accordingly

## Core Rules

- Find the FIRST error, not the last. The final `error: Bad exit status`
  line only says which section failed; the cause is usually far above it
- Never guess what a macro expands to. Check with `rpm --eval` or
  `rpmspec -P` in the same buildroot as the failing build
- Distinguish "the spec is wrong" from "the buildroot changed": a package
  that built last month and fails now with no spec change almost always
  failed because something in the buildroot changed (toolchain, dependency
  update, removed package)
- Reproduce before proposing a fix when a reproduction environment is
  available

## DEBUG.1: Identify the Failing Phase

| Symptom / log location | Phase | Typical causes |
|------------------------|-------|----------------|
| `error: line N: ...` before any section runs, `rpmspec` fails | Spec parse | Undefined macro used in a tag, bad conditional nesting, unclosed `%if` |
| mock `root.log`: `No matching package to install`, `nothing provides` | Buildroot install | Missing/renamed/retired BuildRequires, wrong version constraint, missing `%{?_isa}` mismatch, package not yet in buildroot (koji tag / side tag) |
| `%generate_buildrequires` loops or fails | Dynamic BuildRequires | Generator needs a dep not yet installed, upstream metadata pins a version Fedora does not have |
| `+ ... %prep` then patch/`tar` errors | %prep | Patch no longer applies after rebase, wrong `-p` level, source archive top-level dir changed (`%autosetup -n`) |
| compiler / linker errors during `%build` | %build | Toolchain bump (new GCC/Clang warnings/errors, stricter C standard defaults), missing BuildRequires, flags overridden |
| test failures in `%check` | %check | Network access in tests (blocked in koji/mock), timing-sensitive tests, arch-specific failures, test deps missing |
| `Installed (but unpackaged) file(s) found` | %files | New files after version bump, files installed to unexpected path (`lib` vs `lib64`) |
| `File not found: /builddir/build/BUILDROOT/...` | %files | File not installed, path changed upstream, macro expands differently than assumed |
| brp-* script errors after %install (`brp-mangle-shebangs`, `brp-python-bytecompile`, `check-rpaths`, `check-buildroot`) | Post-install checks | Ambiguous shebang (`#!/usr/bin/python`), invalid RPATH, buildroot path leaked into installed files |
| `Missing build-id`, `find-debuginfo` errors, `Empty %files file debugsourcefiles.list` | debuginfo | Binary not built with distro flags, stripped by upstream build system, Go/Rust built without the ecosystem macros, noarch package with no binaries |
| Package builds, but `dnf install` fails: `nothing provides` | Dependency generation | Auto-generated requires on something not packaged, private library leaked into requires/provides |
| Package installs with scriptlet errors | Scriptlets | See `scriptlets.md` |
| rpmlint `E:` / `W:` lines on the SRPM or built RPMs | rpmlint | Real packaging issue, or rpmlint false positive (check before fixing) |

Load the topic file that matches the phase:

| Phase | File |
|-------|------|
| rpmlint | `false-positive-guide.md` (CHECK 5) first, then the topic file for the flagged area |
| Spec parse, macro expansion | `macros.md`, `spec-file.md` |
| Buildroot install, dependency generation | `dependencies.md` |
| Scriptlets | `scriptlets.md` |
| Anything inside an ecosystem build (cargo, go, pip/pyproject) | matching `ecosystem/*.md` |

## DEBUG.2: Locate the Relevant Logs

### mock (local or koji/copr build results)
- `root.log`: buildroot installation, dependency resolution, dnf errors
- `build.log`: rpmbuild output (all spec sections)
- `state.log`: timing of each stage, useful to tell where it stopped
- `hw_info.log`: builder CPU/memory/disk (relevant for OOM or timeouts)

### koji
- A failed `build` task has child `buildArch` tasks; the logs are on the
  child task for the failing architecture, not on the parent
- If only some architectures fail, the problem is arch-specific (see
  DEBUG.5) or a flaky builder
- `koji buildinfo NVR` / `koji taskinfo -v TASK` to find tasks

### copr
- Per-chroot `builder-live.log` contains the whole mock run;
  `backend.log` covers infrastructure issues (timeouts, failed downloads)

## DEBUG.3: Reproduce

Prefer reproducing in the same buildroot the failure occurred in:

```
# From a dist-git checkout
fedpkg mockbuild                         # current branch's target
fedpkg --release f42 mockbuild           # explicit release

# Plain mock
mock -r fedora-rawhide-x86_64 --rebuild foo.src.rpm
mock -r centos-stream-10-x86_64 --rebuild foo.src.rpm

# Keep the buildroot for inspection
mock -r <cfg> --no-clean --no-cleanup-after --rebuild foo.src.rpm
mock -r <cfg> --shell                    # enter the buildroot
# Sources live under /builddir/build/ inside the chroot

# Iterate on a single phase locally (no clean buildroot guarantee)
rpmbuild -bp foo.spec                    # %prep only
rpmbuild -bi --short-circuit foo.spec    # re-run %install only
rpmbuild -bl foo.spec                    # check %files only
```

Inspect macro expansion in the target environment:

```
rpmspec -P foo.spec                      # fully expanded spec
rpm --eval '%{_libdir}'
rpm --eval '%{optflags}'
mock -r <cfg> --shell -- rpm --eval '%{python3_version}'
```

When the failure involves a dependency that changed recently, compare
buildroots:

```
# root.log of a good and a bad build list installed NVRs; diff them
koji list-tagged --latest <tag> <pkg>
koji list-buildroot <buildroot-id>       # what was in a given buildroot
```

## DEBUG.4: FTBFS After a Distribution Change

When a previously-building package fails with no spec change, check what
changed in the distribution first:

- **Mass rebuild / toolchain bump**: new GCC or Clang major version
  (new default warnings, `-Werror` in upstream builds, removed implicit
  declarations), new default C/C++ standard
- **Language runtime bump**: new Python, Go, Rust, Ruby, Perl, Node
  versions (see ecosystem files)
- **Dependency update**: soname bump in a library (check root.log for
  the version), API removal, pkgconfig module rename
- **Macro changes**: redhat-rpm-config or ecosystem macro package
  updates; deprecated macros removed
- **Retired package**: a BuildRequires was retired from the distro

Fedora tracks these as Changes
(https://fedoraproject.org/wiki/Changes) and mass-rebuild FTBFS bugs are
filed in Bugzilla. Check the Change page for porting notes before
patching.

## DEBUG.5: Architecture-Specific Failures

If only some architectures fail, think about what the failing
architectures have in common:

| Architecture | Common issue |
|--------------|--------------|
| s390x | Big-endian: byte-order assumptions in code or test fixtures |
| i686 | 32-bit: `size_t`/`long` overflow, time_t/large file issues, memory exhaustion during linking |
| ppc64le | Different `long double` ABI, page size 64K |
| aarch64 | Page size assumptions, `char` signedness (unsigned by default), weaker memory ordering exposing races |
| riscv64 | Slower builders: timeouts; missing JIT/asm backends |

Legitimate responses:
- Fix or patch the code (preferred; send upstream)
- Skip the specific failing test on that arch, with a comment and an
  upstream bug link
- `ExcludeArch:` with a justification. In Fedora, excluding an arch
  requires filing a tracker bug blocking the arch's ExcludeArch tracker
- Use ecosystem arch macros (`%{rust_arches}`, `%{golang_arches}`) where
  the toolchain itself is not available

## DEBUG.6: Fix Proposal

For each diagnosed failure provide:
1. The failing phase and the first relevant error line(s) quoted from the log
2. Root cause, with evidence (spec line, log line, macro expansion)
3. Whether this is a spec problem, upstream bug, or buildroot/distribution
   change
4. A concrete spec change (diff) or patch, minimal in scope
5. Whether the fix should go upstream (code/test fixes almost always should)
6. For temporary workarounds (skipped tests, ExcludeArch, version pin):
   a comment in the spec explaining why and when it can be removed

Do not propose:
- Disabling `%check` entirely to fix one failing test
- `AutoReqProv: no` to fix a single bad generated dependency
- Overriding `%{optflags}` / `%{build_ldflags}` to silence a warning
- `-Wno-error` without identifying the warning being suppressed
- Network access during the build
