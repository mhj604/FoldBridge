# Watch 0.5.20 — resume stalled recovery on execution opportunities

[한국어](BACKGROUND_OPPORTUNITY_0.5.20_KO.md) · [Documentation](README.md)

2026-11-15: Watch/widget **0.5.20 / build 46**, retaining Android **0.6.15-local / code 33**. Registration, identity and peer keys, and vehicle settings are retained. [Android APK](https://github.com/mhj604/FoldBridge/releases/download/connection-v0.5.19/FoldBridge-Local-0.6.15.apk).

## Execution-state correction (2026-11-15)

`active=false` means the app was not active. The accompanying `applicationState=1` is SDK `inactive`, not `background=2`, and does not prove passcode lock. Read background-success wording below as **authentication completed while inactive without a Watch app launch command**. It is not evidence of prolonged-lock or actual range-return completion.

## Additional missing paths

An application-refresh callback could return when a peripheral was physically connected without resuming a stalled discovery/authentication stage. Maintenance authentication repair also required uninterrupted runtime: each callback after suspension reset the reference time, so short intermittent opportunities might never reach the threshold.

Invalid-service filtering existed at characteristic callbacks but not the initial cached-service selection. Selecting an obsolete cached service could reject its callback without issuing a real discovery request. Out-of-range background tasks also remained open until expiry even when only a native pending connection remained.

These are source-level gaps, not an established single cause of every reported prolonged-lock or range-return failure.

## Changes

- A shared repair function runs on actual application-refresh and location/maintenance opportunities. It resumes service waits and renews discovery or unfinished authentication after 90 seconds without relevant progress, over the same physical link.
- The 90 seconds is neither a continuously running background timer nor a connection delay. Only actual execution opportunities evaluate it. Silence never cancels or reauthenticates a healthy authenticated link.
- Relevant discovery callbacks, authentication fragments and write responses update progress. Ninety uninterrupted seconds of app execution are no longer required.
- Bluetooth-alert tasks retain the nonce for an already-arriving response. Independent app-refresh opportunities repair stalled stages.
- Initial cached-service lookup excludes invalidated objects and falls through to real discovery.
- A background task with only a native pending connection/restored scan and no remaining frames or notification work completes without cancelling that native request. In-progress authentication/transfers remain pending.

New diagnostics: `executionOpportunityRepairs`, `nativeWaitTaskCompletions`. No background location-session startup, workout/audio session, server or iPhone relay was added.

## Actual records and deployment

At task start, phone 33 and Watch 45 were already authenticated with Watch `active=false`. Watch events showed 37 background service-wait attempts followed by service change, subscription and fast authentication without a Watch app launch command. This is not evidence of physical movement or prolonged passcode lock.

Build 46 state: Build and in-place installation succeeded. Without a Watch launch command, a new process reported build 46, `active=false`, `connected=true`, one completed fast authentication and zero errors/discarded fragments. Authentication measured 154ms, not total connection time. `executionOpportunityRepairs=0` and `nativeWaitTaskCompletions=0` do not demonstrate execution of the new recovery branches.

No separate QA scenarios, system logs, administrator password or real vehicle commands were used. Physical range departure/return was not performed. Installation success does not demonstrate an unexercised repair branch.

## Scope and limits

This repairs additional app recovery gaps. **Unconditional automatic connection after indefinite lock or every physical range return is not guaranteed.** Further app work requires OS execution opportunities and available budget. A preferred application-refresh time 30 minutes ahead is not an exact schedule. No API for overriding exhausted background budget was added.

[Apple background Bluetooth and budgets](https://developer.apple.com/documentation/watchkit/using-background-tasks) · [Complete background tasks when work finishes](https://developer.apple.com/documentation/watchkit/wkrefreshbackgroundtask/settaskcompleted()).

## Handoff

Phone **Settings → Stop connection** was selected directly. App state recorded `bridgeRunning=false`, `centralPresent=false`, `subscribed=false`, `authenticated=false` and stopped status. Registration, keys and vehicle settings were retained. Mac wireless debugging is also closed.

The existing once-weekly Mac renewal source is aligned with installed build 46's commit; renewal is not run now. Watch-only free automatic signing remains separate unfinished work.
