---
name: rpm-debug
description: Debug RPM build failures and packaging issues
---

Using the prompt REVIEW_DIR/technical-patterns.md, analyze the provided
build log, error message, or packaging issue.

Load REVIEW_DIR/technical-patterns.md first, then load relevant topic
files based on the failure type.

Expected input:
- rpmbuild output/error messages
- mock build logs
- rpmlint output
- koji/copr build failure logs
- Dependency resolution errors

The protocol will:
1. Identify the failure type (spec parse error, build error, install
   error, dependency error, rpmlint error)
2. Analyze the relevant spec file section
3. Identify root cause
4. Suggest fixes with concrete spec file changes
