# Known bugs in the options DSL — deliberately preserved

These are real defects. They are **not** being fixed, because each one determines
an `Model.options` **field name**, and those names are written into saved
`FitResults`. Renaming an option silently invalidates results a user saved months
ago: the file loads, the field is missing, and the failure appears far from the
change that caused it.

Each is pinned by a test, so a future tidy-up fails loudly instead of shipping.

See `docs/adr/0001-gui-migration.md` for the decision, and `parseButtons.m` for the
implementation that reproduces them.

---

## 1. The `###` / `***` prefixes strip two characters, not three

The DSL documents three-character markers: `###` disables a control, `***` hides
it. The generator tests and removes **two**:

```matlab
if strcmp(opts{2*ii-1}(1:2),'##')
   opts{2*ii-1} = opts{2*ii-1}(3:end);
```

So `'###Rician noise bias'` becomes `'#Rician noise bias'`, and `genvarname_v2`
maps a surviving `#` to `N`:

| declaration | option field |
|---|---|
| `'Rician noise bias'` | `Riciannoisebias` |
| `'###Rician noise bias'` | `NRiciannoisebias` |

**Toggling the prefix renames the option.** That matters because `dti.m:135-137`
toggles it at runtime, from `UpdateFields`:

```matlab
obj.buttons{strcmp(obj.buttons,'Rician noise bias') | ...
            strcmp(obj.buttons,'###Rician noise bias')} = '###Rician noise bias';
```

so a `dti` model that has been through `UpdateFields` stores the option under a
different name than one that has not.

Pinned by `tDSL/theDtiPrefixAsymmetryIsPreserved`.

## 2. `**` is tested against the string `##` left behind

The hide test runs on the already-stripped label, so the two prefixes do not
compose in the order a reader expects. No shipped model relies on combining them;
it is recorded because the parser reproduces it.

## 3. Three option names contain another option name

`getOptionsFieldName` resolves options by substring in places, so a name contained
in another can address the wrong option:

| model | contained | container |
|---|---|---|
| `qmt_spgr` | `R1fT2f` | `FixR1fT2f` |
| `qsm_sb` | `LambdaL1` | `ReOptimizeLambdaL1` |
| `qsm_sb` | `LambdaL2` | `ReOptimizeLambdaL2` |

Pre-existing, and unfixable without renaming an option — see above.

`tDSL/noFieldNameIsAProperSubstringOfAnother` asserts this set has not **grown**,
and also that none of the three has **vanished** (which would mean someone renamed
an option). It deliberately does not assert the set is empty: a permanently red
test teaches people to ignore it, and the only way to make it green would be to
break data compatibility.

---

## Not in this file

Numeric sentinels in the fitting Start column — `'R1MAP'`, `'R1f'`,
`'(R1f*T2f)/R1f'` in `qmt_spgr` and `qmt_sirfse` — are **not** bugs. They are
load-bearing modelling values that happen to travel through the DSL. Changing them
would be a modelling change disguised as a GUI change.
