# How to release this software

1. Bump the version in `metadata.json`

1. Update the `CHANGELOG.md`

1. Update the `REFERENCE.md` by running `bundle exec rake reference`

1. `git commit -am 'Release x.y.z'`

1. `git tag -a 'x.y.z' -m 'x.y.z'`

1. `git push origin main`

1. `git push origin --tags`

Tags will automatically be pushed to the Puppet Forge [marckri/sssd](https://forge.puppet.com/marckri/sssd)
