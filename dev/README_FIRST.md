# ⚠️ Warning

The contents of the `dev` folder, as the name implies, is intended for developers.

We highly discourage users from changing or deleting any of the files in this directory.

But if you think that there is something wrong with these configs, then you are highly encouraged to open and issue 
or a pull-request to suggest your changes!

# 🤝 qMRLab - BIDS conformance

As of release `v1.5.0`, [qMRI is covered by the BIDS specification](https://twitter.com/agahkarakuzu/status/1364306147474341891)!
Merging this `BEP001` took tens of people all around the world having countless meetings and discussions to decide how to organize
`inputs`, `outputs` and acquisition metadata (`protocols`) for a variety of qMRI applications.

You can read the `stable` BIDS release [here](https://bids-specification.readthedocs.io/en/stable/).

To benefit from BIDS, we introduced this folder in qMRLab release `v2.5.0`. The contents of this folder informs qMRLab 
about the relationship between units/metadata/conventions defined in BIDS specification and units/metadata/conventions of the methods 
qMRLab implements.

#### Contents of the `dev/bids_specification` folder 

These files are created based on what is established by BIDS for a BIDS release. 

- `anat.json`: Converted to json from the original [`anat.yml` schema](https://github.com/bids-standard/bids-specification/blob/master/src/schema/datatypes/anat.yaml).
- `fmap.json`: Converted to json from the original [`fmap.yml` schema](https://github.com/bids-standard/bids-specification/blob/master/src/schema/datatypes/fmap.yaml).
- `dwi.json`: Converted to json from the original [`dwi.yml` schema](https://github.com/bids-standard/bids-specification/blob/master/src/schema/datatypes/fmap.yaml).
- `qmrlab_BIDS_changelog.json` is to be updated when BIDS modules are upgraded w.r.t. a new BIDS release. 
- `units_BIDS_preferences.json` is the config qMRLab reads to override user unit settings to follow BIDS. See `getUserPreferences.m`. 

### Contents at the root of `dev/` folder 

> These files govern qMRLab<-->BIDS relationships
---
- `qmrlab_model_registry` MUST be updated when a new model is added. This file specifies the implementation-native units of `protocols`, `inputs` and `outputs`. Unit assignments MUST be made using units defined in `dev/units.json`. 
---
- `qmrlab_output_to_BIDS_mappings.json` 
    - Within the scope of the following unit families (as of 2021 April)...
        - Time
        - Rate
        - Fraction 
        - B1
        - B0
        - Susceptibility
        - Angle 
        - Diffusivity
        - Arbitrary
        - Categorical
        - Length 
        - Tensor
    - ... this file relates `outputNames` to units within each unit family:
        - `qMapNames`      ->  Description of the output, matching those in the comment header of each classdef
        - `suffixBIDS`     ->  BIDS or BIDS-like suffix associated with the output.
        - `isOfficialBIDS` ->  Defines whether the respective suffix is actually defined by the official specification. (Please use )
        - `folderBIDS`     ->  Describes to which subject subfolder does the respective output belong.
    - Note that `outputs`, `qMapNames`, `suffixBIDS`, `isOfficialBIDS` and `folderBIDS` are defined as an array. Thus, `output[i]` should correspond to `qMapNames[i]`, `suffixBIDS[i]`, `isOfficialBIDS[i]` and `folderBIDS[i]`.

- **Before adding a new unit Family, ensure that the new unit you'd loike to define does not fit in any of the existing families.**
- **Such changes must be addressed in `dev/units.json` as well.** 
---
-   `dev/units.json` describes the units recognized by qMRLab within the scope of the following `unit families` (as of 2021 April):
    - Time
    - Rate
    - Fraction 
    - B1
    - B0
    - Susceptibility
    - Angle 
    - Diffusivity
    - Arbitrary
    - Categorical
    - Length 
    - Tensor
- Each unit is defined by the following: 

```yml
        "minute": # Access name of the unit (fieldname). 
        {
            "factor2base": 60, # Defines by which factor the base unit (unit with "factor2base": 1) should be multiplied to achieve this unit. In this case, base unit of the Time family is seconds. Hence, factor2base of minute is 60.
            "label": "minute", # Display label
            "symbol": "(min)"  # Displat symbol
        }
```

- **Each `unit family` can have only one unit with `factor2base` of `1`.** 
- **Only `unit families` and `units` described in this `json ` file can be recognized by qMRLab.**


## 🧪 Units 

When reading/writing protocol/data in BIDS, units are sourced from: 
- `/dev/bids_preferences.json`
    - These unit configurations override their counterparts in `/usr/preferences.json` **when**:
        - `setenv('BIDS','1')` _command-line override_
        -  `ForAllUnitsUseBIDS` is set `true` in `/usr/preferences.json` _user self-override_
- `units.json`
    - Defines units and scaling factors for qMRLab 

When `modelRegistry('get','ModelName')` is called, output is a struct with two fields: 
- Registry: Returns the information for `ModelName` model defined in `qmrlab_model_registry.json` 
  ```yml
    ModelPath: # Method's namespace in qMRLab (e.g. T1Relaxometry for inversion_recovery) 
    Citation: # DOI link to the reference implementation article 
    InputDataUnits: # Implementation-native unit records for input DATA (e.g. relative B1maps are in decimal or percentage)
    InputProtUnits: # Implementation-native unit records for PROTOCOLS (e.g. inversion_recovery uses milliseconds, but vfa_t1 uses seconds for Time inputs)
    Outputs: # Implementation-native unit records for OUTPUTS (e.g. inversion_recovery outputs T1maps in ms, vfa_t1 in seconds)
   ```
- UnitBIDSMappings: A struct that informs which unit scalings are required for `ModelName` to comply with user/environment settings at the time it is called. It has three main fields: 
    - Outputs
    - Protocols
    - Inputs
- Each of these fields contain multiple structs, one per each `Output`, `Protocol` or `Input` entry of the model, as defined in `qmrlab_model_registry.json`. In each of these structs, the following fields are common: 
    ``` yml
    Family # Specifies to which unit family does the unit of the current element (e.g. Time --> Output.T1 for ModelName inversion_recovery) belong to. 
    ActiveUnit  # Specifies the unit requested by the user for the current element (e.g. seconds)
    ScaleFactor # Specifies the scaling factor between the implementation-native unit and the user req unit (e.g. 0.001 for inversion_recovery if user requested seconds, 1 if user requested milliseconds, 1000 if user requested microseconds etc.) The direction of the scaling (i.e. multiply or divide) is governed by the code.
    Symbol # Symbol of the ActiveUnit (e.g. (s) for second)
    Label # Display label name of the ActiveUnit (e.g. second for second, or relB1+ for relative_scaling_factor_decimal)
    ```
### 🗂 File organization and metadata


- `/dev/qmrlab_output_to_BIDS_mappings.json` 
    - Configurations for qMRLab to infer to which folder will the outputs be saved with which suffix. See `FitResultsSave_BIDS.m` for details.



# FAQ

JK, nothing is that frequently asked when it comes to open-source niche software development. I (agahkarakuzu@gmail.com) just want to clarify some issues below.

#### Why do we need this `dev/` folder, why not use `bids-matlab`?

We should definetely use [`bids-matlab`](https://github.com/bids-standard/bids-matlab), and we are using it to parse and query BIDS data. 

Nonetheless, `bids-matlab` does not tell us how to associate BIDS information with the qMRI methods implemented by qMRLab. That's what 
this folder (and scripts consuming its content) is responsible for.

#### Why use `json` files instead of implementing them in classes?

- Technical reason

On opening or switching methods, qMRLab GUI layout and content is determined based on the object properties assigned during construction. The
same goes for what we see in protocol settings in a `ModelName_batch.m` script generate by `qMRgenBatch`.

To reflect user's selection about how they'd like to configure their input/output/protocol units or read/write their data in CLI and GUI, we 
need to capture their choice during object construction. To do this, we need to associate object's properties with user settings. See the recursion there? 
Ther are solutions to call a different version of a constructor inside of its own, but it is not elegant. Besides, MATLAB is not that 'object oriented'. 
We are giving up on some of matlabs' OOF benefits to keep Octave compatibility, such as using Handles. 

Given that the metadata we need to build that relationship is not dynamic, we can register this information in a way that it reflects the method's 
class design. To do this in a human-readable, matlab-friendly and easy-to-change way is using `json` files. There are some practical benefits as well. 

- Practical reasons

    - To create (e.g. Python) mirrors of qMRLab by retaining the same API, having an interoperable registry is highly useful. 
    - Capture information for parsing documention pages without dealing with matlab types.
    - Keeping a good record of implementation details that are not neccesarily captured in classdefs. For example, not all the outputs a method can generate are captured by the `xnames` attribute. These configs give us an easy way to profile a method's all i/o relationsips with less coding.
    - Provides more comprehensive CI test. It is like two-factor-sanity-check while introducing a new model.

#### How qMRLab was dealing with units before v2.5.0?

There was not a systematic way to manage units before v2.5.0. We kept implementation i/o as they are. Since we have a global data standard to follow, 
(BIDS `v1.5.0+`) changes are in order.