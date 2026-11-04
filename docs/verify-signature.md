# Verifying Artifact Signatures

The artifacts of both builds, `dynatrace-bindplane-otel-collector` (full) and `dynatrace-bindplane-otel-collector-slim`, are signed keyless with [cosign](https://github.com/sigstore/cosign). There is no public key: the release workflow of this repository gets a short-lived certificate for its own identity and signs with it. Every signed artifact has a sigstore bundle next to it (`<artifact>.sigstore.json`) that holds the signature and the certificate, so it can be verified without any other file.

Signed with cosign are the archives, the checksums file, the Windows MSIs and the artifact bundles (`*-artifacts*.tar.gz`). Verifying the checksums file, and then the artifacts against it with `sha256sum -c`, covers everything the checksums file lists.

This needs cosign v2 or later, see the [cosign releases page](https://github.com/sigstore/cosign/releases) for the installation options.

## Verifying a file

```bash
cosign verify-blob \
  --bundle <ARTIFACT>.sigstore.json \
  --certificate-identity https://github.com/dynatrace/dynatrace-bindplane-otel-collector/.github/workflows/base-release.yml@refs/tags/<TAG> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  <ARTIFACT>
```

`<TAG>` is the release tag: `vX.Y.Z` for a release of the full build, `slim/vX.Y.Z-rc.N` for a release of the slim build. The certificate identity is the reusable `base-release` workflow, which both release workflows call. If verification fails on the identity, the error shows the identity found in the certificate.

To accept any release of one build instead of a single tag, match the identity with `--certificate-identity-regexp`:

| Build | Regular expression |
|---|---|
| full | `^https://github.com/dynatrace/dynatrace-bindplane-otel-collector/\.github/workflows/base-release\.yml@refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$` |
| slim | `^https://github.com/dynatrace/dynatrace-bindplane-otel-collector/\.github/workflows/base-release\.yml@refs/tags/slim/v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$` |

### Example

Verify an agent archive of a full release:

```bash
cosign verify-blob \
  --bundle dynatrace-bindplane-otel-collector-v1.2.0-linux-amd64.tar.gz.sigstore.json \
  --certificate-identity https://github.com/dynatrace/dynatrace-bindplane-otel-collector/.github/workflows/base-release.yml@refs/tags/v1.2.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  dynatrace-bindplane-otel-collector-v1.2.0-linux-amd64.tar.gz
```

## Container images

The container images of the slim build are signed by digest as well. Verify one with:

```bash
cosign verify \
  --certificate-identity-regexp '^https://github.com/dynatrace/dynatrace-bindplane-otel-collector/\.github/workflows/base-release\.yml@refs/tags/slim/v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/dynatrace/dynatrace-bindplane-otel-collector:<VERSION>-slim
```

## Attestations

The checksums files and the digests of the slim container images are also attested. The attestation of an artifact can be checked with the GitHub CLI:

```bash
gh attestation verify <ARTIFACT> --repo dynatrace/dynatrace-bindplane-otel-collector
```

## Releases signed with a key

Releases of the full build that were published before the release workflow moved to keyless signing carry a `<artifact>.sig` file instead of a bundle. They were signed with an ECDSA-P256 key. The public key is available in the repository [here](../signature/bp_agent_key.pub).

The signatures are checked with any cosign version:

```bash
cosign verify-blob --key ./signature/bp_agent_key.pub --signature <PATH_TO_SIG> <PATH_TO_ARTIFACT>
```

For example, an agent binary:

```bash
cosign verify-blob --key ./signature/bp_agent_key.pub --signature dynatrace-bindplane-otel-collector-v1.47.1-darwin-amd64.tar.gz.sig dynatrace-bindplane-otel-collector-v1.47.1-darwin-amd64.tar.gz
```
