We know how to:
- monitor nodes for nodedown and nodeup messages, with or without a reason
- if no communication is actively going on we get the net tick timeout as expected
- if active communication is going on, we get a nodedown sooner, usually
- turning off the wifi on one of the windows machines causes a connection_closed reason for the nodedown.
- we can launch a timer upon a nodedown for some period and have it trigger an action in the future
- we can use the nodeup message to cancel a timer that has not yet expired.
- we noticed some odd reconnection failures when we were using different versions of Erlang on the two machines (R15 and R16)
- compiling with R16 on both machines worked
- network interruptions can produce assymetrical behavior in terms of when each side notices the other is gone and when it comes back.
- some number of messages queue up and are delivered all at once when connection is restored.
- R15s behavior seems to be different from R16 in when events are noticed.

