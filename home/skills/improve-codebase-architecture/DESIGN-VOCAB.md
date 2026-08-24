# Design vocabulary (architecture reviews)

Use these terms exactly in architecture suggestions. Do not substitute
"component," "service," "API," "boundary," "layer," or "wrapper" when you mean
the terms below.

| Term | Meaning |
| --- | --- |
| **module** | A unit of code with an interface and an implementation. |
| **interface** | What callers depend on — the test surface. |
| **implementation** | What sits behind the interface. |
| **depth** | How much complexity the implementation absorbs relative to the interface. |
| **deep** | Small interface, large implementation. |
| **shallow** | Interface nearly as complex as the implementation. |
| **seam** | Where two modules meet; adapters sit on seams. |
| **adapter** | Host- or environment-specific code behind a seam. |
| **leverage** | One interface serving many call sites. |
| **locality** | Related complexity (and bugs) concentrating in one module. |

## Principles

- **Deletion test:** would deleting this module concentrate complexity, or just move it? "Concentrates" is the signal you want for deepening.
- **The interface is the test surface.**
- **One adapter = hypothetical seam; two = real.** Don't invent ports until a second adapter justifies them.
