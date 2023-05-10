```
forge test -vvv
```

```
forge test --match-path test/Safe.t.sol
```

```
forge test --match-path test/Safe.t.sol --match-test invariant_testBalanceUnchanged
```

```
forge test -m invariant_testBalanceUnchanged
```

---

```
forge test --gas-report
```

---

```
forge coverage
```

(coverage ignore invariants and testFail) (https://github.com/foundry-rs/foundry/issues/4259 & https://github.com/foundry-rs/foundry/issues/4259#issuecomment-1419010816)

```
forge coverage --report lcov
# lcov --remove lcov.info -o lcov.info 'test/*' 'script/*'
mkdir coverage
mv lcov.info coverage/lcov.info
genhtml -o coverage/results/ coverage/lcov.info --branch-coverage
open coverage/results/index.html
```

`--branch-coverafe` not compatible with `lcov --remove lcov.info -o lcov.info 'test/*' 'script/*'`
