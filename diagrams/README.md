# Diagrams

Rendered, committed diagrams for use in documentation and quick reference.

- `soc-block-diagram.svg` — top-level SoC block diagram (rendered from the
  Mermaid source in `docs/architecture.md`).

To regenerate after editing the Mermaid source:

```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i diagram.mmd -o diagram.svg -b transparent
```
