# DTlib v1.2.0

Modular FiveM library for DT ecosystem resources, with Lation UI, okok and embedded community adapters.

## Download and install

[Download the complete source package](DTlib_v1.2.0_LATION_OKOK_COMMUNITY_ECOSYSTEM.zip). The ZIP contains the full DTlib resource, documentation, configuration, source and license notices.

Extract the `DTlib` folder into your server resources. Start the chosen provider resources before DTlib, then restart DTlib and its consuming DT resources. Consumers use `@DTlib/init.lua` and `dependency 'DTlib'`.

Includes Lation alert, notifications, text UI, progress steps, input, menu and list menu; okok ecosystem adapters; and 22 ecosystem categories covering 153 provider directories. Actual provider resources must be installed separately. No community_bridge runtime dependency is required.

Documentation is included under `DTlib/docs/` inside the package. Mock runtime and syntax validation passed; live FiveM testing is still required.

The combined source distribution is under GPL-3.0. See `COPYING` and the bundled third-party notices.
