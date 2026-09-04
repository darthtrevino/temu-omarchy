# Agent Guidelines

## Configuration model

The primary goal of work in this repository is to modify and improve the
in-situ, working desktop configuration. Treat the files currently used by the
running system as the source of truth for behavior and verify changes against
that live configuration.

Maintain this repository as a reusable abstraction of the working system:

- Apply requested changes to the active configuration when it is not already
  linked to the repository.
- Reflect generalizable changes in the corresponding repository source so they
  persist across installation and can be reproduced on another machine.
- Keep machine-specific values, generated files, credentials, and local state
  out of the repository. Represent them with templates, parameters, or
  documented setup steps instead.
- Preserve the setup script's responsibility for linking static configuration
  and generating configuration that requires local values.
