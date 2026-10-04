# DTlib Security Notes

DTlib is an abstraction layer, not a substitute for server-authoritative validation.

- Never trust client-provided item counts, money values, coordinates, permissions, reward IDs, or ownership.
- Check permissions on the server with ACE/group logic.
- Use `DT.Security.RateLimit` for network events that can produce rewards, purchases, database writes, or expensive operations.
- Inventory mutations should execute on the server.
- Discord bot tokens must only exist in server.cfg convars. Never send the token to NUI/client code.
- Avoid generic server events that accept arbitrary SQL, event names, item names, or export names from clients.
- DTlib callbacks do not automatically make callback data safe. Validate arguments in the registered callback.
