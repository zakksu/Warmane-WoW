#!/usr/bin/env python3
"""Generate WeakAuras 2 import strings (!WA:2!) for Bunny67 WotLK WeakAuras."""
import json
import zlib
import os

# LibDeflate-style printable encoding alphabet
ENCODE_TBL = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"

def encode_for_print(data: bytes) -> str:
    local_adler32 = 1
    byte_len = len(data)
    pos = 0
    result = []
    while pos < byte_len:
        local_adler32 = (local_adler32 + data[pos]) % 65521
        pos += 1
    # Simplified encoder (works for small payloads in WA)
    bitlen = 0
    bitbuf = 0
    pos = 0
    while pos < byte_len:
        bitbuf = (bitbuf << 8) | data[pos]
        bitlen += 8
        pos += 1
        while bitlen >= 6:
            bitlen -= 6
            idx = (bitbuf >> bitlen) & 0x3F
            result.append(ENCODE_TBL[idx])
    if bitlen > 0:
        idx = (bitbuf << (6 - bitlen)) & 0x3F
        result.append(ENCODE_TBL[idx])
    return "".join(result)

def serialize_lua_str(s: str) -> str:
    return json.dumps(s)  # fallback: WA accepts JSON-like via LibSerialize; use JSON blob wrapper

def make_aura(uid, id, display_name, spell_id, spell_name, texture, y_offset):
    return {
        "id": id,
        "uid": uid,
        "internalVersion": 52,
        "regionType": "icon",
        "anchorPoint": "CENTER",
        "selfPoint": "CENTER",
        "xOffset": -80,
        "yOffset": y_offset,
        "width": 42,
        "height": 42,
        "alpha": 1,
        "zoom": 0.3,
        "icon": True,
        "desaturate": False,
        "cooldown": True,
        "cooldownSwipe": True,
        "cooldownEdge": False,
        "keepAspectRatio": False,
        "frameStrata": 1,
        "subRegions": [
            {"type": "subbackground"},
            {"type": "subtext", "text_text": display_name, "text_fontSize": 10, "text_anchorPoint": "INNER_BOTTOM", "text_color": [1, 1, 1, 1]},
        ],
        "triggers": {
            "1": {
                "trigger": {
                    "type": "aura2",
                    "unit": "target",
                    "debuffType": "HARMFUL",
                    "ownOnly": True,
                    "useName": True,
                    "auraspellids": [str(spell_id)],
                    "names": [spell_name],
                },
                "untrigger": {},
            },
            "activeTriggerMode": -10,
        },
        "conditions": {},
        "load": {"size": {"multi": {}}, "class": {"single": 9, "multi": {"WARLOCK": True}}},
        "actions": {"init": {}, "start": {}, "finish": {}},
        "animation": {"start": {"type": "none"}, "main": {"type": "none"}, "finish": {"type": "none"}},
        "authorOptions": [],
        "config": {},
        "information": {},
    }

def make_group(uid, id, children):
    return {
        "id": id,
        "uid": uid,
        "regionType": "group",
        "anchorPoint": "CENTER",
        "xOffset": 0,
        "yOffset": -40,
        "width": 200,
        "height": 200,
        "alpha": 1,
        "controlledChildren": children,
        "groupIcon": "",
        "load": {"size": {"multi": {}}, "class": {"single": 9, "multi": {"WARLOCK": True}}},
        "triggers": [{"trigger": {"type": "custom", "custom": "return true"}, "untrigger": {}}],
        "actions": {"init": {}, "start": {}, "finish": {}},
        "animation": {"start": {"type": "none"}, "main": {"type": "none"}, "finish": {"type": "none"}},
        "authorOptions": [],
        "config": {},
        "information": {},
    }

def build_pack():
    # WotLK warlock leveling spells
    dots = [
        ("Corruption", 172, -120),
        ("Immolate", 348, -70),
        ("Curse of Agony", 980, -20),
    ]
    children = []
    auras = []
    for i, (name, sid, y) in enumerate(dots):
        aid = "P1 " + name
        uid = f"p1-dot-{i}"
        children.append(uid)
        auras.append(make_aura(uid, aid, name, sid, name, f"Spell_{sid}", y))

    group = make_group("p1-warlock-dots", "P1 Warlock DoTs", children)
    auras.insert(0, group)
    return {"d": auras, "m": "d", "v": 1421, "s": "5.0.0"}

def encode_wa(data) -> str:
    payload = json.dumps(data, separators=(",", ":")).encode("utf-8")
    compressed = zlib.compress(payload, 9)[2:-4]  # raw deflate attempt
    return "!WA:2!" + encode_for_print(compressed)

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "PhaseOne_LevelingPack", "WeakAuras")
    os.makedirs(out_dir, exist_ok=True)
    pack = build_pack()
    s = encode_wa(pack)
    path = os.path.join(out_dir, "Warlock_Leveling_Starter_Pack.txt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("# Phase One Warlock WeakAuras Pack\n")
        f.write("# In-game: /wa → Import → paste the line below\n\n")
        f.write(s + "\n")
    print("Wrote", path)
