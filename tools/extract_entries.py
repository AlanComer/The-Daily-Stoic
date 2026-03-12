#!/usr/bin/env python3
"""
extract_entries.py — Extract all 366 daily entries from The Daily Stoic PDF.

Usage (from project root):
    pip3 install pdfplumber
    python3 tools/extract_entries.py

Output: assets/data/entries.json — keyed by MM-DD (zero-padded month and day).

PDF structure (verified):
  - 407 pages total; entry pages are pages 14–392 (0-indexed: 13–391)
  - Each entry page:
      Line 0: "Month Nth"  (e.g. "January 1st")
      Line 1: "TITLE IN ALL CAPS"
      Lines 2–N: Quote starting with \u201c (LEFT DOUBLE QUOTATION MARK)
      Attribution: starts with \u2014 (EM DASH), or no em dash (July 29 edge case)
      Body: everything after attribution

Edge cases handled:
  1. July 29: attribution has no leading em dash
  2. September 28: quote has no closing \u201d — em dash on next line ends quote
  3. Author names in body (Aug 2, Aug 26, Oct 1): avoided by state machine
     (only first post-quote non-empty line is captured as attribution)
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import pdfplumber
except ImportError:
    print("ERROR: pdfplumber not installed. Run: pip3 install pdfplumber")
    sys.exit(1)

# Month name → zero-padded month number
MONTH_MAP = {
    "January": "01", "February": "02", "March": "03", "April": "04",
    "May": "05", "June": "06", "July": "07", "August": "08",
    "September": "09", "October": "10", "November": "11", "December": "12",
}

MONTH_NAMES = list(MONTH_MAP.keys())

# Matches "January 1st", "February 29th", etc.
DATE_HEADER_RE = re.compile(
    r"^(" + "|".join(MONTH_NAMES) + r")\s+(\d{1,2})(?:st|nd|rd|th)$"
)


def parse_entry(lines: List[str], page_num: int) -> Optional[Dict]:
    """
    Parse a single entry page's lines into a structured dict.
    Returns None and prints a warning if parsing fails.

    State machine states:
        pre_title    → looking for date header (line 0)
        pre_quote    → looking for line starting with \u201c
        in_quote     → accumulating quote lines
        post_quote   → next non-empty line is attribution
        in_body      → accumulating body lines
    """
    if not lines:
        return None

    # -- Line 0: date header ------------------------------------------------
    date_match = DATE_HEADER_RE.match(lines[0].strip())
    if not date_match:
        return None  # not an entry page

    month_name = date_match.group(1)
    day = int(date_match.group(2))
    month_num = MONTH_MAP[month_name]
    date_key = f"{month_num}-{day:02d}"

    # -- Line 1: title -------------------------------------------------------
    if len(lines) < 2:
        print(f"  WARNING page {page_num}: missing title line")
        return None
    title = lines[1].strip()

    # -- State machine: quote → attribution → body ---------------------------
    state = "pre_quote"
    quote_lines: List[str] = []
    attribution = ""
    body_lines: List[str] = []

    for line in lines[2:]:
        stripped = line.strip()

        if state == "pre_quote":
            if stripped.startswith("\u201c"):
                state = "in_quote"
                quote_lines.append(stripped)
                # Single-line quote that already closes
                if "\u201d" in stripped:
                    state = "post_quote"

        elif state == "in_quote":
            # Edge case 2 (Sep 28): em dash on next line ends unclosed quote
            if stripped.startswith("\u2014"):
                state = "post_quote"
                # This line is the attribution
                attribution = stripped.lstrip("\u2014").strip()
                state = "in_body"
                continue
            quote_lines.append(stripped)
            if "\u201d" in stripped:
                state = "post_quote"

        elif state == "post_quote":
            if not stripped:
                continue
            # Edge case 1 (Jul 29): attribution may lack leading em dash
            attribution = stripped.lstrip("\u2014").strip()
            state = "in_body"

        elif state == "in_body":
            body_lines.append(stripped)

    if state in ("pre_quote", "in_quote"):
        print(f"  WARNING page {page_num} ({date_key}): incomplete parse (state={state})")

    quote = " ".join(q for q in quote_lines if q)
    body = "\n".join(b for b in body_lines if b)

    return {
        "date_key": date_key,
        "month": month_name,
        "day": day,
        "title": title,
        "quote": quote,
        "attribution": attribution,
        "body": body,
    }


def extract_all(pdf_path: Path) -> Tuple[Dict, int]:
    entries: Dict = {}
    problems = 0

    with pdfplumber.open(str(pdf_path)) as pdf:
        total_pages = len(pdf.pages)
        print(f"PDF has {total_pages} pages. Processing...")

        for i, page in enumerate(pdf.pages):
            page_num = i + 1  # 1-indexed for user messages
            text = page.extract_text()
            if not text:
                continue

            lines = [ln for ln in text.splitlines() if ln.strip()]
            if not lines:
                continue

            # Quick check: does line 0 look like a date header?
            if not DATE_HEADER_RE.match(lines[0].strip()):
                continue

            entry = parse_entry(lines, page_num)
            if entry is None:
                problems += 1
                print(f"  PROBLEM page {page_num}: failed to parse")
                continue

            date_key = entry["date_key"]
            if date_key in entries:
                print(f"  WARNING page {page_num}: duplicate key {date_key} — skipping")
                problems += 1
                continue

            entries[date_key] = entry

    return entries, problems


def main():
    project_root = Path(__file__).parent.parent
    pdf_path = project_root / "docs" / "The_Daily_Stoic.pdf"
    output_path = project_root / "assets" / "data" / "entries.json"

    if not pdf_path.exists():
        print(f"ERROR: PDF not found at {pdf_path}")
        sys.exit(1)

    print(f"Reading: {pdf_path}")
    entries, problems = extract_all(pdf_path)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)

    print(f"\nExtracted {len(entries)} entries. Problems: {problems}")
    print(f"Output: {output_path}")

    if len(entries) < 360:
        print("WARNING: Expected ~366 entries — check PDF page range.")


if __name__ == "__main__":
    main()
