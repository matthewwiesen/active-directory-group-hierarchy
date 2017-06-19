# Overview
This repository contains a PowerShell script that will generate a corporate
hierarchy report centered around a specific Active Directory group. 

# How to use
Open PowerShell ISE on Windows machine that is managed by a domain. Change
directories to where this script is located and run the script. 

The script expects a single command line argument which should be the
Active Directory Group name.

```
PS C:\> cd C:\repositories\active-directory-group-hierarchy

PS C:\repositories\active-directory-group-hierarchy> .\ad-group-hierarchy.ps1
Error: Wrong number of parameters.
The script will generate an organization hierarchy based on on LDAP group

Usage:
  .\ad-group-hierarchy.ps1 <Group Name>

PS C:\repositories\active-directory-group-hierarchy>
```

# FAQs

## User does not have a manager
When running the report, some warnings may appear if there are users
who are members of the group, but no manager could be detected.

This could occur for a number of different reasons including:
* AD User may be a `Secondary` account which does not have a manager
* AD User may have been recently hired and does not have a manager yet
* AD User may have recently left the organization and no longer has a manager
