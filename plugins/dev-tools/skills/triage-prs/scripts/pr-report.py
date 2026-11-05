#!/usr/bin/env python3
"""Collect the author's open pull requests and every signal that bears on
whether they can be merged, normalised across GitHub and Bitbucket.

Emits JSON on stdout. Collection only: this script decides nothing about
whether a pull request should be merged, it just gathers the evidence so the
caller does not have to remember which flag each CLI wants.
"""

import json
import re
import subprocess
import sys
from argparse import ArgumentParser


def run(args, check=False):
    result = subprocess.run(args, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} failed: {result.stderr.strip()}")
    return result


def run_json(args):
    result = run(args)
    if result.returncode != 0:
        return None, result.stderr.strip()
    try:
        return json.loads(result.stdout), None
    except json.JSONDecodeError as error:
        return None, f"could not parse output as JSON: {error}"


def detect_host():
    remote = run(["git", "remote", "get-url", "origin"]).stdout.strip()
    if "github.com" in remote:
        return "github", remote
    if "bitbucket" in remote:
        return "bitbucket", remote
    return None, remote


def current_repo_slug(remote):
    match = re.search(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?$", remote)
    return f"{match.group(1)}/{match.group(2)}" if match else None


def conflict_probe(target, source):
    """Ask git whether merging source into target would conflict.

    Bitbucket Cloud exposes no mergeability field, so the only honest answer
    comes from doing the merge locally. Requires both refs to be fetchable,
    which rules out pull requests in repositories other than this one.
    """
    fetch = run(["git", "fetch", "--quiet", "origin", target, source])
    if fetch.returncode != 0:
        return {"status": "unknown", "reason": "could not fetch both refs", "files": []}

    merge = run(["git", "merge-tree", "--write-tree", f"origin/{target}", f"origin/{source}"])
    if merge.returncode == 0:
        return {"status": "clean", "files": []}

    files = sorted(
        {
            line.split()[-1]
            for line in merge.stdout.splitlines()
            if line.startswith("CONFLICT") or "\t" in line
        }
    )
    return {"status": "conflicts", "files": files[:20]}


def behind_by(target, source):
    counts = run(["git", "rev-list", "--left-right", "--count", f"origin/{target}...origin/{source}"])
    if counts.returncode != 0:
        return None
    try:
        behind, _ahead = counts.stdout.split()
        return int(behind)
    except ValueError:
        return None


# --- Bitbucket -------------------------------------------------------------

BITBUCKET_CHECK_STATES = {
    "SUCCESSFUL": "green",
    "FAILED": "red",
    "STOPPED": "red",
    "INPROGRESS": "pending",
}


def bitbucket_prs(limit, remote):
    listing, error = run_json(["bkt", "pr", "list", "--mine", "--limit", str(limit), "--json"])
    if listing is None:
        return {"error": f"bkt pr list failed: {error}"}

    this_repo = listing.get("repo")
    workspace = listing.get("workspace")
    collected = []

    # --state is not honoured alongside --mine, so filter here rather than
    # trusting the flag and silently reporting merged work as outstanding.
    for pr in listing.get("pull_requests", []):
        if pr.get("state") != "OPEN":
            continue

        number = pr.get("id")
        repo = (pr.get("source", {}).get("repository", {}).get("full_name") or "").split("/")[-1]
        in_this_repo = repo == this_repo
        repo_args = [] if in_this_repo else ["--repo", repo]

        detail, _ = run_json(["bkt", "pr", "view", str(number), *repo_args, "--json"])
        detail = (detail or {}).get("pull_request", {})

        reviewers = [
            {"name": p["user"].get("display_name"), "approved": bool(p.get("approved"))}
            for p in detail.get("participants", [])
            if p.get("role") == "REVIEWER"
        ]
        approvals = [
            p["user"].get("display_name")
            for p in detail.get("participants", [])
            if p.get("approved")
        ]

        checks_payload, _ = run_json(["bkt", "pr", "checks", str(number), *repo_args, "--json"])
        checks = [
            {"name": s.get("name"), "state": s.get("state"), "url": s.get("url")}
            for s in (checks_payload or {}).get("statuses", [])
        ]
        states = {BITBUCKET_CHECK_STATES.get(c["state"], "pending") for c in checks}
        checks_state = (
            "none" if not checks
            else "red" if "red" in states
            else "pending" if "pending" in states
            else "green"
        )

        tasks_payload, _ = run_json(["bkt", "pr", "task", "list", str(number), *repo_args, "--json"])
        tasks = tasks_payload if isinstance(tasks_payload, list) else (tasks_payload or {}).get("tasks", [])
        open_tasks = [
            t.get("content", {}).get("raw") or t.get("text")
            for t in (tasks or [])
            if (t.get("state") or t.get("status") or "").upper() in {"UNRESOLVED", "OPEN", "INCOMPLETE"}
        ]

        source_branch = pr.get("source", {}).get("branch", {}).get("name")
        target_branch = pr.get("destination", {}).get("branch", {}).get("name")

        collected.append(
            {
                "host": "bitbucket",
                "owner": workspace,
                "number": number,
                "repo": f"{workspace}/{repo}" if repo else this_repo,
                "title": pr.get("title"),
                "url": pr.get("links", {}).get("html", {}).get("href"),
                "source": source_branch,
                "target": target_branch,
                "draft": bool(pr.get("draft")),
                "reviewers": reviewers,
                "awaiting": [r["name"] for r in reviewers if not r["approved"]],
                "approved_by": approvals,
                "checks": checks,
                "checks_state": checks_state,
                "open_tasks": [t for t in open_tasks if t],
                "conflicts": (
                    conflict_probe(target_branch, source_branch)
                    if in_this_repo
                    else {
                        "status": "unknown",
                        "reason": f"pull request is in {repo}, not the checked-out repository",
                        "files": [],
                    }
                ),
                "behind_by": behind_by(target_branch, source_branch) if in_this_repo else None,
                "enforces_approvals": None,
            }
        )

    return {"host": "bitbucket", "remote": remote, "prs": collected}


# --- GitHub ----------------------------------------------------------------

GITHUB_FIELDS = (
    "number,title,url,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,"
    "reviewDecision,reviewRequests,latestReviews,statusCheckRollup"
)


def github_prs(limit, remote):
    found, error = run_json(
        [
            "gh", "search", "prs", "--author=@me", "--state=open",
            "--limit", str(limit), "--json", "number,repository",
        ]
    )
    if found is None:
        return {"error": f"gh search prs failed: {error}"}

    collected = []
    for hit in found:
        repo = hit.get("repository", {}).get("nameWithOwner")
        number = hit.get("number")
        detail, detail_error = run_json(
            ["gh", "pr", "view", str(number), "--repo", repo, "--json", GITHUB_FIELDS]
        )
        if detail is None:
            collected.append(
                {
                    "host": "github",
                    "owner": (repo or "/").split("/")[0],
                    "number": number,
                    "repo": repo,
                    "error": detail_error,
                }
            )
            continue

        rollup = detail.get("statusCheckRollup") or []
        checks = [
            {
                "name": c.get("name") or c.get("context"),
                "state": c.get("conclusion") or c.get("state") or c.get("status"),
                "url": c.get("detailsUrl") or c.get("targetUrl"),
            }
            for c in rollup
        ]
        states = {(c["state"] or "").upper() for c in checks}
        checks_state = (
            "none" if not checks
            else "red" if states & {"FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED"}
            else "pending" if states & {"PENDING", "QUEUED", "IN_PROGRESS", "", "EXPECTED"}
            else "green"
        )

        reviewed = {
            r.get("author", {}).get("login"): r.get("state")
            for r in detail.get("latestReviews") or []
        }
        requested = [
            r.get("login") or r.get("name") or r.get("slug")
            for r in detail.get("reviewRequests") or []
        ]
        reviewers = [{"name": name, "approved": state == "APPROVED"} for name, state in reviewed.items()]
        reviewers += [{"name": name, "approved": False} for name in requested if name not in reviewed]

        merge_state = detail.get("mergeStateStatus")
        collected.append(
            {
                "host": "github",
                "owner": (repo or "/").split("/")[0],
                "number": number,
                "repo": repo,
                "title": detail.get("title"),
                "url": detail.get("url"),
                "source": detail.get("headRefName"),
                "target": detail.get("baseRefName"),
                "draft": bool(detail.get("isDraft")),
                "reviewers": reviewers,
                "awaiting": [r["name"] for r in reviewers if not r["approved"]],
                "approved_by": [name for name, state in reviewed.items() if state == "APPROVED"],
                "changes_requested_by": [
                    name for name, state in reviewed.items() if state == "CHANGES_REQUESTED"
                ],
                "checks": checks,
                "checks_state": checks_state,
                "open_tasks": [],
                "conflicts": {
                    "status": {"CONFLICTING": "conflicts", "MERGEABLE": "clean"}.get(
                        detail.get("mergeable"), "unknown"
                    ),
                    "files": [],
                },
                "behind_by": 1 if merge_state == "BEHIND" else 0 if merge_state else None,
                "review_decision": detail.get("reviewDecision"),
                "merge_state_status": merge_state,
                # BLOCKED with checks green and no review requested means a
                # branch protection rule the API will not name directly.
                # An empty reviewDecision means the repo requires no review,
                # which is different from not knowing whether it does.
                "enforces_approvals": bool(detail.get("reviewDecision")),
            }
        )

    return {"host": "github", "remote": remote, "prs": collected}


COLLECTORS = {"github": github_prs, "bitbucket": bitbucket_prs}


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=30)
    parser.add_argument(
        "--host",
        choices=["github", "bitbucket", "both"],
        help="default: both, so the caller can see every owner and ask which to report on",
    )
    parser.add_argument("--owner", help="only pull requests under this owner or workspace")
    args = parser.parse_args()

    detected, remote = detect_host()
    hosts = list(COLLECTORS) if (args.host or "both") == "both" else [args.host or detected]

    prs, warnings = [], []
    for host in hosts:
        if host not in COLLECTORS:
            warnings.append(f"could not tell which host serves {remote or 'this repository'}")
            continue
        result = COLLECTORS[host](args.limit, remote)
        if result.get("error"):
            # One unauthenticated CLI should not hide the other host's work.
            warnings.append(result["error"])
            continue
        prs.extend(result["prs"])

    if args.owner:
        prs = [pr for pr in prs if pr.get("owner") == args.owner]

    owners = sorted({pr["owner"] for pr in prs if pr.get("owner")})
    payload = {
        "remote": remote,
        "hosts": hosts,
        "owners": owners,
        "prs": prs,
        "warnings": warnings,
    }
    if not prs and warnings:
        payload["error"] = "; ".join(warnings)

    json.dump(payload, sys.stdout, indent=2, sort_keys=True)
    print()
    return 1 if payload.get("error") else 0


if __name__ == "__main__":
    sys.exit(main())
