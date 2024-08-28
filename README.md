# Sailfish QML
Workplace repo for creating diff patches

## How-to (fully manual)?
- Fork repo or request addition to organization
- Create branch with your Patch name: `git checkout -b my-patch-name`
- Apply changes
- Create diff: `git diff master  -- . ':!.github' > unified_diff.patch`
- Publish it on Patchmanager's Web Catalog!

## How-to (semi-automatic)?
- Fork repo or request addition to organization
- Create branch with your Patch name: `git checkout -b my-patch-name`<br />
  Alternatively this can be done by GitHub's web-frontend.
- Apply changes
- You can copy additional files according to the [Patchmanager guidelines](https://coderus.openrepos.net/pm2/usage/) to the `patch` folder
- Create pull request
- A CI workflow of this GitHub repo will [produce a ZIP file for you](https://github.com/sailfishos-patches/sailfish-qml/actions)
- Publish it on Patchmanager's Web Catalog!

#### Side note
The content of this repo was created by executing `find /usr -name '*.qml' -o -name '*.js'` as root on a freshly installed SailfishOS.
