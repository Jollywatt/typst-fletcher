#!/usr/bin/env nu

# Run tests and sign the commit by adding it to the tests-passing and tests-failing revset aliases
# which are assumed to exist in jj's repo config file
def test-and-sign [] {
    let commit_id = (jj log -r @ --template commit_id --no-graph)

    mut succeeded = false
    try {
        pixi run tt run
        $succeeded = true
    }

    mut config = open (jj config path --repo)
    if $succeeded {
        let passing = $config.revset-aliases.tests-passing
        $config.revset-aliases.tests-passing = $passing ++ ' | ' ++ $commit_id
    } else {
        let failing = $config.revset-aliases.tests-failing
        $config.revset-aliases.tests-failing = $failing ++ ' | ' ++ $commit_id
    }
    echo ($config | to toml) | save (jj config path --repo) --force
}

# Run tytanic tests and, if using jujutsu vcs, sign the commit
def main [] {
  if (which jj | length) == 0 {
    tt run
  } else {
    test-and-sign
  }
}
