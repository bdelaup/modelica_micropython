"""Verify the Linux test runner with isolated mock simulations."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


RUNNER = Path(__file__).with_name("run_tests.sh")


def main():
    with tempfile.TemporaryDirectory(prefix="mcu_runner_test_") as temp:
        root = Path(temp)
        shutil.copy(RUNNER, root / "run_tests.sh")
        (root / "verify_test.mos").write_text(
            'simulate(M, fileNamePrefix = "Mock");\n', encoding="utf-8"
        )
        protected = root / "Mock_user"
        protected.mkdir()
        (protected / "data").write_text("keep", encoding="utf-8")
        omc = root / "omc"
        env = dict(os.environ, PATH=str(root) + os.pathsep + os.environ["PATH"])
        command = ["bash", str(root / "run_tests.sh"), "verify_test.mos"]

        def fake_omc(source):
            omc.write_text("#!/bin/bash\n" + source, encoding="utf-8")
            omc.chmod(0o755)

        fake_omc("echo PASS\n")
        (root / "Mock.c").write_text("generated", encoding="utf-8")
        result = subprocess.run(
            command, cwd=root, env=env, capture_output=True, text=True, timeout=20
        )
        assert result.returncode == 0 and "1/1 PASS" in result.stdout, result.stdout
        assert not (root / "Mock.c").exists() and (protected / "data").exists()

        fake_omc("echo PASS\necho FAIL\n")
        result = subprocess.run(
            command, cwd=root, env=env, capture_output=True, text=True, timeout=20
        )
        assert result.returncode == 1 and "FAIL" in result.stdout, result.stdout

        fake_omc("sleep 60 &\necho $! > child.pid\nwait\n")
        runner = subprocess.Popen(
            command, cwd=root, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        try:
            pid_file = root / "child.pid"
            deadline = time.monotonic() + 10
            while not pid_file.exists() and time.monotonic() < deadline:
                time.sleep(0.1)
            assert pid_file.exists(), "mock simulation did not start"
            child = int(pid_file.read_text(encoding="utf-8"))
            runner.terminate()
            stdout, stderr = runner.communicate(timeout=10)
            assert runner.returncode == 130, (runner.returncode, stdout, stderr)
            stat = Path("/proc") / str(child) / "stat"
            deadline = time.monotonic() + 2
            while stat.exists() and time.monotonic() < deadline:
                try:
                    if stat.read_text(encoding="utf-8").split()[2] == "Z":
                        break
                except FileNotFoundError:
                    break
                time.sleep(0.05)
            else:
                assert not stat.exists(), ("simulation child still running", child)
        finally:
            if runner.poll() is None:
                runner.kill()
                runner.wait()

        verify_dir = root / "MicroPythonMCU" / "Resources" / "Verification"
        verify_dir.mkdir(parents=True)
        shutil.copy(RUNNER, verify_dir / "run_tests.sh")
        (verify_dir / "run_tests.sh").chmod(0o644)
        shutil.copy(root / "verify_test.mos", verify_dir / "verify_test.mos")
        git = root / "git"
        git.write_text(
            "#!/bin/bash\n"
            "case \"$1 $2\" in\n"
            "  'rev-parse --show-toplevel') printf '%s\\n' \"$MOCK_ROOT\" ;;\n"
            "  'rev-parse --short') echo mock ;;\n"
            "  'ls-files -c') printf '%s\\0' "
            "MicroPythonMCU/Resources/Verification/run_tests.sh "
            "MicroPythonMCU/Resources/Verification/verify_test.mos ;;\n"
            "  'ls-files -o'|'diff --quiet') ;;\n"
            "  *) exit 1 ;;\n"
            "esac\n",
            encoding="utf-8",
        )
        git.chmod(0o755)
        fake_omc("echo PASS\n")
        env["MOCK_ROOT"] = str(root)
        result = subprocess.run(
            ["bash", str(verify_dir / "run_tests.sh"), "--copy", "verify_test.mos"],
            cwd=verify_dir, env=env, capture_output=True, text=True, timeout=20,
        )
        assert result.returncode == 0 and "1/1 PASS" in result.stdout, (
            result.stdout, result.stderr
        )

    print("PASS: runner status, safe cleanup, interruption and non-executable copy")


if __name__ == "__main__":
    main()
