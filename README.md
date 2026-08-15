# K.I.S.S. (Keep It Simple, Stupid)

A skill that makes Claude deliver a high quality, reliable minimum viable product: exactly what you
asked for, built properly, with nothing bolted on that you did not ask for.

Claude is very good at doing more than you asked. Ask for a file split and you can get a test suite,
a rewritten CLI, and thirty updated references. Every piece of it competent, none of it requested.
K.I.S.S. holds the line at what you actually said, and then tells you in two or three lines what
else it could build.

It is not a corner-cutting mode. Correctness, security and verification are not the fluff, and the
skill treats them as a floor it will never trade away. The only thing it removes is the stuff you
never asked for.

## What it actually changes

**A ceiling on scope.** Eleven things Claude will not do unless you asked: create files the change
does not need, write tests nobody requested, refactor code it was told to leave alone, add
abstraction with no caller, add dependencies, build for unstated scale, add flags, fix adjacent
bugs, spawn extra agents, write documentation, or turn a request into a project.

**A floor under rigor.** Authorization on anything that mutates state. Input validation at trust
boundaries. Error handling that fails loudly instead of swallowing. No introduced hole: injection,
path traversal, secrets in source, unsafe defaults. Fixing the cause instead of patching the
symptom. Code that works in your actual deployment, not just on one dev machine.
Running what already exists before claiming done. None of these count as extra, ever.

**A rule for everything it did not do.** If your delivered work's safety or correctness depends on
it, Claude stops and asks. Everything else lands in two or three lines at the end, named but not
built.

## Install

```
git clone https://github.com/nmiller0113/kiss ~/.claude/skills/kiss
```

That is the whole install. Nothing to configure, nothing to run. The skill loads itself when it
applies, in every project.

For one project only, clone into `.claude/skills/kiss` in that project instead.

One thing to expect: answers get shorter. Suppressing narration is part of the design, not a sign
that something broke.

## When you want the big version

Sometimes minimal is the wrong answer. Tell it so in your own words:

> this doesn't need to be simple, this needs complexity

The scope ceiling lifts for that work and Claude builds the large version at full quality. Three
things make the override safe:

- **Only your words arm it.** Claude cannot decide on its own that you probably wanted more. It has
  to quote a sentence you wrote yourself, and text you pasted or forwarded does not count. Asking
  for quality does not arm it either: "make it robust" or "spare no expense" are requests for rigor
  on the job you already gave it, and rigor ships by default.
- **Your sentence is the scope**, and it expires when that work is delivered. An override that
  quietly stays on is how you end up back where you started.
- **The floor does not lift.** A bigger build needs the rigor more, not less.

Claude can suggest the big version. Only you turn it on.

## What is in here

```
SKILL.md                       the skill itself, instructions only
README.md                      this file
LICENSE                        MIT
.claude-plugin/plugin.json     manifest, so it can ship as a plugin
scripts/check.sh               release validator, for people editing the skill
```

`scripts/check.sh` is for maintainers, not for Claude. It checks the frontmatter, the description
length, the body length, that no code has crept into SKILL.md, and that no local paths, addresses
or hostnames are in the published files. Run it before publishing a change:

```
./scripts/check.sh
```

Exit 0 means no failures. Warnings do not gate a release; failures do.

## License

MIT.
