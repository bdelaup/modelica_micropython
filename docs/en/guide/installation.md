# Installation

`MicroPythonMCU` runs on **64-bit Windows** with [OpenModelica](https://openmodelica.org/download/download-windows/) (OMEdit). The Python runtime ships with the library: nothing else to install, apart from the *Microsoft Visual C++ Redistributable*, which is almost always already present.

## Choosing an archive

Each version is published on the [releases page](https://gitlab.com/bdelaup/modelica_micropython3/-/releases) with three archives:

| Archive | Contents | For whom |
|---|---|---|
| `MicroPythonMCU-<version>-lib-om<OM>-win64.zip` | The library, ready to install, with a precompiled runtime | **Students and teachers: this is the one** |
| `MicroPythonMCU-<version>-om<OM>-win64.zip` | The same, with the verification suite (`Resources/Verification`) | Checking an installation, advanced users |
| `MicroPythonMCU-<version>-src.zip` | The package with its C sources, compiled at each simulation | Modifying the library, or using another OpenModelica version |

`<OM>` is the OpenModelica version the runtime was compiled with (for example `1.27.1`). Both precompiled archives require **that** OpenModelica version. With another version, take the source archive: omc then recompiles the runtime with its own toolchain.

## Installing the library (`-lib` archive)

1. Close OMEdit.
2. Unzip the archive into the user's OpenModelica library folder:

    ```
    %APPDATA%\.openmodelica\libraries\
    ```

    A `MicroPythonMCU <version>` folder must appear there (for example `MicroPythonMCU 1.0.0`), directly containing `package.mo`.
3. Reopen OMEdit, then *File → System Libraries → MicroPythonMCU*. In a script: `loadModel(MicroPythonMCU);`.
4. Check: open `MicroPythonMCU.Examples.BasicBlink` and simulate it. `GP0` blinks (see [Getting started](premiers-pas.md)).

Several versions can live side by side in this folder. A model that declares `uses(MicroPythonMCU(version = "1.0.0"))` (OMEdit adds it by itself when the library is used) loads the version it asks for.

## Using the other archives

Unzip the archive anywhere (preferably outside a synchronised folder such as OneDrive), then in OMEdit: *File → Open Model/Library File(s)…* and select `MicroPythonMCU/package.mo`.

The verification suite of the compiled archive is run as described in the (French) [verification suite page](https://bdelaup.gitlab.io/modelica_micropython3/fr/interne/tests/).

## Development version

To try the current state between two releases: clone or download the [repository](https://gitlab.com/bdelaup/modelica_micropython3) (*Code → Download source code → zip*) and open `MicroPythonMCU/package.mo` in OMEdit, as for the source archive.
