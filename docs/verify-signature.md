# Verifying Artifact Signatures

Each release artifact has been signed with a ECDSA-P256 key. The public key is available in the repository at [here](../signature/bp_agent_key.pub) and can be used to verify the signature of the artifact. 

In order to verify the signature of an artifact, you will need to install [cosign](https://github.com/sigstore/cosign). This can be done by getting the release artifacts from the [cosign releases page](https://github.com/sigstore/cosign/releases/tag/v1.13.1) or by using the following command if you have Go installed:

```bash
go install github.com/sigstore/cosign/cmd/cosign@v1.13.1
```

Once you have cosign installed, you can verify the signature of an artifact by running the following command:

```bash
cosign verify-blob --key ./signature/bp_agent_key.pub --signature <PATH_TO_SIG> <PATH_TO_ARTIFACT>
```

## Example

Heres an example of verifying the signature of an agent binary:

```bash
cosign verify-blob --key ./signature/bp_agent_key.pub --signature dynatrace-bindplane-otel-collector-v1.47.1-darwin-amd64.tar.gz.sig dynatrace-bindplane-otel-collector-v1.47.1-darwin-amd64.tar.gz
```

## Slim build (keyless signatures)

The artifacts of the slim build (`dynatrace-bindplane-otel-collector-slim`) are signed keyless with cosign, there is no public key. Every signed artifact has a sigstore bundle next to it (`<artifact>.sigstore.json`) that holds the signature and the certificate that proves it was created by the release workflow of this repository. This needs cosign v2 or later.

Verify an artifact, or the checksums file that lists all of them:

```bash
cosign verify-blob \
  --bundle <ARTIFACT>.sigstore.json \
  --certificate-identity-regexp '^https://github.com/dynatrace/dynatrace-bindplane-otel-collector/\.github/workflows/base-release\.yml@refs/tags/v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  <ARTIFACT>
```

The certificate identity is the reusable `base-release` workflow, which both release workflows call. If verification fails on the identity, the error shows the identity found in the certificate.

Verify a container image by its digest:

```bash
cosign verify \
  --certificate-identity-regexp '^https://github.com/dynatrace/dynatrace-bindplane-otel-collector/\.github/workflows/base-release\.yml@refs/tags/v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/dynatrace/dynatrace-bindplane-otel-collector-slim:<VERSION>
```

The checksums and the image digests are also attested, which can be checked with the GitHub CLI:

```bash
gh attestation verify <ARTIFACT> --repo dynatrace/dynatrace-bindplane-otel-collector
```
