# K.I.S.S. (Keep It Simple, Stupid)

A Claude Code skill that makes Claude deliver a high quality, reliable minimum viable product:
exactly what you asked for, built properly, with nothing bolted on that you did not ask for.

Claude is very good at doing more than you asked. Ask for a file split and you can get a test
suite, a rewritten CLI, and thirty updated references. Every piece of it competent, none of it
requested. K.I.S.S. holds the line at what you actually said, and then tells you in two or three
lines what else it could build.

It is not a corner-cutting mode. The constraint is on scope, never on craft: inside what you asked
for, Claude builds the most robust version it can, to spec, at full quality. Correctness, security
and verification are not the fluff, and the skill treats them as a floor it will never trade away.
If shipping safely depends on something outside your ask, Claude stops and asks instead of deciding
for you. The only thing it removes is the stuff you never asked for.

## Install

```
git clone https://github.com/nmiller0113/kiss ~/.claude/skills/kiss
```

Nothing to configure. The skill loads itself when it applies. For one project only, clone into
that project's `.claude/skills/kiss` instead.

Expect shorter answers. Suppressing narration is the design, not a malfunction.

## When you want the big version

Sometimes minimal is the wrong answer. Say so in your own words:

> this doesn't need to be simple, this needs complexity

Only your own words arm it: Claude must quote a sentence you wrote yourself, and text you pasted
or forwarded never counts. Quality words do not count either, since "make it robust" is a request
for rigor on the job you already gave it, and rigor ships by default. The override covers what
your sentence names, expires when that work is delivered, and never lifts the floor.

Claude can suggest the big version. Only you turn it on.

## License

MIT.
