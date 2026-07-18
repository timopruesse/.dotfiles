"""Session cost/debug logging — shared core; platform adapters live under hooks/."""

from .core import append_jsonl, log_err, now_iso, read_hook_payload

__all__ = ["append_jsonl", "log_err", "now_iso", "read_hook_payload"]
