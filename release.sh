#!/bin/bash

fetch_tags() {
    git fetch --all --force --tags --prune-tags --prune
}

create_release_nightly() {
    printf "create/replace release 'nightly' on branch %s\n" $GITHUB_REF_NAME

    fetch_tags

    RELEASE=nightly
    gh release delete \
        --cleanup-tag \
        --yes \
        $RELEASE \
        2>/dev/null || true

    # Workaround for https://github.com/cli/cli/issues/8458
    printf "waiting for tag to be deleted\n"
    while fetch_tags; git tag -l | grep $RELEASE; do
        sleep 10;
        printf "still waiting...\n"
    done

    fetch_tags

    gh release create \
        --title "Nightly" \
        --notes "$(date +'%Y-%m-%d %H:%M:%S')" \
        --target $GITHUB_REF \
        --latest=false \
        $RELEASE

    fetch_tags
}

create_release_prod() {
    EXISTING=$(gh release list \
        --json tagName \
        --jq "[.[] | select(.tagName == \"$RELEASE\").tagName][0]")

    if [[ -z $EXISTING ]]; then
        printf "create new release '%s'\n" $RELEASE
        gh release create \
            --title $RELEASE \
            --notes "$(date +'%Y-%m-%d %H:%M:%S')" \
            --verify-tag \
            $RELEASE
    else
        printf "use existing release '%s'\n" $RELEASE
    fi
}

upload_artifacts() {
    printf "uploading artifacts to '%s'\n" $RELEASE

    gh release upload --clobber $RELEASE $DISTDIR/*
}

DISTDIR="./dist"

printf "verify github auth status:\n%s\n\n" "$(gh auth status)"

if [[ $GITHUB_REF_TYPE == 'tag' ]]; then
    RELEASE=$GITHUB_REF_NAME
    create_release_prod
elif [[ $GITHUB_REF_TYPE == 'branch' ]]; then
    RELEASE="nightly"
    create_release_nightly
fi

if [[ -e $DISTDIR ]]; then
    upload_artifacts
else
    printf "no artifacts to upload\n"
fi
