import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("run_bot", Path(__file__).resolve().parents[1] / "tools/run_bot.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class ReportTests(unittest.TestCase):
    def report(self, **changes):
        result = dict(outcome="time_limit", survival_seconds=45, health=100,
                      save_directory="/profiles/SpellCast Survivors Bot/test", runtime_errors=[])
        result.update(changes)
        return result

    def test_ansi_errors_are_detected(self):
        log = "Normal output\n\x1b[1;31mERROR:\x1b[0m leaked resources\nSCRIPT ERROR: failed"
        self.assertEqual(runner.runtime_errors(log), ["ERROR: leaked resources", "SCRIPT ERROR: failed"])
        self.assertEqual(runner.runtime_errors("Normal output"), [])

    def test_incomplete_run_is_valid_but_not_victory(self):
        result = self.report()
        runner.validate_report(result)
        self.assertEqual(result["outcome"], "time_limit")

    def test_actual_victory_and_death(self):
        runner.validate_report(self.report(outcome="victory", survival_seconds=1200))
        runner.validate_report(self.report(outcome="death", health=0))

    def test_known_bad_reports_are_rejected(self):
        controls = [dict(outcome="victory"), dict(outcome="death"),
                    dict(save_directory="/profiles/SpellCast Survivors"),
                    dict(runtime_errors=["SCRIPT ERROR: failure"]),
                    dict(outcome="watchdog"), dict(outcome="unknown")]
        for control in controls:
            with self.subTest(control=control), self.assertRaises(ValueError):
                runner.validate_report(self.report(**control))


if __name__ == "__main__":
    unittest.main()
