# vim.cafe


# TODO

- [ ] xxx

# BUGS

- [ ] Testing framework on VimEngine failed (might because multi-process)

When run `swift test`:

```
􀢄  Test testCountPrefixWithMotion() recorded an issue at VimKeystrokesTest.swift:343:6: Caught error: nvimStartupFailed(VimCafe.NvimSessionError.communicationFailed("Timeout waiting for nvim response"))
```

When run `swift test --filter testCountPrefixWithMotion`:

```
􀟈  Test run started.
􀄵  Testing Library Version: 1070
􀄵  Target Platform: arm64e-apple-macos14.0
􀟈  Suite VimKeystrokesTests started.
􀟈  Test testCountPrefixWithMotion() started.
􁁛  Test testCountPrefixWithMotion() passed after 0.137 seconds.
􁁛  Suite VimKeystrokesTests passed after 0.137 seconds.
􁁛  Test run with 1 test passed after 0.137 seconds.
```

