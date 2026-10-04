# 1.3.0-beta.1 validation

Run `python -m pip install lupa`, then `python tests/test_contracts.py`.

Checks compile Lua 5.4 source (normalizing Cfx hash literals only inside the test compiler), load both manifest sides with Cfx stubs, initialize 219 provider/side combinations, and exercise export/event argument mapping and UI/gameplay behavior.

113 Lua files compile; 81 client and 47 server/shared manifest scripts load; all 219 provider/side initialization cases pass.

Covered behavior: Lation alert/input/step progress/list menus; okok notify/text UI/fuel/keys/banking; inventory slot/metadata ordering; native skill leveling; shop session/stock validation and failed-delivery refund; explicit provider selection; unsupported operation discovery; native menu cancellation/nested opening; and absence of the imported source pack or iframe.

These are static and simulated contract checks. They do not execute vendor resources or a live FiveM server. Purchased vendor versions, legacy database schemas, clothing persistence, dispatch delivery and in-game UI remain to be tested on the target server.
