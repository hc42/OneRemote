# 0015. MIT license

Date: 2026-10-18 · Status: Accepted

## Context
Without a license the code is "all rights reserved" and nobody may legally reuse it. A
permissive license was wanted. The choice was between MIT and BSD. BSD 2-clause is
essentially MIT in other words; BSD 3-clause adds a clause forbidding the use of the
author's name to endorse derived products. Apache 2.0 adds an explicit patent grant, which
is of little relevance for a small remote-control app.

## Decision
License the project under the MIT license (`LICENSE`, copyright holder: the author).

## Consequences
- Anyone may use, modify and distribute the code, including in closed or commercial
  products, as long as the copyright notice and license text are kept.
- There is no warranty and no restriction on using the author's name; neither MIT nor BSD
  grants rights to third-party trademarks, so the project stays unofficial and does not use
  the manufacturer's brand (see `README.md`).
- Releases made before a license change stay under the license they were published with.
