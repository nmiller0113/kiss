# Changelog

Entries start at 1.7.1. Earlier releases are on the repository's releases page; they are not
reproduced here, because a history written after the fact is a reconstruction rather than a
record.

## 1.7.1

Portability. The skill text is unchanged; this is about the machines the plugin can install
onto.

**The shipped hook required bash by name.** `hooks.json` invoked `bash` on the hook script,
so a machine with a POSIX shell but no bash, such as a minimal container image, got an error
at every fresh context instead of the reminder. The script was already POSIX-clean, so the
hook now runs it with `sh`, and it checks the file exists first and exits 0 quietly when it
does not, which is what the script's own header always promised.

**The release validator resolved its interpreter as `python3` only.** On a box carrying only
`python` the hooks.json JSON-validity check skipped in silence and the run still exited 0. The
interpreter is now resolved once across both spellings, its major version is probed rather
than inferred from the name, and its absence is announced instead of passing for a clean run.

The executable-bit assertion on the hook script is gone. `hooks.json` hands the path to an
interpreter, which reads the file and never consults the bit, so the check tested a property
nothing here depends on and its message said the hook would not run, which was untrue.

The publish-time leak scan no longer uses `\b`, a GNU extension rather than standard ERE.
Where a grep lacks it the internal-hostname and IP alternatives match nothing while the scan
still prints "ok". The replacement was checked to match the original identically under GNU
grep.

README gains a Requirements section. The skill itself needs nothing and loads anywhere; the
hook needs a POSIX shell, which on Windows means Git Bash. That was true before and stated
nowhere.

New `.gitattributes` pinning LF. Without it a Windows clone rewrites every tracked file to
CRLF, which kills the hook on its first line and trips the validator's own CRLF check, so the
repository would reject its own checkout.
