# Installation

`MicroPythonMCU` runs on **64-bit Windows** with [OpenModelica](https://openmodelica.org/download/download-windows/) (OMEdit, tested with version 1.27.1). The Python runtime ships with the library and the C compiler is OpenModelica's own: nothing else to install, apart from the *Microsoft Visual C++ Redistributable*, which is almost always already present.

## Choosing a version

Each version of the library is a **tag** of the repository, of the form `vX.Y.Z` (for example `v0.1.0`). The list of versions is on the [tags page](https://gitlab.com/bdelaup/modelica_micropython3/-/tags). Take the most recent one unless you have a reason not to.

## Downloading a version

1. On the [tags page](https://gitlab.com/bdelaup/modelica_micropython3/-/tags), click the download button (arrow) of the version you want, then **zip**. Direct address, for `v0.1.0`:

    ```
    https://gitlab.com/bdelaup/modelica_micropython3/-/archive/v0.1.0/modelica_micropython3-v0.1.0.zip
    ```

    With git: `git clone --branch v0.1.0 https://gitlab.com/bdelaup/modelica_micropython3.git`

2. Unzip it, preferably outside a synchronised folder such as OneDrive. It contains the `MicroPythonMCU` folder, which is the library itself (it holds `package.mo`).

## Load or install

There is no need to install the library: **loading** it in OMEdit is enough. Three ways, from the lightest to the most lasting.

### Load the library, without installing anything

In OMEdit, *File → Open Model/Library File(s)…*, then select `MicroPythonMCU/package.mo`. The library appears in the browser for the session: to be repeated each time OMEdit starts. In a script: `loadFile("C:/path/to/MicroPythonMCU/package.mo");`.

This is the recommended way to try a version, or to work on a shared computer: nothing is copied outside the downloaded folder, and several versions can live side by side in different folders.

### Load it automatically at each start

To avoid reopening the file each time, still without installing: *Tools → Options → Libraries*, *User Libraries* section, add the path of `MicroPythonMCU/package.mo`. OMEdit then loads it at every start, from the downloaded folder.

### Install it as a system library

The library then joins OpenModelica's libraries and is loaded on demand:

1. Close OMEdit.
2. Copy the `MicroPythonMCU` folder into the user's OpenModelica library folder:

    ```
    %APPDATA%\.openmodelica\libraries\
    ```

3. Reopen OMEdit, then *File → System Libraries → MicroPythonMCU*. In a script: `loadModel(MicroPythonMCU);`.

To switch versions, replace this folder with the one from another version.

## Checking

Open `MicroPythonMCU.Examples.BasicBlink` and simulate it: `GP0` blinks (see [Getting started](premiers-pas.md)).

**The first simulation of a model takes longer** (from one to a few tens of seconds more): OpenModelica compiles the library's C runtime with its own compiler, from the supplied sources. This is normal, and it is what makes any recent OpenModelica version usable.

## Coming soon: installation through the library manager

Registration of the library in OpenModelica's package index is under way. Once done, nothing will need downloading: in OMEdit, *File → Manage Libraries → Install Library*, or in a script `installPackage(MicroPythonMCU);`. Each tag will become an installable version.

## Development version

To try the current state between two versions: clone the [repository](https://gitlab.com/bdelaup/modelica_micropython3) without specifying a tag, or download it (*Code → zip*), then proceed as above.
