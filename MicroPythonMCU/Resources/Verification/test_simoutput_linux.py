"""Exercise Linux simulation output interval discovery without OpenModelica."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


if not sys.platform.startswith("linux"):
    raise SystemExit("This test requires Linux and /proc/self.")

include = Path(__file__).resolve().parents[1] / "Include"
with tempfile.TemporaryDirectory(prefix="simoutput-test-") as directory:
    root = Path(directory)
    source = root / "probe.c"
    executable = root / "probe"
    source.write_text(
        '#include "simoutput.c"\n'
        'int main(void) { printf("%.12g\\n", sim_output_interval()); return 0; }\n',
        encoding="utf-8",
    )
    subprocess.run(
        [os.environ.get("CC", "cc"), "-Wall", "-Wextra", "-I", str(include),
         str(source), "-o", str(executable)],
        check=True,
    )

    def check(expected, *args):
        result = subprocess.run(
            [str(executable), *args], cwd=root, check=True,
            capture_output=True, text=True,
        )
        actual = float(result.stdout.strip())
        if abs(actual - expected) > 1e-12:
            raise AssertionError(f"{args}: expected {expected}, got {actual}")

    def init_file(path, step):
        path.write_text(f'<DefaultExperiment stepSize="{step}"/>', encoding="utf-8")

    check(-1)
    init_file(root / "probe_init.xml", "0.001")
    check(0.001)
    check(0.0000025, "-override=stepSize=2.5e-6")
    check(0.0000025, "", "-override=stepSize=2.5e-6")
    check(0.0004, "-override", "startTime=0,stopTime=0.04,numberOfIntervals=100")
    override = root / "override settings.txt"
    override.write_text("stepSize=0.003\n", encoding="utf-8")
    check(0.003, f"-overrideFile={override}")
    check(0.003, "-overrideFile", str(override))
    check(0.0000025, "-override=stepSize=2.5e-6", f"-overrideFile={override}")
    custom = root / "custom init.xml"
    init_file(custom, "0.004")
    check(0.004, "-f", str(custom))
    check(0.004, f"-f={custom}")
    check(0.0000025, f"-f={custom}", "-override=stepSize=2.5e-6")
    inputs = root / "input path"
    inputs.mkdir()
    init_file(inputs / "probe_init.xml", "0.005")
    check(0.005, f"-inputPath={inputs}")
    check(0.005, "-inputPath", str(inputs))
    check(0.001, f"-inputPath={root / 'missing'}")
    print("PASS: Linux simulation output interval")
