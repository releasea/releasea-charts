# Releasea Helm Charts

Repository for the public Releasea Helm charts.
This README is intentionally short and routes users to the detailed install documentation.

## Charts

| Chart | Purpose | Details |
|-------|---------|---------|
| [**releasea-platform**](./releasea-platform/) | Install the core platform stack and the default Development quickstart worker | [releasea-platform/README.md](./releasea-platform/README.md) |
| [**releasea-worker**](./releasea-worker/) | Install additional workers for environments or clusters | [releasea-worker/README.md](./releasea-worker/README.md) |

> `releasea-platform` is the primary install entrypoint. `releasea-worker` is used when you need workers beyond the default Development quickstart worker.

## Documentation

- Platform install guide: [docs.releasea.io/?doc=installation](https://docs.releasea.io/?doc=installation)
- Installation modes: [docs.releasea.io/?doc=installation-modes](https://docs.releasea.io/?doc=installation-modes)
- Environments and workers: [docs.releasea.io/?doc=environments-and-workers](https://docs.releasea.io/?doc=environments-and-workers)
- Public components: [docs.releasea.io/?doc=public-components](https://docs.releasea.io/?doc=public-components)
- Platform chart details: [releasea-platform/README.md](./releasea-platform/README.md)
- Worker chart details: [releasea-worker/README.md](./releasea-worker/README.md)

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.
