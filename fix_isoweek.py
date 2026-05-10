"""
Fix isoWeek() algorithm in hotel_dashboard_screen.dart and
compost_dashboard_panel.dart so they produce the same week key as
CompostIngestionService._isoWeek().
"""

NEW_BODY = (
    "    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));\n"
    "    final firstThursday = DateTime(thursday.year, 1, 4);\n"
    "    final week = 1 +\n"
    "        (thursday.difference(firstThursday).inDays / 7).floor();\n"
    "    return '${thursday.year}-W${week.toString().padLeft(2, \\'0\\')}';\n"
)

OLD_BODY_LN = (
    "    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;\n"
    "    final weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();\n"
    "    return '${now.year}-W${weekNum.toString().padLeft(2, \\'0\\')}';\n"
)


def fix_file(path: str, is_crlf: bool = False) -> None:
    with open(path, "r", encoding="utf-8") as fh:
        raw = fh.read()

    # Normalise to LF for matching
    content = raw.replace("\r\n", "\n")

    old_snippet = (
        "    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;\n"
        "    final weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();\n"
        "    return '${now.year}-W${weekNum.toString().padLeft(2, " + "'0'" + ")}';\n"
    )
    new_snippet = (
        "    final thursday = now.add(Duration(days: 3 - ((now.weekday + 6) % 7)));\n"
        "    final firstThursday = DateTime(thursday.year, 1, 4);\n"
        "    final week = 1 +\n"
        "        (thursday.difference(firstThursday).inDays / 7).floor();\n"
        "    return '${thursday.year}-W${week.toString().padLeft(2, " + "'0'" + ")}';\n"
    )

    count = content.count(old_snippet)
    if count == 0:
        print(f"  WARNING: old snippet not found in {path}")
        return

    content = content.replace(old_snippet, new_snippet)
    print(f"  Replaced {count} occurrence(s) in {path}")

    # Restore original line endings
    if is_crlf:
        content = content.replace("\n", "\r\n")

    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(content)


print("Fixing hotel_dashboard_screen.dart ...")
fix_file(
    r"lib\features\hotel\dashboard\hotel_dashboard_screen.dart",
    is_crlf=True,
)

print("Fixing compost_dashboard_panel.dart ...")
fix_file(
    r"lib\features\shared\compost_dashboard_panel.dart",
    is_crlf=False,
)

print("Done.")
