# terrafacer

## tagging

### Add git tag to branch

* `git tag -a <tag> -m <message>`
* e.g.: `git tag -a v2.0.0 -m "upgrade to tf 0.13"`

### Push tags to remote

* `git push --tags`

### Consume module version

* Modify the tag in the module

```tf
module "sos-infrasctructure" {
  source = "git::https://github.com/tdfacer/terrafacer.git//terraform/modules/sos?ref=v2.0.0"
}
```

* Re-run `terraform init` to pull down the latest tag
