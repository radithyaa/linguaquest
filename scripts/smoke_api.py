#!/usr/bin/env python3
"""Smoke test end-to-end LinguaQuest API (server harus sudah berjalan).

Pemakaian: BASE=http://127.0.0.1:8090/v1 python3 scripts/smoke_api.py
"""

import json
import os
import sys
import urllib.error
import urllib.request
import uuid

BASE = os.environ.get("BASE", "http://127.0.0.1:8090/v1")


def call(method, path, body=None, token=None, expect_error=False):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(BASE + path, data=data, method=method)
    request.add_header("content-type", "application/json")
    if token:
        request.add_header("authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, json.loads(response.read() or b"null")
    except urllib.error.HTTPError as error:
        payload = json.loads(error.read() or b"null")
        if expect_error:
            return error.code, payload
        raise SystemExit(f"GAGAL {method} {path}: {error.code} {payload}")


def answer_for(exercise):
    kind = exercise["kind"]
    if kind == "multiple_choice":
        return exercise["options"][0]
    if kind == "word_bank":
        return " ".join(exercise["wordBank"][:3])
    if kind == "pair_matching":
        return "|".join(f"{p['left']}={p['right']}" for p in exercise["pairs"])
    if kind == "fill_in_the_blank":
        return "are"
    if kind == "speech":
        return exercise["prompt"]
    return "jawaban salah total"


def main():
    status, health = call("GET", "/health")
    print(f"health          : {status} db={health['database']} redis={health['redis']}")

    status, auth = call(
        "POST",
        "/auth/login",
        {"email": "demo@linguaquest.app", "password": "demo12345"},
    )
    token = auth["accessToken"]
    print(f"login demo      : {status} user={auth['user']['displayName']}")

    _, courses = call("GET", "/courses", token=token)
    course_id = courses[0]["id"]
    _, curriculum = call("GET", f"/courses/{course_id}/curriculum", token=token)
    first_unit = curriculum["units"][0]
    node = first_unit["nodes"][0]
    print(f"curriculum      : {len(curriculum['units'])} unit, node0={node['title']} status={node['status']}")

    _, start = call("POST", "/sessions/start", {"nodeId": node["id"]}, token=token)
    print(f"session start   : {len(start['exercises'])} soal, hearts={start['hearts']}")

    answers = [
        {
            "exerciseId": exercise["id"],
            "answer": answer_for(exercise),
            "durationMs": 1200,
        }
        for exercise in start["exercises"]
    ]
    op_id = str(uuid.uuid4())
    body = {
        "sessionId": start["sessionId"],
        "clientOpId": op_id,
        "nodeId": node["id"],
        "startedAt": "2026-11-05T00:00:00Z",
        "durationMs": 42000,
        "answers": answers,
    }
    _, summary = call("POST", "/sessions/complete", body, token=token)
    print(
        "session done    : "
        f"xp={summary['xpEarned']} akurasi={summary['accuracy']:.2f} "
        f"combo={summary['maxCombo']} hearts={summary['stats']['hearts']}"
    )

    status, problem = call("POST", "/sessions/complete", body, token=token, expect_error=True)
    print(f"idempotensi     : {status} {problem['code']}")

    _, profile = call("GET", "/me", token=token)
    print(
        "profile         : "
        f"xp={profile['stats']['totalXp']} streak={profile['stats']['streak']} "
        f"gems={profile['stats']['gems']} lencana={len(profile['achievements'])}"
    )

    _, practice = call("GET", "/practice", token=token)
    if practice["dueNow"]:
        card = practice["dueNow"][0]
        _, review = call(
            "POST",
            "/practice/review",
            {"cardId": card["id"], "rating": 3},
            token=token,
        )
        print(
            "fsrs review     : "
            f"'{card['word']}' reps={review['card']['reps']} "
            f"interval={review['card']['intervalDays']:.1f} hari"
        )
    print(f"mistakes        : {len(practice['mistakes'])} kesalahan tercatat")

    _, quests = call("GET", "/quests", token=token)
    print("quests          : " + ", ".join(f"{q['code']}={q['progress']}/{q['target']}" for q in quests["daily"]))
    claimable = [q for q in quests["daily"] if q["completed"] and not q["claimed"]]
    if claimable:
        _, claim = call("POST", f"/quests/{claimable[0]['code']}/claim", token=token)
        print(f"quest claim     : {claimable[0]['code']} +{claim['gemsAwarded']} gems")
    else:
        _, problem = call("POST", "/quests/lessons_2/claim", token=token, expect_error=True)
        print(f"quest claim     : {problem['code']} (belum memenuhi target, sesuai aturan)")

    _, league = call("GET", "/league", token=token)
    print(f"league          : tier={league['tier']} rank={league['currentUserRank']} peserta={len(league['entries'])}")

    _, catalog = call("GET", "/shop/catalog", token=token)
    print("shop catalog    : " + ", ".join(f"{i['sku']}={i['priceGems']}" for i in catalog))
    _, buy = call("POST", "/shop/buy", {"sku": "heart_refill"}, token=token)
    print(f"shop buy        : {buy['message']} gems tersisa={buy['stats']['gems']}")

    _, synced = call(
        "POST",
        "/sync",
        {"sessions": [], "reviews": [], "purchases": []},
        token=token,
    )
    print(f"sync            : applied={len(synced['appliedOps'])} rejected={len(synced['rejectedOps'])}")

    status, problem = call(
        "POST",
        "/auth/login",
        {"email": "x@y.z", "password": "salah"},
        expect_error=True,
    )
    print(f"error RFC 9457  : {status} {problem['code']} — {problem['title']}")

    print("\nSEMUA ALUR API OK")


if __name__ == "__main__":
    sys.exit(main())
