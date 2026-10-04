# Provider support matrix

| Category / DT.Ecosystem namespace | Provider resources |
| --- | --- |
| framework / Framework | `qbx_core`, `qb-core`, `es_extended` |
| inventory / Inventory | `ox_inventory`, `qb-inventory`, `qs-inventory`, `codem-inventory`, `core_inventory`, `jpr-inventory`, `one_inventory`, `origen_inventory`, `ps-inventory`, `tgiann-inventory` |
| target / Target | `ox_target`, `qb-target`, `sleepless_interact` |
| notify / Notify | `lation_ui`, `ox_lib`, `okokNotify`, `brutal_notify`, `FL-Notify`, `msk_core`, `mythic_notify`, `pNotify`, `r_notify`, `solaire_notify`, `t-notify`, `wasabi_notify`, `ZSX_UIV2` |
| helptext / HelpText | `lation_ui`, `ox_lib`, `okokTextUI`, `cd_drawtextui`, `jg-textui`, `lab-HintUI`, `ZSX_UIV2` |
| progressbar / ProgressBar | `lation_ui`, `ox_lib`, `progressbar`, `keep-progressbar`, `msk_core`, `wasabi_uikit`, `ZSX_UIV2` |
| menu / Menu | `lation_ui`, `ox_lib`, `qb-menu`, `wasabi_uikit` |
| input / Input | `lation_ui`, `ox_lib`, `qb-input` |
| weather / Weather | `Renewed-Weathersync`, `qb-weathersync`, `cd_easytime` |
| fuel / Fuel | `okokGasStation`, `ox_fuel`, `LegacyFuel`, `BigDaddy-Fuel`, `cdn-fuel`, `esx-sna-fuel`, `lc_fuel`, `ps-fuel`, `qb-fuel`, `qs-fuelstations`, `Renewed-Fuel`, `ti_fuel`, `x-fuel` |
| vehiclekey / VehicleKey | `okokGarage`, `qbx_vehiclekeys`, `qb-vehiclekeys`, `cd_garage`, `F_RealCarKeysSystem`, `jaksams_VehiclesKeys`, `mk_vehiclekeys`, `MrNewbVehicleKeys`, `mVehicle`, `qs-vehiclekeys`, `Renewed-Vehiclekeys`, `t1ger_keys`, `wasabi_carlock` |
| banking / Banking | `okokBanking`, `Renewed-Banking`, `qb-banking`, `DHS-BankingSim`, `fd_banking`, `kartik-banking`, `tgg-banking`, `tgiann-bank`, `wasabi_banking` |
| phone / Phone | `okokPhone`, `lb-phone`, `qb-phone`, `gksphone`, `qs-smartphone`, `yseries` |
| doorlock / Doorlock | `doors_creator`, `ox_doorlock`, `qb-doorlock`, `rcore_doorlock` |
| dispatch / Dispatch | `bub-mdt`, `cd_dispatch`, `emergencydispatch`, `fd_dispatch`, `kartik-mdt`, `lb-tablet`, `linden_outlawalert`, `origen_police`, `piotreq_gpt`, `ps-dispatch`, `qs-dispatch`, `redutzu-mdt`, `tk_dispatch`, `wasabi_mdt` |
| clothing / Clothing | `illenium-appearance`, `fivem-appearance`, `rcore_clothing`, `qb-clothing`, `esx_skin` |
| housing / Housing | `bcs-housing`, `esx_property`, `ps-housing`, `qb-appartments`, `qb-houses` |
| shops / Shops | `native` |
| skills / Skills | `evolent_skills`, `OT_skills`, `pickle_xp` |
| bossmenu / BossMenu | `esx_society`, `qb-management`, `qbx_management`, `tk_bosstablet`, `zat-bossmenu` |
| zones / Zones | `ox_lib`, `PolyZone` |
| dialogue / Dialogue | `native` |

Provider profile names and actual resource names can differ in case or spelling.
Use `ECOSYSTEM_PROVIDERS.json` for exact names, client/server availability and
method lists (`clientMethods` / `serverMethods`). Native defaults and utility modules are documented in `ECOSYSTEM.md`.
The matrix describes adapter coverage, not access to the actual third-party resources.
