# Contributing

## Tests

```sh
./test.sh   # uses a temporary HOME and a fake claude; doesn't touch your config
```

CI runs it on Linux and macOS (with the stock bash 3.2) on every push and pull request.

## Releasing

Publishing a GitHub release runs the tests and publishes to npm from CI (trusted
publishing, with provenance):

```sh
npm version patch                              # bump package.json, commit and tag
git push --follow-tags
gh release create vX.Y.Z --verify-tag --generate-notes
```
