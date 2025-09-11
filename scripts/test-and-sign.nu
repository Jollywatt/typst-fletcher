#!/usr/bin/env nu

# for use with jujutsu vcs
# run tests and annotate commits with result

def main [] {
    let commit_id = (jj log -r @ --template commit_id --no-graph)
    
    mut succeeded = false
    echo pre
    try {
        pixi run tt run
        $succeeded = true
    }
    echo post

    if (which jdj | length) == 0 {
        echo "Couldn't find jj; results not logged."
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
