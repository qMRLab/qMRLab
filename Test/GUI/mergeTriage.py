#!/usr/bin/env python3
"""Merge sharded geomAudit results into one report.

`runBranchTriage` writes `results_<model>.json` per invocation. One MATLAB process
per model is the only reliable isolation (see STAGE_A_FINDINGS.md -- cached browser
objects survive figure teardown and poison the next in-process launch), so the run is
sharded and merged here.

Usage:  python3 Test/GUI/mergeTriage.py <triage-dir>
"""
import json
import pathlib
import sys
from collections import Counter


def load(d: pathlib.Path):
    rows = []
    for f in sorted(d.glob("results_*.json")):
        payload = json.loads(f.read_text())
        # jsonencode emits a bare object for a 1x1 struct, an array otherwise
        rows.extend(payload if isinstance(payload, list) else [payload])
    return rows


def defects_of(row):
    d = row.get("Defects") or []
    return d if isinstance(d, list) else [d]


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2

    d = pathlib.Path(argv[1])
    rows = load(d)
    if not rows:
        print(f"no results_*.json under {d}")
        return 1

    total = sum(len(defects_of(r)) for r in rows)
    status = Counter(r["Status"] for r in rows)
    affected = sorted({r["Model"] for r in rows if r["Status"] != "ok"})
    kinds = Counter(x["Kind"] for r in rows for x in defects_of(r))

    out = [
        "# qMRLab GUI geometric triage (merged)",
        "",
        f"- Shards: {len(rows)} model/window rows",
        f"- Captures: {len(list(d.glob('*.png')))} PNG",
        f"- Status: " + ", ".join(f"{v} {k}" for k, v in sorted(status.items())),
        f"- Defects: {total}" + (f" ({', '.join(f'{v} {k}' for k, v in kinds.most_common())})" if kinds else ""),
        f"- Models not clean: {len(affected)}" + (f" -- {', '.join(affected)}" if affected else ""),
        "",
        "## Summary",
        "",
        "| Model | Window | Status | Defects |",
        "|---|---|---|---|",
    ]
    for r in sorted(rows, key=lambda r: (r["Model"], r["Window"])):
        out.append(f'| {r["Model"]} | {r["Window"]} | {r["Status"]} | {len(defects_of(r))} |')

    out += ["", "## Detail", ""]
    for r in sorted(rows, key=lambda r: (r["Model"], r["Window"])):
        ds, err = defects_of(r), r.get("Error", "")
        if not ds and not err:
            continue
        out.append(f'### {r["Model"]} / {r["Window"]}')
        out.append("")
        if err:
            out += ["```", f"ERROR: {err}", "```", ""]
        for x in ds:
            out.append(f'- **{x["Kind"]}** `{x.get("Tag","")}` — {x["Detail"]}')
            out.append(f'  - `{x["Path"]}`')
        out.append("")

    report = d / "branch_triage_merged.md"
    report.write_text("\n".join(out) + "\n")
    print(f"{total} defects across {len(affected)} affected models -> {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
