My Claude Code Rules
These are my personal rules when working with Claude Code. Not a framework, not best practices — just what works for me after spending a lot of time with it.

1. I Don't Loop, I Don't Ralph — I Stay In The Loop
   Ralphing is when you throw a task at Claude and disappear until it's done. I don't do that.
   I see myself more as a system architect now than a regular developer. I know the domain, I know the system, and I use Claude to generate most of the code — but I'm always there. I'm providing context, watching the direction, stepping in when something looks off.
   The moment you disconnect is the moment Claude starts guessing. And it will guess confidently.
   Catching a wrong assumption at step 2 is nothing. Catching it after 200 lines of generated code built on top of it is painful.

2. Plan Mode — But Don't Overdo It
   I use plan mode but not religiously. If I need to rename a button I'm not asking for a plan. But if a task touches multiple files, has dependencies I care about, or could go wrong in non-obvious ways — I want Claude to tell me what it's going to do before it does it.
   The point is to catch wrong assumptions early. Not ceremony.
   Simple rule: if you'd feel nervous about Claude just going ahead — use plan mode. If the task is obvious and isolated — skip it.

3. Build Your Infrastructure — Agents, Skills, Hooks
   Most people use Claude Code as a chat thread. That's fine but it's the surface level.
   I have agents for specific types of work, skills that encode how things should be done in our codebase, and hooks that automate stuff around Claude's actions. This took time to build but now it pays off constantly.
   If you're doing the same type of task repeatedly and explaining the same context every time — that should be a skill. Write it once, use it everywhere.

4. Explicit Over Implicit — This Is The Big One
   This is probably the most important thing I can tell you.
   When someone says "fix the login bug" or "add authentication here" without any context — they're not just being lazy with the prompt. They're showing they don't actually know their own system well enough to explain it.
   Claude will fill the gaps. It'll guess which auth pattern you're using, where the state lives, how the API is structured. Sometimes it gets lucky. Usually it doesn't, and you waste time cleaning it up.
   I always tell Claude: what file handles this, what connects to what, what pattern to follow. Not because Claude needs hand-holding — but because that's just how you communicate about a system properly, to anyone.
   If you can't be explicit with Claude, you probably can't be explicit with a new teammate either. That's worth thinking about.
   Vague:

"Add login to the app"

How I do it:

"Add login. We use authContext in src/context/auth.tsx, API call goes to POST /api/auth/login, on success we get a JWT that goes into useAuthStore. Follow the same pattern as register in src/pages/register.tsx."

5. Trust But Verify — But Be Smart About It
   I trust Claude's output. I'm not rewriting everything or second-guessing every line. But I do review — just not everything equally.
   Backend logic, auth, anything touching data or external APIs — I look at that carefully. A generated page of UI that's 80% Tailwind classes and layout? I'm mostly just running it and seeing if it works.
   Spend your review budget where the risk actually is. Not everything deserves the same attention.
   Also — have tests. Have linting. Have CI. Claude works better when there's a safety net, and so do you.

6. You're Still Allowed To Write Code
   Claude is a multiplier. It's not a replacement.
   Sometimes the fastest thing is to just write it yourself. Sometimes giving Claude a code example is worth more than a paragraph of description — you show it the pattern, it follows it.
   I do this less than I used to as I've gotten better at expressing intent clearly. But it's still a valid move. The goal was never to stop writing code — it's to write it when it makes sense, not out of habit.
