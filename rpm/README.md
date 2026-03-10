# RPM Review Prompts for Claude Code

AI-assisted review prompts for RPM packages, supporting Fedora and
CentOS Stream distributions.

## Installation

Run the setup script to install the skill and slash commands:

    ./scripts/claude-setup.sh

This will install:
- The `rpm` skill to `~/.claude/skills/rpm/SKILL.md`
- Slash commands to `~/.claude/commands/`

## Usage

The RPM skill loads automatically when working with spec files or in
a dist-git repository structure.

### Slash Commands

- `/rpm-review` - Review spec files and packages for policy compliance
- `/rpm-debug`  - Debug build failures and packaging issues
- `/rpm-verify` - Verify findings against false positive patterns

### Distribution Detection

The prompts automatically detect the target distribution from context:
- %{dist} tag values (.fc*, .el*)
- Macro usage (%{?fedora}, %{?rhel})
- Branch naming (f*, rawhide, c*s)
- Default: Fedora (most strict)

## File Structure

| File | Purpose | When Loaded |
|------|---------|-------------|
| **review-core.md** | Main review protocol | Always (entry point) |
| **technical-patterns.md** | Core RPM patterns | Always (loaded first) |
| **false-positive-guide.md** | False positive elimination | During verification |
| **spec-file.md** | Spec file structure | Spec file reviews |
| **macros.md** | RPM macro reference | Complex macro usage |
| **scriptlets.md** | Scriptlet safety | Scriptlet review |
| **dependencies.md** | Dependency management | Dependency issues |
| **licensing.md** | License handling | License review |
| **distro/distro.md** | Distribution detection | Always (after context detection) |
| **distro/fedora.md** | Fedora guidelines | Fedora targets |
| **distro/centos-stream.md** | CentOS Stream guidelines | CentOS/RHEL targets |

## Integration

This setup coexists with kernel, systemd, and iproute review prompts.
Each installs to a separate skill directory. To install all:

    cd kernel/scripts && ./claude-setup.sh
    cd ../../systemd/scripts && ./claude-setup.sh
    cd ../../iproute/scripts && ./claude-setup.sh
    cd ../../rpm/scripts && ./claude-setup.sh

## Supported Distributions

- **Fedora** (rawhide and stable releases)
- **CentOS Stream** (9, 10)
- **EPEL** (via CentOS Stream guidelines)
