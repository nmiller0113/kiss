#!/usr/bin/env bash
# Release validator for the K.I.S.S. skill.
#
# Run by a human before publishing. Never invoked by Claude, and SKILL.md does not
# reference it: a skill that tells the model to run a script to check the skill is
# theatre.
#
# Two authorities are mixed on purpose, and each check says which it enforces:
#   [spec]  the portable Agent Skills frontmatter spec (name charset, 1024 chars)
#   [house] this project's own rules, stricter than anything a loader enforces
#
#   ./scripts/check.sh          exit 0 clean, exit 1 on any FAIL
#
# No pipefail: the leak scan pipes into `grep -q`, which exits at the first match
# and SIGPIPEs its producer. With pipefail that returns 141, the `if` goes false,
# and a genuinely leaking file prints "ok". Nothing here needs pipefail.
set -u

cd "$(dirname "$0")/.." || { printf 'FAIL  cannot cd to package root\n' >&2; exit 1; }
SKILL="skills/kiss/SKILL.md"
fails=0
warns=0

fail() { printf 'FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); }
warn() { printf 'WARN  %s\n' "$1" >&2; warns=$((warns + 1)); }
ok()   { printf 'ok    %s\n' "$1"; }
done_() { printf '\n%d fail, %d warn\n' "$fails" "$warns"; [ "$fails" -eq 0 ]; }

[ -f "$SKILL" ] || { fail "$SKILL not found"; done_; exit 1; }

# CRLF breaks every anchored match below, so rule it out before matching anything.
if grep -q $'\r' "$SKILL"; then
    fail "$SKILL has CRLF line endings; convert to LF"
    done_; exit 1
fi

# --- frontmatter boundaries ---------------------------------------------------
# Tolerate trailing whitespace on the fences: YAML parsers do, and a strict match
# silently picks up a later thematic break as the closer and shifts every check.
head -n 1 "$SKILL" | grep -qE '^---[[:space:]]*$' || fail "line 1 must be '---'"
fm_end=$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$SKILL")
[ -n "$fm_end" ] || { fail "frontmatter is never closed"; done_; exit 1; }
[ "$fm_end" -ge 3 ] || { fail "frontmatter is empty"; done_; exit 1; }
fm=$(sed -n "2,$((fm_end - 1))p" "$SKILL")
ok "frontmatter closes at line $fm_end"

# --- keys must be ones we recognise -------------------------------------------
# [spec] Charset covers digits and underscores; an earlier version used
# [a-zA-Z-]+ and was therefore blind to exactly the keys most likely to be typos
# (model_override, when_to_use), certifying them by never seeing them.
allowed="name description license compatibility metadata allowed-tools when_to_use \
disable-model-invocation model context hooks version author"
while IFS= read -r key; do
    case " $allowed " in
        *" $key "*) ;;
        *) fail "unrecognised frontmatter key: $key" ;;
    esac
done < <(printf '%s\n' "$fm" | grep -oE '^[A-Za-z0-9_-]+:' | tr -d ':')

# unquote strips one layer of matching quotes: `name: "kiss"` is valid YAML and
# resolves to kiss, so measuring the quotes is a false fail.
unquote() {
    local v=$1
    case $v in
        \"*\") v=${v#\"}; v=${v%\"} ;;
        \'*\') v=${v#\'}; v=${v%\'} ;;
    esac
    printf '%s' "$v"
}

# scalar_or_die enforces [house]: single-line plain scalars only. A block scalar
# (`>` or `|`) or a value continued on the next indented line reads as empty or
# 1 char here, which would make every length check below a lie. Refusing the
# shape is honest; half-parsing YAML in shell is not.
# Sets SCALAR, returns non-zero on failure. NOT called via $( ): command
# substitution runs in a subshell, so a fail() inside one increments a copy of
# the counter and the failure is printed but never tallied.
SCALAR=""
scalar_or_die() {
    local key=$1 raw
    SCALAR=""
    raw=$(printf '%s\n' "$fm" | sed -n "s/^$key[[:space:]]*:[[:space:]]*//p" | head -n 1)
    case $raw in
        '>'*|'|'*) fail "$key: is a block scalar; keep it on one line"; return 1 ;;
    esac
    if [ -z "$raw" ]; then
        fail "$key: has no value on its own line; keep it on one line"
        return 1
    fi
    raw=$(unquote "$raw")
    # A quoted run of spaces is not a value.
    case $raw in
        *[![:space:]]*) ;;
        *) fail "$key: is empty or whitespace only"; return 1 ;;
    esac
    SCALAR=$raw
}

# --- name ---------------------------------------------------------------------
if scalar_or_die name; then
    name=$SCALAR
    printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
        || fail "name '$name' must be lowercase letters, numbers and hyphens [spec]"
    [ ${#name} -le 64 ] || fail "name is ${#name} chars, spec limit is 64"
    # A downloaded zip lands in kiss-main/, which is fine, so this only warns.
    [ "$name" = "$(basename "$PWD")" ] \
        || warn "name '$name' does not match directory '$(basename "$PWD")'"
    ok "name: $name"
fi

# --- description: the field that decides whether the skill ever loads ----------
if scalar_or_die description; then
    desc=$SCALAR
    n=${#desc}
    if   [ "$n" -gt 1024 ]; then fail "description is $n chars, spec limit is 1024"
    elif [ "$n" -gt 500 ];  then warn "description is $n chars, house target is 500"
    else ok "description: $n chars"
    fi
fi

# --- body length [house] ------------------------------------------------------
# 500 is the documented best-practice ceiling, not a loader limit; 200 is ours.
lines=$(awk 'END{print NR}' "$SKILL")
body=$((lines - fm_end))
if   [ "$body" -gt 500 ]; then fail "body is $body lines, best-practice ceiling is 500"
elif [ "$body" -gt 200 ]; then warn "body is $body lines, house target is 200"
else ok "body: $body lines"
fi

# --- no code in SKILL.md [house] ----------------------------------------------
# Any fence at all, not a language allowlist: the allowlist version passed a bare
# fence containing a whole program. Examples here use blockquotes. Known limit:
# a 4-space-indented markdown code block is not detected, because it cannot be
# told apart from the indented continuation lines this file's bullets use.
if grep -qE '^[[:space:]]*(```|~~~)' "$SKILL"; then
    fail "SKILL.md contains a code fence; instructions belong here, code in scripts/"
else
    ok "no code fences in SKILL.md"
fi

# --- referenced companion files exist -----------------------------------------
while IFS= read -r ref; do
    while [ "${ref%[.,;:)]}" != "$ref" ]; do ref=${ref%[.,;:)]}; done
    [ -e "$ref" ] || fail "SKILL.md references '$ref', which does not exist"
done < <(grep -oE '(\./)?(scripts|references|assets)/[A-Za-z0-9._/-]+' "$SKILL" | sort -u)

# --- publishable: both files, not just SKILL.md -------------------------------
# Modest by design. This catches the leaks that actually happen (a pasted path,
# a host, an address); it is not a general secret scanner and is not claimed to be.
for f in "$SKILL" README.md skills/kiss/REMINDER.md hooks/hooks.json hooks/session-start.sh; do
    [ -f "$f" ] || continue
    if grep -q $'\r' "$f"; then
        fail "$f has CRLF line endings; convert to LF"
    fi
    # ⭐ TRAVERSAL FIRST, BEFORE ANY MASKING. Masking ~/.claude/<letter> to
    # INSTALLDIR/ strips the ~/ trigger from paths that merely START there and
    # then escape: '~/.claude/skills/../../../etc/x' masked clean while
    # '~/.claude/../.ssh/id_rsa' tripped, which is an arbitrary line. A published
    # skill has no legitimate use for a relative parent segment in a path, so any
    # occurrence is a finding rather than something to mask around.
    if grep -qE '\.\./' "$f"; then
        fail "$f contains a '../' path segment; it can smuggle a local path past the mask"
    fi
    # ~/.claude/ is the documented install location, so it is masked before the
    # scan rather than exempted after it: every OTHER tilde path still trips.
    if sed 's|~/\.claude/\([A-Za-z]\)|INSTALLDIR/\1|g' "$f" | grep -E '(/home/|/Users/|~/|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\b([a-z0-9-]+\.)+(local|lan|internal)\b|\b[0-9]{1,3}(\.[0-9]{1,3}){3}\b)' >/dev/null; then
        fail "$f contains a local path, address, internal hostname, or IP"
    else
        ok "$f: no local paths, addresses or hosts"
    fi
    if grep -q '—' "$f"; then
        fail "$f contains em dashes [house]"
    fi
done

# --- files a published package must carry -------------------------------------
# The shipped hook is the plugin's only guarantee that the rule reaches a context, and
# every way it can fail is silent by design. So check that it exists, is non-empty, is
# valid JSON, actually names the script it claims to reference, and can execute.
if [ ! -s hooks/hooks.json ]; then
    fail "hooks/hooks.json missing or empty; the SessionStart injector does not ship"
elif command -v python3 >/dev/null 2>&1 \
        && ! python3 -c 'import json,sys;json.load(open(sys.argv[1]))' hooks/hooks.json 2>/dev/null; then
    fail "hooks/hooks.json is not valid JSON; the hook will not register"
elif ! grep -q 'hooks/session-start.sh' hooks/hooks.json; then
    fail "hooks/hooks.json does not reference hooks/session-start.sh"
fi
[ -s hooks/session-start.sh ] || fail "hooks/session-start.sh missing or empty; hooks/hooks.json references it"
[ -x hooks/session-start.sh ] || fail "hooks/session-start.sh is not executable; the hook will not run"
# The hook prints this file and nothing else. Absent, it injects silently nothing.
[ -s skills/kiss/REMINDER.md ] || fail "skills/kiss/REMINDER.md missing or empty; the shipped hook prints nothing"

if [ -f LICENSE ]; then
    ok "LICENSE present"
else
    # The frontmatter declares a license; MIT requires its text to travel along.
    if printf '%s\n' "$fm" | grep -qE '^license[[:space:]]*:'; then
        fail "no LICENSE file, but the frontmatter declares one"
    else
        fail "no LICENSE file"
    fi
fi

done_
