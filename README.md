# K.I.S.S. (Keep It Simple, Stupid)

A Claude Code skill that makes Claude deliver a high quality, reliable minimum viable product:
exactly what you asked for, built properly, with nothing bolted on that you did not ask for.

Claude is very good at doing more than you asked. Ask for a file split and you can get a test
suite, a rewritten CLI, and thirty updated references. Every piece of it competent, none of it
requested. K.I.S.S. holds the line at what you actually said, and then tells you in two or three
lines what else it could build.

It is not a corner-cutting mode. The constraint is on scope, not on craft: inside what you asked
for, Claude builds it properly, to spec, at full quality. Correctness, security
and verification are not the fluff, and the skill treats them as a floor it will never trade away.
If shipping safely depends on something outside your ask, Claude stops and asks instead of deciding
for you. The only thing it removes is the stuff you never asked for.

## Install

```
/plugin marketplace add nmiller0113/claude-marketplace
/plugin install kiss@nates-plugins
```

Then `/reload-plugins`, or restart. Update later with `/plugin update kiss@nates-plugins`
followed by `/reload-plugins` again.

Expect shorter answers. Suppressing narration is the design, not a malfunction.

## How it fires

Three ways, in increasing order of reliability. Pick the one that matches how much you want to
think about it.

**Automatically.** Claude reads the skill's description and loads it when it judges the task
matches: before the first edit on anything that produces work. No setup, and it is the intended
path.

**On demand: `/kiss:kiss`.** Loads it right now. This is the one to reach for when Claude has
already started sprawling mid-task and you want the rule in front of it immediately.

**Always, via a hook.** Worth understanding the limitation honestly: a skill only enters Claude's
context when it is *invoked*, and automatic invocation is a judgment call Claude can simply miss.
If you want the constraint present in every session regardless, put a short factual summary in a
`SessionStart` hook, which runs at every fresh context including after compaction:

```json
{ "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact",
  "hooks": [ { "type": "command", "command": "cat ~/.claude/kiss-reminder.txt" } ] } ] } }
```

Keep that file to a dozen declarative lines: the boundary of the work is the boundary of the
request, a finding outside the ask is one sentence rather than a task, and the floor still ships.
Write it as statements of fact, not as commands. Claude's prompt-injection defenses will surface
command-shaped hook text to you instead of absorbing it, which leaves you with a rule that reads
well and never applies.

## Using it

- **Ask for one thing.** The skill is most useful when the request has a clear boundary, because
  the boundary is what it enforces.
- **Read the closing offer.** Every response ends with two or three lines of what could come next.
  That is where the work you did not ask for goes, and saying "do the second one" is how you get it.
- **Expect one-line findings.** When Claude spots a real bug outside your ask, you get a sentence
  and nothing else. That is deliberate; the sentence is your cue to decide.
- **Answer the mid-task question.** If scope grows, Claude stops and asks before editing rather
  than after. A "yes" costs a word; discovering an unrequested rewrite costs an afternoon.
- **Pair it with a plan for large work.** The skill deliberately makes Claude stop at the edge of
  the ask, so for genuinely multi-part builds, give it the whole shape up front or use the
  override below.

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
