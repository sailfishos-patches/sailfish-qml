# Sailfish QML
Workplace repo for creating diff patches

## How to manual?
- Fork repo or request addition to organization
- Create branch named your patch name:
`git checkout -b my-patch-name`
- Apply changes
- Create diff:
`git diff master  -- . ':!.github' > unified_diff.patch`
- Publish it to Patchmanager web catalog!

## How to automatic?
- Fork repo or request addition to organization
- Create branch named your patch name:
`git checkout -b my-patch-name`
- Apply changes
- You can copy additional files according to [pm2 guidelines](https://coderus.openrepos.net/pm2/usage/) to the 'patch' folder
- Create pull request
- Github CI will produce zip file for you
- Publish it to Patchmanager web catalog!