# RPM Scriptlet Safety Guide

## When to Load

Load this file when the spec file contains %pre, %post, %preun, %postun,
%pretrans, %posttrans, or %trigger* sections.

## Scriptlet Execution Order

### Install ($1 == 1)
1. `%pretrans` of new package
2. `%pre` of new package
3. Files installed
4. `%post` of new package
5. `%posttrans` of new package

### Upgrade ($1 == 2 for new, $1 == 1 for old)
1. `%pretrans` of new package
2. `%pre` of new package
3. Files of new package installed
4. `%post` of new package
5. `%preun` of old package ($1 == 1)
6. Files of old package removed
7. `%postun` of old package ($1 == 1)
8. `%posttrans` of new package

### Uninstall ($1 == 0)
1. `%preun` of old package ($1 == 0)
2. Files removed
3. `%postun` of old package ($1 == 0)

## The $1 Argument

| Scriptlet | Install | Upgrade | Uninstall |
|-----------|---------|---------|-----------|
| %pre | 1 | 2 | - |
| %post | 1 | 2 | - |
| %preun | - | 1 | 0 |
| %postun | - | 1 | 0 |
| %pretrans | 0 | 0 | - |
| %posttrans | 0 | 0 | - |

## systemd Service Macros

### Proper Usage
```
%post
%systemd_post myservice.service

%preun
%systemd_preun myservice.service

%postun
%systemd_postun_with_restart myservice.service
```

### Variants
- `%systemd_post` - enable service on install
- `%systemd_preun` - stop and disable on uninstall
- `%systemd_postun` - just reload daemon on upgrade (no restart)
- `%systemd_postun_with_restart` - restart service on upgrade

### tmpfiles and sysusers
```
%post
%tmpfiles_create_package %{name} %{_tmpfilesdir}/myapp.conf
%sysusers_create_package %{name} %{_sysusersdir}/myapp.conf
```

## File Trigger Scriptlets

Modern replacement for many scriptlets. Executed when files matching a
path pattern are installed/removed by any package.

```
%transfiletriggerin -- %{_libdir}
/sbin/ldconfig

%transfiletriggerpostun -- %{_libdir}
/sbin/ldconfig
```

Most common use: ldconfig is now handled by file triggers in base packages,
so `%ldconfig_scriptlets` or explicit ldconfig calls are often unnecessary
on modern systems.

## User/Group Creation

### Modern: sysusers.d (preferred)
```
# Install a sysusers.d file
Source1: myapp.sysusers
...
install -D -m 644 %{SOURCE1} %{buildroot}%{_sysusersdir}/myapp.conf

%post
%sysusers_create_package %{name} %{_sysusersdir}/myapp.conf
```

### Legacy: useradd in %pre
```
%pre
getent group myapp >/dev/null || groupadd -r myapp
getent passwd myapp >/dev/null || \
    useradd -r -g myapp -d /var/lib/myapp -s /sbin/nologin \
    -c "My Application" myapp
exit 0
```

## Common Scriptlet Bugs

### 1. Not Checking $1
```
# WRONG - runs on uninstall too
%post
systemctl enable myservice.service

# CORRECT - use macros that handle $1
%post
%systemd_post myservice.service
```

### 2. Failing on Uninstall
```
# WRONG - if config was already removed, this fails
%preun
rm /etc/myapp/generated.conf

# CORRECT - guard against missing files
%preun
rm -f /etc/myapp/generated.conf
```

### 3. Interactive Prompts
```
# WRONG - no terminal during package transactions
%post
read -p "Enter configuration value: " value

# CORRECT - use default values or config file
```

### 4. Assuming Network Availability
```
# WRONG - network may not be available
%post
curl -O https://example.com/data.json

# CORRECT - include needed files in the package
```

### 5. Referencing %{buildroot} Paths
```
# WRONG - buildroot does not exist at install time
%post
cat %{buildroot}%{_sysconfdir}/myapp.conf

# CORRECT
%post
cat %{_sysconfdir}/myapp.conf
```
