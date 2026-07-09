# Source Limitations and Gaps

This is the honest boundary of the dump.

## What was captured

- Local Codex JSONL logs for the AutoQuant-origin thread, AnalyticsShinyApp continuation thread, and current projectless mega-thread.

- Plaintext user messages, assistant messages, tool calls, selected tool outputs, and compaction markers.

- Topic-tagged excerpts and validation/failure signals.


## What may not be fully captured

- Encrypted compaction payloads in Codex logs cannot be expanded from plaintext here. Their existence is recorded as compaction markers.

- Regular ChatGPT web-interface threads are not present in local Codex JSONL unless they were pasted into Codex. They require export/paste to become literal source material.

- Tool outputs are sometimes truncated in the logs or by extraction to keep the corpus usable. Full raw JSONL files remain the source if needed.

- Some user requests arrived as attached pasted text files; if the attachment text was ingested into the visible conversation it is included, otherwise the task is represented by the visible wrapper/request.


## How to use this corpus

- Start with `combined_user_request_sequence.md` to see the exact request progression.

- Use `combined_chronology_actions_findings.md` for the step/action trail.

- Use `empirical_findings_validation_signals.md` for QA/failure/fix material.

- Use topic dossiers for narrative clustering.

- Only after reading these should the book draft be pruned or reorganized.
